# M2 App Matrix
_Last updated: 2026-04-22_

Running log of how the Accessibility capture pipeline behaves per host app. Updated every time we re-test or bump Caret to a new version. M8 release gates on this file being green for all "Tier 1" apps.

## Tiers

- **Tier 1 (must work)** — Apple text apps + Safari. These have full, stable AX support. A regression here is a ship blocker.
- **Tier 2 (expected to work)** — Chromium-based web apps with native text fields.
- **Tier 3 (degraded OK)** — Electron apps and rich web editors. `nil` is an acceptable outcome as long as no crash, hang, or main-thread block occurs.

## Results

| App | Tier | Capture | Notes |
|---|---|---|---|
| TextEdit | 1 | ✅ full | Baseline. `text`, `cursorRange`, `caretScreenRect` all present. |
| Notes | 1 | ✅ | |
| Mail (compose body) | 1 | ✅ | |
| Safari (URL bar) | 1 | — | Not tested yet |
| Messages | 1 | — | Not tested yet |
| Chrome (URL bar) | 2 | ✅ | |
| Slack | 3 | ⛔ `nil` | Electron; `focusedContext` returns nil. No crash. Expected. |
| Discord | 3 | — | Not tested yet |
| VS Code | 3 | — | Not tested yet |
| Notion (web) | 3 | — | Not tested yet |
| Figma | 3 | — | Canvas-based, expected bad |

## How to reproduce

1. Build + run Caret from Xcode.
2. Grant Accessibility permission (once, if not already).
3. In the target app, focus a text field and type a few characters.
4. Click the Caret menu bar icon → `Capture focused text` (or ⌥⌘C with the menu open).
5. Open Console.app, filter `category:capture`, read the emitted line.

## What "green" means per tier

- **Tier 1**: `text` non-empty, `cursorRange` sensible, `caretScreenRect` non-nil.
- **Tier 2**: `text` + `cursorRange` non-nil. `caretScreenRect` optional.
- **Tier 3**: `nil` OR partial context is acceptable. Crashes / hangs / main-thread stalls are blockers even here.
