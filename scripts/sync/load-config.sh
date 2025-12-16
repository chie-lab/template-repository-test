#!/bin/bash
set -euo pipefail

# 共通定数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 引数チェック
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <template_repo> <template_branch>" >&2
  exit 1
fi

TEMPLATE_REPO="$1"
TEMPLATE_BRANCH="$2"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set" >&2
  exit 1
fi

# 設定ファイルの読み込み
CONFIG_FILE=".github/sync-config.override.yml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  # オーバーライドファイルがない場合、テンプレートから取得
  CONFIG_URL="https://api.github.com/repos/$TEMPLATE_REPO/contents/.github/sync-config.yml?ref=$TEMPLATE_BRANCH"
  
  CONFIG_CONTENT=$($CURL_CMD -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3.raw" \
    "$CONFIG_URL")
  
  if ! check_api_error "$CONFIG_CONTENT" "Fetching config from template"; then
    exit 1
  fi
  
  CONFIG_FILE="/tmp/sync-config.yml"
  echo "$CONFIG_CONTENT" > "$CONFIG_FILE"
fi

# 設定ファイルのパスを出力
echo "$CONFIG_FILE"
