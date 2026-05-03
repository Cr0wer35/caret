import SwiftUI

/// AI Provider tab — provider, model, endpoint (OpenAI-compatible only),
/// API key, and a "Test connection" button.
struct ProviderSettingsTab: View {
    @ObservedObject var store: ProviderStore
    @ObservedObject var tester: ConnectionTester

    @State private var apiKey: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsSection(
                    "Provider",
                    subtitle: "Pick which model answers your corrections."
                ) {
                    field("Provider") {
                        Picker("", selection: providerBinding) {
                            ForEach(Provider.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    field("Model") {
                        TextField("", text: $store.config.model)
                            .textFieldStyle(.roundedBorder)
                    }

                    if store.config.provider == .openAICompatible {
                        field("Endpoint") {
                            TextField("", text: endpointBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                SettingsSection(
                    "Authentication",
                    subtitle: "Your API key is stored in the macOS Keychain."
                ) {
                    field("API key") {
                        SecureField("", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: apiKey, perform: persistKey)
                    }

                    HStack(spacing: 10) {
                        Button("Test connection") {
                            Task { await tester.test() }
                        }
                        .controlSize(.large)
                        .disabled(tester.status == .testing || apiKey.isEmpty)

                        statusBadge
                        Spacer()
                    }
                }
            }
            .padding(28)
        }
        .onAppear(perform: loadKey)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch tester.status {
        case .idle:
            EmptyView()
        case .testing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Testing…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .success:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private func field<Content: View>(
        _ label: String,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .frame(width: 90, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var providerBinding: Binding<Provider> {
        Binding(
            get: { store.config.provider },
            set: { newValue in
                store.config = ProviderConfig(
                    provider: newValue,
                    endpoint: newValue.defaultEndpoint,
                    model: newValue.defaultModel
                )
                tester.reset()
                loadKey()
            }
        )
    }

    private var endpointBinding: Binding<String> {
        Binding(
            get: { store.config.endpoint.absoluteString },
            set: { raw in
                if let url = URL(string: raw) {
                    store.config.endpoint = url
                }
            }
        )
    }

    private func loadKey() {
        apiKey = store.apiKey(for: store.config.provider) ?? ""
        tester.reset()
    }

    private func persistKey(_ newValue: String) {
        if newValue.isEmpty {
            store.clearAPIKey(for: store.config.provider)
        } else {
            try? store.setAPIKey(newValue, for: store.config.provider)
        }
        tester.reset()
    }
}
