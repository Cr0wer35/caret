import AppKit
import SwiftUI

/// About tab — version, license, project link.
struct AboutSettingsTab: View {
    private let repoURL = URL(string: "https://github.com/Cr0wer35/caret")!

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "pencil.tip")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            VStack(spacing: 4) {
                Text("Caret")
                    .font(.system(size: 18, weight: .semibold))
                Text(AppVersion.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("A streaming, in-place grammar correction assistant for macOS.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Divider()
                .padding(.horizontal, 60)

            VStack(spacing: 6) {
                Button("View on GitHub") {
                    NSWorkspace.shared.open(repoURL)
                }
                .buttonStyle(.link)

                Text("MIT License · © 2026 Mathis Fumel")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
