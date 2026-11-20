#!/usr/bin/env bash
#/ 用法：skeleton.sh [子命令] [選項]
#/ 不帶參數且有終端機時進入選單；帶子命令時直接執行（可供排程與其他腳本呼叫）。
#/
#/ 子命令：
#/   hello   示範：建立一個目錄（支援 --dry-run，只印將執行的指令）
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

# ---- BEGIN ops-lib v1 ----
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
  if [[ -z "$(table_rows | grep -Fx -- "$name")" ]]; then
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

cmd_hello() {
  local dry=0 dir
  while (($#)); do
    case "$1" in
      --dry-run) dry=1 ;;
      -h | --help) usage; return 0 ;;
      *) usage_error "hello 不認得的參數：$1" "可用的選項：--dry-run" ;;
    esac
    shift
  done
  dir="${HELLO_DIR:-./hello-out}"
  run "$dry" mkdir -p -- "$dir"
  if [[ "$dry" != 1 ]]; then printf '已建立 %s\n' "$dir"; fi
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
    -*) usage_error "未知選項：$1" "用 --help 查看用法" ;;
    *) run_command "$@" ;;
  esac
}

if [[ "${SKELETON_LIB:-}" != "1" ]]; then main "$@"; fi
