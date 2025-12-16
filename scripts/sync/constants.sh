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
