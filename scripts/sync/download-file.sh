#!/bin/bash
set -euo pipefail

# 共通定数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 引数チェック
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <repo> <ref> <file_path>"
  exit 1
fi

REPO="$1"
REF="$2"
FILE_PATH="$3"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set"
  exit 1
fi

# ファイルの内容を取得
API_URL="https://api.github.com/repos/$REPO/contents/$FILE_PATH?ref=$REF"

CONTENT=$(curl_with_status_check "$API_URL" "application/vnd.github.v3.raw" "Downloading file: $FILE_PATH")

if [[ $? -ne 0 ]]; then
  exit 1
fi

# コンテンツが空でないことを確認
if [[ -z "$CONTENT" ]]; then
  echo "Error: Downloaded file is empty: $FILE_PATH" >&2
  exit 1
fi

echo "$CONTENT"
