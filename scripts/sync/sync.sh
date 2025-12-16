#!/bin/bash
set -euo pipefail

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 設定ファイルの読み込み
echo "Loading config..."
CONFIG_FILE=$("$SCRIPT_DIR/load-config.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH")

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found"
  exit 1
fi

echo "Using config: $CONFIG_FILE"
echo ""

# 同期対象を処理
"$SCRIPT_DIR/process-targets.sh" "$CONFIG_FILE" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH"

echo "Sync process completed successfully"
