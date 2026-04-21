# ADR 0002 — BYOK-first, no managed cloud for v0.1

**Status**: Accepted
**Date**: 2026-04-21

## Context

Caret calls an LLM on every accepted trigger. The LLM call needs to be paid for somehow. Options:

1. Caret author pays (managed cloud, free to users). Not financially sustainable as a side project.
2. Users pay a subscription. Too commitment-heavy for a side project; forces account systems, billing, etc.
3. Bring Your Own Key (BYOK). User supplies their own Anthropic/OpenAI/etc. key and pays the provider directly.
4. Local LLM (Ollama, MLX). Works offline and privately but requires local inference setup.

## Decision

**BYOK** is the only model for v0.1. A local-LLM option is an explicit stretch goal for vX. A managed cloud is deferred with no commitment.

## Consequences

Positive:
- Zero infrastructure for Caret author. No servers, no billing, no accounts.
- Privacy-friendly: text goes directly from user's Mac to their chosen provider. Caret author has no data path at all.
- Users pick the model and provider they trust.

Negative:
- Onboarding friction: new users must get an API key from Anthropic before Caret becomes useful.
- No usage floor: a user with no key cannot try Caret in a useful state. We mitigate via a "test with a free Gemini key" walkthrough in settings (v0.2).
- If/when a managed cloud is added, it must match the same privacy guarantees as BYOK.
