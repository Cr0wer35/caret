# Vision

_Last updated: 2026-04-21_

## The problem

Writing with AI-powered help on macOS today means breaking your flow. You type, notice a mistake, select the text, open ChatGPT or Claude, paste, wait, copy, paste back. Or you select text, press a shortcut, pick a menu option, wait for a rewrite to appear, accept or undo.

For people who write a lot, this is friction multiplied by hundreds of times per day. For people who make a lot of mistakes — dyslexics, non-native speakers, fast typists — it becomes a real productivity tax.

Existing tools all follow one of two patterns:

1. **Selection + shortcut + rewrite** (Apple Intelligence Writing Tools, Raycast AI, Typeless, Kerlig, Fixkey, WritingTools, etc.) — you stop, select, trigger, wait.
2. **Extension-bound correction** (Grammarly, LanguageTool) — only works in supported apps, lots of UI clutter.

None of them do what editors do naturally for code (Copilot, Cursor): **suggest as you type, inline, accept with one keystroke**.

## The vision

Caret is a macOS writing assistant that is invisible until it matters.

- You type. Caret watches.
- If you make a typo or grammar mistake, Caret shows a corrected version as a ghost next to your cursor.
- Press `Tab` to accept. Keep typing to ignore.
- That's it.

No menu. No selection. No copy-paste. No waiting for a response that takes you out of your current sentence.

## Who it's for

- **Dyslexic writers** who need grammar help without breaking flow.
- **Non-native speakers** writing in a second language daily.
- **Mac users without Apple Intelligence** (Intel Macs, M1 base, macOS < 15.1) — roughly half of the active Mac install base.
- **People who prefer streaming-style AI assistance** (the Copilot feel) over menu-driven tools.
- **Open source-minded users** who want BYOK and no vendor lock-in.

## What Caret is not

- Not a replacement for Apple Intelligence when the select + menu workflow fits. Apple's tool is natively integrated, free, and good at what it does.
- Not a full writing suite. No document management, no AI chat, no agents, no summarization in v0.1.
- Not trying to be Grammarly. No analytics dashboard, no account system, no team features.
- Not trying to be a business. Caret is a side project, open source, MIT. Long term, there may be an optional managed cloud offering for people who don't want to manage their own API key, but that is not the goal.

## Guiding principles

1. **Invisible by default.** If you are not being corrected, you should not see Caret at all.
2. **One keystroke to accept.** The cost of accepting a suggestion must be lower than the cost of ignoring it.
3. **Respect the user's text.** Never auto-replace. Never touch the user's original text without explicit consent.
4. **Respect the user's privacy.** Sensitive fields are off by default (password managers, terminals, secure inputs). Zero telemetry by default.
5. **Native Mac.** Caret should feel like an Apple-designed system utility, not a cross-platform app in disguise.
