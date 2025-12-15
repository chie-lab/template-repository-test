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
  # オーバーライドファイルがない場合、テンプレートから取得
  echo "Fetching config from template..."
  CONFIG_URL="https://api.github.com/repos/$TEMPLATE_REPO/contents/.github/sync-config.yml?ref=$TEMPLATE_BRANCH"
  
  CONFIG_CONTENT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3.raw" \
    "$CONFIG_URL")
  
  if [[ $? -ne 0 ]] || [[ -z "$CONFIG_CONTENT" ]]; then
    echo "Error: Failed to fetch config from template"
    exit 1
  fi
  
  echo "$CONFIG_CONTENT" > /tmp/sync-config.yml
  CONFIG_FILE="/tmp/sync-config.yml"
  echo "Using template config"
else
  echo "Using override config: $CONFIG_FILE"
fi

# 設定ファイルの解析
echo ""
echo "=== Sync Targets ==="
SYNC_TARGETS=$(yq eval '.sync_targets[] | .path' "$CONFIG_FILE")

if [[ -z "$SYNC_TARGETS" ]]; then
  echo "No sync targets found in config"
  exit 0
fi

echo "$SYNC_TARGETS"
echo ""

# TODO: GitHub APIでファイル取得
# TODO: ファイルの反映
# TODO: 変更検知

echo "Sync process completed successfully"
