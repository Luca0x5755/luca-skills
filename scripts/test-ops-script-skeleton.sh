#!/usr/bin/env bash
# ops-script 骨架的回歸規格。兩個接縫：CLI（bash skeleton.sh <args> 的結束碼／輸出／副作用）
# 與 LIB（SKELETON_LIB=1 source 之後呼叫共用段）。不碰內部變數，不測真終端機分支（沒有 pty）。
# 執行：bash scripts/test-ops-script-skeleton.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")/.."
SK="$PWD/skills/draft/ops-script/skeleton.sh"

fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

verdict() {  # verdict <ok|ng> <name>
  if [ "$1" = ok ]; then printf '  ✓ %s\n' "$2"; else printf '  ✗ %s\n' "$2"; fail=1; fi
}
expect() {  # expect <name> <want> <got>
  if [ "$2" = "$3" ]; then verdict ok "$1"; else verdict ng "$1（想要「$2」，實得「$3」）"; fi
}
contains() {  # contains <name> <haystack> <needle>
  case "$2" in *"$3"*) verdict ok "$1" ;; *) verdict ng "$1（找不到「$3」）" ;; esac
}
# lib <script>：以 LIB 模式 source 骨架後執行一段 shell；回傳其結束碼
lib() { SKELETON_LIB=1 bash -c 'source "$1"; shift; eval "$1"' _ "$SK" "$1"; }

echo "[CLI] --help 與用法"
out=$(bash "$SK" --help </dev/null 2>"$tmp/err"); rc=$?
expect "--help 回 0" 0 "$rc"
expect "--help 的 stderr 為空" "" "$(cat "$tmp/err")"
want=$(sed -n 's/^#\/ \{0,1\}//p' "$SK")
expect "--help 逐字等於檔頭 #/ 行" "$want" "$out"

echo "[CLI] 用法錯誤一律 2"
out=$(bash "$SK" </dev/null 2>"$tmp/err"); rc=$?
expect "無參數且無終端機回 2" 2 "$rc"
expect "無參數時 stdout 為空" "" "$out"
contains "無參數時 stderr 印用法" "$(cat "$tmp/err")" "用法"
bash "$SK" --bogus >/dev/null 2>&1 </dev/null; expect "--bogus 回 2" 2 $?
bash "$SK" nosuchcmd >/dev/null 2>&1 </dev/null; expect "未知子命令回 2" 2 $?
bash "$SK" hello --bogus >/dev/null 2>&1 </dev/null; expect "hello --bogus 回 2" 2 $?

echo "[CLI] hello 與 --dry-run"
d="$tmp/hello-out"
out=$(HELLO_DIR="$d" bash "$SK" hello --dry-run </dev/null 2>&1); rc=$?
expect "hello --dry-run 回 0" 0 "$rc"
contains "--dry-run 印出將執行的指令" "$out" "mkdir -p"
[ ! -e "$d" ] && verdict ok "--dry-run 不做事" || verdict ng "--dry-run 不該建立目錄"
HELLO_DIR="$d" bash "$SK" hello >/dev/null 2>&1 </dev/null; expect "hello 回 0" 0 $?
[ -d "$d" ] && verdict ok "hello 真的建立目錄" || verdict ng "hello 沒建立目錄"

echo "[CLI] 測試接縫 SKELETON_LIB 嚴格比對 \"1\""
out=$(SKELETON_LIB=1 bash "$SK" 2>&1 </dev/null); rc=$?
expect "LIB=1 直接執行回 0" 0 "$rc"
expect "LIB=1 直接執行不跑 main" "" "$out"
for v in "" 0 true 1x; do
  out=$(SKELETON_LIB="$v" bash "$SK" --help 2>&1 </dev/null)
  contains "LIB=「$v」照常跑 main" "$out" "用法"
done

echo "[CLI] 拒絕 source"
out=$(bash -c 'source "$1"; echo "rc=$?"; shopt -qo errexit && echo errexit-on || echo errexit-off' _ "$SK" 2>&1 </dev/null)
contains "source 被擋、回傳非 0" "$out" "rc=1"
contains "source 被擋時有訊息" "$out" "✗"
contains "呼叫端 shell 沒被設 errexit" "$out" "errexit-off"
out=$(SKELETON_LIB=true bash -c 'source "$1"; echo "rc=$?"' _ "$SK" 2>&1 </dev/null)
contains "LIB=true 的 source 仍被擋" "$out" "rc=1"

echo "[CLI] 檔案結構與語法"
b=$(grep -n '^# ---- BEGIN ops-lib v1 ----$' "$SK" | cut -d: -f1)
e=$(grep -n '^# ---- END ops-lib ----$' "$SK" | cut -d: -f1)
[ -n "$b" ] && [ -n "$e" ] && [ "$b" -lt "$e" ] && verdict ok "BEGIN 標記在 END 標記之前" || verdict ng "ops-lib 標記缺漏或順序錯"
for fn in die confirm require_tty; do
  l=$(grep -n "^$fn()" "$SK" | cut -d: -f1)
  [ -n "$l" ] && [ -n "$b" ] && [ -n "$e" ] && [ "$l" -gt "$b" ] && [ "$l" -lt "$e" ] \
    && verdict ok "$fn 定義在標記之間" || verdict ng "$fn 沒定義在 ops-lib 標記之間"
done
bash -n "$SK" && verdict ok "bash -n 通過" || verdict ng "bash -n 失敗"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$SK" >/dev/null 2>&1 && verdict ok "shellcheck 零警告" || verdict ng "shellcheck 有警告"
else
  echo "  - shellcheck 未安裝，略過"
fi

echo "[LIB] die"
out=$(lib 'die "標題" "修法一行"' 2>"$tmp/err"); rc=$?
expect "die 結束碼 1" 1 "$rc"
expect "die 的 stdout 為空" "" "$out"
expect "die 兩行格式" "$(printf '✗ 標題\n    修法一行')" "$(cat "$tmp/err")"
lib 'die_with 2 "x" "y"' >/dev/null 2>&1; expect "die_with 2 結束碼 2" 2 $?

echo "[LIB] confirm"
for a in y Y; do
  printf '%s\n' "$a" | lib 'confirm "繼續？"' >/dev/null 2>&1; expect "輸入 $a 回 0" 0 $?
done
for a in n "" maybe; do
  printf '%s\n' "$a" | lib 'confirm "繼續？"' >/dev/null 2>&1; expect "輸入「$a」回 1（預設 No）" 1 $?
done
lib 'confirm "繼續？"' </dev/null >/dev/null 2>&1; expect "EOF 回 1" 1 $?
out=$(echo n | lib 'confirm "繼續？"' 2>&1); contains "提示含 [y/N]" "$out" "[y/N]"

echo "[LIB] require_tty 只看 stdin"
lib 'require_tty' </dev/null >/dev/null 2>&1; expect "stdin 非終端機回 2" 2 $?

echo "[LIB] 顏色開關（覆寫 _is_tty 模擬終端機）"
esc=$(printf '\033')
colored() {  # colored <env 前綴...>：模擬終端機，色碼是否出現在 die 的 stderr
  env "$@" bash -c 'SKELETON_LIB=1; source "$1"; _is_tty() { return 0; }; color_init; die x y' _ "$SK" 2>&1 >/dev/null </dev/null
}
contains "條件全成立時有色碼" "$(colored NO_COLOR= TERM=xterm)" "$esc["
case "$(colored NO_COLOR=1 TERM=xterm)" in *"$esc["*) verdict ng "NO_COLOR 非空應關閉色碼" ;; *) verdict ok "NO_COLOR 非空關閉色碼" ;; esac
case "$(colored NO_COLOR= TERM=dumb)" in *"$esc["*) verdict ng "TERM=dumb 應關閉色碼" ;; *) verdict ok "TERM=dumb 關閉色碼" ;; esac
out=$(bash -c 'SKELETON_LIB=1; source "$1"; _is_tty() { return 1; }; color_init; die x y' _ "$SK" 2>&1 >/dev/null </dev/null)
case "$out" in *"$esc["*) verdict ng "stdout 非終端機應關閉色碼" ;; *) verdict ok "stdout 非終端機關閉色碼" ;; esac

echo "[LIB] 一表三用：table_rows、print_menu、run_menu"
expect "table_rows 恰為 hello（說明行不算列）" hello "$(lib 'table_rows')"
miss=0
for n in $(lib 'table_rows'); do
  lib "declare -F cmd_${n//-/_} >/dev/null" || miss=1
done
expect "每個列都有對應的 cmd_ 函式" 0 "$miss"
expect "print_menu 行數等於 table_rows" "$(lib 'table_rows' | wc -l | tr -d ' ')" "$(lib 'print_menu' | wc -l | tr -d ' ')"
out=$(echo 1 | HELLO_DIR="$tmp/menu-out" lib 'run_menu --dry-run' 2>&1); rc=$?
expect "選單選 1 回 0" 0 "$rc"
contains "執行前印出等價指令" "$out" "skeleton.sh hello"
for a in q ""; do
  printf '%s\n' "$a" | lib 'run_menu' >/dev/null 2>&1; expect "選單輸入「$a」取消回 1" 1 $?
done
lib 'run_menu' </dev/null >/dev/null 2>&1; expect "選單 EOF 取消回 1" 1 $?

echo "[回歸] 審查發現的缺陷"
# 選單路徑不得吞掉子命令的失敗（函式在 || 左側時 errexit 失效）
echo 1 | HELLO_DIR=/dev/null/x bash -c 'SKELETON_LIB=1; source "$1"; run_menu' _ "$SK" >/dev/null 2>&1
[ $? -ne 0 ] && verdict ok "選單中子命令失敗會中止並回非 0" || verdict ng "選單吞掉了子命令的失敗"
# 腳本中途 cd 之後仍讀得到自己
out=$(cd "$(dirname "$SK")/.." && SKELETON_LIB=1 bash -c 'source ops-script/skeleton.sh; cd /; usage' 2>&1 | head -1)
contains "cd 之後 usage 仍可用" "$out" "用法"
# 含空白的名稱不得蒙混過子命令表
bash "$SK" "hello world" >/dev/null 2>&1 </dev/null; expect "含空白的子命令名回 2" 2 $?
printf 'yes\n' | lib 'confirm "繼續？"' >/dev/null 2>&1; expect "輸入 yes 回 0" 0 $?
lib 'die' >/dev/null 2>&1; expect "die 不帶參數仍回 1" 1 $?

echo
if [ $fail -eq 0 ]; then echo "ops-script 骨架測試全部通過。"; else echo "ops-script 骨架測試未通過。"; fi
exit $fail
