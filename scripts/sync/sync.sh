#!/bin/bash
set -euo pipefail

# 環境変数の確認
TEMPLATE_REPO="${TEMPLATE_REPO:-}"
TEMPLATE_BRANCH="${TEMPLATE_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$TEMPLATE_REPO" ]]; then
  echo "Error: TEMPLATE_REPO is not set"
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set"
  exit 1
fi

echo "=== Template Sync Script ==="
echo "Template: $TEMPLATE_REPO@$TEMPLATE_BRANCH"
echo ""

# 設定ファイルの読み込み
CONFIG_FILE=".github/sync-config.override.yml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  CONFIG_FILE=".github/sync-config.yml"
  echo "Using template config: $CONFIG_FILE"
else
  echo "Using override config: $CONFIG_FILE"
fi

# TODO: 設定ファイルの解析
# TODO: GitHub APIでファイル取得
# TODO: ファイルの反映
# TODO: 変更検知

echo "Sync process completed successfully"
