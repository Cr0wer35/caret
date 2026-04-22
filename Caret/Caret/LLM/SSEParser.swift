import Foundation

/// One parsed Server-Sent Event.
struct SSEEvent: Sendable, Equatable {
    let event: String?
    let data: String
}

/// HTTP utilities shared by LLM providers.
nonisolated enum HTTPBody {
    /// Drains up to `maxBytes` of an async byte sequence into a UTF-8
    /// string. Used on non-2xx responses to surface the API's error
    /// payload in log messages.
    static func read(_ bytes: URLSession.AsyncBytes, maxBytes: Int) async throws -> String {
        var buffer = Data()
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= maxBytes { break }
        }
        return String(data: buffer, encoding: .utf8) ?? "<binary response>"
    }
}

/// Parses a line-oriented SSE stream into `SSEEvent`s — one event per
/// `data:` line. Both Anthropic and OpenAI send single-line JSON data
/// payloads, so we don't bother with the spec's multi-line `data:`
/// joining rules; each `data:` line becomes its own event.
nonisolated enum SSEParser {
    static func parse<S>(_ lines: S) -> AsyncThrowingStream<SSEEvent, Error>
    where S: AsyncSequence & Sendable, S.Element == String {
        AsyncThrowingStream { continuation in
            let task = Task {
                var pendingEvent: String?
                do {
                    for try await line in lines {
                        if line.hasPrefix("event:") {
                            pendingEvent = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let data = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            continuation.yield(SSEEvent(event: pendingEvent, data: String(data)))
                            pendingEvent = nil
                        }
                        // Empty lines, SSE comments (":..."), and other fields: skip.
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
