import SwiftUI

/// General tab — startup behavior + the global pause shortcut.
struct GeneralSettingsTab: View {
    @ObservedObject var loginItem: LoginItemController
    @ObservedObject var shortcutStore: PauseShortcutStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsSection(
                    "Startup",
                    subtitle: "Open Caret automatically when you log in."
                ) {
                    HStack {
                        Text("Open at login")
                        Spacer()
                        Toggle("", isOn: launchToggleBinding)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    if let error = loginItem.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                SettingsSection(
                    "Pause shortcut",
                    subtitle: "Toggle Caret on and off from any app."
                ) {
                    HStack {
                        Text("Shortcut")
                        Spacer()
                        KeyRecorder(shortcut: $shortcutStore.shortcut)
                    }
                }
            }
            .padding(28)
        }
    }

    private var launchToggleBinding: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        )
    }
}
