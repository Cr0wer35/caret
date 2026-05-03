import SwiftUI

/// Privacy tab — denylist editor (apps Caret refuses to read from).
struct PrivacySettingsTab: View {
    @ObservedObject var store: DenylistStore

    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsSection(
                    "Denylist",
                    subtitle: "Caret never reads text from these apps."
                ) {
                    list

                    HStack(spacing: 8) {
                        TextField("com.example.app", text: $draft)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                            .onSubmit(commitDraft)
                        Button("Add", action: commitDraft)
                            .controlSize(.large)
                            .disabled(trimmedDraft.isEmpty)
                    }

                    HStack {
                        Spacer()
                        Button("Reset to defaults") { store.resetToDefault() }
                            .controlSize(.small)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(28)
        }
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                if store.bundleIDs.isEmpty {
                    Text("No apps denylisted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(store.bundleIDs.enumerated()), id: \.element) { index, id in
                        denylistRow(id)
                        if index < store.bundleIDs.count - 1 {
                            Divider().padding(.leading, 28)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.2), lineWidth: 0.5)
        )
    }

    private func denylistRow(_ id: String) -> some View {
        HStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(id)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button {
                store.remove(id)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private func commitDraft() {
        store.add(draft)
        draft = ""
    }
}
