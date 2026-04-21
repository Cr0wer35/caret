# App Shell

_Last updated: 2026-04-21_

The "app shell" is everything around the functional layers: lifecycle, permissions, updates, distribution. It's the boring-but-critical scaffolding that makes Caret a real app instead of a demo.

The guiding principle here is **the absolute minimum**. No hidden daemons, no background services separate from the UI app, no complex IPC.

## Lifecycle

### Launch at login

Caret registers itself as a login item via `SMAppService.mainApp.register()` when the user enables the setting.

- macOS 13 (Ventura) and later — required API, no legacy fallback.
- The user sees the item in System Settings > General > Login Items > Allow in the Background.
- Unregistering works symmetrically via `.unregister()`.

Reference: [Apple — SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice), [theevilbit blog — SMAppService quick notes](https://theevilbit.github.io/posts/smappservice/).

The app is a standard **NSApplication**, not an `LSUIElement`-only agent. However:

- `Info.plist` sets `LSUIElement = YES` so there's no Dock icon or app switcher entry.
- Launches hidden, only the menu bar icon is visible.

### Quit behavior

`Cmd+Q` from the menu bar popover quits cleanly:

- Cancel any in-flight LLM request.
- Tear down `CGEventTap` and `AXObserver`s.
- Persist the last-accepted counter to `UserDefaults` (`caret.stats.acceptsToday`, resets daily).
- Standard `NSApp.terminate(nil)`.

There is no force-quit fallback needed — the app is small enough to quit reliably.

### Single instance

Multiple launches are prevented by `NSApplication`'s default single-instance behavior (same bundle identifier → activates the existing instance). No custom lock file or IPC needed.

## Permissions

Caret needs exactly **one** permission: Accessibility.

### Accessibility (mandatory)

Granted in System Settings > Privacy & Security > Accessibility.

Without it, Caret cannot read text or cursor position from other apps. The app's onboarding screen:

1. First-launch window: explains what Accessibility is used for (one paragraph, no marketing).
2. Button: "Open Accessibility settings".
3. A small poller (`AXIsProcessTrustedWithOptions`) checks every second; when the permission is granted, onboarding advances.

No other permissions are requested. Specifically:

- **No Input Monitoring** — we use event taps via Accessibility, which is sufficient for keyboard taps in session scope.
- **No Full Disk Access** — not needed.
- **No Screen Recording** — not needed.
- **No network permission prompt** — macOS does not require it.

### What Caret never asks for

- Contacts, Calendar, Reminders, Photos.
- Camera, Microphone.
- Location.

If a future feature requires any of these, it's a separate ADR and an opt-in toggle.

## Settings storage

Two storage backends, split by sensitivity:

- **`UserDefaults`** (`com.caret.app`): everything non-secret — shortcut binding, context window size, rate limit, blacklist entries, launch-at-login state mirror, model selection, telemetry opt-in flag, last-accepted counters.
- **Keychain**: API keys only.

No file-based settings. No `~/.caret/` directory. No custom plist.

Rationale: `UserDefaults` is well-understood, portable, and shows up in macOS-standard backup flows. Keychain is the only correct place for secrets.

## Logging

For v0.1, Caret ships with OS log integration (`os.Logger`) with category `caret.app`:

- `.debug` level events: trigger decisions, cache hits, AX failures.
- `.info` level events: app start, settings change, connection test.
- `.error` level events: network failures, Keychain errors, AX permission revoked.

Logs go to the unified logging system. Users can inspect them via Console.app filtering on `subsystem == "com.caret"`.

**No file logs. No cloud logs. No PII in logs** (never log the context string or the corrected text).

## Updates — Sparkle

Caret uses [Sparkle 2](https://sparkle-project.org/) for out-of-store updates.

- Checked every 24 hours, user-configurable.
- Updates are `.zip` bundles signed with an EdDSA key.
- Delta updates for small patches.
- Sandbox-compatible (Sparkle 2 supports sandboxed apps).
- The updater framework is embedded in the app bundle as `Sparkle.framework`.

Appcast file hosted at `https://releases.caret.app/appcast.xml` (placeholder URL — actual hosting to be decided). Artifacts hosted on GitHub Releases. The appcast points at them.

Reference: [SwiftLee — Sparkle distribution guide](https://www.avanderlee.com/xcode/sparkle-distribution-apps-in-and-out-of-the-mac-app-store/), [Itsuki, Mar 2026 — Swift + Supabase + Sparkle](https://medium.com/@itsuki.enjoy/swift-macos-supabase-sparkle-auto-app-updates-a6c3774650a8).

## Distribution

Caret is distributed **outside the App Store**:

- Reason: entitlements we need (deep `kAXUIElement` access, `CGEventTap` at session scope) are restricted in the App Store sandbox. Submitting is not impossible but would require a negotiated entitlement and a lot of extra review cycles.
- Builds are signed with **Apple Developer ID**.
- Each release is **notarized** by Apple before publishing.
- Hosted as a `.dmg` on GitHub Releases.

### Code signing

- Developer ID Application certificate (will be personal in early days, team later if needed).
- Hardened Runtime enabled.
- No explicit entitlements file until we need one — the less we claim, the less we break.
- Notarization via `notarytool` in the CI release script.

### Sandboxing

Caret is **not** sandboxed. The reasons:

- `CGEventTap` at session level requires permissions granted per-user, not achievable with full sandbox constraints.
- `AXUIElementCreateSystemWide` usage requires Accessibility permission, which is fine, but the system-wide interaction is smoother without sandbox brackets.
- Sandboxing would force per-app entitlements we don't need.

Trade-off: we lose App Store eligibility (already ruled out), but keep notarization + Hardened Runtime + Developer ID — the standard for serious out-of-store macOS apps.

## CI & release

Eventually (not v0.1 priority), a GitHub Actions workflow:

- PR: build, unit tests, SwiftLint.
- Tag push (`v*`): build release bundle, sign, notarize, staple, zip, upload to GitHub Releases, update `appcast.xml`.

Until that exists, releases are local Xcode builds with a manual notarization step. Documented in `docs/04-dev/release.md` when we get there.

## Minimum macOS version

**macOS 13 Ventura.**

Drivers:

- `SMAppService` (login items) is Ventura+.
- Swift 6 concurrency is most stable on Ventura+.
- Covers ~95% of the active Mac user base by late 2026.

We explicitly drop support for macOS 12 Monterey and earlier to avoid dragging legacy Service Management API code along.
