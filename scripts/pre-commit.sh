#!/usr/bin/env bash
# Pre-commit hook: format and lint staged Swift files.

set -euo pipefail

STAGED_SWIFT=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.swift$' || true)

if [ -z "$STAGED_SWIFT" ]; then
  exit 0
fi

if command -v swift-format >/dev/null 2>&1; then
  echo "→ swift-format"
  # shellcheck disable=SC2086
  swift-format format --in-place $STAGED_SWIFT
  # shellcheck disable=SC2086
  git add $STAGED_SWIFT
else
  echo "warning: swift-format not installed, skipping format (brew install swift-format)" >&2
fi

if command -v swiftlint >/dev/null 2>&1; then
  echo "→ swiftlint"
  # shellcheck disable=SC2086
  swiftlint lint --strict --quiet $STAGED_SWIFT
else
  echo "warning: swiftlint not installed, skipping lint (brew install swiftlint)" >&2
fi
