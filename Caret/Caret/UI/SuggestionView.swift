import SwiftUI

/// The pill rendered inside the floating suggestion panel: corrected
/// text on the left, a `⇥ Tab` hint on the right. The panel itself is
/// transparent — this view draws the entire visible card.
struct SuggestionView: View {
    let corrected: String

    var body: some View {
        HStack(spacing: 10) {
            Text(corrected)
                .font(.system(size: 13))
                .foregroundStyle(.primary.opacity(0.9))
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: 360, alignment: .leading)

            HStack(spacing: 4) {
                Text("⇥")
                    .font(.system(size: 11, weight: .medium))
                Text("Tab")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.secondary.opacity(0.4), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
        )
        .padding(2)
        .fixedSize()
    }
}
