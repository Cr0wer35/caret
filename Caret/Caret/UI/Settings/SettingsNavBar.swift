import SwiftUI

/// Top-of-window nav bar à la Raycast / Dropover: large icon over a
/// caption label, with a tinted background pill behind the active tab
/// and a subtle hover highlight for the others.
struct SettingsNavBar: View {
    @Binding var selection: SettingsTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                NavButton(
                    tab: tab,
                    isSelected: tab == selection,
                    action: { selection = tab }
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

private struct NavButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22, weight: .medium))
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(background)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var foreground: Color {
        if isSelected { return .accentColor }
        return .secondary
    }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.16) }
        if isHovered { return Color.secondary.opacity(0.08) }
        return .clear
    }
}
