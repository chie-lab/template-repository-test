#!/bin/bash
set -euo pipefail

# 引数
SCRIPT_DIR="$1"
CONFIG_FILE="$2"
TEMPLATE_REPO="$3"
TEMPLATE_BRANCH="$4"

# 同期対象を解析
SYNC_TARGETS=$(/usr/local/bin/yq eval '.sync_targets[] | .path' "$CONFIG_FILE")

if [[ -z "$SYNC_TARGETS" ]]; then
  echo "No sync targets found in config"
  exit 0
fi

echo "=== Sync Targets ==="
echo "$SYNC_TARGETS"
echo ""

# 変更フラグ
CHANGED=false

# 各ターゲットを処理
while IFS= read -r target; do
  path=$(/usr/local/bin/yq eval ".sync_targets[] | select(.path == \"$target\") | .path" "$CONFIG_FILE")
  type=$(/usr/local/bin/yq eval ".sync_targets[] | select(.path == \"$target\") | .type" "$CONFIG_FILE")
  
  echo "Processing: $path (type: $type)"
  
  # ファイルリストを取得
  files=$("$SCRIPT_DIR/fetch-files.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$path" "$type")
  
  if [[ -z "$files" ]]; then
    echo "  No files found"
    continue
  fi
  
  # 各ファイルを同期
  while IFS=$'\t' read -r file template_sha; do
    echo "  - $file"
    
    result=$("$SCRIPT_DIR/sync-file.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$file" "$template_sha" "$SCRIPT_DIR")
    
    if [[ "$result" == "updated" ]]; then
      CHANGED=true
      echo "    Updated"
    else
      echo "    No changes (SHA match)"
    fi
    
  done <<< "$files"
  
done <<< "$SYNC_TARGETS"

# 結果を出力
echo ""
if [[ "$CHANGED" == "true" ]]; then
  echo "Files have been updated"
else
  echo "No changes detected"
fi
