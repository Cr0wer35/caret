import AppKit
import Combine
import CoreGraphics
import os

/// Owns a `CGEventTap` that fires on every `keyUp` and triggers a
/// `TextCapture` read. Lives for the lifetime of the app; `self` is
/// passed by unretained pointer to the C callback, so never free it.
@MainActor
final class InputCoordinator: ObservableObject {
    @Published private(set) var lastContext: FocusedContext?
    private let textCapture: TextCapture
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(textCapture: TextCapture) {
        self.textCapture = textCapture
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

    fileprivate func handleKeyUp() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let ctx = await self.textCapture.focusedContext() else { return }
            self.lastContext = ctx
            let msg = """
                bundle=\(ctx.bundleID ?? "nil") \
                cursor=\(ctx.cursorRange.location)+\(ctx.cursorRange.length) \
                text=\(ctx.text.prefix(80))
                """
            Log.capture.notice("\(msg, privacy: .public)")
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
