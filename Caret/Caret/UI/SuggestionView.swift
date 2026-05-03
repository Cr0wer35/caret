import SwiftUI

/// The pill rendered inside the floating suggestion panel: the
/// corrected text on the left (multi-line, scrolls beyond ~5 lines),
/// a `⇥ Tab` hint on the right. The panel itself is transparent —
/// this view draws the entire visible card.
struct SuggestionView: View {
    let corrected: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScrollView {
                Text(corrected)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary.opacity(0.92))
                    .frame(maxWidth: 460, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .padding(.vertical, 2)
            }
            .frame(maxHeight: 110)

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
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 3)
        )
        .padding(2)
        .frame(maxWidth: 540)
        .fixedSize()
    }
}
