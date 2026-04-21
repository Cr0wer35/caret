#!/usr/bin/env bash
# Installs git hooks for the Caret project.
# Run once after cloning: ./scripts/install-hooks.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT/.git/hooks"
SCRIPTS_DIR="$ROOT/scripts"

if [ ! -d "$ROOT/.git" ]; then
  echo "error: not a git repository" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR"

ln -sf "$SCRIPTS_DIR/pre-commit.sh" "$HOOKS_DIR/pre-commit"
chmod +x "$SCRIPTS_DIR/pre-commit.sh"

echo "✓ Installed pre-commit hook"
echo "  Runs swift-format + swiftlint on staged Swift files before each commit."
