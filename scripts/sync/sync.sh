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
  
  CONFIG_CONTENT=$(/usr/bin/curl -s -H "Authorization: token $GITHUB_TOKEN" \
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

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 同期対象を処理
CHANGED=false
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

while IFS= read -r target; do
  path=$(yq eval ".sync_targets[] | select(.path == \"$target\") | .path" "$CONFIG_FILE")
  type=$(yq eval ".sync_targets[] | select(.path == \"$target\") | .type" "$CONFIG_FILE")
  delete_if_missing=$(yq eval ".sync_targets[] | select(.path == \"$target\") | .delete_if_missing" "$CONFIG_FILE")
  
  echo "Processing: $path (type: $type)"
  
  # ファイルリストを取得
  files=$("$SCRIPT_DIR/fetch-files.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$path" "$type" "$delete_if_missing")
  
  if [[ -z "$files" ]]; then
    echo "  No files found"
    continue
  fi
  
  # 各ファイルをダウンロードして比較
  while IFS= read -r file; do
    echo "  - $file"
    
    # ダウンロード
    "$SCRIPT_DIR/download-file.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$file" > "$TEMP_DIR/$file.new"
    
    # ディレクトリを作成
    mkdir -p "$(dirname "$file")"
    
    # 変更チェック
    if [[ ! -f "$file" ]] || ! diff -q "$file" "$TEMP_DIR/$file.new" > /dev/null 2>&1; then
      cp "$TEMP_DIR/$file.new" "$file"
      CHANGED=true
      echo "    Updated"
    else
      echo "    No changes"
    fi
  done <<< "$files"
  
done <<< "$SYNC_TARGETS"

if [[ "$CHANGED" == "true" ]]; then
  echo ""
  echo "Files have been updated"
else
  echo ""
  echo "No changes detected"
fi

echo "Sync process completed successfully"
