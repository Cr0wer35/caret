import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permissions: PermissionsMonitor
    var onGranted: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to Caret")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(
                "Caret needs the macOS Accessibility API to read the text you're typing "
                    + "and insert corrections. No data leaves your Mac without going through "
                    + "your API key."
            )
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Open System Settings", action: PermissionsMonitor.openSystemSettings)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(width: 480, height: 260)
        .onChange(of: permissions.status) { newStatus in
            if newStatus == .granted { onGranted() }
        }
    }
}
