import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?
    private let permissions: PermissionsMonitor

    init(permissions: PermissionsMonitor) {
        self.permissions = permissions
    }

    func showIfNeeded() {
        guard permissions.status == .denied else { return }
        show()
    }

    func show() {
        if window == nil {
            let root = OnboardingView(permissions: permissions) { [weak self] in
                self?.close()
            }
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable]
            window.title = "Welcome to Caret"
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
    }
}
