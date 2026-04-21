# UI Layer

_Last updated: 2026-04-21_

The UI layer is deliberately tiny. It has three visible surfaces: the **suggestion panel**, the **menu bar icon**, and the **settings window**. Nothing else.

## Suggestion panel

A single `NSPanel` with these properties:

- Window level: `.floating` (above all normal windows, below system modals).
- Style mask: `.nonactivatingPanel`, `.hud`, `.titled = false`, `.borderless`.
- Corner radius: 8, with a subtle shadow (system shadow, no custom glow).
- Background: `.windowBackgroundColor` with reduced opacity on light mode, `.controlBackgroundColor` on dark.
- Size: fits content — minimum 80×28, maximum 600×80. Text wraps at 600.
- Animations: none (per user preference). The panel simply appears and disappears. No fade.

### Content

SwiftUI view with one `Text` showing the suggestion. The text is rendered with:

- System font, same size as the average macOS body text (`.body`, 13pt).
- Foreground color: `.secondaryLabelColor` (subdued, signals "this is a hint, not your text").
- A leading subtle glyph indicator (a small `pencil.tip.crop.circle`) to make it clear this is a correction, not a completion — maximum 14pt.
- A trailing inline hint: `Tab` key symbol (rendered as an SF Symbol `keyboard`-style).

Example visual concept (text-only):

```
✎  phrase corrigée                    ⇥
```

### Positioning

In the happy path:

1. Input pipeline resolves caret position via `kAXBoundsForRangeParameterizedAttribute`.
2. Resulting rectangle is translated to screen coordinates.
3. Panel appears **directly above** the caret, 8 points of vertical gap.
4. If the caret is near the top of the screen, panel flips to **below** the caret.
5. Horizontal alignment follows the caret (left edge of panel = caret X).

In the degraded path (AX failed to return caret rect):

- Panel appears as a top-right **pill** on the active screen, 20 points below the menu bar, 20 points from the right edge.
- The pill is narrower and has a subtle `globe` glyph indicating "position unresolved".

The panel follows the caret as the user keeps typing within the suggestion window (until accept or dismiss). If the caret moves out of screen bounds or the focus changes, the panel hides immediately.

### Interaction

Handled by the Input Pipeline, not the UI:

- `Tab` → accept: the corrected text replaces the original span via `AXUIElementSetAttributeValue` on `kAXSelectedTextRangeAttribute` and `kAXValueAttribute`. Panel hides.
- Any other key → dismiss: panel hides. The key event is NOT swallowed — it propagates to the app.
- Mouse click outside panel → dismiss.
- Focus change → dismiss.

The `Tab` key event is **swallowed** when Caret consumes it for accept. This is the only event Caret ever swallows. If no suggestion is visible, `Tab` passes through normally.

### Accept flow detail

When the user presses `Tab`:

1. Input pipeline detects the event.
2. Panel state is checked: if a suggestion is active, swallow the `Tab`.
3. The pipeline asks the Text Capture layer to replace the span (`span_start` to `span_end`) with the corrected text.
4. `AXUIElementSetAttributeValue(focused, kAXSelectedTextRangeAttribute, range)` — select the span to replace.
5. `AXUIElementSetAttributeValue(focused, kAXSelectedTextAttribute, correctedText)` — substitute.
6. Panel hides.
7. A state counter increments (for menu bar stats: "N corrections accepted today").

If step 4 or 5 fails (app doesn't support replacement via AX), Caret falls back to:

- Copy the corrected text to the pasteboard.
- Show a brief menu bar tooltip: "Copied — paste with ⌘V".
- No automatic paste (we never inject `Cmd+V` — too intrusive and can trigger other app behavior).

## Menu bar icon

A single `NSStatusItem` with a template image.

States:

- **Active** — regular monochrome icon (`pencil.tip`).
- **Paused** — icon with a slashed-out overlay.
- **Working** — icon with a subtle dot indicator when a request is in flight.
- **Error** — icon with an exclamation mark (only for persistent errors: invalid key, misconfigured).

Click on the icon opens a small popover:

```
Caret — Active
─────────────────
Pause Caret                ⌥⌘C
Open Settings…
─────────────────
12 corrections today
─────────────────
About Caret
Quit
```

No flashy gradients. Plain system `NSPopover`.

## Settings window

Single SwiftUI `Window`, four tabs, compact layout. Opens from the menu bar popover.

### Tab 1 — General

- Launch at login (toggle, wires to `SMAppService.mainApp`).
- Global pause shortcut (re-bindable, default `⌥⌘C`).
- Menu bar visibility toggle (even if off, the app keeps running).

### Tab 2 — AI Provider

- Provider dropdown (v0.1: only Anthropic; v0.2 adds others).
- Model dropdown (v0.1: Haiku 4.5 default, Sonnet 4.5 optional).
- API key field (secure input, reads/writes Keychain).
- "Test connection" button (sends a throwaway "Hello?" prompt).

### Tab 3 — Privacy

- Context window size slider (100 ↔ 1000 chars, default 300).
- Rate limit slider (10 ↔ 120 requests/minute, default 30).
- Blacklist table:
  - Default entries shown with a toggle each.
  - `+` button to add any running app.
  - `-` button to remove custom entries.
- Telemetry toggle (default off, currently does nothing — placeholder).
- "Open Accessibility permission in System Settings" button.

### Tab 4 — About

- Version number (reads from `Bundle`).
- GitHub link.
- License (MIT, short text).
- Credits (acknowledgements for Sparkle, Apple AX docs, etc.).

No analytics, no feedback form, no Discord link, no newsletter.

## Accessibility of the UI itself

The settings window and menu bar popover are fully VoiceOver-compatible. The suggestion panel is **not** exposed to VoiceOver (it's transient, purely visual; it would speak unnecessarily every keystroke). This is a deliberate exclusion documented in the settings About tab.

## Animations policy

Per product direction: **no animations** beyond instantaneous show/hide and the standard macOS window transitions. No fades, no bounces, no slides. The UI appears when needed, disappears when not.

The only exception is a subtle **streaming tick**: as tokens arrive from the LLM, the text in the suggestion panel updates character-by-character naturally. This is the streaming itself, not a UI animation — we don't add any extra motion on top.

## Implementation notes

- SwiftUI for panel content, menu bar popover, settings window.
- AppKit (`NSPanel`, `NSStatusItem`) for the outer shells where SwiftUI-only doesn't work.
- No third-party UI library. System components only.
- One file per surface: `SuggestionPanel.swift`, `MenuBar.swift`, `SettingsWindow.swift`.
- The UI layer depends on an `InputPipeline` protocol exposed by the pipeline layer; for tests, it's mocked.
