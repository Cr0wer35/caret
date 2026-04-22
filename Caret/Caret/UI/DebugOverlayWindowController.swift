import AppKit
import SwiftUI

/// Floating utility window that hosts `DebugOverlay`. Does not steal
/// focus from the user's current app — we use `orderFrontRegardless`
/// instead of `makeKeyAndOrderFront`.
@MainActor
final class DebugOverlayWindowController {
    private var window: NSWindow?
    private let coordinator: InputCoordinator

    init(coordinator: InputCoordinator) {
        self.coordinator = coordinator
    }

    var isVisible: Bool { window?.isVisible ?? false }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: DebugOverlay(coordinator: coordinator))
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .resizable, .utilityWindow]
            window.title = "Caret Debug"
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            self.window = window
        }
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.close()
    }
}
