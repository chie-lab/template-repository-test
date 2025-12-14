#!/bin/bash

# コミットメッセージのプレフィックスチェック
# 使用方法: このスクリプトはcommit-msgフックから自動実行されます

set -e

COMMIT_MSG_FILE="$1"
ROOT_DIR=$(git rev-parse --show-toplevel)
CONFIG_FILE="${ROOT_DIR}/.git-hooks/conf.d/commit_prefixes.yml"

# 設定ファイルが存在しない場合はエラー
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Commit prefix config not found at $CONFIG_FILE"
    echo ""
    echo "Please ensure the configuration file exists with valid prefixes."
    exit 1
fi

# コミットメッセージを読み取り
commit_message=$(cat "$COMMIT_MSG_FILE")

# マージコミットの場合はスキップ
if echo "$commit_message" | grep -q "^Merge "; then
    exit 0
fi

# リバートコミットの場合はスキップ  
if echo "$commit_message" | grep -q "^Revert "; then
    exit 0
fi

# yqコマンドの存在確認
if ! command -v yq &> /dev/null; then
    echo "❌ Error: yq is required but not installed."
    exit 1
fi

# 許可されたプレフィックスを取得
allowed_prefixes=$(yq -r '.[]' "$CONFIG_FILE" 2>/dev/null | tr '\n' '|' | sed 's/|$//')

if [ -z "$allowed_prefixes" ]; then
    echo "❌ Error: No valid prefixes found in $CONFIG_FILE"
    echo "Please check the YAML format and ensure it contains a list of prefixes."
    exit 1
fi

# プレフィックスチェック
if ! echo "$commit_message" | grep -qE "^($allowed_prefixes)(\(.+\))?: "; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Commit message must start with one of these prefixes:"
    yq -r '.[]' "$CONFIG_FILE" | sed 's/^/  - /'
    echo ""
    echo "Format: <prefix>: <description> or <prefix>(<scope>): <description>"
    echo ""
    echo "Examples:"
    echo "  feat: add new feature"
    echo "  fix(api): resolve authentication issue"
    echo "  docs: update README"
    echo ""
    echo "Your message: $commit_message"
    exit 1
fi

echo "✅ Commit message format is valid"
exit 0
