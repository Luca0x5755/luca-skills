#!/usr/bin/env bash
# manage.sh 的行為測試：命令列（結束碼、輸出、檔案系統結果）與互動入口。
# HOME 指向暫存目錄，不碰真實的技能目錄。互動入口靠測試接縫 MANAGE_LIB=1 載入後覆寫 _is_tty。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$repo/scripts/manage.sh"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
export NO_COLOR=1

rc=0
out=""

# check 條件... -- 訊息：條件為真才過；不過就把訊息與最近一次輸出印出來。
check() {
  local msg=${*: -1}
  if ! "${@:1:$#-1}"; then
    printf '✗ %s\n--- 最近一次輸出（結束碼 %s）---\n%s\n' "$msg" "$rc" "$out" >&2
    exit 1
  fi
}

# m 參數...：非終端機執行 manage.sh；結果放進 rc 與 out（stdout 與 stderr 合併）。
m() {
  rc=0
  out="$(HOME="$test_home" bash "$script" "$@" </dev/null 2>&1)" || rc=$?
}

# t 輸入 參數...：載入腳本、把 _is_tty 覆寫成真，從 stdin 餵輸入，驗證互動入口。
t() {
  local input=$1
  shift
  rc=0
  out="$(printf '%b' "$input" | HOME="$test_home" MANAGE_LIB=1 bash -c \
    'source "$1"; shift; _is_tty() { return 0; }; main "$@"' _ "$script" "$@" 2>&1)" || rc=$?
}

reset_home() { rm -rf "$test_home/.claude" "$test_home/.copilot" "$test_home/.agents"; }
skill_path() {
  case "$1" in
    claude) echo "$test_home/.claude/skills/${2:-ask-luca}" ;;
    copilot) echo "$test_home/.copilot/skills/${2:-ask-luca}" ;;
    codex) echo "$test_home/.agents/skills/${2:-ask-luca}" ;;
  esac
}
linked() { [ -L "$(skill_path "$1" "${2:-ask-luca}")" ]; }
exists() { [ -e "$1" ] || [ -L "$1" ]; }
count_lines() { printf '%s\n' "$out" | grep -c "$1" || true; }
eq() { [ "$1" = "$2" ]; }

echo 'exit codes: help 0, usage errors 2'
m --help
check eq "$rc" 0 '--help 沒有結束碼 0'
m
check eq "$rc" 2 '沒有終端機又沒有子命令，應結束碼 2'
m install
check eq "$rc" 2 'install 沒給代理又沒有終端機，應結束碼 2'
m install nope
check eq "$rc" 2 '未知代理應結束碼 2'
m bogus
check eq "$rc" 2 '未知子命令應結束碼 2'
m all
check eq "$rc" 2 '已移除的 all 目標應被拒絕'
m -x
check eq "$rc" 2 '未知選項應結束碼 2'
m install codex --yes
check eq "$rc" 2 'install 不支援 --yes，應結束碼 2'
m status codex --dry-run
check eq "$rc" 2 'status 不支援 --dry-run，應結束碼 2'
m install --help
check eq "$rc" 0 'install --help 應結束碼 0'
[ ! -e "$test_home/.agents" ] || { echo '✗ help 與用法錯誤不應建立目錄' >&2; exit 1; }

echo 'install codex links only Codex'
m install codex
check eq "$rc" 0 'install codex 失敗'
check linked codex 'install codex 沒有連結 ask-luca'
check eq "$(readlink "$(skill_path codex)")" "$repo/skills/core/ask-luca" 'ask-luca 連結沒有指向 repo 的 core'
[ ! -e "$test_home/.claude/skills" ] && [ ! -e "$test_home/.copilot/skills" ] || { echo '✗ install codex 動到其他代理' >&2; exit 1; }

echo 'a bare agent name is an alias of install'
reset_home
m claude
check eq "$rc" 0 '裸代理名失敗'
check linked claude '裸代理名沒有連結'
[ ! -e "$test_home/.agents/skills" ] || { echo '✗ 裸代理名動到其他代理' >&2; exit 1; }

echo 'install --dry-run prints the commands and changes nothing'
reset_home
m install codex --dry-run
check eq "$rc" 0 'install --dry-run 失敗'
check grep -q '^+ ln ' <<<"$out" 'install --dry-run 沒有印出將執行的指令'
[ ! -e "$test_home/.agents" ] || { echo '✗ install --dry-run 改了檔案系統' >&2; exit 1; }

echo 'duplicate agent names install once'
m install codex codex
check eq "$rc" 0 '重複代理名失敗'
check eq "$(count_lines '^== codex')" 1 '重複代理名裝了兩次'

echo 'a foreign same-name skill is preserved, and a collision does not block another agent'
reset_home
foreign="$(skill_path codex)"
mkdir -p "$foreign"
printf 'keep me' >"$foreign/sentinel.txt"
m install codex
check eq "$rc" 1 'install 覆寫了外來同名技能（或沒回報失敗）'
[ -f "$foreign/sentinel.txt" ] || { echo '✗ 外來技能被改動' >&2; exit 1; }
[ ! -e "$(skill_path codex tdd)" ] || { echo '✗ 衝突後仍部分安裝' >&2; exit 1; }
m install codex claude
check eq "$rc" 1 '多代理安裝遇到衝突卻回報成功'
check linked claude '衝突擋住了獨立的 Claude 安裝'
[ -f "$foreign/sentinel.txt" ] || { echo '✗ 多代理執行改動了外來技能' >&2; exit 1; }

echo 'a dangling link left by graduation is replaced'
reset_home
mkdir -p "$test_home/.agents/skills"
ln -s "$repo/skills/draft/ask-luca" "$(skill_path codex)"
m install codex
check eq "$rc" 0 'install 拒絕了自己的斷鏈'
check test -f "$(skill_path codex)/SKILL.md" '斷鏈沒有改指向 core'

echo 'a dangling link that is not ours counts as a conflict and stays untouched'
reset_home
mkdir -p "$test_home/.agents/skills"
ln -s "$test_home/no-such-target" "$(skill_path codex)"
m install codex
check eq "$rc" 1 'install 把外來的斷鏈當成可以覆寫'
check eq "$(readlink "$(skill_path codex)")" "$test_home/no-such-target" '外來斷鏈被改動'

echo 'a skills directory that points into this repo is refused'
reset_home
mkdir -p "$test_home/.agents"
ln -s "$repo/docs" "$test_home/.agents/skills"
m install codex --dry-run
check eq "$rc" 1 'install 沒擋下指回本 repo 的技能目錄'
m uninstall codex --dry-run
check eq "$rc" 1 'uninstall 沒擋下指回本 repo 的技能目錄'

echo 'a link whose name contains a newline is never split into two removals'
reset_home
skills_dir="$test_home/.claude/skills"
mkdir -p "$skills_dir" "$test_home/cwd"
ln -s "$test_home/mine-target" "$skills_dir/mine"
printf 'x' >"$skills_dir/userfile"
printf 'x' >"$test_home/cwd/sentinel"
ln -s "$repo/skills/core/ask-luca" "$skills_dir/mine
sentinel"
(cd "$test_home/cwd" && HOME="$test_home" bash "$script" uninstall claude -y </dev/null >/dev/null 2>&1) || true
[ -L "$skills_dir/mine" ] && [ -f "$skills_dir/userfile" ] && [ -f "$test_home/cwd/sentinel" ] ||
  { echo '✗ 換行名稱的連結讓 uninstall 刪到無關的東西' >&2; exit 1; }
(cd "$test_home/cwd" && HOME="$test_home" bash "$script" install claude </dev/null >/dev/null 2>&1) || true
[ -L "$skills_dir/mine" ] && [ -f "$skills_dir/userfile" ] && [ -f "$test_home/cwd/sentinel" ] ||
  { echo '✗ 換行名稱的連結讓 install 的過期清理刪到無關的東西' >&2; exit 1; }

echo 'install prunes stale repo links but leaves everything else'
reset_home
skills_dir="$test_home/.agents/skills"
mkdir -p "$skills_dir" "$test_home/outside-target" "$skills_dir/my-own-skill"
ghost="$skills_dir/ghost-skill"
ln -s "$repo/skills/core/ghost-skill" "$ghost"
ln -s "$test_home/outside-target" "$skills_dir/outside-link"
m install codex --dry-run
check eq "$rc" 0 'install --dry-run 失敗'
check exists "$ghost" 'install --dry-run 清掉了過期連結'
m install codex
check eq "$rc" 0 '有過期連結時 install 失敗'
[ ! -L "$ghost" ] || { echo '✗ install 沒有清掉過期連結' >&2; exit 1; }
[ -L "$skills_dir/outside-link" ] || { echo '✗ install 清掉了不是本 repo 建的連結' >&2; exit 1; }
[ -d "$skills_dir/my-own-skill" ] || { echo '✗ install 清掉了一般資料夾' >&2; exit 1; }
m status codex
check eq "$rc" 0 'install 後 status 不乾淨'

echo 'uninstall removes only this repo links and keeps the rest'
reset_home
m install codex claude
own="$test_home/.agents/skills/my-own-skill"
mkdir -p "$own"
printf 'keep me' >"$own/sentinel.txt"
ln -s "$repo/skills/core/ghost-skill" "$test_home/.agents/skills/ghost-skill"
m uninstall codex -y
check eq "$rc" 0 'uninstall 失敗'
for name in ask-luca tdd ghost-skill; do
  [ ! -e "$(skill_path codex "$name")" ] && [ ! -L "$(skill_path codex "$name")" ] || { echo "✗ uninstall 留下 $name" >&2; exit 1; }
done
[ -f "$own/sentinel.txt" ] || { echo '✗ uninstall 刪了不是本 repo 建的技能' >&2; exit 1; }
[ -d "$test_home/.agents/skills" ] || { echo '✗ uninstall 把技能目錄本身刪了' >&2; exit 1; }
check linked claude 'uninstall codex 動到 Claude'
[ -f "$repo/skills/core/ask-luca/SKILL.md" ] || { echo '✗ uninstall 刪到 repo 裡的檔案' >&2; exit 1; }

echo 'uninstall skips a foreign same-name skill'
rm "$(skill_path claude)"
mkdir "$(skill_path claude)"
printf 'keep me' >"$(skill_path claude)/sentinel.txt"
m uninstall claude -y
check eq "$rc" 0 '遇到外來同名技能時 uninstall 失敗'
[ -f "$(skill_path claude)/sentinel.txt" ] || { echo '✗ uninstall 刪了外來同名技能' >&2; exit 1; }
[ ! -L "$(skill_path claude tdd)" ] || { echo '✗ uninstall 留下其他本 repo 連結' >&2; exit 1; }

echo 'uninstall without a terminal needs -y; --dry-run changes nothing'
reset_home
m install codex
m uninstall codex
check eq "$rc" 2 '沒有終端機又沒有 -y，uninstall 應結束碼 2'
check linked codex '沒有 -y 的 uninstall 動了連結'
m uninstall codex --dry-run
check eq "$rc" 0 'uninstall --dry-run 失敗'
check linked codex 'uninstall --dry-run 動了連結'

echo 'uninstall on an agent that was never installed succeeds quietly'
m uninstall copilot -y
check eq "$rc" 0 '對沒裝過的代理 uninstall 失敗'
[ ! -e "$test_home/.copilot" ] || { echo '✗ uninstall 建立了目錄' >&2; exit 1; }

echo 'status: missing exits 1, complete exits 0, damage is named, nothing changes'
reset_home
m status codex
check eq "$rc" 1 '空的代理 status 應結束碼 1'
[ ! -e "$test_home/.agents" ] || { echo '✗ status 建立了目錄' >&2; exit 1; }
m install codex
m status codex
check eq "$rc" 0 '完整安裝的 status 應結束碼 0'
d="$test_home/.agents/skills"
rm "$d/ask-luca" && ln -s "$repo/skills/draft/ask-luca" "$d/ask-luca"
ln -s "$repo/skills/core/ghost-skill" "$d/ghost-skill"
rm "$d/tdd" && mkdir "$d/tdd"
before="$(ls -A "$d" | wc -l)"
m status codex
check eq "$rc" 1 '受損安裝的 status 應結束碼 1'
for word in ask-luca ghost-skill tdd; do
  check grep -q "$word" <<<"$out" "status 沒有點名 $word"
done
check eq "$(ls -A "$d" | wc -l)" "$before" 'status 改動了技能目錄'

echo 'Git Bash / MSYS is refused for every action, --help still works'
reset_home
for action in install uninstall status; do
  rc=0
  out="$(HOME="$test_home" MANAGE_LIB=1 bash -c 'source "$1"; _os_name() { echo MINGW64_NT-10.0; }; main "$2" claude' _ "$script" "$action" </dev/null 2>&1)" || rc=$?
  check eq "$rc" 1 "MSYS 下 $action 應被擋"
  check grep -q 'manage.ps1' <<<"$out" "MSYS 的訊息沒有指向 manage.ps1（$action）"
done
[ ! -e "$test_home/.claude" ] || { echo '✗ MSYS 防護擋下後仍建立了目錄' >&2; exit 1; }
rc=0
out="$(HOME="$test_home" MANAGE_LIB=1 bash -c 'source "$1"; _os_name() { echo MINGW64_NT-10.0; }; main install --help' _ "$script" </dev/null 2>&1)" || rc=$?
check eq "$rc" 0 'MSYS 下 install --help 不該被擋'

echo 'interactive: end of input cancels the menu and the agent prompt'
reset_home
t ''
check eq "$rc" 1 '選單讀到 EOF 應結束碼 1'
t '1'
check eq "$rc" 1 '選代理時讀到 EOF 應結束碼 1'
t '1\n1,3'
check eq "$rc" 1 '輸入錯誤後讀到 EOF 應結束碼 1'
[ ! -e "$test_home/.claude/skills" ] || { echo '✗ 取消後仍安裝了技能' >&2; exit 1; }

echo 'interactive: the menu picks the action, then installs only the chosen agent without confirmation'
t '1\n3\n'
check eq "$rc" 0 '選單安裝失敗'
check linked codex '選單安裝沒有連結 Codex'
[ ! -e "$test_home/.claude/skills" ] || { echo '✗ 選單安裝了沒選的代理' >&2; exit 1; }
check eq "$(count_lines '確認繼續')" 0 'install 仍要求確認'
check eq "$(count_lines '^→ manage.sh install codex$')" 1 '選單沒有印出等價指令'
for line in '  1) install ' '  2) uninstall ' '  3) status '; do
  check grep -qF -- "$line" <<<"$out" "選單缺少：$line"
done

echo 'interactive: space-separated selection installs each agent once'
reset_home
t '1\n  3  1\t3  \n'
check eq "$rc" 0 '多選失敗'
check linked codex '多選沒有裝 Codex'
check linked claude '多選沒有裝 Claude'
[ ! -e "$test_home/.copilot/skills" ] || { echo '✗ 多選裝了沒選的代理' >&2; exit 1; }
check eq "$(count_lines '^== codex')" 1 '重複編號讓 Codex 裝了兩次'
check eq "$(count_lines '即將安裝：codex, claude$')" 1 '選定摘要不符'
for line in '  1. claude' '  2. copilot' '  3. codex'; do
  check grep -qxF -- "$line" <<<"$out" "代理選單缺少：$line"
done

echo 'interactive: invalid selections retry without partial installs'
reset_home
t '1\n\n   \n1,3\n0\n4\n-1\n1 x\n13\n999999999999999999999999999999\n2\n'
check eq "$rc" 0 '錯誤後的有效輸入應成功'
check linked copilot '有效輸入沒有裝 Copilot'
check eq "$(count_lines '請輸入一個或多個有效編號')" 9 '無效輸入沒有全部重問'
[ ! -e "$test_home/.claude/skills" ] && [ ! -e "$test_home/.agents/skills" ] || { echo '✗ 無效輸入造成部分安裝' >&2; exit 1; }

echo 'interactive: uninstall asks once, default No'
t '2\n2\n\n'
check eq "$rc" 1 '空答案應取消 uninstall'
check linked copilot '空答案後連結不見了'
t '2\n2\nn\n'
check eq "$rc" 1 '回答 n 應取消 uninstall'
check linked copilot '回答 n 後連結不見了'
t '2\n2\ny\n'
check eq "$rc" 0 '回答 y 應執行 uninstall'
[ ! -L "$(skill_path copilot)" ] || { echo '✗ 回答 y 後連結還在' >&2; exit 1; }

echo 'interactive: status from the menu is read only'
t '3\n2\n'
check eq "$rc" 1 '沒裝的代理 status 應結束碼 1'

echo 'ops-lib is copied verbatim from the skeleton'
diff <(sed -n '/^# ---- BEGIN ops-lib/,/^# ---- END ops-lib/p' "$script") \
  <(sed -n '/^# ---- BEGIN ops-lib/,/^# ---- END ops-lib/p' "$repo/skills/draft/ops-script/skeleton.sh") >/dev/null ||
  { echo '✗ manage.sh 的 ops-lib 區段與骨架不一致' >&2; exit 1; }

echo 'bash and PowerShell expose the same subcommands'
bash_subs=$(sed -n 's/^#\/   \([a-z][a-z-]*\) .*/\1/p' "$script" | tr '\n' ' ')
ps_subs=$(sed -n 's/^    \([a-z]*\) *= @{ Desc.*/\1/p' "$repo/scripts/manage.ps1" | tr '\n' ' ')
[[ -n "$bash_subs" && "$bash_subs" == "$ps_subs" ]] ||
  { echo "✗ manage.sh [$bash_subs] 與 manage.ps1 [$ps_subs] 的子命令不一致" >&2; exit 1; }

echo 'shellcheck reports nothing (skipped when not installed)'
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$script" || { echo '✗ manage.sh 有 shellcheck 警告' >&2; exit 1; }
else
  echo '  - shellcheck 未安裝，略過'
fi

echo 'all manage.sh tests passed'
