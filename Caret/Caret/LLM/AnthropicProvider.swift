import Foundation

/// Calls Anthropic's Messages API with `stream: true` and surfaces
/// `content_block_delta` text chunks as `CorrectionEvent.delta`.
/// The full JSON is accumulated and decoded at stream end.
struct AnthropicProvider: LLMProvider {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func correct(
        context: FocusedContext,
        config: ProviderConfig,
        apiKey: String,
        systemPrompt: String
    ) -> AsyncThrowingStream<CorrectionEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try Self.buildRequest(
                        context: context,
                        config: config,
                        apiKey: apiKey,
                        systemPrompt: systemPrompt
                    )
                    let (bytes, response) = try await urlSession.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw LLMError.unexpectedResponse
                    }
                    guard http.statusCode == 200 else {
                        let body = try await HTTPBody.read(bytes, maxBytes: 4096)
                        throw LLMError.fromHTTPStatus(http.statusCode, body: body)
                    }

                    var accumulated = ""
                    var lastRawEvent = ""
                    for try await sse in SSEParser.parse(bytes.lines) {
                        try Task.checkCancellation()
                        lastRawEvent = sse.data
                        if sse.event == "error" {
                            throw LLMError.malformedResponse("API error: \(sse.data)")
                        }
                        guard sse.event == "content_block_delta" else { continue }
                        if let text = Self.extractDeltaText(from: sse.data) {
                            accumulated += text
                            continuation.yield(.delta(text))
                        }
                    }

                    guard !accumulated.isEmpty else {
                        throw LLMError.malformedResponse(
                            lastRawEvent.isEmpty ? "(empty stream)" : lastRawEvent
                        )
                    }

                    let decoded = try Self.decodeResponse(accumulated)
                    continuation.yield(.completed(decoded))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: LLMError.translate(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func buildRequest(
        context: FocusedContext,
        config: ProviderConfig,
        apiKey: String,
        systemPrompt: String
    ) throws -> URLRequest {
        let url = config.endpoint.appending(path: "messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 512,
            "stream": true,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": context.text]
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func extractDeltaText(from json: String) -> String? {
        guard
            let data = json.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let delta = root["delta"] as? [String: Any],
            let text = delta["text"] as? String
        else { return nil }
        return text
    }

    private static func decodeResponse(_ accumulated: String) throws -> CorrectionResponse {
        guard let data = accumulated.data(using: .utf8) else {
            throw LLMError.malformedResponse(accumulated)
        }
        do {
            return try JSONDecoder().decode(CorrectionResponse.self, from: data)
        } catch {
            throw LLMError.malformedResponse(accumulated)
        }
    }
}
