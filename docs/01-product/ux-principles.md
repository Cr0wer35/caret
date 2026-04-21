# UX Principles

_Last updated: 2026-04-21_

The north star: **invisible when idle, instant when needed, zero friction to accept or ignore**.

## Core UX rules

### 1. Ghost text, not auto-replace

Caret never modifies the user's text without explicit consent. The suggestion appears as a floating ghost near the cursor; only `Tab` triggers replacement.

Rationale: the user often writes abbreviations, slang, names, or intentional fragments. Auto-replacing them is a worse experience than no correction at all. Trust is built by never surprising the user.

### 2. One keystroke to accept

`Tab` is the universal accept key. Any other key (continuing to type, `Escape`, arrows, `Enter`) dismisses the suggestion.

Rationale: accepting must be cheaper than ignoring. If accepting costs two keystrokes, users will default to ignoring.

### 3. Suggestion appears near the cursor

The ghost text is rendered in a small, floating `NSPanel` positioned immediately next to the caret (cursor) position in the focused text field. The panel follows the caret as typing continues.

Fallback if caret position cannot be resolved (some Electron or web-embedded fields): show the suggestion in a small fixed pill at the top-right of the screen or in the menu bar. Never fail silently.

### 4. Streaming, not batch

The suggestion is streamed token-by-token from the LLM. The user sees words appear in real time — this signals that something is happening and sets latency expectations. A 600ms TTFT feels fast when streaming starts quickly.

### 5. Debounce, don't spam

Caret does not call the LLM on every keystroke. It waits for a pause in typing (default: 400–600ms of inactivity) or for a sentence boundary (`.`, `?`, `!`, newline). Exact timing to be tuned during implementation.

Rationale: spamming the API burns tokens, triggers rate limits, and causes flickering suggestions. The user rarely benefits from mid-word corrections.

## Activation

### Default behavior

- **Launches on user login** (macOS Login Item).
- **Active by default** — no explicit activation required.
- **Global keyboard shortcut** to pause/resume (default: `Option+Cmd+C`, user-configurable).
- **Menu bar icon** shows state: active, paused, error (API down, no key, etc.).

### Pause semantics

When paused, Caret stops capturing keystrokes entirely — not just hides suggestions. This guarantees zero data leaves the machine while paused. Pausing is one keystroke; resuming is the same keystroke.

## Privacy & trust

### Blacklist (enabled by default)

Caret does not observe or send any text from:

- **Password managers**: 1Password, Bitwarden, LastPass, Dashlane, Proton Pass, Keeper, Apple Passwords.
- **Terminal applications**: Terminal.app, iTerm2, Warp, Alacritty, Kitty, Ghostty, Hyper.
- **Secure fields**: any field where `kAXRoleAttribute == AXSecureTextField` or the macOS secure input flag is set.

### User-editable blacklist

Settings pane exposes:

- The default list (toggleable per entry)
- A way to add any running app to the blacklist
- A way to temporarily disable Caret for N minutes (in case the user is doing something sensitive outside the default list)

### Context window

The LLM receives at most **300 characters before the cursor** by default. Configurable in settings between 100 and 1000.

Rationale: 300 characters is enough for the LLM to understand sentence context and tense, but small enough to limit exposure of surrounding content.

### Visual indicator when sending

When Caret is sending text to the LLM, the menu bar icon briefly pulses. The pulse is subtle but present. Users who want more discretion can disable it.

### Zero telemetry by default

No analytics, no crash reports, no usage stats leave the machine unless the user explicitly opts in via settings. If we ever add opt-in telemetry, it must never include text content — only aggregate counters (e.g. "N suggestions accepted per day").

## Visual design

### Inspiration

- Apple's native system utilities: Spotlight, Raycast, Focus modes, Passwords app.
- The goal is that a stranger opening Caret for the first time should think "this feels like an Apple app".

### Ghost text panel

- Small `NSPanel`, `.floating` level, no title bar, rounded corners.
- Respects macOS appearance (light/dark/auto).
- Uses system font and system colors. No branded typography.
- Text is shown with reduced opacity to signal "this is a suggestion, not your text".
- The panel animates in/out with a short fade (~100ms).

### Menu bar

- One icon, monochrome, template-rendered so it adapts to menu bar color.
- Click → small popover with: state, pause toggle, shortcut hint, settings link.
- No branding noise.

### Settings pane

- Single window, SwiftUI.
- Four sections max: **General** (activation, shortcut, launch on login), **AI Provider** (BYOK key, model selector), **Privacy** (context window, blacklist, telemetry opt-in), **About** (version, license, GitHub link).

## What we won't do

- No onboarding tutorial that teaches "how to write". The product should be self-explanatory.
- No notifications, ever. Status lives in the menu bar.
- No floating widgets beyond the suggestion panel.
- No "tips" or "feedback" prompts. Users who want to contribute will find the GitHub repo.
