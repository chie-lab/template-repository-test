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

# curlでHTTPステータスコードをチェックしてレスポンスを返す
curl_with_status_check() {
  local url="$1"
  local accept_header="${2:-application/vnd.github.v3+json}"
  local context="${3:-API call}"
  
  local response
  response=$($CURL_CMD -s -w "\n%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: $accept_header" \
    "$url")
  
  # HTTPステータスコードを取得（最終行）
  local http_code
  http_code=$(echo "$response" | tail -n 1)
  # レスポンスボディ（最終行以外）
  local content
  content=$(echo "$response" | head -n -1)
  
  # ステータスコードチェック
  if [[ "$http_code" != "200" ]]; then
    echo "Error: $context - HTTP $http_code" >&2
    return 1
  fi
  
  echo "$content"
}

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
