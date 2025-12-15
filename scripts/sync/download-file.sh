#!/bin/bash
set -euo pipefail

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

curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3.raw" \
  "$API_URL"
