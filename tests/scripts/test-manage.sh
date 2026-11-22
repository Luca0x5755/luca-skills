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

echo 'menu rows say what and whether it asks; flag details stay in --help'
# disp_width 字串：顯示寬度近似值 — 多位元組字元算 2 欄（CJK 與全形標點皆為 3 位元組）
disp_width() {
  local c b
  c=$(LC_ALL=C.UTF-8 bash -c 'printf %s "${#1}"' _ "$1")
  b=$(LC_ALL=C bash -c 'printf %s "${#1}"' _ "$1")
  echo $((c + (b - c) / 2))
}
# 選單畫面：run_menu 立刻讀到 EOF 取消；清單列用 awk 挑（grep 沒對上回 1，pipefail 會中止）
screen="$(MANAGE_LIB=1 bash -c 'source "$1"; run_menu' _ "$script" </dev/null 2>&1 || true)"
out="$(awk '/^ +[0-9]+\) /' <<<"$screen")"
check eq "$(printf '%s\n' "$out" | awk 'END { print NR }')" 3 '選單應恰有 3 列'
FLAG_RE='(^|[[:space:]（(、，；：「/])--?[A-Za-z]'
no_flag() { ! [[ "$1" =~ $FLAG_RE ]]; }
fits_80() { (($(disp_width "$1") <= 80)); }
has() { [[ "$1" == *"$2"* ]]; }
check has "$screen" '要做什麼？（q 取消）' '選單應有標題行「要做什麼？（q 取消）」'
check has "$screen" '輸入編號：' '選單的輸入行應是「輸入編號：」'
check eq "$(awk '/選擇編號/' <<<"$screen")" "" '選單不該再印「選擇編號」'
# 選單行＝「  N) 名稱<空白>」＋需確認欄（[需確認] 或同寬空白）＋描述
ROW_RE='^( *[0-9]+\) [a-z0-9-]+ +)(\[需確認\] )?(.*)$'
BRACKET_RE='[（(\[]'
no_bracket() { ! [[ "$1" =~ $BRACKET_RE ]]; }
row_parses() { [[ "$1" =~ $ROW_RE ]]; }
starts=""
while IFS= read -r line; do
  check no_flag "$line" "選單行不該含旗標：$line"
  check fits_80 "$line" "選單行超過 80 欄：$line"
  # 單獨一行 =~ 沒對上時 errexit 會無聲中止，所以走 check 印出是哪一列
  check row_parses "$line" "選單行無法解析：$line"
  [[ "$line" =~ $ROW_RE ]]
  # 先存起來：後面的 =~ 會覆寫 BASH_REMATCH
  prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}" desc="${BASH_REMATCH[3]}"
  check no_bracket "$desc" "描述欄不該有括號：$line"
  starts+="$(disp_width "$prefix")"$'\n'
done <<<"$out"
check eq "$(printf '%s' "$starts" | sort -u | awk 'END { print NR }')" 1 "各列描述起始欄位應相同，實得 ${starts//$'\n'/ }"
# 要確認的子命令集合由下方行為測試證明：uninstall 無終端機沒帶 -y 結束碼 2、install 不問
# 用 awk 不用 grep：沒有任何一列帶標記時 grep 回 1，pipefail 會讓整支測試無聲中止
marked="$(printf '%s\n' "$out" | awk 'index($0, "[需確認]") { print $2 }' | paste -sd, -)"
check eq "$marked" uninstall "標 [需確認] 的子命令應恰為 uninstall，實得「$marked」"
m --help
check has "$out" '--dry-run    只印將移除的連結' '--help 應仍說明 uninstall 的 --dry-run'
check has "$out" '-y, --yes    免互動確認' '--help 應仍說明 uninstall 的 -y'

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
t '1\n3\n\n'
check eq "$rc" 0 '選單安裝失敗'
check linked codex '選單安裝沒有連結 Codex'
[ ! -e "$test_home/.claude/skills" ] || { echo '✗ 選單安裝了沒選的代理' >&2; exit 1; }
check eq "$(count_lines '確認繼續')" 0 'install 仍要求確認'
check eq "$(count_lines '^→ manage.sh install codex$')" 1 '選單沒有印出等價指令'
for line in '  1) install ' '  2) uninstall ' '  3) status '; do
  check grep -qF -- "$line" <<<"$out" "選單缺少：$line"
done

echo 'interactive: the agent prompt is the ops-lib multiselect, picks come back in list order'
reset_home
t '1\n3 1\n\n'
check eq "$rc" 0 '多選失敗'
check linked codex '多選沒有裝 Codex'
check linked claude '多選沒有裝 Claude'
[ ! -e "$test_home/.copilot/skills" ] || { echo '✗ 多選裝了沒選的代理' >&2; exit 1; }
check eq "$(count_lines '即將安裝：claude, codex$')" 1 '選定摘要不符（應依清單順序）'
check eq "$(count_lines '要安裝哪些代理？（例：1 3 5-7；a 全選、n 全不選、Enter 確定）$')" 2 '代理選單不是 ops-lib 的多選器'
for line in '  1) [x] claude' '  2) [ ] copilot' '  3) [x] codex'; do
  check grep -qxF -- "$line" <<<"$out" "代理選單缺少：$line"
done

echo 'interactive: toggling twice unpicks, out-of-range and junk are ignored'
reset_home
t '1\n1 1 0 4 x 2\n\n'
check eq "$rc" 0 '忽略無效記號後應成功'
check linked copilot '有效編號沒有裝 Copilot'
[ ! -e "$test_home/.claude/skills" ] && [ ! -e "$test_home/.agents/skills" ] || { echo '✗ 無效記號造成多餘安裝' >&2; exit 1; }

echo 'interactive: confirming with nothing picked cancels'
reset_home
t '1\n\n'
check eq "$rc" 1 '什麼都沒選就確定應結束碼 1'
[ ! -e "$test_home/.claude/skills" ] || { echo '✗ 沒選卻安裝了技能' >&2; exit 1; }

echo 'interactive: uninstall asks once, default No'
reset_home
m install copilot
t '2\n2\n\n\n'
check eq "$rc" 1 '空答案應取消 uninstall'
check linked copilot '空答案後連結不見了'
t '2\n2\n\nn\n'
check eq "$rc" 1 '回答 n 應取消 uninstall'
check linked copilot '回答 n 後連結不見了'
t '2\n2\n\ny\n'
check eq "$rc" 0 '回答 y 應執行 uninstall'
[ ! -L "$(skill_path copilot)" ] || { echo '✗ 回答 y 後連結還在' >&2; exit 1; }

echo 'interactive: status from the menu is read only'
t '3\n2\n\n'
check eq "$rc" 1 '沒裝的代理 status 應結束碼 1'

echo 'ops-lib is copied verbatim from the skeleton'
diff <(sed -n '/^# ---- BEGIN ops-lib/,/^# ---- END ops-lib/p' "$script") \
  <(sed -n '/^# ---- BEGIN ops-lib/,/^# ---- END ops-lib/p' "$repo/skills/draft/ops-script/skeleton.sh") >/dev/null ||
  { echo '✗ manage.sh 的 ops-lib 區段與骨架不一致' >&2; exit 1; }

echo 'pickers live only in ops-lib: no hand-rolled number prompt outside the block'
# 自製選擇器曾與 multiselect 並存而不自知；挑選一律走 ops-lib，區段外不得有自己的編號提示
outside=$(sed '/^# ---- BEGIN ops-lib/,/^# ---- END ops-lib/d' "$script" | grep -c '輸入編號' || true)
check eq "$outside" 0 'manage.sh 在 ops-lib 區段外自己畫了編號提示，改用 multiselect'

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
