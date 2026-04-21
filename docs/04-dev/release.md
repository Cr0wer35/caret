# Release Process

_Last updated: 2026-04-21_

This document describes how we turn a `main` commit into a public, signed, notarized, auto-updateable release.

It is **placeholder-heavy** until milestone **M9** lands. The final script lives in `scripts/release.sh` once written.

## One-time setup (done once per machine)

### Apple Developer account

- Paid or free? For distribution, **paid Apple Developer Program** is required (notarization is paid-only).
- Generate a **Developer ID Application** certificate in Keychain Access > Certificate Assistant.
- Export to `.p12` and back up securely (1Password).

### Sparkle keys

Generate an EdDSA key pair for Sparkle update signing:

```bash
./bin/generate_keys           # Sparkle binary from their release
```

- Public key: committed in `Info.plist` as `SUPublicEDKey`.
- Private key: stored in 1Password only. **Never** committed.

### `notarytool` credentials

Store App Store Connect credentials in Keychain for non-interactive notarization:

```bash
xcrun notarytool store-credentials "caret-notarize" \
    --apple-id "your@apple.id" \
    --team-id "TEAMID" \
    --password "app-specific-password"
```

(App-specific password created at https://appleid.apple.com.)

## Each release

### 1. Preflight

- `main` is green on CI.
- Manual test matrix freshly run ([`manual-test-matrix.md`](manual-test-matrix.md)).
- `CHANGELOG.md` updated with a new `## [x.y.z] — YYYY-MM-DD` section.
- Version bumped in `Info.plist` (`CFBundleShortVersionString` and `CFBundleVersion`).

### 2. Tag

```bash
git tag -a v0.1.0 -m "Caret v0.1.0"
git push origin v0.1.0
```

The CI workflow picks up the tag and runs the full release pipeline. If CI isn't set up yet (early days), steps 3–7 are local.

### 3. Build (Release configuration)

```bash
xcodebuild -scheme Caret -configuration Release \
    -archivePath build/Caret.xcarchive archive
```

Produces `build/Caret.xcarchive`.

### 4. Export

```bash
xcodebuild -exportArchive \
    -archivePath build/Caret.xcarchive \
    -exportPath build/export \
    -exportOptionsPlist ExportOptions.plist
```

`ExportOptions.plist` specifies `developer-id` distribution method and the signing certificate.

### 5. Notarize

```bash
ditto -c -k --keepParent build/export/Caret.app build/Caret.zip
xcrun notarytool submit build/Caret.zip --keychain-profile "caret-notarize" --wait
xcrun stapler staple build/export/Caret.app
```

Wait for Apple's notarization response. Staple the ticket so Gatekeeper validates offline.

### 6. Package DMG

```bash
create-dmg \
    --volname "Caret" \
    --window-size 500 300 \
    --icon-size 100 \
    --icon "Caret.app" 125 150 \
    --app-drop-link 375 150 \
    build/Caret-0.1.0.dmg \
    build/export/Caret.app
```

(Requires `brew install create-dmg`.)

### 7. Sign the DMG for Sparkle

```bash
./bin/sign_update build/Caret-0.1.0.dmg
# outputs an EdDSA signature — paste into appcast.xml
```

### 8. Publish

- Upload `Caret-0.1.0.dmg` to GitHub Releases (as a release asset).
- Update `appcast.xml`:
  - New `<item>` with version, link, signature, minimum macOS.
  - Short release notes.
- Publish the GitHub Release. `main` page of the landing site should link to the Release page.

### 9. Announce

- Post on GitHub Discussions.
- Update `README.md` "Latest version" badge.
- (Optional) Share on relevant communities.

## Post-release

- Check Sparkle update on a local older build: should prompt within 24h (or via manual check).
- Monitor GitHub issues for the first 72h.
- Tag any hot-fix as `v0.1.1` and run through this doc again.

## Rollback

If a release is found to be broken:

1. Unpublish the GitHub Release immediately.
2. Revert the entry in `appcast.xml` (point to the previous version).
3. Announce in GitHub Discussions.
4. Fix, tag `v0.1.1`, re-release.

No force-push on the tag. Broken tags stay in history as evidence.

## CI automation (deferred)

Eventually, steps 3–8 run in a GitHub Actions workflow on tag push:

- `macos-latest` runner.
- Secrets: Developer ID `.p12`, Sparkle private key, notarytool credentials, GitHub token.
- Workflow: `.github/workflows/release.yml`.

Writing this workflow is part of milestone M9 in [`docs/03-roadmap/v0.1-correction.md`](../03-roadmap/v0.1-correction.md).
