#!/usr/bin/env bash
# guard-git.sh 的回歸規格。每列：預期判決 <TAB> 指令。
# 行為變更必須先改這張表 — 沒有檢查的規則不是規則，是願望。
# 所有案例都在暫存假 repo 裡跑：分支預設 work，第二段換到 main／master 驗分支規則；
# msg-ok.txt／msg-bad.txt 驗 -F 檔案的 trailer 規則。
# 執行：bash hooks/test-guard-git.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")"
HOOK="$PWD/guard-git.sh"

fail=0
tmp=$(mktemp -d)
trap 'cd / && rm -rf "$tmp"' EXIT
cd "$tmp" || exit 9
git init -q && git symbolic-ref HEAD refs/heads/main
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m fixture
printf 'Subject\n\n- Did x\n' > msg-ok.txt
printf 'Subject\n\n- Documented that Generated with footers are blocked\n' > msg-mentions.txt
printf 'Subject\n\n- Did x\n\nCo-Authored-By: X <x@y>\n' > msg-bad.txt
printf 'Subject\n\n- Did x\n\nco-authored-by: x <x@y>\n' > msg-lower.txt
printf 'Subject\n\n- Did x\n\nClaude-Session: https://example\n' > msg-session.txt
printf 'Subject\n\n- Did x\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n' > msg-harness.txt
printf '## Summary\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n' > body.md

# 只有 exit 2 算 BLOCK — hook 崩潰（exit 1）在 Claude Code 裡不擋，測試也不能把它當擋。
# run <want> <cmd> [cwd]：第三個參數模擬 payload 的 cwd 欄位。
run() {
  local want="$1" cmd="$2" hcwd="${3:-}"
  jq -n --arg c "$cmd" --arg w "$hcwd" '{tool_input:{command:$c}} + (if $w == "" then {} else {cwd:$w} end)' \
    | bash "$HOOK" >/dev/null 2>&1
  local code=$?
  local got=ALLOW
  [ "$code" = 2 ] && got=BLOCK
  if [ "$got" = "$want" ]; then
    printf '  ✓ %-5s [%s] %s\n' "$want" "$(git symbolic-ref --short -q HEAD 2>/dev/null || echo unborn)" "$cmd"
  else
    printf '  ✗ want=%s got=%s(exit %s) [%s] %s\n' "$want" "$got" "$code" "$(git symbolic-ref --short -q HEAD 2>/dev/null || echo unborn)" "$cmd"
    fail=1
    return 1
  fi
  return 0
}

table() {
  while IFS=$'	' read -r want cmd; do
    [ -z "$want" ] && continue
    run "$want" "$cmd"
  done
}

git switch -q -c work
table <<'CASES'
ALLOW	git reset --hard HEAD
BLOCK	git reset --hard
BLOCK	git reset --hard HEAD~1
BLOCK	git reset --hard origin/main
ALLOW	git status && git reset --hard HEAD
BLOCK	git reset --hard HEAD && git reset --hard abc123
ALLOW	echo "do not mention git reset --hard here"
ALLOW	git reset HEAD~1
BLOCK	git add -A
BLOCK	git add .
ALLOW	git add file.txt other/file.md
BLOCK	git push --force origin main
BLOCK	git push -f
BLOCK	git commit --no-verify -F msg-ok.txt
BLOCK	gh pr merge 100 --merge
BLOCK	gh pr merge --squash --delete-branch
BLOCK	gh pr view 100 --json state && gh pr merge 100
BLOCK	gh api repos/o/r/pulls/100/merge --method PUT
ALLOW	gh pr view 100 --json state,mergedAt
ALLOW	gh pr create --title "x" --body-file body.md
ALLOW	echo "tell the user to run gh pr merge themselves"
ALLOW	gh api repos/o/r/pulls/100 --jq .mergeable
BLOCK	git commit -m "x"
BLOCK	git commit -am "x"
BLOCK	git commit -qm "x"
BLOCK	git commit --message="x"
BLOCK	git commit -m"x"
BLOCK	git commit -m'x'
BLOCK	git commit -mfoo
BLOCK	git commit -sm "x"
BLOCK	git commit -F msg-ok.txt --trailer "Co-Authored-By: X <x@y>"
BLOCK	git add a.txt && git commit -m "x"
ALLOW	git commit --amend --no-edit
ALLOW	git commit -F msg-ok.txt
ALLOW	git commit -F "msg-ok.txt"
ALLOW	git commit --file=msg-ok.txt
ALLOW	git commit -Fmsg-ok.txt
ALLOW	git commit -F missing.txt
ALLOW	git commit -F msg-mentions.txt
ALLOW	gh pr edit 1 -F body.md && git commit -F msg-ok.txt
BLOCK	git commit -F msg-bad.txt
BLOCK	git commit -F "msg-bad.txt"
BLOCK	git commit --file=msg-bad.txt
BLOCK	git commit -Fmsg-bad.txt
BLOCK	git commit -F msg-lower.txt
BLOCK	git commit -F msg-session.txt
BLOCK	git commit -F msg-harness.txt
ALLOW	git commit -F msg-ok.txt && git push -u origin work
ALLOW	echo "never git commit -m, always -F"
CASES

git switch -q main
table <<'CASES'
BLOCK	git commit -F msg-ok.txt
BLOCK	git commit --amend --no-edit
ALLOW	git switch -c docs/x && git commit -F msg-ok.txt
ALLOW	git switch --create docs/x && git commit -F msg-ok.txt
ALLOW	git checkout -b docs/x && git commit -F msg-ok.txt
ALLOW	git status
ALLOW	git add file.txt
CASES

# payload 的 cwd 欄位決定看哪個 repo：程序 cwd 在 work 分支的 repo，payload 指向 main 的 repo。
other=$(mktemp -d)
( cd "$other" && git init -q && git symbolic-ref HEAD refs/heads/main \
  && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m fixture && git switch -q -c work )
run BLOCK "git commit -F msg-ok.txt" "$tmp"
( cd "$other" && run ALLOW "git commit -F $tmp/msg-ok.txt" ) || fail=1
rm -rf "$other"

# unborn branch：剛 init、零 commit 的 main 也算 main。
unborn=$(mktemp -d)
( cd "$unborn" && git init -q && git symbolic-ref HEAD refs/heads/main && run BLOCK "git commit --allow-empty -F $tmp/msg-ok.txt" ) || fail=1
rm -rf "$unborn"

git switch -q -c master
table <<'CASES'
BLOCK	git commit -F msg-ok.txt
CASES

exit $fail
