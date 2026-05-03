import SwiftUI

/// Native-feel popover for the menu bar. Three sections: status header
/// (state dot + version), stats (today's count + active shortcut),
/// then primary + tertiary actions.
struct MenuBarPopover: View {
    @ObservedObject var permissions: PermissionsMonitor
    @ObservedObject var pauseState: PauseState
    @ObservedObject var dailyCounter: DailyCounter
    @ObservedObject var shortcutStore: PauseShortcutStore
    let onTogglePause: () -> Void
    let onReopenOnboarding: () -> Void
    let onShowSettings: () -> Void
    let onToggleDebugOverlay: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            stats
            Divider()
            primaryAction
            Divider()
            tertiaryActions
        }
        .frame(width: 260)
        .padding(.bottom, 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Caret")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("v0.1.0-dev")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 7, height: 7)
                Text(stateLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Today")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(countLabel)
                    .fontWeight(.medium)
            }
            HStack {
                Text("Shortcut")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(shortcutStore.shortcut.displayString)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var primaryAction: some View {
        VStack(spacing: 0) {
            switch permissions.status {
            case .denied:
                actionRow(
                    title: "Enable Accessibility…",
                    systemImage: "lock.shield.fill",
                    action: onReopenOnboarding
                )
            case .granted:
                actionRow(
                    title: pauseState.isPaused ? "Resume" : "Pause",
                    systemImage: pauseState.isPaused ? "play.fill" : "pause.fill",
                    trailing: shortcutStore.shortcut.displayString,
                    action: onTogglePause
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    private var tertiaryActions: some View {
        VStack(spacing: 0) {
            menuRow(title: "Settings…", shortcut: "⌘,", action: onShowSettings)
            menuRow(title: "Toggle debug overlay", shortcut: "⌥⌘D", action: onToggleDebugOverlay)
            menuRow(title: "Quit Caret", shortcut: "⌘Q", action: onQuit)
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
    }

    private var stateColor: Color {
        switch permissions.status {
        case .denied: .red
        case .granted: pauseState.isPaused ? .orange : .green
        }
    }

    private var stateLabel: String {
        switch permissions.status {
        case .denied: "Accessibility disabled"
        case .granted: pauseState.isPaused ? "Paused" : "Active"
        }
    }

    private var countLabel: String {
        let count = dailyCounter.count
        return "\(count) " + (count == 1 ? "fix" : "fixes")
    }

    private func actionRow(
        title: String,
        systemImage: String,
        trailing: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HoverableRow {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        } action: {
            action()
        }
    }

    private func menuRow(
        title: String,
        shortcut: String,
        action: @escaping () -> Void
    ) -> some View {
        HoverableRow {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        } action: {
            action()
        }
    }
}

/// Tappable row with subtle hover highlight matching native menu items.
private struct HoverableRow<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.accentColor.opacity(0.18) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
