# Caret

Real-time inline writing assistant for macOS.

## What it does

Caret streams AI-powered suggestions as you type, displayed next to your cursor in any app. Accept with a single keystroke. No copy-paste, no context switching.

## Why

Existing AI writing tools force you out of your flow: select, shortcut, wait, paste. Caret stays invisible until it matters, then surfaces suggestions inline without breaking your rhythm.

Apple Intelligence Writing Tools covers the "select + menu" workflow natively on macOS 15.1+ with compatible hardware. Caret targets the **streaming ghost-text experience**, works on any Mac, and is fully open source with BYOK.

## MVP — v0.1

Typo and grammar correction, streamed in real time as you type.

- System-wide across macOS apps
- Ghost text near the cursor, `Tab` to accept
- BYOK (bring your own API key) — Claude Haiku 4.5 recommended for latency
- Auto-blacklist for password managers, terminals, secure fields
- Launches on boot, active by default, global shortcut to pause
- French and English

## Roadmap

| Version | Focus |
|---|---|
| v0.1 | Grammar / typo correction (streaming ghost text) |
| v0.2 | Autocomplete (Copilot-style next-word prediction) |
| v0.3 | Rewrite (tone change) + translation |
| vX | Local LLM option, optional managed cloud |

## Design principles

- macOS native — Swift + AppKit / SwiftUI
- Minimal, invisible when not needed
- Zero telemetry by default
- Global pause shortcut
- Configurable context window (default: 300 chars before cursor)

## Status

Design and architecture phase. No code yet.

`docs/` will be populated as decisions land:

```
docs/
├── 01-product/        # Vision, scope, UX principles, competitive landscape
├── 02-architecture/   # Text capture, suggestion engine, LLM layer, UI
├── 03-roadmap/        # Milestones per version
└── 04-dev/            # Setup, Swift crashcourse, ADRs
```

## License

MIT (see `LICENSE`).
