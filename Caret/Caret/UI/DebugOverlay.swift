import SwiftUI

/// Dev-only floating view. Shows the most recent `FocusedContext` emitted
/// by the input tap, updated in real time via the coordinator's
/// `@Published` snapshot.
struct DebugOverlay: View {
    @ObservedObject var coordinator: InputCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caret — Debug")
                .font(.headline)

            if let bundle = coordinator.lastBlocked {
                Text("Blocked")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                row("bundle", bundle)
                Text("No AX read, no LLM call. This app is on the privacy denylist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let ctx = coordinator.lastContext {
                row("bundle", ctx.bundleID ?? "—")
                row("cursor", "\(ctx.cursorRange.location)+\(ctx.cursorRange.length)")
                row("rect", ctx.caretScreenRect.map { String(describing: $0) } ?? "—")

                Divider()

                ScrollView {
                    Text(ctx.text.isEmpty ? "(empty)" : ctx.text)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 140)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)
            } else {
                Text("Waiting for input…")
                    .foregroundStyle(.secondary)
            }

            if let fire = coordinator.lastFire {
                Divider()
                Text("Last fire")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                row("reason", fire.reason.rawValue)
                row("at", Self.fireTimeFormatter.string(from: fire.at))
            }

            if let correction = coordinator.lastCorrection {
                Divider()
                Text("Correction")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                correctionBody(correction)
            }
        }
        .padding(12)
        .frame(width: 360)
    }

    @ViewBuilder
    private func correctionBody(_ state: CorrectionState) -> some View {
        switch state {
        case .pending:
            row("status", "calling LLM…")
        case .streaming(let accumulated):
            row("status", "streaming")
            ScrollView {
                Text(accumulated)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 80)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(4)
        case .completed(let response):
            row("status", "done")
            row("shouldFix", String(response.shouldCorrect))
            if response.shouldCorrect {
                row("chars", String(response.corrected.count))
                ScrollView {
                    Text(response.corrected)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 80)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)
            }
        case .failed(let message):
            row("status", "error")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private static let fireTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
