#!/bin/bash
set -euo pipefail

# 引数チェック
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <repo> <ref> <path> <type> [delete_if_missing]"
  exit 1
fi

REPO="$1"
REF="$2"
PATH="$3"
TYPE="$4"
DELETE_IF_MISSING="${5:-false}"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN is not set"
  exit 1
fi

# ファイル/ディレクトリの取得
fetch_content() {
  local path="$1"
  local api_url="https://api.github.com/repos/$REPO/contents/$path?ref=$REF"
  
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$api_url"
}

# ディレクトリを再帰的に取得
fetch_directory() {
  local path="$1"
  local content
  
  content=$(fetch_content "$path")
  
  if [[ -z "$content" ]] || echo "$content" | grep -q "\"message\""; then
    echo "Error: Failed to fetch directory: $path" >&2
    return 1
  fi
  
  echo "$content" | jq -r '.[] | select(.type == "file") | .path'
  
  # サブディレクトリを再帰的に処理
  local subdirs
  subdirs=$(echo "$content" | jq -r '.[] | select(.type == "dir") | .path')
  
  for subdir in $subdirs; do
    fetch_directory "$subdir"
  done
}

# メイン処理
if [[ "$TYPE" == "directory" ]]; then
  fetch_directory "$PATH"
elif [[ "$TYPE" == "file" ]]; then
  echo "$PATH"
else
  echo "Error: Invalid type: $TYPE" >&2
  exit 1
fi
