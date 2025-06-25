#!/bin/bash

OWNER="krabbe16"

# NOTE: 以下の環境変数は設定が必要
# REPO_DIR: コミットを書き換える対象のリポジトリが存在するディレクトリ

show_git_remotes() {
  git remote -v
}

check_git_filter_repo_installed() {
  if ! command -v git-filter-repo >/dev/null 2>&1; then
    echo "Error: git-filter-repo is not installed." >&2
    exit 1
  fi
}

# コミットのAuthorとCommitterを置換
replace_author_committer() {
  git-filter-repo --force \
    --name-callback '
      name = name.replace(b"aaa", b"bbb")
      name = name.replace(b"ccc", b"ddd")
      return name
    ' \
    --email-callback '
      email = email.replace(b"aaa", b"bbb")
      email = email.replace(b"ccc", b"ddd")
      return email
    '
}

# git-filter-repoの実行後はリモートリポジトリの設定が消失するため追加
add_remote() {
  if git remote | grep -q "^origin$"; then
    echo "origin remote already exists. Skipping add."
  else
    git remote add origin "https://github.com/${OWNER}/${REPO}.git"
    echo "origin remote added."
  fi
}

force_push_all_branches() {
  git push origin --force --all
}

enter_repo_dir() {
  pushd "$REPO_DIR" >/dev/null || { echo "Failed to change directory: $REPO_DIR"; return 1; }
}

leave_repo_dir() {
  popd >/dev/null
}

main() {
  enter_repo_dir || return 1
  show_git_remotes
  check_git_filter_repo_installed
  replace_author_committer
  add_remote_and_push
  force_push_all_branches
  leave_repo_dir
}

main
