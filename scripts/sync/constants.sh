#!/bin/bash
# 共通定数定義

# コマンドパス
readonly CURL_CMD="/usr/bin/curl"
readonly GREP_CMD="/usr/bin/grep"
readonly JQ_CMD="/usr/bin/jq"
readonly YQ_CMD="/usr/local/bin/yq"

# 同期タイプ
readonly TYPE_DIRECTORY="directory"
readonly TYPE_FILE="file"

# 同期結果
readonly SYNC_RESULT_UPDATED="updated"
readonly SYNC_RESULT_NO_CHANGE="no-change"

# APIエラーチェック用関数
check_api_error() {
  local content="$1"
  local context="${2:-API call}"
  
  if [[ -z "$content" ]]; then
    echo "Error: $context - Empty response" >&2
    return 1
  fi
  
  # JSONエラーメッセージをチェック
  local error_message
  error_message=$(echo "$content" | $JQ_CMD -r '.message // empty' 2>/dev/null)
  
  if [[ -n "$error_message" ]]; then
    echo "Error: $context - $error_message" >&2
    return 1
  fi
  
  return 0
}
