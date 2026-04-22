import Foundation

/// One event emitted during a streaming correction request.
enum CorrectionEvent: Sendable, Equatable {
    /// Incremental text chunk from the LLM (partial JSON).
    case delta(String)
    /// Final parsed response — guaranteed to arrive once per successful request.
    case completed(CorrectionResponse)
}

/// Error taxonomy shared by all providers. M5c will extend this with
/// `rateLimited`, `offline`, etc.
enum LLMError: Error, Equatable {
    case missingAPIKey
    case invalidEndpoint
    case unexpectedResponse
    case httpStatus(Int)
    case malformedResponse(String)
    case cancelled
}

/// An LLM provider streams `CorrectionEvent`s for a single request.
/// Implementations must surface cancellation by honoring `Task.isCancelled`.
protocol LLMProvider: Sendable {
    func correct(
        context: FocusedContext,
        config: ProviderConfig,
        apiKey: String,
        systemPrompt: String
    ) -> AsyncThrowingStream<CorrectionEvent, Error>
}
