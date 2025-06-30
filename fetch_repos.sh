#!/bin/bash

OWNER="krabbe16"

# jqコマンドの存在チェック
check_jq_installed() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed." >&2
    exit 1
  fi
}

# GITHUB_TOKEN未設定時のチェック
check_github_token_set() {
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set." >&2
    exit 1
  fi
}

# ログファイルへのリダイレクト
redirect_log() {
  SCRIPT_NAME="$(basename "$0" .sh)"
  LOG_FILE="${SCRIPT_NAME}.log"
  exec > "$LOG_FILE" 2>&1
}

# リポジトリ一覧を取得
fetch_repos() {
  PAGE=1
  while :; do
    RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/users/$OWNER/repos?per_page=100&page=$PAGE")

    if [ "$(echo "$RESPONSE" | jq 'length')" -eq 0 ]; then
      break
    fi

    # フォークしたリポジトリを除外
    echo "$RESPONSE" | jq -r '.[] | select(.fork == false) | .name'

    ((PAGE++))
  done
}

main() {
  check_jq_installed
  check_github_token_set
  redirect_log

  fetch_repos
}

main
