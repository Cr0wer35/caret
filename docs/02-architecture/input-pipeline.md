# Input Pipeline

_Last updated: 2026-04-21_

The input pipeline covers everything from "user pressed a key" to "we have a context string ready to send to the LLM". It merges two responsibilities that are tightly coupled:

1. **Text capture** — read the focused field's text and cursor position from any app.
2. **Trigger engine** — decide when to actually trigger a correction.

## Text capture

### Primary mechanism — Accessibility API (AX)

The app requires Accessibility permission (granted in System Settings > Privacy & Security > Accessibility). With that permission, the app can use `AXUIElement` to read system-wide text across apps.

Core calls:

- `AXUIElementCreateSystemWide()` — a handle to "whatever is focused right now".
- `AXUIElementCopyAttributeValue(_, kAXFocusedUIElementAttribute, _)` — returns the currently focused UI element across apps.
- `kAXValueAttribute` on the focused element → the full string content.
- `kAXSelectedTextRangeAttribute` → the cursor position as a `CFRange` (location + length; length = 0 means a collapsed caret).
- `kAXBoundsForRangeParameterizedAttribute` → given a `CFRange`, returns the screen coordinates of that text range, used to position the ghost text panel next to the caret.

Reference: [Apple — AXUIElement](https://developer.apple.com/documentation/applicationservices/axuielement), [Itsuki, Feb 2026 — Get Caret Position](https://medium.com/@itsuki.enjoy/swiftui-macos-get-text-cursor-caret-position-05f1419c5cc8).

### Secondary mechanism — CGEventTap (keystroke trigger)

AX queries are cheap but we don't want to poll the focused element. We use `CGEventTap` at the `cgSessionEventTap` level, listening to `keyDown` only, to wake up the pipeline.

Every keyDown event triggers:

1. A **tap event** with the key (used for: detecting sentence boundaries, detecting `Tab` to accept, detecting user typing over the ghost text to dismiss).
2. A **debounced AX read** of the focused element (after ~50ms, so the app has processed the key).

The event tap does NOT buffer the content of keystrokes in memory. It only counts them and reads the boundary characters (punctuation, newlines, `Tab`). The actual text is always read fresh from AX when we trigger.

Reference: [usagimaru/EventTapper](https://github.com/usagimaru/EventTapper).

### Fallback for apps where AX fails

Known problem apps:

- **Electron apps** (Slack desktop, Discord, VS Code, Notion desktop): AX returns partial or empty text unless the app sets `AXManualAccessibility = true`. Some do, most don't. Selected range often returns `{0, 0}` regardless of true cursor position. See [electron/electron#34755](https://github.com/electron/electron/issues/34755).
- **Browser-embedded editors** (Gmail, Google Docs, Figma): rely on contenteditable or canvas. AX exposes variable amounts of content.
- **Password managers / secure fields**: AX role = `AXSecureTextField`. Caret must skip these entirely (non-negotiable privacy).

Fallback strategy for Electron/web when AX is unreliable:

1. **Detect**: if `kAXValueAttribute` returns empty/nil, OR `kAXSelectedTextRangeAttribute` returns `{0, 0}` while keystrokes are being received, we're in a bad state.
2. **Degraded mode**: Caret shows a small pill at the top-right of the screen instead of inline ghost text. The pill says "Suggestion (Tab to accept)" with the corrected text. Positioning near caret is abandoned for that session.
3. **Content source in degraded mode**: buffer the last N keystrokes (N = context size ÷ average char/key) in an in-memory ring buffer. This buffer is reset on focus change and never persisted.

Degraded mode is an acceptable compromise: it keeps Caret functional everywhere without building per-app integrations. We can improve on specific apps later (e.g. a Chrome extension bridge for contenteditable fields) if demand justifies it.

### Blacklist check

Before reading any text, Caret checks the frontmost app and focused element:

- Frontmost app bundle identifier against the blacklist (`com.1password.1password`, `com.googlecode.iterm2`, `com.apple.Terminal`, etc.).
- Focused element role — if `AXSecureTextField`, abort immediately.
- Focused element's app (if different from frontmost) against the blacklist.

If any check fails, Caret does not read the text and does not send anything to the LLM. The menu bar icon shows "paused for this field" state.

## Trigger engine

The trigger engine answers one question: **given a keystroke event, should we fire an LLM request right now?**

### Rules

A correction request fires when **all** of the following are true:

1. Caret is active (not globally paused).
2. The focused field passes the blacklist check.
3. The text capture succeeded (we have a context string + cursor position).
4. Since the last fired request, at least one of:
   - **N new words** have been typed (default: 3, user-configurable between 2 and 6).
   - A **sentence boundary** character was just typed (`.`, `?`, `!`, newline).
5. The user has paused typing for at least **400ms** (debounce).

The debounce always applies, even on sentence boundaries. It is short enough to feel immediate but long enough to avoid firing mid-thought.

### Cancellation

If the user resumes typing while a request is in flight:

- **Small edit** (≤ 2 chars appended): let the request complete. If the suggestion still applies to the current text, display it. If the text has diverged too much (Levenshtein distance > threshold), discard.
- **Larger edit**: cancel the in-flight request via `URLSessionTask.cancel()`. Start a fresh request on next trigger.

Cancellation is critical. Without it, we would display outdated suggestions and waste tokens.

### Ignore triggers

Caret skips the trigger entirely (even if all rules above pass) when:

- The user just pressed `Tab` (they accepted or are tab-completing elsewhere).
- The user just pressed `Escape` (explicit dismiss signal).
- The user is holding a modifier key (`Cmd`, `Ctrl`, `Option`) — they're probably doing an app-specific action, not writing prose.
- The focused element's value is shorter than **10 characters** (too little context to correct meaningfully).

### Why debounce on every word, not every keystroke

Firing on every keystroke would:

- Burn 10-20x more tokens than necessary.
- Trigger rate limits on BYOK providers quickly.
- Cause visible flickering as suggestions change word-by-word.

Firing after 3 words + 400ms pause gives the user a stable context the LLM can reason about, while still feeling "real time".

## Threading and concurrency (Swift 6)

All I/O is async. The pipeline is organized as:

- `@MainActor` **InputCoordinator** — owns the event tap, dispatches events.
- **TextCaptureActor** — handles AX reads, isolated from the main thread.
- **TriggerEngine** actor — tracks debounce state, boundary detection, cancellation tokens.

The event tap callback is a C function pointer; we bridge to Swift via a `@Sendable` closure that dispatches an `await` into the actor. `CGEventTap` is not `Sendable`, so the tap itself is owned by `InputCoordinator` on the main actor. Events are immutable value types (`CGEvent` copies) passed to the `TextCaptureActor`.

## Testing strategy

- **Unit tests**: `TriggerEngine` is a pure actor; all its decisions are testable by feeding synthetic `KeyEvent` streams.
- **Integration tests**: a test harness launches a dummy macOS window with a known text field, simulates keystrokes via `CGEventPost`, and asserts AX reads return expected values. Runs on CI with an unlocked session.
- **Manual app matrix**: a checklist of apps to try before every release (Mail, Messages, Slack, Safari text fields, Chrome, Notes, VS Code editor, Notion web, Discord). Tracked in `docs/04-dev/manual-test-matrix.md` once we start releasing.
