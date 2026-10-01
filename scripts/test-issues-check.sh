#!/usr/bin/env bash
# check-issues.sh 的回歸規格。每個案例在暫存假 repo 裡開一條分支、做一件事、commit，
# 再以 main 當 base 跑檢查，只看 exit code（與失敗時 stderr 是否點名檔案）。
# 行為變更必須先改這份規格 — 沒有檢查的規則不是規則，是願望。
# 執行：bash scripts/test-issues-check.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")/.."
CHECK="$PWD/skills/core/setup-skills/check-issues.sh"

fail=0
tmp=$(mktemp -d)
trap 'cd / && rm -rf "$tmp"' EXIT
cd "$tmp" || exit 9
g() { git -c user.email=t@t -c user.name=t "$@"; }
git init -q && git symbolic-ref HEAD refs/heads/main && git config core.autocrlf false
mkdir -p docs/issues
echo old > docs/issues/ISSUE-000-old.md
echo hello > README.md
git add -A && g commit -q -m base
BASE=$(git rev-parse main)

verdict() {  # verdict <want-exit> <name> <got-exit>
  if [ "$3" = "$1" ]; then
    printf '  ✓ exit %s  %s\n' "$1" "$2"
  else
    printf '  ✗ want exit %s, got %s  %s\n' "$1" "$3" "$2"
    fail=1
  fi
}

n=0
# case_ <want-exit> <name> <shell body run on a fresh branch off main> [must-mention]
case_() {
  local want="$1" name="$2" body="$3" mention="${4:-}"
  n=$((n + 1))
  git switch -q main && git switch -q -c "t$n"
  eval "$body"
  git add -A && g commit -q --allow-empty -m "$name"
  local err code
  err=$(bash "$CHECK" "$BASE" 2>&1 >/dev/null)
  code=$?
  verdict "$want" "$name" "$code"
  if [ -n "$mention" ] && ! printf '%s' "$err" | grep -qF "$mention"; then
    printf '  ✗ stderr 沒有點名 %s\n' "$mention"
    fail=1
  fi
}

case_ 1 "分支新增議題 → 擋，並點名檔案" 'echo n > docs/issues/ISSUE-001-new.md' 'ISSUE-001-new.md'
case_ 0 "分支沒動 docs/issues → 過" 'echo x >> README.md'
case_ 0 "新增後又刪除（淨零）→ 過" 'echo n > docs/issues/ISSUE-001-tmp.md; git add -A; g commit -q -m tmp; git rm -q docs/issues/ISSUE-001-tmp.md'
case_ 0 "刪除分支點前就存在的議題 → 過" 'git rm -q docs/issues/ISSUE-000-old.md'
case_ 0 "修改分支點前就存在的議題 → 過" 'echo more >> docs/issues/ISSUE-000-old.md'
case_ 0 "新增 docs/issues 以外的檔案 → 過" 'echo n > docs/other.md'
case_ 1 "把別處的檔案 rename 進 docs/issues → 擋" 'git mv README.md docs/issues/ISSUE-002-moved.md' 'ISSUE-002-moved.md'
case_ 0 "在 docs/issues 內重新命名既有議題 → 過" 'git mv docs/issues/ISSUE-000-old.md docs/issues/ISSUE-000-renamed.md'

# 從子目錄執行結果不變：pathspec 以 repo 根為準，不看目前目錄。
git switch -q t1
(cd docs && bash "$CHECK" "$BASE" >/dev/null 2>&1)
verdict 1 "從 repo 子目錄執行也照樣擋" $?

# 分支點之後 main 才新增的議題不算這條分支的：三點語法以 merge-base 為準。
git switch -q main && git switch -q -c t-advance
echo x >> README.md && git add -A && g commit -q -m "branch work"
git switch -q main && echo n > docs/issues/ISSUE-003-on-main.md && git add -A && g commit -q -m "main advances"
git switch -q t-advance
bash "$CHECK" "$(git rev-parse main)" >/dev/null 2>&1
verdict 0 "分支點之後 main 才新增的議題 → 過" $?

# 傳參出錯必須擋（fail closed），CI 不能因為 base 是空字串就靜默通過。
bash "$CHECK" >/dev/null 2>&1
verdict 2 "缺 base 參數 → 擋" $?
bash "$CHECK" deadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/dev/null 2>&1
verdict 2 "base 不存在 → 擋" $?
git switch -q --orphan t-unrelated && echo u > u.txt && git add -A && g commit -q -m unrelated
bash "$CHECK" "$BASE" >/dev/null 2>&1
verdict 2 "與 base 沒有共同祖先，git diff 自己失敗 → 擋" $?

[ $fail -eq 0 ] && echo "全部通過。"
exit $fail
