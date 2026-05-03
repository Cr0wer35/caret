import AppKit
import SwiftUI

@main
struct CaretApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover(
                permissions: appDelegate.permissions,
                pauseState: appDelegate.pauseState,
                dailyCounter: appDelegate.dailyCounter,
                shortcutStore: appDelegate.pauseShortcutStore,
                onTogglePause: { appDelegate.pauseState.toggle() },
                onReopenOnboarding: { appDelegate.reopenOnboarding() },
                onShowSettings: { appDelegate.showSettings() },
                onToggleDebugOverlay: { appDelegate.toggleDebugOverlay() },
                onQuit: { NSApp.terminate(nil) }
            )
        } label: {
            MenuBarLabel(
                permissions: appDelegate.permissions,
                pauseState: appDelegate.pauseState
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var permissions: PermissionsMonitor
    @ObservedObject var pauseState: PauseState

    var body: some View {
        Image(systemName: iconName)
    }

    private var iconName: String {
        switch (permissions.status, pauseState.isPaused) {
        case (.denied, _): "exclamationmark.triangle.fill"
        case (_, true): "pause.circle.fill"
        case (_, false): "pencil.tip"
        }
    }
}
