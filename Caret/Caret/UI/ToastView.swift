import SwiftUI

/// Tiny transient pill rendered by `ToastNotifier`. Used today only
/// for the "Copied — paste with ⌘V" pasteboard fallback.
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
            )
            .padding(2)
            .fixedSize()
    }
}
