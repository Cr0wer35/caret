import Foundation

/// One event emitted during a streaming correction request.
enum CorrectionEvent: Sendable, Equatable {
    /// Incremental text chunk from the LLM (partial JSON).
    case delta(String)
    /// Final parsed response — guaranteed to arrive once per successful request.
    case completed(CorrectionResponse)
}

/// Closed error taxonomy shared by all providers and surfaced into the
/// overlay via `userDescription`.
enum LLMError: Error, Equatable {
    case missingAPIKey
    case invalidKey
    case invalidEndpoint
    case unexpectedResponse
    case httpStatus(Int)
    case malformedResponse(String)
    case cancelled
    case rateLimited
    case offline
    case timeout
    case contextTooLong
}

extension LLMError {
    /// User-facing message shown in the debug overlay.
    var userDescription: String {
        switch self {
        case .missingAPIKey: "No API key set"
        case .invalidKey: "Invalid API key — check Settings"
        case .invalidEndpoint: "Invalid endpoint URL"
        case .unexpectedResponse: "Unexpected response from provider"
        case .httpStatus(let code): "HTTP \(code)"
        case .malformedResponse(let body): body
        case .cancelled: "Cancelled"
        case .rateLimited: "Rate limited — wait a moment"
        case .offline: "Offline — check your connection"
        case .timeout: "Request timed out"
        case .contextTooLong: "Text too long for this model"
        }
    }

    /// Maps an HTTP non-2xx response to a specific case where possible.
    /// Falls back to `.malformedResponse` carrying the raw body.
    static func fromHTTPStatus(_ status: Int, body: String) -> LLMError {
        switch status {
        case 401, 403:
            return .invalidKey
        case 413:
            return .contextTooLong
        case 429:
            return .rateLimited
        case 400:
            let lowered = body.lowercased()
            if lowered.contains("context") && (lowered.contains("long") || lowered.contains("limit")) {
                return .contextTooLong
            }
            return .malformedResponse("HTTP 400: \(body)")
        default:
            return .malformedResponse("HTTP \(status): \(body)")
        }
    }

    /// Maps a transport-level `URLError` to the matching case.
    static func fromURLError(_ error: URLError) -> LLMError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .malformedResponse("network: \(error.localizedDescription)")
        }
    }

    /// Normalizes any thrown error into a single `LLMError`. Used by
    /// providers in their outer `catch` so the caller only ever sees
    /// `LLMError`.
    static func translate(_ error: Error) -> LLMError {
        if let llm = error as? LLMError { return llm }
        if error is CancellationError { return .cancelled }
        if let urlError = error as? URLError { return .fromURLError(urlError) }
        return .malformedResponse(String(describing: error))
    }
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
