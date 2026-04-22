# Changelog

All notable changes to Caret will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Accessibility permission flow (M1): onboarding window shown at launch when permission is missing, `Permissions.swift` wraps `AXIsProcessTrusted` + 1 Hz async poller, menu bar icon reflects live status (`pencil.tip` / `exclamationmark.triangle.fill`), menu exposes a re-open shortcut on revocation.
- Initial Xcode project (macOS app, Swift 6, SwiftUI).
- Menu bar app shell via `MenuBarExtra` (placeholder icon, quit).
- `LSUIElement = YES` (no Dock icon, no app switcher entry).
- `MACOSX_DEPLOYMENT_TARGET = 13.0` (minimum macOS 13 Ventura).
- `SWIFT_VERSION = 6.0` with `SWIFT_STRICT_CONCURRENCY = complete`.
- `ENABLE_APP_SANDBOX = NO` (required for upcoming Accessibility + CGEventTap usage).
- SwiftLint config (`.swiftlint.yml`).
- swift-format config (`.swift-format`).
- Pre-commit hook installer (`scripts/install-hooks.sh`).
- GitHub Actions build workflow (macos-15, lint + build).
- MIT `LICENSE`.
- Full project documentation in `docs/` (product, architecture, roadmap, dev).
