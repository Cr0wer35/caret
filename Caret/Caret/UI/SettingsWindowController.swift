import AppKit
import SwiftUI

/// Manages the lifecycle of the Settings `NSWindow`. Opens key + focused,
/// since the user is explicitly interacting with Caret's own UI.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let store: ProviderStore

    init(store: ProviderStore) {
        self.store = store
    }

    func show() {
        if window == nil {
            let root = SettingsView(
                store: store,
                onClose: { [weak self] in self?.close() }
            )
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable]
            window.title = "Caret — Settings"
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
