#!/usr/bin/env bash
#/ 用法：skeleton.sh [子命令] [選項]
#/ 不帶參數且有終端機時進入選單；帶子命令時直接執行（可供排程與其他腳本呼叫）。
#/
#/ 子命令：
#/   hello   示範：挑選並建立目錄
#/
#/ hello：沒有終端機時要 --pick。
#/   --pick 名稱[,名稱...]   依名稱挑選、免互動（例：--pick alpha,gamma）
#/   --dry-run               只印將執行的指令，什麼都不改
#/   --step                  逐步執行：每個步驟前停下，Enter 執行、a 之後不再停、q 離開（需要終端機）
#/
#/ 選項：
#/   -h, --help   顯示這份說明
#/
#/ 結束碼：0 完成、1 失敗或操作者取消、2 用法錯誤
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

# run_menu [轉交給子命令的參數...]：子命令選單就是一次 select_one；選了就先印等價指令再執行，取消 exit 1。
# 取消直接 exit、呼叫端不以 `||` 接它：函式在 `||` 左側時 errexit 失效，子命令失敗會被吞掉。
# shellcheck disable=SC2120 # 轉交參數是選配：主流程不帶，測試與擴充才帶
run_menu() {
  local idx name items=()
  mapfile -t items < <(menu_items)
  idx=$(select_one "要做什麼？" "${items[@]}") || exit 1
  name=$(table_rows | sed -n "${idx}p")
  printf '→ %s %s%s\n' "$SCRIPT_NAME" "$name" "${*:+ $*}"
  run_command "$name" "$@"
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

cmd_hello() {
  local dry=0 pick="" has_pick=0 stepping=0 dir picks idx name
  while (($#)); do
    case "$1" in
      --dry-run) dry=1 ;;
      --step) stepping=1 ;;
      --pick)
        shift
        [[ $# -gt 0 ]] || usage_error "--pick 缺少值" "例：--pick alpha,gamma"
        pick=$1; has_pick=1 ;;
      -h | --help) usage; return 0 ;;
      *) usage_error "hello 未知的參數：$1" "可用的選項：--pick、--dry-run、--step" ;;
    esac
    shift
  done
  # 逐步模式要在任何挑選與動作之前檢查終端機：沒有終端機就什麼都不做。
  if ((stepping)); then enable_step_mode; fi
  dir="${HELLO_DIR:-./hello-out}"
  if ((has_pick)); then
    picks=$(pick_by_name --pick "$pick" "${HELLO_ITEMS[@]}") || exit $?
  else
    require_tty "改用 --pick 指定名稱（例：--pick alpha,gamma），或在終端機中執行"
    picks=$(multiselect "要建立哪些目錄？" "${HELLO_ITEMS[@]}") || die "已取消" "沒有選任何項目，什麼都沒做"
  fi
  step "建立目錄" "對每個選中的名稱建立同名目錄；目錄已存在時不會報錯，可重跑" "停在這裡：尚未建立任何目錄"
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
    --step)
      # 唯一參數才進選單並轉交；其餘情況 --step 屬於子命令，不由這裡解析。
      (($# == 1)) || usage_error "--step 要放在子命令之後" "例：$SCRIPT_NAME hello --step"
      require_tty "拿掉 --step 並帶上子命令，或在終端機中執行"
      run_menu --step
      ;;
    -*) usage_error "未知選項：$1" "用 --help 查看用法" ;;
    *) run_command "$@" ;;
  esac
}

if [[ "${SKELETON_LIB:-}" != "1" ]]; then main "$@"; fi
