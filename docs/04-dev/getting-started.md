# Getting Started

_Last updated: 2026-04-21_

This document will evolve as the code lands. During the docs-only phase, it's a placeholder with the intended setup.

## Prerequisites

- **macOS 14 Sonoma** or later (to develop; the app supports macOS 13+).
- **Xcode 16** or later (Swift 6 toolchain).
- **Homebrew** (optional, for SwiftLint and swift-format).
- An **Anthropic API key** for testing the LLM layer. Get one at https://console.anthropic.com.

## Clone and open

```bash
git clone https://github.com/Cr0wer35/caret.git
cd caret
open Caret.xcodeproj
```

> The Xcode project does not exist yet. It will be added in **milestone M0** (see [`docs/03-roadmap/v0.1-correction.md`](../03-roadmap/v0.1-correction.md)).

## First run (once M0 is done)

1. Open the project in Xcode.
2. Select your personal Team in **Signing & Capabilities** (any free Apple developer account works for local builds).
3. Hit `⌘R`.
4. First launch asks for **Accessibility** permission. Grant it in System Settings > Privacy & Security > Accessibility.
5. Open Caret settings (menu bar icon > Open Settings).
6. Paste your Anthropic API key in the **AI Provider** tab.
7. Click "Test connection" — should return a green check.

## Dev tools

```bash
# Install formatters/linters (only once)
brew install swiftlint swift-format

# Run manually
swiftlint
swift-format lint -r Caret/

# Pre-commit hook is auto-installed after first run of:
./scripts/install-hooks.sh
```

## Debug flags

Environment variables supported during `⌘R`:

| Variable | Effect |
|---|---|
| `CARET_DEBUG_OVERLAY=1` | Shows a floating HUD of what Caret currently sees (focused app, text, cursor pos). |
| `CARET_MOCK_LLM=1` | Routes LLM calls to a local mock that returns canned responses. Useful offline. |
| `CARET_LOG_LEVEL=debug` | Verbose logs via `os.Logger`. |

Set them in Xcode: **Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables**.

## Running tests

- Unit tests: `⌘U` in Xcode, or `xcodebuild test -scheme Caret-Tests`.
- UI tests: `⌘U` on the `Caret-UITests` scheme.
- Swift Testing is the primary framework; XCTest is used only for UI tests.

## Common first-install problems

| Symptom | Cause | Fix |
|---|---|---|
| App launches but no menu bar icon | `LSUIElement` not set in Info.plist | Check Info.plist |
| "The operation couldn't be completed. (com.apple.SecurityAgent error -1)" | Missing code signing identity | Set a Team in Signing & Capabilities |
| `AXIsProcessTrustedWithOptions` returns false even after granting | Xcode re-signs the binary on each build, sometimes invalidating the Accessibility grant | Remove the old entry in System Settings and re-add |
| "Test connection" fails with 401 | API key invalid or expired | Re-paste key, check for trailing whitespace |
