# Manual Test Matrix

_Last updated: 2026-04-21_

A focused list of apps where Caret must behave predictably. Run through this matrix before every public release, and every time the input pipeline changes.

Not exhaustive — the goal is catching regressions in the apps the author and early testers actually use.

## How to use

1. For each app, follow the **steps** column.
2. Mark the result: ✅ works as expected / ⚠️ degraded (pill mode acceptable) / ❌ broken (log issue).
3. Record any oddity in the notes.
4. Update the "Last verified" column.

## Matrix

| App | Type | Expected | Steps | Last result | Last verified |
|---|---|---|---|---|---|
| TextEdit | Native | ✅ Inline | Type "This is a beautifull test." → wait. Expect ghost text on "beautiful". | — | — |
| Mail (compose) | Native | ✅ Inline | New message, body field, type a sentence with a typo. | — | — |
| Messages | Native | ✅ Inline | Type a typo in the iMessage field. | — | — |
| Notes | Native | ✅ Inline | Type a typo in a note. | — | — |
| Pages | Native | ✅ Inline | Document field, type a typo. | — | — |
| Safari — text field | Webkit | ✅ Inline | google.com search box, type typo. | — | — |
| Safari — contenteditable | Webkit | ⚠️ or ✅ | gmail.com compose body. | — | — |
| Chrome — text field | Blink | ✅ Inline or ⚠️ pill | google.com search box. | — | — |
| Chrome — contenteditable | Blink | ⚠️ pill | notion.so page editor. | — | — |
| Slack (desktop) | Electron | ⚠️ pill | Channel message box. | — | — |
| Discord (desktop) | Electron | ⚠️ pill | Channel message box. | — | — |
| VS Code | Electron | ⚠️ pill | Editor pane, type a comment with typo. | — | — |
| Notion (desktop) | Electron | ⚠️ pill | Page body. | — | — |
| Figma (desktop) | Electron/canvas | ❌ expected | Comment, text tool. | — | — |
| Obsidian | Electron | ⚠️ pill | Editor. | — | — |
| Warp | Native | 🚫 blacklisted | Should NOT activate. | — | — |
| iTerm2 | Native | 🚫 blacklisted | Should NOT activate. | — | — |
| 1Password | Native | 🚫 blacklisted | Should NOT activate. | — | — |
| Apple Passwords | Native | 🚫 blacklisted | Should NOT activate. | — | — |
| System Settings — password field | Native | 🚫 secure field | Should NOT activate. | — | — |

## Latency spot-checks

Do at least one sentence in each of the top 3 daily apps and note:

- Time from last keystroke to first streamed character.
- Total time to full suggestion.

Acceptance target: **first char under 1000ms in 95% of cases on a decent connection**.

## Regression flags

Mark any of these as blockers:

- [ ] Any crash, anywhere.
- [ ] Any keystroke not making it to the app (Caret accidentally swallowing).
- [ ] Any suggestion being committed without explicit `Tab` press.
- [ ] Any text sent to the LLM from a blacklisted app.
- [ ] Any text visible in Console logs (privacy leak).

## Release sign-off

Before tagging `v0.1.0`:

- ≥ 80% of matrix passes with expected result.
- Zero blockers marked.
- Author has used Caret daily for ≥ 14 consecutive days.
- At least one external tester has installed and confirmed working setup.

Everything short of that blocks the release.
