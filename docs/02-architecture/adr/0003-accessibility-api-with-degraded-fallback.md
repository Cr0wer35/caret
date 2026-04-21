# ADR 0003 — Accessibility API primary, degraded pill as fallback

**Status**: Accepted
**Date**: 2026-04-21

## Context

System-wide text capture on macOS has three possible approaches:

1. **Accessibility API (AX)** — standard, works in most apps with granted permission.
2. **Custom Input Method (IME)** — user must switch input source to Caret; invasive, forbidding onboarding UX.
3. **CGEventTap keystroke buffering** — record every keystroke in memory; works universally but is privacy-sensitive and hard to map to screen position.

Electron apps and some web editors break AX's `kAXSelectedTextRangeAttribute` (returns `{0, 0}`) and sometimes `kAXValueAttribute` (returns empty).

## Decision

**Accessibility API as primary**, with a **degraded-mode pill at top-right** when AX fails to resolve caret position in the focused field.

- Primary path: ghost text appears inline near the caret.
- Degraded path: a small top-right pill shows the suggestion; accept via `Tab` still works; in-memory ring buffer of recent keystrokes provides context when `kAXValueAttribute` is empty.
- Secure fields (`AXSecureTextField`) are skipped entirely in both paths.

We explicitly do NOT implement a custom IME in v0.1.

## Consequences

Positive:
- No forced input-source switching.
- Native inline UX in ~80–90% of apps.
- Graceful degradation for Electron/web — user still gets suggestions, just not inline.
- Clear boundary for privacy: key buffer is in-memory only, reset on focus change.

Negative:
- Degraded-mode UX is strictly worse than inline. Apps like Slack desktop always fall back, which is annoying for heavy Slack users. We could later add per-app improvements (browser extension bridge, etc.) but they are not v0.1.
- Accessibility permission is a barrier at first launch. Mitigated by clear onboarding.
