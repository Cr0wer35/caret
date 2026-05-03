import SwiftUI

/// Container shell: Raycast-style icon nav at the top, selected tab
/// content below. Each tab owns its own state.
struct SettingsView: View {
    let providerStore: ProviderStore
    let shortcutStore: PauseShortcutStore
    let denylistStore: DenylistStore
    let loginItem: LoginItemController
    let connectionTester: ConnectionTester

    @State private var selection: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavBar(selection: $selection)
            Divider()
            content
        }
        .frame(width: 580, height: 460)
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .general:
            GeneralSettingsTab(loginItem: loginItem, shortcutStore: shortcutStore)
        case .provider:
            ProviderSettingsTab(store: providerStore, tester: connectionTester)
        case .privacy:
            PrivacySettingsTab(store: denylistStore)
        case .about:
            AboutSettingsTab()
        }
    }
}
