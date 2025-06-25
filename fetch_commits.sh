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

    # ステータスコードとレスポンスを取得
    RESPONSE_AND_STATUS=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$OWNER/$repo/commits?per_page=100&page=$PAGE")
    HTTP_STATUS=$(echo "$RESPONSE_AND_STATUS" | tail -n1)
    HTTP_BODY=$(echo "$RESPONSE_AND_STATUS" | sed '$d')

    # HTTPステータスコードのチェック
    if [ "$HTTP_STATUS" -ne 200 ]; then
      echo "Error: HTTP status $HTTP_STATUS for $repo (page $PAGE)" >&2
      break
    fi

    # レスポンスが配列かどうかのチェック
    if ! echo "$HTTP_BODY" | jq 'type == "array"' | grep -q true; then
      echo "Error: Response is not an array for $repo (page $PAGE)" >&2
      break
    fi

    if [ "$(echo "$HTTP_BODY" | jq 'length')" -eq 0 ]; then
      break
    fi

    echo "$HTTP_BODY" | jq -r '
      .[]
      | "Author: \(.commit.author.name) <\(.commit.author.email)>\nCommitter: \(.commit.committer.name) <\(.commit.committer.email)>\n"
    '

    ((PAGE++))
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
