#!/bin/bash
set -euo pipefail

# 共通定数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 引数
CONFIG_FILE="$1"
TEMPLATE_REPO="$2"
TEMPLATE_BRANCH="$3"

# 変更フラグ
CHANGED=false

# 単一ターゲットの処理
process_single_target() {
  local target="$1"
  local path type files
  
  path=$($YQ_CMD eval ".sync_targets[] | select(.path == \"$target\") | .path" "$CONFIG_FILE")
  type=$($YQ_CMD eval ".sync_targets[] | select(.path == \"$target\") | .type" "$CONFIG_FILE")
  
  echo "Processing: $path (type: $type)"
  
  files=$("$SCRIPT_DIR/fetch-files.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$path" "$type")
  
  if [[ -z "$files" ]]; then
    echo "  No files found"
    return
  fi
  
  sync_files "$files"
}

# ファイルリストの同期
sync_files() {
  local files="$1"
  local file template_sha result
  
  while IFS=$'\t' read -r file template_sha; do
    echo "  - $file"
    
    result=$("$SCRIPT_DIR/sync-file.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$file" "$template_sha")
    
    if [[ "$result" == "$SYNC_RESULT_UPDATED" ]]; then
      CHANGED=true
      echo "    Updated"
    else
      echo "    No changes (SHA match)"
    fi
  done <<< "$files"
}

# 同期対象を解析
SYNC_TARGETS=$($YQ_CMD eval '.sync_targets[] | .path' "$CONFIG_FILE")

if [[ -z "$SYNC_TARGETS" ]]; then
  echo "No sync targets found in config"
  exit 0
fi

echo "=== Sync Targets ==="
echo "$SYNC_TARGETS"
echo ""

# 各ターゲットを処理
while IFS= read -r target; do
  process_single_target "$target"
done <<< "$SYNC_TARGETS"

# 結果を出力
echo ""
if [[ "$CHANGED" == "true" ]]; then
  echo "Files have been updated"
else
  echo "No changes detected"
fi
