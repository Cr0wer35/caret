# ADR 0001 — macOS-only, no cross-platform

**Status**: Accepted
**Date**: 2026-04-21

## Context

Caret could be built cross-platform (Electron, Tauri, React Native for macOS, Flutter). Each of those has a macOS story.

## Decision

Caret is macOS-only for v0.1 and the foreseeable future. Written in **Swift** targeting **macOS 13+**.

## Consequences

Positive:
- Full access to Accessibility API, event taps, AppKit's `NSPanel`, SMAppService — no FFI layers.
- Native feel matches the product's "invisible, macOS-native" design principle.
- Smaller binary, lower memory, faster startup.
- No Electron security/update surface.

Negative:
- Can't ship on Windows/Linux. That's fine; Caret's value prop is deeply tied to macOS system APIs.
- Team needs Swift expertise; the author is learning Swift as part of this project.
- Cross-platform parity with tools like [WritingTools](https://github.com/theJayTea/WritingTools) is deferred indefinitely.
