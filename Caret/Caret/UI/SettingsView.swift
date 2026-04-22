import SwiftUI

/// One-screen settings form: provider picker, model, endpoint (for
/// OpenAI-compatible), and the API key. The key is stored in the
/// Keychain via `ProviderStore`; the rest goes to `UserDefaults`.
struct SettingsView: View {
    @ObservedObject var store: ProviderStore
    var onClose: () -> Void = {}

    @State private var apiKey: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 14) {
                labeled("Provider") {
                    Picker("", selection: providerBinding) {
                        ForEach(Provider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                labeled("Model") {
                    TextField("", text: $store.config.model)
                        .textFieldStyle(.roundedBorder)
                }

                if store.config.provider == .openAICompatible {
                    labeled("Endpoint") {
                        TextField("", text: endpointBinding)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                labeled("API key") {
                    SecureField("", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Clear API key") {
                    store.clearAPIKey(for: store.config.provider)
                    apiKey = ""
                }
                .disabled(apiKey.isEmpty)

                Spacer()

                Button("Cancel", action: onClose)
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    save()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear(perform: loadKey)
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
    }

    private func save() {
        if apiKey.isEmpty {
            store.clearAPIKey(for: store.config.provider)
        } else {
            try? store.setAPIKey(apiKey, for: store.config.provider)
        }
    }

    private func labeled<Content: View>(
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
}
