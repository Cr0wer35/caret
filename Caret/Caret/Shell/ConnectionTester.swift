import Combine
import Foundation

/// Drives the "Test connection" button in the AI Provider tab.
/// Sends one tiny correction request through the active provider
/// and reports the resulting state to the UI.
@MainActor
final class ConnectionTester: ObservableObject {
    enum Status: Equatable {
        case idle
        case testing
        case success
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    private let store: ProviderStore

    init(store: ProviderStore) {
        self.store = store
    }

    func reset() {
        status = .idle
    }

    func test() async {
        let config = store.config
        guard let key = store.apiKey(for: config.provider), !key.isEmpty else {
            status = .failed(LLMError.missingAPIKey.userDescription)
            return
        }

        status = .testing
        let provider = Self.makeProvider(for: config.provider)
        let context = FocusedContext(
            text: "ping",
            cursorRange: NSRange(location: 4, length: 0),
            caretScreenRect: nil,
            bundleID: nil
        )

        do {
            for try await event in provider.correct(
                context: context,
                config: config,
                apiKey: key,
                systemPrompt: CorrectionPrompt.v1
            ) {
                if case .completed = event {
                    status = .success
                    return
                }
            }
            status = .failed("No response from provider")
        } catch let llm as LLMError {
            status = .failed(llm.userDescription)
        } catch {
            status = .failed(LLMError.translate(error).userDescription)
        }
    }

    private static func makeProvider(for kind: Provider) -> any LLMProvider {
        switch kind {
        case .anthropic: AnthropicProvider()
        case .openAICompatible: OpenAIProvider()
        }
    }
}
