# Tech Stack

_Last updated: 2026-04-21_

Deliberately small. Each dependency is a decision we'll have to live with.

## Core

| What | Choice | Why |
|---|---|---|
| Language | **Swift 6** | Native to macOS, strict concurrency, best tooling |
| UI | **SwiftUI + AppKit hybrid** | SwiftUI where it works, AppKit for `NSPanel`/`NSStatusItem` |
| Project type | **Xcode project** (not pure SPM) | Needs app target, entitlements, code signing |
| Min macOS | **13 Ventura** | `SMAppService`, Swift 6 runtime support |
| Concurrency | **Swift 6 strict** (`-strict-concurrency=complete`) | Future-proof, no warnings debt |
| Architecture | **Actor-based**, protocol-oriented boundaries | Safe concurrency, testable |

## Dependencies

The rule: **add a dependency only when rewriting it would be non-trivial**. Everything else is in-house.

### Production dependencies (v0.1)

| Name | Purpose | Justification |
|---|---|---|
| **Sparkle 2** | Auto-updates | The de facto standard for out-of-store macOS apps. Rewriting = absurd. |

That's it. One dependency for v0.1.

Everything else (Keychain wrapper, SSE parser, JSON decoder, event tap manager, AX helpers) is in-house Swift, because:

- Each one is < 200 lines.
- Each one is boring, stable code with no "features" to keep up with.
- Fewer deps = fewer supply-chain risks on a security-adjacent app.

### Dev dependencies

| Name | Purpose |
|---|---|
| **SwiftLint** | Style / common-mistakes checks in CI |
| **swift-format** (Apple) | Consistent formatting |

Both are dev-only, not shipped.

### Rejected (for now)

- [**jamesrochabrun/SwiftAnthropic**](https://github.com/jamesrochabrun/SwiftAnthropic), [**tthew/anthropic-swift-sdk**](https://github.com/tthew/anthropic-swift-sdk), [**marcusziade/AnthropicKit**](https://github.com/marcusziade/AnthropicKit) — community Anthropic SDKs. Rejected because our usage is one endpoint with SSE, ~150 lines of URLSession code. Adding an SDK is more surface area than value.
- [**kishikawakatsumi/KeychainAccess**](https://github.com/kishikawakatsumi/KeychainAccess) — Keychain wrapper. Rejected because our Keychain usage is 3 operations (store, read, delete) of strings, ~80 lines of Security framework code.
- Any analytics SDK (Sentry, TelemetryDeck, etc.). No analytics by default.
- Any logging framework. `os.Logger` is enough.

### Things that might be added later

- **MLX Swift** or **llama.cpp** bindings — if v0.2+ adds local LLM support.
- **Mockingbird** or **ViewInspector** — if the testing story gets heavier.
- An Anthropic SDK — if Anthropic ships an official Swift SDK and it's well-maintained.

Each one gets its own ADR before being added.

## Project structure

Target layout inside the Xcode project:

```
Caret/
├── Caret.xcodeproj
├── Caret/
│   ├── App/
│   │   ├── CaretApp.swift              # @main entry point
│   │   ├── AppDelegate.swift           # NSApplicationDelegate for NSStatusItem
│   │   └── Onboarding/
│   │       └── OnboardingView.swift    # Accessibility permission flow
│   │
│   ├── Pipeline/
│   │   ├── InputCoordinator.swift      # @MainActor, owns the event tap
│   │   ├── TextCaptureActor.swift      # AX reads
│   │   ├── TriggerEngine.swift         # Debounce + boundary logic
│   │   └── AXHelpers.swift             # Thin wrappers over AXUIElement C APIs
│   │
│   ├── LLM/
│   │   ├── LLMProvider.swift           # Protocol
│   │   ├── AnthropicProvider.swift     # Claude implementation
│   │   ├── SSEParser.swift             # SSE line-by-line parser
│   │   ├── CorrectionResponse.swift    # JSON model
│   │   └── CorrectionCache.swift       # LRU cache
│   │
│   ├── UI/
│   │   ├── SuggestionPanel.swift       # The floating NSPanel
│   │   ├── MenuBar.swift               # NSStatusItem
│   │   └── Settings/
│   │       ├── SettingsWindow.swift
│   │       ├── GeneralTab.swift
│   │       ├── ProviderTab.swift
│   │       ├── PrivacyTab.swift
│   │       └── AboutTab.swift
│   │
│   ├── Shell/
│   │   ├── KeychainStore.swift         # API key storage
│   │   ├── LoginItem.swift             # SMAppService wrapper
│   │   ├── Permissions.swift           # AX permission check + prompt
│   │   ├── Blacklist.swift             # Bundle ID + role checks
│   │   └── Logger+Caret.swift          # os.Logger categories
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Prompts/
│   │   │   └── CorrectionPrompt.v1.md  # Versioned system prompt
│   │   └── Localizable.xcstrings       # Strings for FR and EN UI
│   │
│   ├── Info.plist
│   └── Caret.entitlements               # Minimal or absent
│
├── CaretTests/
│   ├── TriggerEngineTests.swift
│   ├── SSEParserTests.swift
│   ├── CorrectionCacheTests.swift
│   └── BlacklistTests.swift
│
└── CaretUITests/
    └── OnboardingUITests.swift
```

No grab-bag `Utils/` or `Common/`. Every file has a home.

## Build configuration

Two configurations: `Debug` and `Release`. No beta/staging configs needed for v0.1.

Key flags:

- `SWIFT_STRICT_CONCURRENCY = complete`
- `DEAD_CODE_STRIPPING = YES`
- `ENABLE_HARDENED_RUNTIME = YES` (Release only)
- `DEVELOPMENT_TEAM` set per-developer locally (not committed).

## Testing

- **Unit tests** via Swift Testing (the new testing framework, not XCTest), using `@Test` and `#expect`.
- **UI tests** via XCTest (Swift Testing does not fully cover UI testing yet).
- Coverage goal: ≥ 70% on `Pipeline/`, `LLM/`, `Shell/` — not on UI code.

## Formatting & lint

- SwiftLint: strict set, enforced in CI and pre-commit hook.
- swift-format: run on save in Xcode, checked in CI.
- Pre-commit hook: format + lint + fast unit tests. Adds ~5 seconds per commit.

## Git hygiene

- Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- Branches: `main` is always green. Features in short-lived branches.
- PR-sized commits. No giant "initial commit" after weeks of work.
- `CHANGELOG.md` updated on each merged PR. Human-readable, user-facing.

## Language policy for the codebase

- **Code**: English (identifiers, comments, commit messages).
- **User-facing strings**: French and English in `Localizable.xcstrings`. French is primary for v0.1 (author is a native French speaker; makes dogfooding trivial).
- **Docs in `docs/`**: English primarily, mixed FR/EN commentary acceptable when capturing discussion. Any reader should be able to follow without translation tools.
