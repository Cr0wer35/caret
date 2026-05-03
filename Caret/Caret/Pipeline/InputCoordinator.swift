import AppKit
import Combine
import CoreGraphics
import os

/// Owns a `CGEventTap` that fires on every `keyUp` and triggers a
/// `TextCapture` read. Lives for the lifetime of the app; `self` is
/// passed by unretained pointer to the C callback, so never free it.
/// One correction request's life cycle, exposed to the UI.
enum CorrectionState: Sendable, Equatable {
    case pending
    case streaming(String)
    case completed(CorrectionResponse)
    case failed(String)
}

@MainActor
final class InputCoordinator: ObservableObject {
    @Published private(set) var lastContext: FocusedContext?
    @Published private(set) var lastBlocked: String?
    @Published private(set) var lastFire: TriggerFire?
    @Published private(set) var lastCorrection: CorrectionState?
    nonisolated let acceptArmed = AcceptArmedFlag()
    let acceptRequests = PassthroughSubject<Void, Never>()
    private let textCapture: TextCapture
    private let providerStore: ProviderStore
    private let pauseState: PauseState
    private let correctionCache = CorrectionCache()
    private let rateLimiter = RateLimiter()
    private var inflightCorrection: Task<Void, Never>?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private lazy var triggerEngine = TriggerEngine { [weak self] fire in
        Task { @MainActor in
            guard let self else { return }
            self.lastFire = fire
            let reason = fire.reason.rawValue
            let bundle = fire.context.bundleID ?? "nil"
            Log.capture.notice(
                "trigger fire reason=\(reason, privacy: .public) bundle=\(bundle, privacy: .public)"
            )
            self.startCorrection(for: fire)
        }
    }

    init(textCapture: TextCapture, providerStore: ProviderStore, pauseState: PauseState) {
        self.textCapture = textCapture
        self.providerStore = providerStore
        self.pauseState = pauseState
    }

    func start() {
        guard tap == nil else { return }
        let mask = CGEventMask(
            (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.keyDown.rawValue)
        )
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard
            let createdTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: InputCallback.cFn,
                userInfo: refcon
            )
        else {
            Log.capture.error("CGEvent.tapCreate failed — Accessibility permission missing?")
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, createdTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: createdTap, enable: true)
        self.tap = createdTap
        self.runLoopSource = source
        Log.capture.notice("input event tap started")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        tap = nil
        runLoopSource = nil
    }

    fileprivate func reenableTap() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
        Log.capture.notice("input event tap re-enabled after system disable")
    }

    fileprivate func handleTabAccept() {
        Log.capture.notice("tab intercepted (accept armed)")
        acceptRequests.send()
    }

    private func startCorrection(for fire: TriggerFire) {
        inflightCorrection?.cancel()
        lastCorrection = .pending

        let config = providerStore.config
        guard let apiKey = providerStore.apiKey(for: config.provider) else {
            lastCorrection = .failed("No API key set for \(config.provider.displayName)")
            Log.capture.error("correction skipped: no API key")
            return
        }

        let cacheKey = CorrectionCache.key(
            provider: "\(config.provider.rawValue)+\(CorrectionPrompt.version)",
            model: config.model,
            text: fire.context.text
        )

        inflightCorrection = Task { @MainActor [weak self] in
            await self?.runCorrection(
                context: fire.context,
                config: config,
                apiKey: apiKey,
                cacheKey: cacheKey
            )
        }
    }

    private func runCorrection(
        context: FocusedContext,
        config: ProviderConfig,
        apiKey: String,
        cacheKey: String
    ) async {
        if let cached = await correctionCache.get(cacheKey) {
            lastCorrection = .completed(cached)
            Log.capture.notice("correction cache hit")
            return
        }

        do {
            try await rateLimiter.take()
        } catch {
            failCorrection(with: error, prefix: "blocked")
            return
        }

        let provider = Self.makeProvider(for: config.provider)
        var accumulated = ""
        do {
            for try await event in provider.correct(
                context: context,
                config: config,
                apiKey: apiKey,
                systemPrompt: CorrectionPrompt.v1
            ) {
                try Task.checkCancellation()
                switch event {
                case .delta(let text):
                    accumulated += text
                    lastCorrection = .streaming(accumulated)
                case .completed(let response):
                    lastCorrection = .completed(response)
                    await correctionCache.set(cacheKey, response)
                    Log.capture.notice(
                        """
                        correction completed shouldCorrect=\(response.shouldCorrect, privacy: .public) \
                        original='\(response.original, privacy: .public)' \
                        corrected='\(response.corrected, privacy: .public)'
                        """
                    )
                }
            }
        } catch is CancellationError {
            // Superseded by a newer fire — leave state as-is.
        } catch let error as LLMError where error == .cancelled {
            // Provider surfaced the cancellation itself.
        } catch {
            failCorrection(with: error, prefix: "failed")
        }
    }

    private func failCorrection(with error: Error, prefix: String) {
        let llm = (error as? LLMError) ?? .malformedResponse(String(describing: error))
        lastCorrection = .failed(llm.userDescription)
        Log.capture.error("correction \(prefix, privacy: .public): \(llm.userDescription, privacy: .public)")
    }

    private static func makeProvider(for kind: Provider) -> any LLMProvider {
        switch kind {
        case .anthropic: AnthropicProvider()
        case .openAICompatible: OpenAIProvider()
        }
    }

    fileprivate func handleKeyUp() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard !self.pauseState.isPaused else { return }
            let outcome = await self.textCapture.capture()
            switch outcome {
            case .captured(let ctx):
                self.lastContext = ctx
                self.lastBlocked = nil
                await self.triggerEngine.evaluate(ctx)
                let msg = """
                    bundle=\(ctx.bundleID ?? "nil") \
                    cursor=\(ctx.cursorRange.location)+\(ctx.cursorRange.length) \
                    text=\(ctx.text.prefix(80))
                    """
                Log.capture.debug("\(msg, privacy: .public)")
            case .blocked(let bundleID):
                self.lastContext = nil
                self.lastBlocked = bundleID
                Log.capture.notice("blocked \(bundleID, privacy: .public)")
            case .unavailable:
                // Keep previous state — no focus / secure field / AX miss.
                break
            }
        }
    }
}

/// C-convention callback for the event tap. Wrapped in a `nonisolated`
/// enum so the closure literal escapes the file's `@MainActor` default
/// isolation — the callback runs on the main run loop but Swift can't
/// see that across the C boundary.
private enum InputCallback {
    nonisolated(unsafe) static let cFn: CGEventTapCallBack = { @Sendable _, type, event, refcon in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let coordinator = Unmanaged<InputCoordinator>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            Task { @MainActor in coordinator.reenableTap() }
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let modifierBits =
                CGEventFlags.maskCommand.rawValue
                | CGEventFlags.maskAlternate.rawValue
                | CGEventFlags.maskControl.rawValue
                | CGEventFlags.maskShift.rawValue
            let isPlainTab = keyCode == 0x30 && (event.flags.rawValue & modifierBits) == 0
            if isPlainTab {
                let armed = coordinator.acceptArmed.isArmed
                Log.capture.notice("plain tab keyDown armed=\(armed, privacy: .public)")
                if armed {
                    Task { @MainActor in coordinator.handleTabAccept() }
                    return nil
                }
            }
        }

        if type == .keyUp {
            Task { @MainActor in coordinator.handleKeyUp() }
        }

        return Unmanaged.passUnretained(event)
    }
}
