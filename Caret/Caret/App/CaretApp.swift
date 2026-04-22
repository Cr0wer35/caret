import AppKit
import SwiftUI

@main
struct CaretApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                permissions: appDelegate.permissions,
                onReopenOnboarding: { appDelegate.reopenOnboarding() },
                onDebugCapture: { appDelegate.performDebugCapture() }
            )
        } label: {
            MenuBarLabel(permissions: appDelegate.permissions)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var permissions: PermissionsMonitor

    var body: some View {
        Image(systemName: iconName)
    }

    private var iconName: String {
        switch permissions.status {
        case .granted: "pencil.tip"
        case .denied: "exclamationmark.triangle.fill"
        }
    }
}

private struct MenuContent: View {
    @ObservedObject var permissions: PermissionsMonitor
    let onReopenOnboarding: () -> Void
    let onDebugCapture: () -> Void

    var body: some View {
        Text("Caret — v0.1.0-dev")
            .font(.caption)

        Divider()

        switch permissions.status {
        case .granted:
            Text("Accessibility: enabled")
                .foregroundStyle(.secondary)
            Button("Capture focused text", action: onDebugCapture)
                .keyboardShortcut("c", modifiers: [.command, .option])
        case .denied:
            Button("Enable Accessibility…", action: onReopenOnboarding)
        }

        Divider()

        Button("Quit Caret") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
