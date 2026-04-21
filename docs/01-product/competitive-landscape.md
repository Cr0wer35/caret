# Competitive Landscape

_Last updated: 2026-04-21_

## The space

AI-assisted writing on macOS in 2026 is crowded but fragmented. Most tools follow one of three patterns:

1. **Native OS integration** (Apple Intelligence)
2. **Select + shortcut + rewrite** (Raycast AI, Typeless, Kerlig, Fixkey, WritingTools, Elephas, etc.)
3. **Browser/editor extensions** (Grammarly, LanguageTool)

Almost none do **streaming ghost text during typing** for correction. That is Caret's slot.

## Direct and indirect competitors

### Apple Intelligence Writing Tools — the default

- **What**: Built-in macOS Sequoia (15.1+) feature. Select text → menu → proofread / rewrite / summarize.
- **Strengths**: Native, free, already installed, works in most apps (Mail, Messages, Slack, Gmail, Notes, Pages, Outlook, Reddit, Signal, Threads, etc.).
- **Weaknesses**: Requires compatible hardware (Apple Silicon, not all models); select + menu workflow interrupts flow; quality varies by language (weaker on French than English); no ghost-text streaming; no BYOK.
- **How Caret differs**: Streaming UX, works on any Mac, BYOK with choice of provider, stronger FR quality via Claude Haiku 4.5.

### WritingTools by theJayTea — the open source benchmark

- **Repo**: https://github.com/theJayTea/WritingTools
- **What**: Cross-platform (Win/Linux/Mac) open source "Apple Intelligence Writing Tools clone, but better". Hotkey-triggered rewrite via BYOK (Gemini free tier, local LLMs, Ollama).
- **Strengths**: Mature, actively maintained, BYOK including local, multi-platform. Free.
- **Weaknesses**: Python + PyQt — not a native Mac experience; still hotkey-triggered (select + shortcut), no streaming ghost text; UI feels cross-platform.
- **How Caret differs**: Native Swift app with Mac-first design; streaming during typing, not select-and-trigger; macOS-only (deliberate trade-off for UX depth).

### Cotypist — the UX cousin

- **Site**: https://cotypist.app
- **What**: Free macOS app that provides inline AI autocomplete (next-word prediction) system-wide.
- **Strengths**: Does streaming inline suggestions. Free. Native Mac.
- **Weaknesses**: Focused on autocomplete, not correction — predicts the next phrase rather than fixing the current one. Closed source.
- **How Caret differs**: Caret v0.1 is focused on **correction** (fixing what you typed), not prediction (guessing what's next). Cotypist solves a different problem. v0.2 of Caret will overlap with Cotypist's space; by then we should have a strong UX differentiator (e.g. merged correction + prediction in one unified suggestion).

### Typeless — voice + AI writing

- **Site**: https://www.typeless.com
- **What**: AI voice dictation with rewrite via voice commands ("rewrite as professional email").
- **Strengths**: Novel voice-first workflow.
- **Weaknesses**: Not really a correction tool; voice-first means it doesn't help when you're in a meeting or on a train.
- **How Caret differs**: Caret is a text-first companion to dictation apps (SuperWhisper, Wispr, Typeless itself) — you dictate, then correct the transcription inline with Caret.

### Kerlig, Fixkey, Elephas, SnapRewrite, Writers Brew, GrammaticAI

- **What**: Commercial macOS apps, all BYOK or subscription, all select + shortcut + rewrite.
- **Strengths**: Polished, feature-rich, many integrations.
- **Weaknesses**: All use the same menu-triggered workflow; mostly closed source; mostly paid.
- **How Caret differs**: Streaming ghost text; free and open source; minimalist scope.

### Grammarly, Antidote, LanguageTool — the classic grammar engines

- **What**: Rule-based + ML grammar engines with browser extensions and desktop apps.
- **Strengths**: Decades of linguistic expertise, very solid on edge cases.
- **Weaknesses**: Not AI-native in the LLM sense; subscription-heavy; privacy concerns (cloud-hosted, account-bound); limited outside supported integrations.
- **How Caret differs**: LLM-native, BYOK (privacy stays with the user's chosen provider), no account, system-wide via AX API instead of app-by-app extensions.

### OpenGrammar

- **Repo**: https://github.com/swadhinbiswas/opengrammar
- **What**: Open source Grammarly alternative with BYOK. Integrates via extensions in rich-text editors (Gmail, Notion, Reddit, Google Docs).
- **How Caret differs**: Caret operates at the OS level (any text field, anywhere), not as a web extension. Complementary, not competing — could even co-exist.

## Caret's positioning (one line)

> The streaming ghost-text writing assistant for macOS. Inline corrections as you type, one keystroke to accept, open source, BYOK.

## Positioning matrix

| Tool | Streaming | Native Mac | Open source | BYOK | System-wide | Correction focus |
|---|---|---|---|---|---|---|
| Apple Intelligence | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| WritingTools (theJayTea) | ❌ | ⚠️ (Python) | ✅ | ✅ | ✅ | ✅ |
| Cotypist | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ (autocomplete) |
| Typeless | ❌ | ✅ | ❌ | ⚠️ | ⚠️ | ⚠️ |
| Kerlig / Fixkey / Elephas | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Grammarly | ❌ | ⚠️ | ❌ | ❌ | ⚠️ | ✅ |
| OpenGrammar | ❌ | ❌ | ✅ | ✅ | ❌ (web only) | ✅ |
| **Caret (v0.1)** | **✅** | **✅** | **✅** | **✅** | **✅** | **✅** |

The empty cell in this matrix — streaming + native Mac + open source + BYOK + system-wide + correction — is Caret's slot. No current tool occupies it.

## Risks

- **Apple catches up**: Apple could ship streaming-style Writing Tools in macOS 16. Mitigation: Caret's BYOK + open source + older Mac support remain distinct even then.
- **Cotypist adds correction**: Cotypist could expand into correction, effectively becoming Caret's closest competitor. Mitigation: differentiate on open source + BYOK + design polish.
- **A well-funded player enters the space**: Raycast, Arc, Linear, or similar Mac-first tools could ship a writing assistant. Mitigation: Caret stays small and opinionated; complement rather than compete.
