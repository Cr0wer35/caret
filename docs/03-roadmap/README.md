# Roadmap

_Last updated: 2026-04-21_

Caret is built in small, shippable slices. Each version is a fully working app — no broken intermediate states merged on `main`.

## Versions

| Version | Focus | Status | Target |
|---|---|---|---|
| **v0.1** | Grammar / typo correction (streaming ghost text) | Design complete, not started | First public release |
| **v0.2** | Autocomplete (Copilot-style next-word prediction) | Backlog | After v0.1 dogfooding |
| **v0.3** | Rewrite (tone change) + Translation | Backlog | After v0.2 |
| **vX** | Local LLM option, managed cloud offering | Open questions | TBD |

## Files

- [`v0.1-correction.md`](v0.1-correction.md) — the detailed milestone-by-milestone breakdown for shipping v0.1.
- [`v0.2-autocomplete.md`](v0.2-autocomplete.md) — directional plan. Not a detailed spec yet.
- [`v0.3-rewrite-translate.md`](v0.3-rewrite-translate.md) — directional plan.
- [`future.md`](future.md) — ideas and open questions beyond v0.3.

## How we work

- One version at a time. No parallel feature development across versions.
- Each milestone in a version has **acceptance criteria** — no handwave.
- Every milestone ends with a working app, even if limited in scope.
- The `main` branch is always green. Work in short-lived branches, squash-merge.
- Dogfooding is a milestone, not an afterthought.

## What we don't plan

- Exact dates. Caret is a side project; velocity fluctuates. Targets are ordering, not deadlines.
- Stretch features during the main milestones. Stretch goes in a separate "stretch" list per version, pulled only if the core is solid.
- Features driven by speculation. We add v0.4 when v0.3 ships and we have real feedback.
