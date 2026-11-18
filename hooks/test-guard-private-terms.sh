#!/usr/bin/env bash
# guard-private-terms.sh 的回歸規格。每列：預期判決 <TAB> 指令。
# 名單由 PRIVATE_TERMS_FILE 指向暫存 fixture，不碰使用者的真名單；fixture 詞是虛構的。
# 執行：bash hooks/test-guard-private-terms.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")"
HOOK="$PWD/guard-private-terms.sh"

fail=0
tmp=$(mktemp -d)
trap 'cd / && rm -rf "$tmp"' EXIT
cd "$tmp" || exit 9
printf '# 註解行不算詞\n\nzebra-farm\n秘密專案\n' > terms.txt
printf 'Subject\n\n- Ported the fix from zebra-farm\n' > msg-bad.txt
printf 'Subject\n\n- Ported the fix from ZEBRA-FARM\n' > msg-upper.txt
printf 'Subject\n\n- Fixed the general failure mode\n' > msg-ok.txt
printf '## 摘要\n\n- 秘密專案實測\n' > body-bad.md
printf '## 摘要\n\n- 一般化的失效模式\n' > body-ok.md
cp msg-bad.txt "my msg.txt"
printf '  zebra-farm  \n' > padded.txt

# 只有 exit 2 算 BLOCK。run <want> <cmd> [terms-file]
run() {
  local want="$1" cmd="$2" list="${3-$tmp/terms.txt}"
  jq -n --arg c "$cmd" --arg w "$tmp" '{tool_input:{command:$c}, cwd:$w}' \
    | PRIVATE_TERMS_FILE="$list" bash "$HOOK" >/dev/null 2>&1
  local code=$? got=ALLOW
  [ "$code" = 2 ] && got=BLOCK
  if [ "$got" = "$want" ]; then
    printf '  ✓ %-5s %s\n' "$want" "$cmd"
  else
    printf '  ✗ want=%s got=%s(exit %s) %s\n' "$want" "$got" "$code" "$cmd"
    fail=1
  fi
}

table() {
  while IFS=$'\t' read -r want cmd; do
    [ -z "$want" ] && continue
    run "$want" "$cmd"
  done
}

table <<'CASES'
BLOCK	git commit -F msg-bad.txt
BLOCK	git commit -F msg-upper.txt
BLOCK	git commit --file=msg-bad.txt
BLOCK	git add a.md && git commit -F "msg-bad.txt"
ALLOW	git commit -F msg-ok.txt
ALLOW	git commit -F missing.txt
BLOCK	gh pr create --title "x" --body-file body-bad.md
BLOCK	gh pr edit 1 -F body-bad.md
ALLOW	gh pr create --title "x" --body-file body-ok.md
BLOCK	gh issue create --title "x" --body-file body-bad.md
BLOCK	gh issue comment 3 -F body-bad.md
BLOCK	git commit -F "my msg.txt"
BLOCK	git -C . commit -F msg-bad.txt
BLOCK	gh pr create --title "x" --body "從 zebra-farm 移植"
BLOCK	gh pr create --title "移植 zebra-farm" --body-file body-ok.md
ALLOW	gh pr create --title "x" --body "一般化的失效模式"
ALLOW	cat msg-bad.txt
ALLOW	git log -F msg-bad.txt
CASES

# 沒有名單 → 放行：CI 與別人的機器上沒有這份檔。
run ALLOW "git commit -F msg-bad.txt" "$tmp/no-such-list.txt"
# heredoc 的訊息在指令文字裡，不在檔案裡。
run BLOCK "git commit -F - <<'EOF'
Ported the fix from zebra-farm
EOF"
# 名單詞前後的空白不算詞的一部分。
run BLOCK "git commit -F msg-bad.txt" "$tmp/padded.txt"
# 絕對路徑的訊息檔。
run BLOCK "git commit -F $tmp/msg-bad.txt"
# 名單只有註解與空行 → 放行，不能變成比中每一行。
printf '# only comments\n\n' > empty.txt
run ALLOW "git commit -F msg-ok.txt" "$tmp/empty.txt"

exit $fail
