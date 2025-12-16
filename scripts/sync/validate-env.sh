#!/bin/bash
set -euo pipefail

# 環境変数の検証
TEMPLATE_REPO="${TEMPLATE_REPO:-}"
TEMPLATE_BRANCH="${TEMPLATE_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$TEMPLATE_REPO" ]]; then
  echo "Error: TEMPLATE_REPO is not set" >&2
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set" >&2
  exit 1
fi

echo "=== Template Sync Script ==="
echo "Template: $TEMPLATE_REPO@$TEMPLATE_BRANCH"
echo ""
