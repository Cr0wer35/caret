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
    private let textCapture: TextCapture
    private let providerStore: ProviderStore
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

    init(textCapture: TextCapture, providerStore: ProviderStore) {
        self.textCapture = textCapture
        self.providerStore = providerStore
    }

    func start() {
        guard tap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyUp.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard
            let createdTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: inputCoordinatorCallback,
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

    private func startCorrection(for fire: TriggerFire) {
        inflightCorrection?.cancel()
        lastCorrection = .pending

        let config = providerStore.config
        guard let apiKey = providerStore.apiKey(for: config.provider) else {
            lastCorrection = .failed("No API key set for \(config.provider.displayName)")
            Log.capture.error("correction skipped: no API key for \(config.provider.rawValue, privacy: .public)")
            return
        }

        let provider = Self.makeProvider(for: config.provider)
        let prompt = CorrectionPrompt.v1
        let context = fire.context

        inflightCorrection = Task { @MainActor [weak self] in
            var accumulated = ""
            do {
                for try await event in provider.correct(
                    context: context,
                    config: config,
                    apiKey: apiKey,
                    systemPrompt: prompt
                ) {
                    try Task.checkCancellation()
                    switch event {
                    case .delta(let text):
                        accumulated += text
                        self?.lastCorrection = .streaming(accumulated)
                    case .completed(let response):
                        self?.lastCorrection = .completed(response)
                        Log.capture.notice(
                            "correction completed shouldCorrect=\(response.shouldCorrect, privacy: .public)"
                        )
                    }
                }
            } catch is CancellationError {
                // Superseded by a newer fire — leave state as-is.
            } catch let error as LLMError where error == .cancelled {
                // Provider surfaced the cancellation itself.
            } catch {
                let message = String(describing: error)
                self?.lastCorrection = .failed(message)
                Log.capture.error("correction failed: \(message, privacy: .public)")
            }
        }
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

/// C-convention callback invoked by the event tap on the main run loop.
/// File-scope so it carries no Swift-level captures.
private nonisolated(unsafe) let inputCoordinatorCallback: CGEventTapCallBack = { _, type, event, refcon in
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let coordinator = Unmanaged<InputCoordinator>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        Task { @MainActor in coordinator.reenableTap() }
        return Unmanaged.passUnretained(event)
    }

    if type == .keyUp {
        Task { @MainActor in coordinator.handleKeyUp() }
    }

    return Unmanaged.passUnretained(event)
}
