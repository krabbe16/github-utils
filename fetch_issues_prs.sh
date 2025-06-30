#!/bin/bash

OWNER="krabbe16"
REPOS=(
  github-utils
  krabbe16
  puppeteer-css-coverage
  sandbox-cdk-ts
  sandbox-cdk-ts-cfn-lint
  sandbox-cdk-ts-ecs-fargate-datadog
  sandbox-circleci-nuxt-test-utils
  sandbox-eslint-config-typescript
  sandbox-hast-util-raw
  sandbox-husky-lint-staged
  sandbox-jest-puppeteer
  sandbox-js-debug
  sandbox-jsmart
  sandbox-jsonld
  sandbox-lighthouse
  sandbox-lighthouse-v6
  sandbox-lint-action
  sandbox-nltk
  sandbox-node-express
  sandbox-nuxt-axios-retry
  sandbox-nuxt-intersection-observer
  sandbox-nuxt-proxy
  sandbox-nuxt-retry-axios
  sandbox-nuxt-watch
  sandbox-nuxt-with-vue-intersect
  sandbox-nuxt2-ts-provide-inject
  sandbox-nuxt3-lighthouse-ci
  sandbox-preload-polyfill
  sandbox-puppeteer
  sandbox-puppeteer-examples
  sandbox-tesseract
  sandbox-tf-waf-rule-uri-and-ip
  sandbox-uuid
  sandbox-vite-promise
  sandbox-vscode-extension
  sandbox-webpack-typescript
  slides-from-markdown
  sugoi-haskell
  tokei-note
  yurikago
  yurikago-astro
  yurikago-next
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

# リポジトリのイシューとPRの数を取得
fetch_issues_and_prs() {
  local repo="$1"
  echo "===== Repository: $repo ====="

  # イシュー数
  for state in open closed; do
    RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/search/issues?q=repo:$OWNER/$repo+type:issue+state:$state")

    if [ "$(echo "$RESPONSE" | jq 'length')" -eq 0 ]; then
      echo "Issues ($state): 0"
      continue
    fi

    ISSUE_COUNT=$(echo "$RESPONSE" | jq '.total_count')
    echo "Issues ($state): $ISSUE_COUNT"

    # レートリミット対策
    sleep 5s
  done

  # PR数
  for state in open closed; do
    RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/search/issues?q=repo:$OWNER/$repo+type:pr+state:$state")

    if [ "$(echo "$RESPONSE" | jq 'length')" -eq 0 ]; then
      echo "Pull Requests ($state): 0"
      continue
    fi

    PR_COUNT=$(echo "$RESPONSE" | jq '.total_count')
    echo "Pull Requests ($state): $PR_COUNT"

    # レートリミット対策
    sleep 5s
  done
}

# メイン処理
main() {
  check_jq_installed
  check_github_token_set
  redirect_log

  for REPO in "${REPOS[@]}"; do
    fetch_issues_and_prs "$REPO"
  done
}

main
