# Changelog

All notable changes to Caret will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- LLM pipeline end-to-end (M5b): `LLM/LLMProvider.swift` exposes a `Sendable` protocol returning an `AsyncThrowingStream<CorrectionEvent, Error>`; `LLM/CorrectionResponse.swift` is the structured JSON target (`should_correct`, `span_start`, `span_end`, `corrected`); `LLM/CorrectionPrompt.swift` holds the versioned system prompt (v1). `LLM/SSEParser.swift` yields one `SSEEvent` per `data:` line (plus a small `HTTPBody.read` helper shared by providers). `LLM/AnthropicProvider.swift` streams via the Messages API (`content_block_delta` extraction); `LLM/OpenAIProvider.swift` streams via `chat/completions` with `response_format: json_object` and handles `data: [DONE]` + inline `error` payloads. `InputCoordinator` now holds a `@Published lastCorrection: CorrectionState?` and, on every `TriggerEngine` fire, cancels the previous in-flight request and kicks off a new one against the active provider (resolved from `ProviderStore` + Keychain). `UI/DebugOverlay.swift` renders the live correction state (pending / streaming / completed / failed). Non-2xx responses surface the API's error body; stream-level errors (Anthropic `event: error`, OpenAI inline `error` payloads) are parsed and shown in the overlay.

- Provider configuration + Keychain (M5a): `Shell/KeychainStore.swift` wraps `Security` directly (`SecItemAdd/Copy/Update/Delete`), one UTF-8 string per account under service `com.caret.Caret`. `Shell/ProviderConfig.swift` exposes a `Provider` enum (`anthropic`, `openAICompatible`), a `ProviderConfig` (provider + endpoint + model) persisted as JSON in `UserDefaults`, and an `@MainActor ObservableObject ProviderStore` that routes API-key CRUD to the Keychain. `UI/SettingsView.swift` + `UI/SettingsWindowController.swift` render a picker + model + endpoint (for OpenAI-compatible) + API-key form, reachable from the menu bar via "Settings…" (⌘,). Defaults: Anthropic `claude-haiku-4-5` and OpenAI-compatible `gpt-5.4-nano` at `https://api.openai.com/v1`.

- Trigger engine (M4): `Pipeline/TriggerEngine.swift` — off-main actor that debounces keystroke-driven captures into a small stream of "ready to correct" fires. Rule: `(newWords ≥ 3 OR text ends in ".!?") AND idle ≥ 400ms`. Resets state on focus change across apps. `InputCoordinator` feeds every `.captured` outcome to the engine and publishes `lastFire: TriggerFire?`; per-keyup logs dropped to `.debug`, fire events stay at `.notice`. Debug overlay gains a "Last fire" row showing reason + timestamp.

- Privacy denylist (M3): `Shell/Denylist.swift` holds a hardcoded `Sendable` set of bundle IDs (password managers, terminals) checked before any AX text read. `TextCapture.capture()` now returns a `CaptureOutcome` enum (`.captured` / `.blocked` / `.unavailable`); `InputCoordinator` exposes `lastBlocked` alongside `lastContext`, and `DebugOverlay` renders a red "Blocked" state when a denylisted app is focused. Renamed from "blacklist" to satisfy SwiftLint's inclusive-language rule without disabling it.

- Input-driven text capture (M2b): `Pipeline/InputCoordinator.swift` owns a session-level `CGEventTap` (`.defaultTap`) listening on `keyUp`; each keystroke triggers a `TextCapture` read, publishes the latest `FocusedContext` via `@Published`, and logs it. `UI/DebugOverlay.swift` + `UI/DebugOverlayWindowController.swift` render a floating utility window that streams the current context live without stealing focus. A menu entry "Toggle debug overlay" (`⌥⌘D`) shows/hides it. The M2a one-shot menu action is removed (superseded).
- Text capture primitive (M2a): `Pipeline/AXHelpers.swift` exposes `nonisolated` wrappers over the Accessibility C APIs (`focusedElement`, `string`, `range`, `bounds(for:in:)`, `bundleID`, `isSecure`). `Pipeline/TextCaptureActor.swift` wraps those helpers into an off-main `TextCapture` actor returning a `FocusedContext { text, cursorRange, caretScreenRect?, bundleID? }` snapshot. Logs to `os.Logger` category `capture`. Initial app matrix captured in `docs/04-dev/m2-app-matrix.md`.
- Accessibility permission flow (M1): onboarding window shown at launch when permission is missing, `Permissions.swift` wraps `AXIsProcessTrusted` + 1 Hz async poller, menu bar icon reflects live status (`pencil.tip` / `exclamationmark.triangle.fill`), menu exposes a re-open shortcut on revocation.
- Initial Xcode project (macOS app, Swift 6, SwiftUI).
- Menu bar app shell via `MenuBarExtra` (placeholder icon, quit).
- `LSUIElement = YES` (no Dock icon, no app switcher entry).
- `MACOSX_DEPLOYMENT_TARGET = 13.0` (minimum macOS 13 Ventura).
- `SWIFT_VERSION = 6.0` with `SWIFT_STRICT_CONCURRENCY = complete`.
- `ENABLE_APP_SANDBOX = NO` (required for upcoming Accessibility + CGEventTap usage).
- SwiftLint config (`.swiftlint.yml`).
- swift-format config (`.swift-format`).
- Pre-commit hook installer (`scripts/install-hooks.sh`).
- GitHub Actions build workflow (macos-15, lint + build).
- MIT `LICENSE`.
- Full project documentation in `docs/` (product, architecture, roadmap, dev).
