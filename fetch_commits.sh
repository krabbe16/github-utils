#!/bin/bash

OWNER="krabbe16"
REPOS=(
  "yurikago"
  "yurikago-astro"
  "yurikago-next"
)

# NOTE: 以下の環境変数は設定が必要
# GITHUB_TOKEN: GitHub APIを使用するために必要なトークン

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

# リポジトリのコミット情報を取得
fetch_commits() {
  local repo="$1"
  echo "===== Repository: $repo ====="

  PAGE=1
  while :; do
    echo "Fetching page $PAGE..."

    RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$OWNER/$repo/commits?per_page=100&page=$PAGE")

    if [ "$(echo "$RESPONSE" | jq 'length')" -eq 0 ]; then
      break
    fi

    echo "$RESPONSE" | jq -r '
      .[] | [
        "Date:   \(.commit.author.date)",
        "Author: \(.commit.author.name) <\(.commit.author.email)>",
        "Committer: \(.commit.committer.name) <\(.commit.committer.email)>",
        ""
      ] | .[]
    '

    ((PAGE++))

    # レートリミット対策
    sleep 3s
  done
}

# メイン処理
main() {
  check_jq_installed
  check_github_token_set
  redirect_log

  for REPO in "${REPOS[@]}"; do
    fetch_commits "$REPO"
  done
}

main
