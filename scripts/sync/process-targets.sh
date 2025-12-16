#!/bin/bash
set -euo pipefail

# 共通定数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 引数
CONFIG_FILE="$1"
TEMPLATE_REPO="$2"
TEMPLATE_BRANCH="$3"

# 単一ターゲットの処理
# 戻り値: 0=変更あり, 1=変更なし, 2=エラー
process_single_target() {
  local target="$1"
  local path type files
  local has_changes=1
  
  path=$($YQ_CMD eval ".sync_targets[] | select(.path == \"$target\") | .path" "$CONFIG_FILE")
  type=$($YQ_CMD eval ".sync_targets[] | select(.path == \"$target\") | .type" "$CONFIG_FILE")
  
  echo "Processing: $path (type: $type)"
  
  if ! files=$("$SCRIPT_DIR/fetch-files.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$path" "$type"); then
    echo "  Error: Failed to fetch files" >&2
    return 2
  fi
  
  if [[ -z "$files" ]]; then
    echo "  No files found"
    return 1
  fi
  
  if ! sync_files "$files"; then
    local sync_result=$?
    if [[ $sync_result -eq 2 ]]; then
      return 2
    fi
    has_changes=1
  else
    has_changes=0
  fi
  
  return $has_changes
}

# ファイルリストの同期
# 戻り値: 0=変更あり, 1=変更なし, 2=エラー
sync_files() {
  local files="$1"
  local file template_sha result
  local has_changes=1
  
  while IFS=$'\t' read -r file template_sha; do
    echo "  - $file"
    
    if ! result=$("$SCRIPT_DIR/sync-file.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$file" "$template_sha"); then
      echo "    Error: Failed to sync file" >&2
      return 2
    fi
    
    if [[ "$result" == "$SYNC_RESULT_UPDATED" ]]; then
      has_changes=0
      echo "    Updated"
    else
      echo "    No changes (SHA match)"
    fi
  done <<< "$files"
  
  return $has_changes
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
HAS_CHANGES=false
while IFS= read -r target; do
  process_result=0
  if ! process_single_target "$target"; then
    process_result=$?
    if [[ $process_result -eq 2 ]]; then
      echo "Error: Failed to process target: $target" >&2
      exit 1
    fi
  else
    HAS_CHANGES=true
  fi
done <<< "$SYNC_TARGETS"

# 結果を出力
echo ""
if [[ "$HAS_CHANGES" == "true" ]]; then
  echo "Files have been updated"
else
  echo "No changes detected"
fi
