import Foundation

/// Calls an OpenAI-compatible `chat/completions` endpoint with
/// `stream: true` and `response_format: json_object`. Works against
/// OpenAI proper, Ollama, Groq, Together, Mistral — anything that
/// speaks the OpenAI wire format.
struct OpenAIProvider: LLMProvider {
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
                        if sse.data == "[DONE]" { break }
                        lastRawEvent = sse.data
                        if let apiError = Self.extractAPIError(from: sse.data) {
                            throw LLMError.malformedResponse("API error: \(apiError)")
                        }
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
        let url = config.endpoint.appending(path: "chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "stream": true,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": context.text],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func extractAPIError(from json: String) -> String? {
        guard
            let data = json.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = root["error"] as? [String: Any],
            let message = error["message"] as? String
        else { return nil }
        return message
    }

    private static func extractDeltaText(from json: String) -> String? {
        guard
            let data = json.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let first = choices.first,
            let delta = first["delta"] as? [String: Any],
            let content = delta["content"] as? String
        else { return nil }
        return content
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
