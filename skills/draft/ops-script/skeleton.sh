#!/usr/bin/env bash
#/ 用法：skeleton.sh [子命令] [選項]
#/ 不帶參數且有終端機時進入選單；帶子命令時直接執行（可供排程與其他腳本呼叫）。
#/
#/ 子命令：
#/   hello   示範：用多選器挑要建立的目錄（--pick 1,3 免互動；支援 --dry-run，只印將執行的指令）
#/
#/ 選項：
#/   -h, --help   顯示這份說明
#
# 運維腳本骨架。複製後改名，替換 hello 示範，其餘照結構擴充。
#   - 子命令表就是上方的 `#/` 行：--help 逐字印出它們，選單與分派解析同一批行。
#     子命令列固定「#/」加三個空格縮排；名稱 x-y 分派到函式 cmd_x_y。
#   - ops-lib 區段逐字複製、不准手改；要改就改本骨架並升版號，再同步回各腳本。
#   - 測試接縫：SKELETON_LIB=1。複製後把變數名改成 <腳本名>_LIB，三處一起改。

# 拒絕被 source：set -e 與 exit 會汙染操作者的 shell。要載入請用測試接縫。
# 守衛放在 set 之前，被擋時呼叫端的 shell 選項不會被動到。
if [[ "${BASH_SOURCE[0]}" != "$0" && "${SKELETON_LIB:-}" != "1" ]]; then
  printf '✗ 不可 source 這支腳本\n    請直接執行；要在測試中載入函式，設定 SKELETON_LIB=1\n' >&2
  return 1
fi

# 嚴格模式只是安全網：重要的失敗一律自己攔下、用 die 回報，不靠 set -e 報錯。
set -euo pipefail

# ---- BEGIN ops-lib v2 ----
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

# require_tty：只看 stdin。缺值要詢問的路徑先過這關，沒有終端機就 exit 2。
require_tty() {
  _is_tty 0 || die_with 2 "需要終端機" "改用旗標或參數傳入所需的值，或在終端機中執行"
}

# ---- 結果回報 ----
# 計數與訊息：每個行程從 0 開始。計數一律用 $((…))，不用 ((n++))（n 為 0 時回傳 1，set -e 會中止）。
N_PASS=0; N_FAIL=0; N_WARN=0; N_SKIP=0
ISSUES=()

# step 標題：步驟標題，走 stderr。
step() { printf '%s== %s%s\n' "$BOLD" "$*" "$RESET" >&2; }

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
  local title=$1 line="" i n picked=0
  shift
  local items=("$@")
  n=${#items[@]}
  MS_SEL=()
  for ((i = 0; i < n; i++)); do MS_SEL+=(0); done
  while true; do
    printf '%s\n' "$title" >&2
    for ((i = 0; i < n; i++)); do
      printf '  [%s] %d) %s\n' "$( ((MS_SEL[i])) && echo x || echo ' ')" "$((i + 1))" "${items[i]}" >&2
    done
    printf '輸入編號切換（例：1 3 5-7；a 全選、n 全不選、Enter 確定）：' >&2
    IFS= read -r line || return 1
    if [[ -z "${line//[[:space:]]/}" ]]; then break; fi
    _ms_apply "$line"
  done
  for ((i = 0; i < n; i++)); do
    if ((MS_SEL[i])); then printf '%d\n' "$((i + 1))"; picked=1; fi
  done
  ((picked)) || return 1
}
# ---- END ops-lib ----

# 絕對路徑：腳本中途 cd 之後，--help、選單與分派仍讀得到自己。
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}"
SCRIPT_NAME="${SELF##*/}"

# --help 的唯一來源：檔頭的 `#/` 行（去掉前綴）。
usage() { sed -n 's/^#\/ \{0,1\}//p' "$SELF"; }
usage_error() { usage >&2; die_with 2 "$@"; }

# 子命令表：只認「#/」加三個空格縮排、接小寫名稱的行。
table_rows() { sed -n 's/^#\/   \([a-z][a-z0-9-]*\)[[:space:]].*$/\1/p' "$SELF"; }
table_desc() { sed -n "s/^#\/   $1[[:space:]]\{1,\}//p" "$SELF"; }

print_menu() {
  local i=0 name
  while IFS= read -r name; do
    i=$((i + 1))
    printf '  %d) %-10s %s\n' "$i" "$name" "$(table_desc "$name")"
  done < <(table_rows)
}

# run_menu [轉交給子命令的參數...]：選了就先印等價指令再執行；取消 exit 1。
# 取消直接 exit、呼叫端不以 `||` 接它：函式在 `||` 左側時 errexit 失效，子命令失敗會被吞掉。
# shellcheck disable=SC2120 # 轉交參數是選配：主流程不帶，測試與擴充才帶
run_menu() {
  local choice name
  while true; do
    print_menu
    printf '選擇編號（q 取消）：' >&2
    read -r choice || exit 1
    case "$choice" in "" | q) exit 1 ;; esac
    name=""
    [[ "$choice" =~ ^[1-9][0-9]*$ ]] && name=$(table_rows | sed -n "${choice}p")
    if [[ -n "$name" ]]; then
      printf '→ %s %s%s\n' "$SCRIPT_NAME" "$name" "${*:+ $*}"
      run_command "$name" "$@"
      return
    fi
    printf '無效的選項：%s\n' "$choice" >&2
  done
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

# hello 的項目：示範多選器與結果總表，換成腳本真正的選項。
HELLO_ITEMS=(alpha beta gamma)

# _hello_pick_lines 1,3：把 --pick 的值轉成一行一個編號；任何一個無效就 exit 2。
_hello_pick_lines() {
  local v vals=() n=${#HELLO_ITEMS[@]}
  # 逗號切詞同樣不能讓 glob 展開；空值（含 `,`）一律當無效，不得靜默成功。
  IFS=, read -ra vals <<<"$1" || true
  ((${#vals[@]})) || usage_error "--pick 沒有值" "例：--pick 1,3"
  for v in "${vals[@]}"; do
    if [[ ! "$v" =~ ^[0-9]{1,6}$ ]] || ((10#$v < 1 || 10#$v > n)); then
      usage_error "--pick 的值無效：$v" "請給 1 到 $n 之間的編號，逗號分隔（例：--pick 1,3）"
    fi
    printf '%d\n' "$((10#$v))"
  done
}

cmd_hello() {
  local dry=0 pick="" has_pick=0 dir picks idx name
  while (($#)); do
    case "$1" in
      --dry-run) dry=1 ;;
      --pick)
        shift
        [[ $# -gt 0 ]] || usage_error "--pick 缺少值" "例：--pick 1,3"
        pick=$1; has_pick=1 ;;
      -h | --help) usage; return 0 ;;
      *) usage_error "hello 不認得的參數：$1" "可用的選項：--pick、--dry-run" ;;
    esac
    shift
  done
  dir="${HELLO_DIR:-./hello-out}"
  if ((has_pick)); then
    picks=$(_hello_pick_lines "$pick") || exit $?
  else
    require_tty
    picks=$(multiselect "要建立哪些目錄？" "${HELLO_ITEMS[@]}") || die "已取消" "沒有選任何項目，什麼都沒做"
  fi
  step "建立目錄"
  for idx in $picks; do
    name=${HELLO_ITEMS[idx - 1]}
    # 失敗要記帳而不是中止：if 條件裡 set -e 不生效，結果交給 finish 決定結束碼。
    if run "$dry" mkdir -p -- "$dir/$name"; then pass "建立 $name"; else fail "建立 $name"; fi
  done
  finish
}

main() {
  case "${1:-}" in
    -h | --help) usage ;;
    "")
      if _is_tty 0; then
        # shellcheck disable=SC2119 # 主流程沒有要轉交的參數；參數只給測試與擴充用
        run_menu
      else
        usage_error "未指定子命令" "帶上子命令，或在終端機中執行以進入選單"
      fi
      ;;
    -*) usage_error "未知選項：$1" "用 --help 查看用法" ;;
    *) run_command "$@" ;;
  esac
}

if [[ "${SKELETON_LIB:-}" != "1" ]]; then main "$@"; fi
