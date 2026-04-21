# LLM Layer

_Last updated: 2026-04-21_

This layer owns everything between "here is a context string" and "here is a corrected string". It is the only component allowed to talk to the outside world.

## Provider abstraction

```swift
protocol LLMProvider: Sendable {
    var id: String { get }                    // "anthropic", "openai", ...
    var model: String { get }                 // "claude-haiku-4-5", ...
    func correct(
        context: String,
        language: Language,
        cancellation: CancellationToken
    ) -> AsyncThrowingStream<CorrectionChunk, Error>
}

struct CorrectionChunk {
    let deltaText: String    // incremental text from SSE
    let isFinal: Bool
}
```

One protocol, one return type. The UI layer does not care which provider is behind it.

### First implementation — Anthropic

`AnthropicProvider: LLMProvider` using **Claude Haiku 4.5** by default.

Rationale:
- Fastest TTFT among current cloud models (~600 ms on medium prompts).
- Strong French quality.
- Structured outputs available — we can constrain the model to return only a JSON schema when needed.
- Reasonable price for BYOK users (`~$0.80/MTok input, $4/MTok output` pricing class).

Implementation options, in order of preference:

1. **Raw `URLSession` with manual SSE parsing.** Zero dependencies, full control, ~150 lines of Swift. Preferred for v0.1.
2. **Community SDK** like [jamesrochabrun/SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic) if raw implementation becomes a maintenance burden.
3. **No official Anthropic Swift SDK** existed as of our last check — treat as "don't rely on it, but use it if/when it ships and stabilizes".

### Future implementations

Protocols are in place; actual code deferred until v0.2 or user demand:
- `OpenAIProvider`
- `GeminiProvider` (free tier is attractive for casual users)
- `LocalProvider` (via `llama.cpp` bindings or `MLX` on Apple Silicon)

Adding any of these is: new file, new test, new dropdown entry in settings. No other change.

## Prompt design

Two approaches are possible. We implement option B.

### Option A — plain text in/out (rejected)

Give the model a context and ask for a corrected version. Easy to implement but has three problems:

- The model sometimes adds explanations ("Here is your corrected text: ...").
- The model sometimes over-edits (reformulates instead of correcting).
- Hard to know what changed — we have to diff client-side.

### Option B — structured JSON output (chosen)

Using Claude's **structured outputs** feature ([Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)), the model returns:

```json
{
  "should_correct": true,
  "span_start": 42,
  "span_end": 61,
  "corrected": "phrase corrigée"
}
```

Where:
- `should_correct`: `false` if the text is already fine (most common case, short-circuit UI).
- `span_start` / `span_end`: the character range in the original context that needs replacement.
- `corrected`: the replacement text.

Advantages:
- No parsing heuristics.
- We know exactly what to highlight and replace.
- Streaming still works — we parse partial JSON as it arrives (or wait for completion since payloads are small).
- If the model returns `should_correct: false`, UI does nothing (no flicker).

### System prompt (draft)

```
You are a grammar and spelling corrector. You receive a snippet of text ending
at the user's current cursor position. Your job: return a minimal correction,
or indicate no correction is needed.

Rules:
- Only fix clear spelling, grammar, and punctuation errors.
- NEVER rewrite for style, tone, or length.
- NEVER translate.
- Preserve the author's casing, abbreviations, slang, and informal language.
- Preserve the author's language (French stays French, English stays English).
- If the text is already correct, return {"should_correct": false}.

Respond with JSON only, matching this schema: { ... }
```

The prompt is **separate from the code**, stored in `Resources/Prompts/CorrectionPrompt.v1.md`, versioned. Changing it is a PR, not a code change.

## Streaming

Anthropic's API exposes SSE via `stream: true`. Events received:

- `message_start`
- `content_block_start`
- `content_block_delta` (the text deltas we care about)
- `content_block_stop`
- `message_stop`

The implementation parses SSE line-by-line, extracts `data: {...}` events, decodes `content_block_delta.delta.text`, and yields to the `AsyncThrowingStream`.

Minimal implementation sketch:

```swift
let (bytes, response) = try await URLSession.shared.bytes(for: request)
for try await line in bytes.lines {
    guard line.hasPrefix("data: ") else { continue }
    let payload = String(line.dropFirst(6))
    if payload == "[DONE]" { return }
    let event = try decoder.decode(SSEEvent.self, from: Data(payload.utf8))
    if case .contentBlockDelta(let delta) = event {
        continuation.yield(.init(deltaText: delta.text, isFinal: false))
    }
}
```

We prefer `URLSession.bytes(for:)` over a full SDK because the event shape is stable and simple.

## BYOK — API key storage

API keys live in the **macOS Keychain**, Data Protection class, per-app only (no sharing group).

Wrapper: one file `KeychainStore.swift`, ~80 lines, using `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` directly. We avoid `KeychainAccess` (third-party wrapper) for v0.1 to keep deps minimal.

Keys stored:
- `caret.provider.anthropic.apiKey`
- `caret.provider.openai.apiKey` (when v0.2 ships)

The UI reads the key only at the moment of a request; it's not kept in memory between calls.

Reference: [Apple — Storing Keys in the Keychain](https://developer.apple.com/documentation/security/storing-keys-in-the-keychain).

## Caching

A small LRU cache avoids hitting the API on repeated identical contexts (common when users re-focus a field without editing):

- Key: SHA-256 of `(providerId, model, contextString, language, promptVersion)`.
- Value: the last `CorrectionResponse`.
- Capacity: 100 entries, evict least-recently-used.
- TTL: 10 minutes (correction decisions can drift slightly with model updates; short TTL is safe).
- Purely in-memory, cleared on app quit.

Estimated hit rate: 10–30% in casual use, more when the user hesitates on the same sentence.

## Error handling

| Error | UX |
|---|---|
| No API key configured | Menu bar shows "!", settings pane opens on click |
| 401 / 403 | Same as above with explicit "invalid key" message |
| 429 rate limit | Exponential backoff, pause for 30 seconds, menu bar hint |
| Network offline | Silent — retry on next trigger, no error UI |
| Timeout (> 5s) | Cancel, no display |
| Malformed JSON response | Log, skip display, count toward a rate of "bad responses" in logs |

Errors never interrupt typing. Caret fails silently for the user's benefit.

## Rate budget

To prevent runaway costs with BYOK keys, Caret enforces a soft cap:

- Maximum **30 requests per minute** per active session.
- If exceeded, Caret pauses for 30 seconds (with menu bar indicator).
- Configurable between 10 and 120 per minute in settings.

This also acts as a safety net against bugs in the trigger engine.

## Privacy

- Only the **context window** (default 300 chars before cursor) is sent.
- The app identifier is **not** sent (no telemetry).
- The user's language preference is sent (e.g. `"fr-FR"`).
- HTTPS only. TLS pinning is not implemented for v0.1 (over-engineering).
- If Caret ever ships a managed cloud offering, the same API shape and privacy guarantees apply.
