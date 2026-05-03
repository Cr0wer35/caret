import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permissions: PermissionsMonitor
    var onGranted: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            hero

            VStack(spacing: 6) {
                Text("Welcome to Caret")
                    .font(.system(size: 22, weight: .semibold))
                Text("One quick permission and you're ready.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            valueProps

            Button(action: PermissionsMonitor.openSystemSettings) {
                HStack(spacing: 6) {
                    Text("Open System Settings")
                    Image(systemName: "arrow.up.forward.app")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Text("Caret will close this window automatically once you grant access.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 460)
        .onChange(of: permissions.status) { newStatus in
            if newStatus == .granted { onGranted() }
        }
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 84, height: 84)
            Image(systemName: "pencil.tip")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var valueProps: some View {
        VStack(alignment: .leading, spacing: 14) {
            valueRow(
                icon: "eye",
                title: "Read what you type",
                subtitle: "Only the text in the focused field, never anything else."
            )
            valueRow(
                icon: "sparkles",
                title: "Suggest a fix in place",
                subtitle: "Press ⇥ to accept, keep typing to dismiss."
            )
            valueRow(
                icon: "lock.shield.fill",
                title: "Stay private",
                subtitle: "Nothing leaves your Mac without your API key."
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }

    private func valueRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
