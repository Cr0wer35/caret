# Future — vX and beyond

_Last updated: 2026-04-21_

**Status**: Ideas, open questions, unvalidated assumptions. Nothing here is committed.

## Themes

### Local LLM

Run correction and autocomplete entirely on-device, with zero network dependency. Two candidate stacks:

- **MLX** (Apple's on-device ML framework) with a small fine-tuned model, or a quantized Qwen 2.5 3B / Phi 4 mini / Mistral Small.
- **llama.cpp** Swift bindings for broader model support.

Drivers:
- Full privacy (text never leaves the Mac).
- No BYOK friction for casual users.
- Works offline.

Blockers:
- Model size and RAM footprint (a 3B model at Q4 is ~2 GB, tolerable on modern Macs).
- Inference latency on non-Apple Silicon (Intel Macs would be too slow).
- Bundle size and distribution (models should be downloaded on first run, not shipped in the DMG).

Open question: does quality at 3B match Haiku 4.5 for grammar correction in French? This needs a benchmarking effort before committing.

### Managed cloud option

For users who don't want to manage their own Anthropic key but are willing to pay a small subscription:

- Caret-hosted proxy to Anthropic (or bring-our-own model behind it).
- Privacy guarantee: same as BYOK — text is passed through, not stored.
- Likely priced to cover cost + small margin: ~€3–5/month.

Drivers:
- Lower onboarding friction.
- Smooth upgrade path for users who started with BYOK.

Blockers:
- Requires infrastructure the author doesn't want to maintain as a side project.
- Requires a business entity, billing, compliance. Probably needs Caret to move beyond "side project".

Open question: should we ship this at all? Or just recommend Anthropic's own Console for onboarding?

### Per-user adaptation

Learn the user's style — common abbreviations, proper nouns, sector-specific vocabulary — to reduce false corrections.

- Local profile (never leaves the device).
- Builds up over time from corrections the user rejects ("this was a false positive").
- Fed into the prompt as a small "your voice" preamble.

Open question: is a static blacklist of terms enough, or does this need real learning?

### Browser extension companion

For web apps where AX breaks (Google Docs, Figma, some Slack views), a thin browser extension that exposes the editable text region to Caret via a local WebSocket.

- Chrome + Firefox + Safari extensions.
- Extension injects a ~200-line script that listens to contenteditable changes and forwards them.
- Caret app listens on a localhost port.

Open question: is the install friction worth it, or do we just accept degraded-mode pill forever?

### Voice integration

Partner with (or complement) dictation tools like SuperWhisper and Wispr. After dictation, Caret kicks in on the transcribed text to fix punctuation, casing, and grammar in place.

Open question: is this a feature inside Caret, or a preset for the "Rewrite" flow added in v0.3?

### Team / organization edition

Shared vocabulary, shared prompt tweaks, centrally managed API keys for a team. Explicitly out of scope for the open source core; could be an extension or a separately licensed product.

## What we are NOT going to do

- **Grammarly-style advisor panel** with "here are 42 mistakes, click to fix each". Not the vision.
- **AI chat** inside Caret. Plenty of other tools do this.
- **Summarization, bullet-pointing, rephrasing as tables**. Out of scope. Apple Intelligence does this.
- **Mobile companion**. Caret is desktop.
- **Windows / Linux port**. Deep OS integration makes cross-platform disproportionately expensive.

## Decision process for adding to this list

Before any idea here graduates to a planned version:

1. A measurable problem from v0.1/v0.2 users (issues, feedback).
2. A short prototype or spike validating technical feasibility.
3. A one-page ADR in `docs/02-architecture/adr/`.
4. A milestone breakdown in a new `vX.Y-feature.md` file.

We don't do speculative roadmap. We do validated roadmap.
