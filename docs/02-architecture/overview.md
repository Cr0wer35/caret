# Architecture Overview

_Last updated: 2026-04-21_

## Shape of the system

Caret is a single macOS app with five logical components, each isolated behind a clean boundary:

```
┌─────────────────────────────────────────────────────────────┐
│                        Caret.app                            │
│                                                             │
│  ┌──────────────┐   ┌──────────────────┐   ┌─────────────┐  │
│  │ Input        │──▶│ Trigger Engine   │──▶│ LLM Layer   │  │
│  │ Pipeline     │   │ (debounce,       │   │ (BYOK, SSE, │  │
│  │ (AX + Event  │   │  boundary,       │   │  prompt,    │  │
│  │  Tap)        │   │  cancel)         │   │  provider)  │  │
│  └──────┬───────┘   └──────────────────┘   └──────┬──────┘  │
│         │                                         │         │
│         ▼                                         ▼         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  UI Layer                            │   │
│  │   (floating NSPanel ghost text, follows caret)       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  App Shell                           │   │
│  │  (menu bar, settings, login item, Keychain, perms)   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

Each component has one job and one owner in code. No hidden coupling across layers.

## Data flow (happy path)

1. **User types** in any text field of any macOS app.
2. **Input Pipeline** observes via `CGEventTap` (keystroke detection) and `AXUIElement` (reads focused field's text + cursor position).
3. **Trigger Engine** decides whether to act: enough new content (≥ 3 words or sentence boundary), typing paused ≥ 400ms, field not blacklisted.
4. **LLM Layer** builds a prompt from the last 300 chars before cursor, calls the configured provider with SSE streaming, cancels if the user types more meanwhile.
5. **UI Layer** renders the streamed suggestion as ghost text in a floating panel positioned near the caret.
6. **User** presses `Tab` (accept) or keeps typing (dismiss). Accept replaces the corrected span via `AXUIElementSetAttributeValue`; dismiss clears the panel.

## Key design decisions (summary)

| Concern | Decision | Rationale |
|---|---|---|
| Text capture | Accessibility API primary, CGEventTap for keystroke triggers | Standard for system-wide tools, well-documented |
| Electron/web fallback | Degraded mode: show pill at top-right when caret position unresolvable | Never fail silently, graceful degradation |
| Trigger timing | Debounce 400ms + ≥ 3 new words OR sentence boundary | Balance responsiveness and API cost |
| LLM streaming | SSE via `URLSession` or a thin community SDK | Full control, no heavy deps |
| Provider abstraction | `LLMProvider` protocol, first impl = Anthropic | Future-proof without over-abstracting |
| BYOK storage | macOS Keychain (Data Protection class) | Native, encrypted, per-app isolation |
| UI | Single `NSPanel` floating layer, SwiftUI content | Native feel, performant |
| Concurrency | Swift 6 strict, Actor-based isolation | Future-proof, safer |
| Distribution | Developer ID signed + notarized + Sparkle 2 | Out-of-store, auto-update |
| Minimum target | macOS 13 Ventura | SMAppService availability |

Each decision has a short ADR in `docs/02-architecture/adr/`.

## What this architecture optimizes for

- **Latency**: every layer is async, nothing blocks the main thread.
- **Privacy**: text never leaves the machine except when explicitly sent to the user-configured LLM provider. Keystrokes are not persisted.
- **Simplicity**: 5 components, each < 500 lines of Swift ideally. If a file grows past 800 lines, split it.
- **Testability**: each component has a protocol-based interface; UI layer is mocked in tests by swapping the renderer.
- **Extensibility**: adding OpenAI/Gemini/local is adding a new `LLMProvider` implementation, nothing else changes.

## What this architecture does NOT try to do

- No plugin system. Not needed in v0.1.
- No IPC between processes. Single app, single process.
- No background daemon separate from the UI app. `SMAppService` auto-launches the app itself.
- No custom input method (IME). The overhead of becoming a macOS IME is not worth it for this use case.
