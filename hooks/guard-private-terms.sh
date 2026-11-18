#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). 擋住帶有私有名單詞的 commit 訊息、PR／議題標題與內文。
# 名單在 repo 外（預設 ~/.claude/private-terms.txt），一行一詞、# 開頭為註解、不分大小寫；
# 沒有名單就放行。只掛在本 repo，不外發 — 外發會讓其他專案連自己的名字都寫不進去。
# 名單的讀法與 scripts/check.sh [19] 相同，改一邊就改另一邊。
# Contract: exit 2 = block the tool call; stderr goes back to the model as the reason.

list=${PRIVATE_TERMS_FILE:-$HOME/.claude/private-terms.txt}
[ -r "$list" ] || exit 0
# 空行與註解不能進樣式：空樣式會比中每一行。前後空白不算詞的一部分。
terms=$(tr -d '\r' < "$list" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -vE '^(#|$)')
[ -z "$terms" ] && exit 0

input=$(cat 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
hcwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$hcwd" ] && cd "$hcwd" 2>/dev/null

G="git([[:space:]]+(-C|-c)[[:space:]]+(\"[^\"]*\"|'[^']*'|[^[:space:]\"';|&]+))*[[:space:]]+commit"
segments=$(printf '%s\n' "$cmd" | tr ';&|' '\n' | sed -E 's/^[[:space:]]*(\$\()?[[:space:]]*//' \
  | grep -E "^(${G}|gh[[:space:]]+(pr|issue)[[:space:]]+(create|edit|comment))([[:space:]]|$)")
[ -z "$segments" ] && exit 0

# 換行分隔的單一樣式即多個樣式；Git Bash 的 grep -f <(…) 讀不到 process substitution，
# LC_ALL=C 搭 -iF 會 abort（exit 134）— 保持使用者 locale，中英文都比得到。
block() {
  printf 'Blocked: %s contains "%s", a term on the private list (%s). This repo only names outside projects listed under README 〈參考來源〉 or named by the user to borrow from; session examples and the user'"'"'s other projects stay out. Rewrite it as the general failure mode, then run the command again.\n' "$1" "$2" "$list" >&2
  exit 2
}

# 指令文字本身：涵蓋 -m、--title、--body 與 heredoc（-F -）。
hit=$(printf '%s\n' "$cmd" | grep -oiF -e "$terms" | head -1)
[ -n "$hit" ] && block "the command text" "$hit"

# 訊息檔：引號內的路徑可含空白。
files=$(printf '%s\n' "$segments" \
  | grep -oE "(-F|--file|--body-file)([[:space:]]+|=)?(\"[^\"]*\"|'[^']*'|[^[:space:]\"';|&]+)" \
  | sed -E "s/^(-F|--file|--body-file)([[:space:]]+|=)?//; s/^[\"']//; s/[\"']$//")
while IFS= read -r f; do
  [ -n "$f" ] && [ -r "$f" ] || continue
  hit=$(grep -oiF -e "$terms" "$f" | head -1)
  [ -n "$hit" ] && block "$f" "$hit"
done <<< "$files"

exit 0
