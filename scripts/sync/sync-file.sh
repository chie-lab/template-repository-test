#!/bin/bash
set -euo pipefail

# 共通定数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 引数チェック
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <template_repo> <template_branch> <file_path> <template_sha>" >&2
  exit 1
fi

TEMPLATE_REPO="$1"
TEMPLATE_BRANCH="$2"
FILE_PATH="$3"
TEMPLATE_SHA="$4"

# ローカルファイルのSHAを計算
LOCAL_SHA=""
if [[ -f "$FILE_PATH" ]]; then
  LOCAL_SHA=$(git hash-object "$FILE_PATH" 2>/dev/null || echo "")
fi

# SHA比較
if [[ "$LOCAL_SHA" == "$TEMPLATE_SHA" ]]; then
  echo "$SYNC_RESULT_NO_CHANGE"
  exit 0
fi

# SHAが異なる場合のみダウンロード
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$(dirname "$TEMP_DIR/$FILE_PATH.new")"
"$SCRIPT_DIR/download-file.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH" "$FILE_PATH" > "$TEMP_DIR/$FILE_PATH.new"

# ディレクトリを作成
mkdir -p "$(dirname "$FILE_PATH")"

# ファイルをコピー
cp "$TEMP_DIR/$FILE_PATH.new" "$FILE_PATH"

echo "$SYNC_RESULT_UPDATED"
