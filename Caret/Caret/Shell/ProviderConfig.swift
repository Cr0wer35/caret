import Combine
import Foundation

/// An LLM provider Caret can talk to. Each case exposes its defaults
/// (endpoint, model, Keychain account for its API key).
enum Provider: String, Codable, Sendable, CaseIterable, Identifiable {
    case anthropic
    case openAICompatible = "openai-compatible"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: "Anthropic (Claude)"
        case .openAICompatible: "OpenAI-compatible"
        }
    }

    /// Default base URL. Users typically override only for `openAICompatible`
    /// (to point at Ollama, Groq, Together, a self-hosted model, etc.).
    var defaultEndpoint: URL {
        switch self {
        case .anthropic: URL(string: "https://api.anthropic.com/v1")!
        case .openAICompatible: URL(string: "https://api.openai.com/v1")!
        }
    }

    var defaultModel: String {
        switch self {
        case .anthropic: "claude-haiku-4-5"
        case .openAICompatible: "gpt-5.4-nano"
        }
    }

    /// Keychain account key for this provider's API key.
    var keychainAccount: String {
        "caret.\(rawValue).apikey"
    }
}

/// Active provider plus its endpoint override and model name.
/// Serialized into `UserDefaults` as JSON.
struct ProviderConfig: Codable, Sendable, Equatable {
    var provider: Provider
    var endpoint: URL
    var model: String

    static let `default` = ProviderConfig(
        provider: .anthropic,
        endpoint: Provider.anthropic.defaultEndpoint,
        model: Provider.anthropic.defaultModel
    )
}

/// Mutable, observable store for `ProviderConfig`. Changes are
/// persisted to `UserDefaults` on every mutation. API keys themselves
/// live in the Keychain via `KeychainStore`.
@MainActor
final class ProviderStore: ObservableObject {
    @Published var config: ProviderConfig { didSet { persist() } }

    private let defaults: UserDefaults
    private static let storageKey = "caret.providerConfig"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.config = Self.load(from: defaults) ?? .default
    }

    private static func load(from defaults: UserDefaults) -> ProviderConfig? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(ProviderConfig.self, from: data)
    }

    func apiKey(for provider: Provider) -> String? {
        try? KeychainStore.get(provider.keychainAccount)
    }

    func setAPIKey(_ key: String, for provider: Provider) throws {
        try KeychainStore.set(key, for: provider.keychainAccount)
    }

    func clearAPIKey(for provider: Provider) {
        try? KeychainStore.delete(provider.keychainAccount)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
