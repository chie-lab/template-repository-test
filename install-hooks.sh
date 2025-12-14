#!/bin/bash
set -e

echo "🔧 Installing Git hooks..."

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$ROOT_DIR" ]; then
  echo "❌ Error: This is not a git repository"
  exit 1
fi

HOOKS_DIR="$ROOT_DIR/.git-hooks"
GIT_HOOKS_DIR="$ROOT_DIR/.git/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Error: $HOOKS_DIR directory not found"
    exit 1
fi

for hook in "$HOOKS_DIR"/*; do
    if [ -f "$hook" ] && [ ! -d "$hook" ]; then
        hook_name=$(basename "$hook")
        ln -sf "$HOOKS_DIR/$hook_name" "$GIT_HOOKS_DIR/$hook_name"
    fi
done

echo "✅ Git hooks installed successfully"
exit 0
