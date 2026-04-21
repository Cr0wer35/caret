# Scope — MVP v0.1

_Last updated: 2026-04-21_

## Goal of v0.1

Ship a macOS app that corrects typos and grammar mistakes as the user types, in any application, with a streaming ghost-text UX.

The v0.1 exists to validate two things:

1. **Is the streaming ghost-text UX actually better than select + menu** for correction in daily use?
2. **Is the technical stack (Swift + Accessibility API + CGEventTap + NSPanel) stable and fast enough** across real-world apps (Slack, Mail, Notion, browser, etc.)?

If both answers are yes, v0.2 adds autocomplete. If no, we iterate on v0.1 before adding anything.

## In scope

### Features

- Real-time typo and grammar correction while typing
- Streaming ghost-text suggestion displayed next to the cursor
- `Tab` to accept the suggestion, any other key to ignore
- Works system-wide across macOS apps via Accessibility API
- BYOK: the user pastes their own API key in settings (Anthropic recommended — Haiku 4.5)
- Blacklist of apps where Caret is disabled by default (password managers, terminals, secure fields)
- User-editable blacklist
- Global keyboard shortcut to pause/resume Caret
- Launches on boot, active by default
- Configurable context window (default: 300 characters before cursor)
- French and English support

### Quality bars

- First-token latency ≤ 1s in 95% of cases on a decent connection
- No visible lag on user input (suggestion computation must not block typing)
- Memory footprint under 100 MB idle
- CPU usage negligible when idle
- Zero crashes in a one-week daily-use test

## Out of scope for v0.1

- Autocomplete / next-word prediction (→ v0.2)
- Rewrite / tone change (→ v0.3)
- Translation on the fly (→ v0.3)
- Local LLM inference (→ vX)
- Managed cloud offering (→ vX)
- Multi-language beyond FR + EN
- Custom vocabulary / per-user fine-tuning
- Team / sync features
- iOS / iPadOS / Windows / Linux versions
- Account system
- Telemetry / analytics
- App-specific customization (different behavior per app)

## Non-goals

These are things we **intentionally will not build**, even if requested:

- Auto-replace mode (changing the user's text without consent)
- A menu bar full of features — the menu bar has one icon, one state indicator, one pause toggle
- Onboarding walkthroughs with tutorials — one screen, three fields (API key, activation, permissions)
- A "Pro" tier. Caret stays open source and free.

## Success criteria

v0.1 ships when:

- The author (primary user) uses it daily for at least two weeks without reverting to ChatGPT/Claude for correction.
- At least 3 external users can install it, configure BYOK, and get a usable experience within 10 minutes.
- It works without crashing in: Mail, Messages, Slack (desktop), Safari text fields, Chrome text fields, Notes, VS Code editor, Notion (web), Discord.
- Apple Intelligence users confirm Caret's streaming UX feels distinctly different and useful.

## Stretch for v0.1 (only if core is solid)

- Spanish and German support
- Light/dark mode polish for the suggestion panel
- Settings pane with per-app toggles (not just blacklist)
