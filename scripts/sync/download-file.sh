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

RESPONSE=$($CURL_CMD -s -w "\n%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3.raw" \
  "$API_URL")

# HTTPステータスコードを取得（最終行）
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
# レスポンスボディ（最終行以外）
CONTENT=$(echo "$RESPONSE" | head -n -1)

# ステータスコードチェック
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Error: Failed to download file: $FILE_PATH (HTTP $HTTP_CODE)" >&2
  exit 1
fi

# コンテンツが空でないことを確認
if [[ -z "$CONTENT" ]]; then
  echo "Error: Downloaded file is empty: $FILE_PATH" >&2
  exit 1
fi

echo "$CONTENT"
