#!/bin/bash
set -euo pipefail

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 環境変数の検証
source "$SCRIPT_DIR/validate-env.sh"

# 設定ファイルの読み込み
echo "Loading config..."
CONFIG_FILE=$("$SCRIPT_DIR/load-config.sh" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH")

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found"
  exit 1
fi

echo "Using config: $CONFIG_FILE"
echo ""

# 同期対象を処理
"$SCRIPT_DIR/process-targets.sh" "$SCRIPT_DIR" "$CONFIG_FILE" "$TEMPLATE_REPO" "$TEMPLATE_BRANCH"

echo "Sync process completed successfully"
