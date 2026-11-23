#!/usr/bin/env bash
#/ 用法：manage.sh [子命令] [代理...] [選項]
#/ 把 skills/core 與 skills/draft 的技能連進代理的個人技能目錄，或移除、檢查這些連結。
#/ 不帶參數且有終端機時先選動作、再選代理；帶子命令時直接執行（可供排程與其他腳本呼叫）。
#/
#/ 子命令：
#/   install              把技能連進代理目錄
#/   uninstall   [需確認] 移除本 repo 建的連結
#/   status               唯讀檢查連結狀態
#/
#/ install：順手清掉已封存或改名的過期連結。
#/   --dry-run    只印將執行的指令，什麼都不改
#/ uninstall：只移除本 repo 建立的連結，不碰外來技能。
#/   --dry-run    只印將移除的連結，什麼都不改
#/   -y, --yes    免互動確認（沒有終端機時必須給）
#/ status：有缺漏、斷鏈、過期或同名衝突時結束碼 1。
#/
#/ 代理：claude、copilot、codex，可多個；省略時有終端機就詢問、沒有就結束碼 2。
#/ 代理名稱單獨當子命令，等同 install 該代理（bash scripts/manage.sh claude）。
#/
#/ 選項：
#/   -h, --help   顯示這份說明
#/
#/ 結束碼：0 完成、1 失敗或操作者取消、2 用法錯誤
#
# draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
# 沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。archive 不連。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。
#
# 只處理「本 repo 建立」的連結（目標落在本 repo 的 core/ 或 draft/ 底下，斷鏈也算）；外來的同名技能一律不碰。
#   - 子命令表就是上方的 `#/` 行：--help 逐字印出它們，選單與分派解析同一批行。
#     子命令列固定「#/」加三個空格縮排；名稱 x-y 分派到函式 cmd_x_y。
#   - ops-lib 區段逐字複製、不准手改；要改就改 skills/draft/ops-script/skeleton.sh 並升版號。
#   - 測試接縫：MANAGE_LIB=1，只定義函式、不跑主流程。

# 拒絕被 source：set -e 與 exit 會汙染操作者的 shell。要載入請用測試接縫。
# 守衛放在 set 之前，被擋時呼叫端的 shell 選項不會被動到。
if [[ "${BASH_SOURCE[0]}" != "$0" && "${MANAGE_LIB:-}" != "1" ]]; then
  printf '✗ 不可 source 這支腳本\n    請直接執行；要在測試中載入函式，設定 MANAGE_LIB=1\n' >&2
  return 1
fi

# 嚴格模式只是安全網：重要的失敗一律自己攔下、用 die 回報，不靠 set -e 報錯。
set -euo pipefail

# ---- BEGIN ops-lib v8 ----
# 終端機探針：全區段唯一碰 -t 的地方，測試覆寫它來模擬終端機。
_is_tty() { [[ -t "$1" ]]; }

# 顏色：stdout 非終端機、NO_COLOR 非空、TERM=dumb 任一成立即關閉。可重複呼叫。
color_init() {
  if _is_tty 1 && [[ -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    RED=$'\033[31m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
  else
    RED=""; BOLD=""; RESET=""
  fi
}
color_init

# die_with CODE 標題 [怎麼修...]：先寫錯什麼、再寫怎麼修，全走 stderr。
die_with() {
  local code=$1 title=${2:-發生錯誤} line
  shift $(($# < 2 ? $# : 2))
  printf '%s✗ %s%s\n' "$RED$BOLD" "$title" "$RESET" >&2
  for line in "$@"; do printf '    %s\n' "$line" >&2; done
  exit "$code"
}
die() { die_with 1 "$@"; }

# confirm 提示：預設 No；只有 y／yes（不分大小寫）回 0，EOF 也是 No。
confirm() {
  local ans=""
  printf '%s [y/N] ' "$1" >&2
  read -r ans || true
  case "$ans" in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# require_tty [怎麼修...]：只看 stdin。缺值要詢問的路徑先過這關，沒有終端機就 exit 2。
# 修法由呼叫端給（點名該補的選項）；不給才用通用句。
require_tty() {
  (($#)) || set -- "改用選項或參數傳入所需的值，或在終端機中執行"
  _is_tty 0 || die_with 2 "需要終端機" "$@"
}

# ---- 結果回報 ----
# 計數與訊息：每個行程從 0 開始。計數一律用 $((…))，不用 ((n++))（n 為 0 時回傳 1，set -e 會中止）。
N_PASS=0; N_FAIL=0; N_WARN=0; N_SKIP=0
ISSUES=()

# ---- 逐步模式 ----
# 全域狀態（本區段保留的名稱）：STEP_ON 開關、STEP_ALL 已按 a、STEP_N 目前步驟的流水號。
STEP_ON=0; STEP_ALL=0; STEP_N=0

# enable_step_mode：開啟逐步模式。停點讀 stdin，所以沒有終端機就 exit 2、什麼都還沒做。
# 由子命令在解析完參數後呼叫；修法點名 --step，因為操作者只能拿掉它。
enable_step_mode() {
  require_tty "拿掉 --step，或在終端機中執行"
  STEP_ON=1
}

# _step_gate 標題：停點。Enter 執行；a 執行並讓之後不再停；q 或 EOF 先印總表、點名停在哪一步之前，exit 1；
# 其他輸入（含 y）重問。沒有跳過：跳過的步驟若記成 [PASS] 就是說謊。
_step_gate() {
  local ans=""
  while true; do
    printf '[Enter 執行、a 之後不再停、q 離開] ' >&2
    # 最後一行沒有換行時 read 回非 0 但 ans 有值：有值就照常處理，只有真正的 EOF 才當 q。
    read -r ans || [[ -n "$ans" ]] || ans=q
    case "$ans" in
      "") return 0 ;;
      [aA]) STEP_ALL=1; return 0 ;;
      [qQ])
        printf '\n' >&2
        print_summary
        printf '停在步驟 %d「%s」之前\n' "$STEP_N" "$1" >&2
        exit 1
        ;;
    esac
  done
}

# step 標題 [說明行...]：步驟標題，走 stderr。說明行（選填，1–3 行）只在逐步模式印；
# 逐步模式下標題帶流水號並在執行前停一次（a 之後只印不停）。停點掛在 step、不掛在 run：
# 掛在 run 會讓被跳過的步驟記成 [PASS]。
step() {
  local title=$1 line
  shift
  if ((!STEP_ON)); then
    printf '%s== %s%s\n' "$BOLD" "$title" "$RESET" >&2
    return 0
  fi
  STEP_N=$((STEP_N + 1))
  printf '%s== 步驟 %d：%s%s\n' "$BOLD" "$STEP_N" "$title" "$RESET" >&2
  for line in "$@"; do printf '   %s\n' "$line" >&2; done
  if ((!STEP_ALL)); then _step_gate "$title"; fi
}

pass() { N_PASS=$((N_PASS + 1)); printf '[PASS] %s\n' "$*" >&2; }
skip() { N_SKIP=$((N_SKIP + 1)); printf '[SKIP] %s\n' "$*" >&2; }
warn() {
  N_WARN=$((N_WARN + 1)); ISSUES+=("[WARN] $*")
  printf '[WARN] %s\n' "$*" >&2
}
fail() {
  N_FAIL=$((N_FAIL + 1)); ISSUES+=("[FAIL] $*")
  printf '%s[FAIL] %s%s\n' "$RED" "$*" "$RESET" >&2
}

# print_summary：總表走 stderr，並重列所有 fail 與 warn。
# 空陣列在 -u 下要用 ${arr[@]+"${arr[@]}"}，舊版 bash 直接展開會當成未設定變數。
print_summary() {
  local line
  printf '總計：pass %d  fail %d  warn %d  skip %d\n' "$N_PASS" "$N_FAIL" "$N_WARN" "$N_SKIP" >&2
  for line in ${ISSUES[@]+"${ISSUES[@]}"}; do printf '  %s\n' "$line" >&2; done
}

# finish：印總表後結束；有任何 fail 結束碼為 1，否則 0。
finish() {
  print_summary
  if ((N_FAIL > 0)); then exit 1; fi
  exit 0
}

# ---- 多選器 ----
# _ms_toggle LO HI：切換 MS_SEL 的第 LO～HI 項（1 起算）；越界的部分忽略。
_ms_toggle() {
  local i lo=$1 hi=$2 t
  if ((lo > hi)); then t=$lo; lo=$hi; hi=$t; fi
  # 夾進 1..n：越界的部分直接不走，不靠迴圈跑完再丟棄。
  if ((lo < 1)); then lo=1; fi
  if ((hi > ${#MS_SEL[@]})); then hi=${#MS_SEL[@]}; fi
  for ((i = lo; i <= hi; i++)); do MS_SEL[i - 1]=$((1 - MS_SEL[i - 1])); done
}

# _ms_apply 一行輸入：a 全選、n 全不選、「3」「5-7」切換；不認得的記號忽略。
_ms_apply() {
  local tok i toks=()
  # 用 read -a 切詞：for tok in $1 會讓 * 與 ? 依目前目錄的檔名展開。
  read -ra toks <<<"$1" || true
  for tok in ${toks[@]+"${toks[@]}"}; do
    if [[ "$tok" =~ ^[aA]$ ]]; then
      for i in "${!MS_SEL[@]}"; do MS_SEL[i]=1; done
    elif [[ "$tok" =~ ^[nN]$ ]]; then
      for i in "${!MS_SEL[@]}"; do MS_SEL[i]=0; done
    elif [[ "$tok" =~ ^([0-9]{1,6})-([0-9]{1,6})$ ]]; then
      _ms_toggle "$((10#${BASH_REMATCH[1]}))" "$((10#${BASH_REMATCH[2]}))"
    elif [[ "$tok" =~ ^[0-9]{1,6}$ ]]; then
      _ms_toggle "$((10#$tok))" "$((10#$tok))"
    fi
  done
}

# multiselect 標題 項目...（MS_SEL 為本區段保留的全域名）：畫面與提示走 stderr；確定後 stdout 每行一個選中的編號（1 起算、遞增）、回傳 0。
# 取消（什麼都沒選就 Enter，或讀到 EOF）回傳 1、stdout 無輸出；用 return，由呼叫端決定怎麼收尾。
multiselect() {
  local title=$1 line="" i n w picked=0
  shift
  local items=("$@")
  n=${#items[@]}
  w=${#n}
  MS_SEL=()
  for ((i = 0; i < n; i++)); do MS_SEL+=(0); done
  while true; do
    printf '%s（例：1 3 5-7；a 全選、n 全不選、Enter 確定）\n' "$title" >&2
    # 編號在前、標記在後，編號欄寬依項目數；與選單的 `N) 名稱` 對齊。
    for ((i = 0; i < n; i++)); do
      printf '  %*d) [%s] %s\n' "$w" "$((i + 1))" "$( ((MS_SEL[i])) && echo x || echo ' ')" "${items[i]}" >&2
    done
    printf '輸入編號：' >&2
    IFS= read -r line || return 1
    if [[ -z "${line//[[:space:]]/}" ]]; then break; fi
    _ms_apply "$line"
  done
  for ((i = 0; i < n; i++)); do
    if ((MS_SEL[i])); then printf '%d\n' "$((i + 1))"; picked=1; fi
  done
  ((picked)) || return 1
}

# ---- 單選器 ----
# select_one 標題 項目...：畫面與提示走 stderr；輸入有效編號即選定，stdout 印該編號（1 起算）、回傳 0。
# Enter、q 或讀到 EOF 回傳 1、stdout 無輸出；越界或看不懂的輸入說明後重問（只讀一個值，忽略它等於沒反應）。
select_one() {
  local title=$1 line="" i n w
  shift
  local items=("$@")
  n=${#items[@]}
  w=${#n}
  while true; do
    printf '%s（q 取消）\n' "$title" >&2
    for ((i = 0; i < n; i++)); do printf '  %*d) %s\n' "$w" "$((i + 1))" "${items[i]}" >&2; done
    printf '輸入編號：' >&2
    # 不設 IFS=：讓 read 去掉前後空白，「 3 」照樣選得到。
    read -r line || return 1
    case "$line" in "" | [qQ]) return 1 ;; esac
    if [[ "$line" =~ ^[0-9]{1,6}$ ]] && ((10#$line >= 1 && 10#$line <= n)); then
      printf '%d\n' "$((10#$line))"
      return 0
    fi
    printf '無效的選項：%s\n' "$line" >&2
  done
}

# pick_by_name 旗標 值 項目...：無人值守時的挑選。值是逗號分隔的項目名稱，逐一與項目整串精確比對（分大小寫）；
# 輸出與 multiselect 相同（stdout 每行一個編號、1 起算、遞增、不重複），呼叫端兩條路共用同一段收尾。
# 收名稱不收編號：編號跟著清單順序走，清單一改，排程裡的編號就指到別的項目。
# 空值或任何一個不認得的名稱都以結束碼 2 結束，訊息列出可用的名稱。
pick_by_name() {
  local flag=$1 raw=$2 v i hit hint vals=() sel=()
  shift 2
  local items=("$@")
  hint="可用的名稱（逗號分隔）：$(IFS=,; printf '%s' "${items[*]}")"
  for i in "${!items[@]}"; do sel+=(0); done
  [[ -n "$raw" ]] || die_with 2 "$flag 沒有值" "$hint"
  # -d '' 讀到輸入結尾：值裡的換行留在欄位內、比對失敗；預設的 read 只讀第一行，會讓「alpha\n其他」蒙混過關。
  # 補一個逗號再切：read 會丟掉結尾的空欄位，補上之後「alpha,」的空名稱才留得下來、被擋。
  IFS=, read -r -d '' -a vals < <(printf '%s,' "$raw") || true
  for v in "${vals[@]}"; do
    hit=0
    for i in "${!items[@]}"; do
      if [[ "$v" == "${items[i]}" ]]; then sel[i]=1; hit=1; fi
    done
    ((hit)) || die_with 2 "$flag 的值無效：${v:-（空）}" "$hint"
  done
  for i in "${!items[@]}"; do
    if ((sel[i])); then printf '%d\n' "$((i + 1))"; fi
  done
}

# pick_one_by_name 旗標 值 項目...：pick_by_name 的單選版，select_one 的無人值守路徑；給了不只一個名稱就以結束碼 2 結束。
pick_one_by_name() {
  local flag=$1 picks
  picks=$(pick_by_name "$@") || exit "$?"
  [[ "$picks" != *$'\n'* ]] || die_with 2 "$flag 只能選一個：$2" "只給一個名稱，不要用逗號列出多個"
  printf '%s\n' "$picks"
}
# ---- END ops-lib ----

# 絕對路徑：腳本中途 cd 之後，--help、選單與分派仍讀得到自己。
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}"
SCRIPT_NAME="${SELF##*/}"
REPO="$(cd "$(dirname "$SELF")/.." && pwd)"

# --help 的唯一來源：檔頭的 `#/` 行（去掉前綴）。
usage() { sed -n 's/^#\/ \{0,1\}//p' "$SELF"; }
usage_error() { usage >&2; die_with 2 "$@"; }

# 子命令表：只認「#/」加三個空格縮排、接小寫名稱的行。
table_rows() { sed -n 's/^#\/   \([a-z][a-z0-9-]*\)[[:space:]].*$/\1/p' "$SELF"; }
table_desc() { sed -n "s/^#\/   $1[[:space:]]\{1,\}//p" "$SELF"; }

# 需確認欄：描述以 CONFIRM_MARK 開頭的列會停下來確認。table_desc 吃掉名稱後的所有空白，
# 所以任一列有需確認時，由選單替其餘列補同寬的 CONFIRM_PAD；全表都沒有就不留這一欄。
CONFIRM_MARK='[需確認] '
CONFIRM_PAD='         ' # 與 CONFIRM_MARK 同寬：中文一字 2 欄
confirm_pad() {
  local name
  while IFS= read -r name; do
    if [[ "$(table_desc "$name")" == "$CONFIRM_MARK"* ]]; then
      printf '%s' "$CONFIRM_PAD"
      return 0
    fi
  done < <(table_rows)
}

# menu_items：選單的項目，每列「名稱 需確認欄 描述」，依子命令表順序；編號由 select_one 加上。
menu_items() {
  local name desc pad
  pad=$(confirm_pad)
  while IFS= read -r name; do
    desc=$(table_desc "$name")
    [[ "$desc" == "$CONFIRM_MARK"* ]] || desc="$pad$desc"
    printf '%-10s %s\n' "$name" "$desc"
  done < <(table_rows)
}

# run_menu：先選動作（一次 select_one）；代理在動作裡再選，等價指令在選完代理後印（FROM_MENU）。取消 exit 1。
# 取消直接 exit、呼叫端不以 `||` 接它：函式在 `||` 左側時 errexit 失效，子命令失敗會被吞掉。
run_menu() {
  local idx items=()
  FROM_MENU=1
  mapfile -t items < <(menu_items)
  idx=$(select_one "要做什麼？" "${items[@]}") || exit 1
  run_command "$(table_rows | sed -n "${idx}p")"
}

run_command() {
  local name=$1
  shift
  # 整行精確比對；不用空白拼接，否則含空白的名稱會同時對上兩列。
  if ! table_rows | grep -Fx -- "$name" >/dev/null; then
    usage_error "未知子命令：$name" "用 --help 查看可用的子命令"
  fi
  "cmd_${name//-/_}" "$@"
}

# run DRY 指令...：先印將執行的指令；DRY=1 時到此為止。會改系統的動作都走它。
run() {
  local dry=$1
  shift
  printf '+ %s\n' "$*"
  if [[ "$dry" != 1 ]]; then "$@"; fi
}

# ---- 代理與技能 ----
AGENT_NAMES=(claude copilot codex)
AGENTS=()
DRY=0
YES=0
FROM_MENU=0
SKILLS=()
SKILL_NAMES=" "

# 代理各自的個人技能目錄。Codex 讀 ~/.agents/skills；Copilot 也讀這裡，
# 但 Copilot 改連自己的目錄，避免同一個技能被載入兩次。
dest_for() {
  case "$1" in
    claude) echo "$HOME/.claude/skills" ;;
    copilot) echo "$HOME/.copilot/skills" ;;
    codex) echo "$HOME/.agents/skills" ;;
  esac
}

resolve_directory() { (cd -P "$1" 2>/dev/null && pwd); }

# 取得作業系統名稱：獨立成函式，測試覆寫它來模擬 Git Bash。
_os_name() { uname -s; }

# Git Bash / MSYS 的 ln -s 會退化成「複製目錄」而不是建連結，
# 複製品不會跟著 repo 更新 —— 靜默地裝出一份會過期的技能。--help 不經過這裡。
refuse_msys() {
  case "$(_os_name)" in
    MINGW* | MSYS* | CYGWIN*)
      die_with 1 "Git Bash / MSYS 下的 ln -s 會複製而非連結" \
        "改用 PowerShell：.\\scripts\\manage.ps1 $*" ;;
  esac
}

load_skills() {
  local skill
  SKILLS=()
  shopt -s nullglob
  for skill in "$REPO"/skills/core/*/ "$REPO"/skills/draft/*/; do SKILLS+=("${skill%/}"); done
  shopt -u nullglob
  # 名稱表只放資料夾名，供 has_skill 比對
  SKILL_NAMES=" "
  for skill in ${SKILLS[@]+"${SKILLS[@]}"}; do SKILL_NAMES="$SKILL_NAMES${skill##*/} "; done
}

has_skill() { case "$SKILL_NAMES" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# 目標落在本 repo 的 core/ 或 draft/ 底下就算本 repo 管理，不要求目標仍存在：
# 技能畢業或封存後舊連結成了斷鏈，它仍是本 repo 建的，要能被替換或移除。
is_managed_skill_link() {
  [ -L "$1" ] || return 1
  local target parent
  target="$(readlink "$1")"
  case "$target" in /*) ;; *) target="$(dirname "$1")/$target" ;; esac
  parent="$(resolve_directory "$(dirname "$target")")" || return 1
  [ "$parent" = "$(resolve_directory "$REPO/skills/core")" ] ||
    [ "$parent" = "$(resolve_directory "$REPO/skills/draft")" ]
}

# 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡。
guard_dest() {
  local resolved
  if [ -L "$1" ]; then
    resolved="$(resolve_directory "$1")" || return 0
    case "$resolved" in
      "$REPO"*) die "$1 指向本 repo（$resolved）" "移除它再重跑" ;;
    esac
  fi
}

# 與 repo 技能同名、卻不由本 repo 管理的項目，一行一個。
list_conflicts() {
  local skill link
  for skill in ${SKILLS[@]+"${SKILLS[@]}"}; do
    link="$1/${skill##*/}"
    if { [ -e "$link" ] || [ -L "$link" ]; } && ! is_managed_skill_link "$link"; then
      printf '%s\n' "$link"
    fi
  done
}

# 本 repo 建立的連結（含斷鏈與已不在 core/、draft/ 的過期連結），一行一個。
list_owned_links() {
  local link
  [ -d "$1" ] || return 0
  while IFS= read -r -d '' link; do
    # 名稱含換行的連結不可能是技能資料夾名；下游逐行讀取會把它拆成兩個路徑去 rm，所以直接略過。
    case "$link" in *$'\n'*) continue ;; esac
    if is_managed_skill_link "$link"; then printf '%s\n' "$link"; fi
  done < <(find "$1" -mindepth 1 -maxdepth 1 -type l -print0)
}

# 技能封存或改名後的殘影：本 repo 建的、但名字已不在技能表裡。
list_stale_links() {
  local link
  while IFS= read -r link; do
    if ! has_skill "${link##*/}"; then printf '%s\n' "$link"; fi
  done < <(list_owned_links "$1")
}

# ---- 選代理 ----
# 逐一整串比對去重；不用空白拼接比對（見 ops-script 規則）。
add_agent() {
  local a
  for a in ${AGENTS[@]+"${AGENTS[@]}"}; do [[ "$a" == "$1" ]] && return 0; done
  AGENTS+=("$1")
}

join_agents() {
  local out
  out="$(printf '%s, ' "${AGENTS[@]}")"
  printf '%s' "${out%, }"
}

# 互動選代理：走 ops-lib 的多選器；選定後直接處理，不再確認。
# 沒選就確定或讀到 EOF 取消（結束碼 1）。
read_agents() {
  local verb=$1 picks idx
  picks=$(multiselect "要${verb}哪些代理？" "${AGENT_NAMES[@]}") || die "已取消" "沒有選任何代理，什麼都沒做"
  AGENTS=()
  for idx in $picks; do AGENTS+=("${AGENT_NAMES[idx - 1]}"); done
  printf '即將%s：%s\n' "$verb" "$(join_agents)" >&2
}

# 參數給了代理就沿用；沒給就詢問（需要終端機），不替操作者挑。
resolve_agents() {
  local name=$1 verb=$2
  if ((${#AGENTS[@]})); then return 0; fi
  _is_tty 0 || usage_error "沒有指定代理" "例：$SCRIPT_NAME $name claude；或在終端機中執行以互動選擇"
  read_agents "$verb"
  if ((FROM_MENU)); then printf '→ %s %s %s\n' "$SCRIPT_NAME" "$name" "${AGENTS[*]}"; fi
}

# parse_agent_args 子命令 允許的旗標(dry|yes ...) 參數...：填 AGENTS、DRY、YES。
parse_agent_args() {
  local name=$1 allowed=$2 arg
  shift 2
  AGENTS=(); DRY=0; YES=0
  for arg in "$@"; do
    case "$arg" in
      -h | --help) usage; exit 0 ;;
      claude | copilot | codex) add_agent "$arg" ;;
      --dry-run)
        case " $allowed " in *" dry "*) DRY=1 ;; *) usage_error "$name 不支援 --dry-run" "用 --help 查看用法" ;; esac ;;
      -y | --yes)
        case " $allowed " in *" yes "*) YES=1 ;; *) usage_error "$name 不支援 $arg" "用 --help 查看用法" ;; esac ;;
      *) usage_error "$name 未知的參數：$arg" "代理只能是 ${AGENT_NAMES[*]}；選項見 --help" ;;
    esac
  done
}

print_install_hint() {
  case " ${AGENTS[*]} " in *" claude "*) echo "Claude Code：重開後輸入 /ask-luca 確認。" ;; esac
  # $ask-luca 是要原樣印給使用者的技能呼叫語法，不是要展開的變數
  # shellcheck disable=SC2016
  case " ${AGENTS[*]} " in *" codex "*) echo 'Codex：重開後輸入 /skills 查看，並用 $ask-luca 明確呼叫技能。' ;; esac
  case " ${AGENTS[*]} " in
    *" copilot "*)
      echo "Copilot：重開後問「有哪些 skills 可以用？」確認。"
      echo "注意：Copilot 不支援 disable-model-invocation，編排型技能"
      echo "（implement、to-tickets…）在那邊會變成代理可自行呼叫。"
      ;;
  esac
}

# ---- install ----
prune_stale() {
  local link
  while IFS= read -r link; do
    if run "$DRY" rm -- "$link"; then pass "pruned stale ${link##*/}"; else fail "${link##*/}：移除失敗"; fi
  done < <(list_stale_links "$1")
}

install_agent() {
  local agent=$1 dest skill link conflicts
  dest="$(dest_for "$agent")"
  guard_dest "$dest"

  conflicts="$(list_conflicts "$dest")"
  if [ -n "$conflicts" ]; then
    fail "$agent 無法安裝：以下同名技能不由本 repo 管理，未做任何變更：$(printf '%s' "$conflicts" | tr '\n' ' ')"
    return 0
  fi

  step "$agent : $dest"
  if ! run "$DRY" mkdir -p -- "$dest"; then fail "$agent 無法建立目錄：$dest"; return 0; fi
  for skill in ${SKILLS[@]+"${SKILLS[@]}"}; do
    link="$dest/${skill##*/}"
    # -n：已存在的連結被當成檔案本身替換，而不是跟進去在目標資料夾裡再建一個。
    if run "$DRY" ln -sfn "$skill" "$link"; then
      pass "linked [$(basename "$(dirname "$skill")")] ${skill##*/}"
    else
      fail "${skill##*/}：連結失敗"
    fi
  done
  prune_stale "$dest"
}

cmd_install() {
  local agent
  parse_agent_args install dry "$@"
  refuse_msys install "${AGENTS[@]+"${AGENTS[@]}"}"
  load_skills
  resolve_agents install 安裝
  for agent in "${AGENTS[@]}"; do install_agent "$agent"; done
  if ((N_FAIL == 0)); then print_install_hint; fi
  finish
}

# ---- uninstall ----
# 刪東西前的最後一道門：互動時問一次（預設 No），沒有終端機就必須帶 -y；--dry-run 什麼都不刪，免問。
confirm_uninstall() {
  local agent total=0 n
  for agent in "${AGENTS[@]}"; do
    n="$(list_owned_links "$(dest_for "$agent")" | grep -c '' || true)"
    total=$((total + n))
  done
  if ((total == 0 || YES || DRY)); then return 0; fi
  _is_tty 0 || die_with 2 "移除需要確認" "沒有終端機時請加 -y（先用 --dry-run 看會移除什麼）"
  confirm "將移除 $(join_agents) 的 $total 個本 repo 連結。繼續？" || die "已取消" "沒有移除任何連結"
}

uninstall_agent() {
  local agent=$1 dest link links found=0
  dest="$(dest_for "$agent")"
  guard_dest "$dest"
  step "$agent : $dest"
  while IFS= read -r link; do
    [ -n "$link" ] && warn "略過（不由本 repo 管理）：$link"
  done < <(list_conflicts "$dest")
  links="$(list_owned_links "$dest")"
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    found=1
    if run "$DRY" rm -- "$link"; then pass "removed ${link##*/}"; else fail "${link##*/}：移除失敗"; fi
  done <<<"$links"
  if ((found == 0)); then skip "$agent 沒有本 repo 建立的連結"; fi
}

cmd_uninstall() {
  local agent
  parse_agent_args uninstall "dry yes" "$@"
  refuse_msys uninstall "${AGENTS[@]+"${AGENTS[@]}"}"
  load_skills
  resolve_agents uninstall 移除
  confirm_uninstall
  for agent in "${AGENTS[@]}"; do uninstall_agent "$agent"; done
  finish
}

# ---- status ----
# 唯讀：把一個代理的技能目錄分成 缺少／斷鏈／同名衝突／過期 四種異常，全無異常才算正常。
status_agent() {
  local agent=$1 dest skill name link clean=1
  local missing=() broken=() conflict=() stale=()
  dest="$(dest_for "$agent")"
  step "$agent : $dest"
  for skill in ${SKILLS[@]+"${SKILLS[@]}"}; do
    name=${skill##*/}
    link="$dest/$name"
    if [ ! -e "$link" ] && [ ! -L "$link" ]; then missing+=("$name")
    elif ! is_managed_skill_link "$link"; then conflict+=("$name")
    elif [ ! -f "$link/SKILL.md" ]; then broken+=("$name")
    fi
  done
  while IFS= read -r link; do
    [ -n "$link" ] && stale+=("${link##*/}")
  done < <(list_stale_links "$dest")
  report_problem "$agent" '缺少（跑 install 補上）' ${missing[@]+"${missing[@]}"} && clean=0
  report_problem "$agent" '斷鏈（跑 install 重連）' ${broken[@]+"${broken[@]}"} && clean=0
  report_problem "$agent" '同名但不由本 repo 管理（install 會拒絕，請自行處理）' ${conflict[@]+"${conflict[@]}"} && clean=0
  report_problem "$agent" '過期連結（技能已封存或改名，跑 install 或 uninstall 清掉）' ${stale[@]+"${stale[@]}"} && clean=0
  if ((clean)); then pass "$agent 的 ${#SKILLS[@]} 個技能都已連結"; fi
}

# report_problem 代理 標籤 名稱...：有名稱才記一筆 fail 並回傳 0（表示有異常），沒有就回傳 1。
report_problem() {
  local agent=$1 label=$2 names
  shift 2
  (($#)) || return 1
  names="$(printf '%s, ' "$@")"
  fail "$agent $label：${names%, }"
}

cmd_status() {
  local agent
  parse_agent_args status "" "$@"
  refuse_msys status "${AGENTS[@]+"${AGENTS[@]}"}"
  load_skills
  resolve_agents status 檢查
  for agent in "${AGENTS[@]}"; do status_agent "$agent"; done
  finish
}

main() {
  case "${1:-}" in
    -h | --help) usage ;;
    "")
      if _is_tty 0; then
        run_menu
      else
        usage_error "未指定子命令" "帶上子命令，或在終端機中執行以進入選單"
      fi
      ;;
    # 代理名稱單獨當子命令，等同 install 該代理（PR-INSTALL-05）。
    claude | copilot | codex) run_command install "$@" ;;
    -*) usage_error "未知選項：$1" "用 --help 查看用法" ;;
    *) run_command "$@" ;;
  esac
}

if [[ "${MANAGE_LIB:-}" != "1" ]]; then main "$@"; fi
