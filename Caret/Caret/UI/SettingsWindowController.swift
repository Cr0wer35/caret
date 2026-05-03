import AppKit
import SwiftUI

/// Manages the lifecycle of the Settings `NSWindow`. Opens key + focused,
/// since the user is explicitly interacting with Caret's own UI.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let providerStore: ProviderStore
    private let shortcutStore: PauseShortcutStore
    private let denylistStore: DenylistStore
    private let loginItem: LoginItemController
    private let connectionTester: ConnectionTester

    init(
        providerStore: ProviderStore,
        shortcutStore: PauseShortcutStore,
        denylistStore: DenylistStore,
        loginItem: LoginItemController,
        connectionTester: ConnectionTester
    ) {
        self.providerStore = providerStore
        self.shortcutStore = shortcutStore
        self.denylistStore = denylistStore
        self.loginItem = loginItem
        self.connectionTester = connectionTester
    }

    func show() {
        if window == nil {
            let root = SettingsView(
                providerStore: providerStore,
                shortcutStore: shortcutStore,
                denylistStore: denylistStore,
                loginItem: loginItem,
                connectionTester: connectionTester
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
