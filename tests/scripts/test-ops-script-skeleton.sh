#!/usr/bin/env bash
# ops-script 骨架的回歸規格。兩個接縫：CLI（bash skeleton.sh <args> 的結束碼／輸出／副作用）
# 與 LIB（SKELETON_LIB=1 source 之後呼叫共用段）。不碰內部變數，不測真終端機分支（沒有 pty）。
# 執行：bash tests/scripts/test-ops-script-skeleton.sh（tests/test-tooling.sh 會跑）
set -u
cd "$(dirname "$0")/../.."
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
# 片段之後的參數原樣成為片段裡的 $1、$2…，值不必拼進程式碼字串。
lib() {
  local code=$1
  shift
  SKELETON_LIB=1 bash -c 'source "$1"; code=$2; shift 2; eval "$code"' _ "$SK" "$code" "$@"
}

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
out=$(HELLO_DIR="$d" bash "$SK" hello --pick alpha --dry-run </dev/null 2>&1); rc=$?
expect "hello --dry-run 回 0" 0 "$rc"
contains "--dry-run 印出將執行的指令" "$out" "mkdir -p"
[ ! -e "$d" ] && verdict ok "--dry-run 不做事" || verdict ng "--dry-run 不該建立目錄"
HELLO_DIR="$d" bash "$SK" hello --pick alpha >/dev/null 2>&1 </dev/null; expect "hello 回 0" 0 $?
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
b=$(grep -n '^# ---- BEGIN ops-lib v4 ----$' "$SK" | cut -d: -f1)
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
out=$(printf '1\n1\n\n' | HELLO_DIR="$tmp/menu-out" lib '_is_tty() { return 0; }; run_menu --dry-run' 2>&1); rc=$?
expect "選單選 1 回 0" 0 "$rc"
contains "執行前印出等價指令" "$out" "skeleton.sh hello"
for a in q ""; do
  printf '%s\n' "$a" | lib 'run_menu' >/dev/null 2>&1; expect "選單輸入「$a」取消回 1" 1 $?
done
lib 'run_menu' </dev/null >/dev/null 2>&1; expect "選單 EOF 取消回 1" 1 $?

echo "[回歸] 審查發現的缺陷"
# 選單路徑不得吞掉子命令的失敗（函式在 || 左側時 errexit 失效）
printf '1\n1\n\n' | HELLO_DIR=/dev/null/x bash -c 'SKELETON_LIB=1; source "$1"; _is_tty() { return 0; }; run_menu' _ "$SK" >/dev/null 2>&1
[ $? -ne 0 ] && verdict ok "選單中子命令失敗會中止並回非 0" || verdict ng "選單吞掉了子命令的失敗"
# 腳本中途 cd 之後仍讀得到自己
out=$(cd "$(dirname "$SK")/.." && SKELETON_LIB=1 bash -c 'source ops-script/skeleton.sh; cd /; usage' 2>&1 | head -1)
contains "cd 之後 usage 仍可用" "$out" "用法"
# 含空白的名稱不得蒙混過子命令表
bash "$SK" "hello world" >/dev/null 2>&1 </dev/null; expect "含空白的子命令名回 2" 2 $?
printf 'yes\n' | lib 'confirm "繼續？"' >/dev/null 2>&1; expect "輸入 yes 回 0" 0 $?
lib 'die' >/dev/null 2>&1; expect "die 不帶參數仍回 1" 1 $?

echo "[LIB v2] multiselect（here-string 餵輸入；結果走 stdout、畫面走 stderr）"
# ms <輸入> [項目數]：設定 MS_OUT（stdout 的選取結果，逗號串接）與 MS_RC（multiselect 的結束碼）
ms() {
  local n=${2:-7} items=() i
  for ((i = 1; i <= n; i++)); do items+=("項目$i"); done
  lib "multiselect 標題 ${items[*]}" <<<"$1" >"$tmp/ms.out" 2>/dev/null; MS_RC=$?
  MS_OUT=$(paste -sd, "$tmp/ms.out")
}
ms $'1 3 5-7\n'; expect "「1 3 5-7」選中 1,3,5,6,7" "1,3,5,6,7" "$MS_OUT"
ms $'1 3 5-7\n'; expect "「1 3 5-7」確定回 0" 0 "$MS_RC"
ms $'A\n'; expect "「A」全選" "1,2,3,4,5,6,7" "$MS_OUT"
ms $'a\n'; expect "「a」全選" "1,2,3,4,5,6,7" "$MS_OUT"
ms $'a\nn\n2\n\n'; expect "a 之後 n 全不選、再選 2" "2" "$MS_OUT"
ms $'N\n3\n\n'; expect "大寫 N 全不選、再選 3" "3" "$MS_OUT"
ms $'a\n2 4\n\n'; expect "a 之後再輸入編號是切換（取消勾選）" "1,3,5,6,7" "$MS_OUT"
ms $'1\n1\n2\n\n'; expect "同一編號切換兩次回到未選" "2" "$MS_OUT"
ms $'0 8 99 2\n\n'; expect "越界編號忽略、其餘照算" "2" "$MS_OUT"
ms $'5-9\n\n'; expect "範圍中越界的部分忽略" "5,6,7" "$MS_OUT"
ms $'\n'; expect "空輸入取消：stdout 為空" "" "$MS_OUT"
ms $'\n'; expect "空輸入取消回 1" 1 "$MS_RC"
ms $'1\nn\n\n'; expect "全部取消勾選後 Enter 等於取消（stdout）" "" "$MS_OUT"
ms $'1\nn\n\n'; expect "全部取消勾選後 Enter 回 1" 1 "$MS_RC"
lib 'multiselect 標題 a b' </dev/null >/dev/null 2>&1; expect "EOF 取消回 1" 1 $?
out=$(lib 'multiselect 標題 a b' <<<$'1\n' 2>&1 >/dev/null); contains "畫面走 stderr" "$out" "標題"

echo "[LIB v4] 清單格式：編號在前、標記在後、編號依項目數補齊寬度"
out=$(lib 'multiselect 標題 a b' <<<$'1\n\n' 2>&1 >/dev/null)
contains "未選的列是「  1) [ ] a」" "$out" "  1) [ ] a"
contains "選中的列是「  1) [x] a」" "$out" "  1) [x] a"
items10=(); for ((i = 1; i <= 10; i++)); do items10+=("項目$i"); done
out=$(lib "multiselect 標題 ${items10[*]}" <<<$'\n' 2>&1 >/dev/null)
contains "10 項時 9 號補一格空白" "$out" "   9) [ ] 項目9"
contains "10 項時 10 號不補" "$out" "  10) [ ] 項目10"
out=$(lib "multiselect 標題 a b c" <<<$'\n' 2>&1 >/dev/null)
contains "少於 10 項時編號不補空白" "$out" "  1) [ ] a"
out=$(lib 'table_rows() { printf "n%s\n" 1 2 3 4 5 6 7 8 9 10; }; print_menu')
contains "選單 10 列時 9 號補一格空白" "$out" "   9) n9"
contains "選單 10 列時 10 號不補" "$out" "  10) n10"
out=$(lib 'print_menu')
contains "選單 1 列時編號不補空白" "$out" "  1) hello"

echo "[LIB] 選單行只答「做什麼、要不要確認」：無旗標、80 欄內；旗標細節留在 --help"
# disp_width <字串>：顯示寬度近似值 — 多位元組字元算 2 欄（CJK 與全形標點皆為 3 位元組）
disp_width() {
  local c b
  c=$(LC_ALL=C.UTF-8 bash -c 'printf %s "${#1}"' _ "$1")
  b=$(LC_ALL=C bash -c 'printf %s "${#1}"' _ "$1")
  echo $((c + (b - c) / 2))
}
# check_menu_lines <選單輸出>：每行不含旗標、不超過 80 欄；空輸出算失敗
check_menu_lines() {
  local line flagged="" wide="" bracket="" starts="" prefix desc re='(^|[[:space:]（(、，；：「/])--?[A-Za-z]'
  # 選單行＝「  N) 名稱<空白>」＋需確認欄（[需確認] 或同寬空白）＋描述
  local row='^( *[0-9]+\) [a-z0-9-]+ +)(\[需確認\] )?(.*)$' br='[（(\[]'
  [ -n "$1" ] || { verdict ng "抓不到選單輸出"; return; }
  while IFS= read -r line; do
    [[ "$line" =~ $re ]] && flagged+="[$line]"
    (($(disp_width "$line") > 80)) && wide+="[$line]"
    [[ "$line" =~ $row ]] || { bracket+="[無法解析：$line]"; continue; }
    prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}" desc="${BASH_REMATCH[3]}"
    [[ "$desc" =~ $br ]] && bracket+="[$line]"
    starts+="$(disp_width "$prefix")"$'\n'
  done <<<"$1"
  expect "選單行不含旗標" "" "$flagged"
  expect "選單行不超過 80 欄" "" "$wide"
  expect "描述欄不含括號" "" "$bracket"
  expect "各列描述起始欄位相同" 1 "$(printf '%s' "$starts" | sort -u | awk 'END { print NR }')"
}
check_menu_lines "$(lib 'print_menu')"
# 需確認欄：有任一列需確認時，其餘列補同寬空白；全表都沒有就不留欄（SELF 指向測試用的表）
printf '#/   alpha   甲\n#/   beta    [需確認] 乙\n' >"$tmp/table-mark"
printf '#/   alpha   甲\n' >"$tmp/table-plain"
out=$(lib 'SELF=$1; print_menu' "$tmp/table-mark")
contains "需確認列印出 [需確認]" "$out" "  2) beta       [需確認] 乙"
contains "其餘列補同寬空白" "$out" "  1) alpha               甲"
expect "全表沒有需確認時不留欄" "  1) alpha      甲" "$(lib 'SELF=$1; print_menu' "$tmp/table-plain")"
case "$(lib 'print_menu')" in *"[需確認]"*) verdict ng "hello 不需確認，不該標 [需確認]" ;; *) verdict ok "hello 沒有標 [需確認]" ;; esac
out=$(bash "$SK" --help </dev/null 2>/dev/null)
contains "--help 仍說明 --pick" "$out" "--pick"
contains "--help 仍說明 --dry-run" "$out" "--dry-run"

echo "[LIB v2] step 與結果計數"
out=$(lib 'step 準備' 2>&1 >/dev/null); expect "step 在 stderr 印 == 標題" "== 準備" "$out"
out=$(lib 'step 準備' 2>/dev/null); expect "step 不碰 stdout" "" "$out"
out=$(lib 'pass 甲; fail 乙; warn 丙; skip 丁; print_summary' 2>&1 >/dev/null)
contains "pass 行" "$out" "[PASS] 甲"
contains "fail 行" "$out" "[FAIL] 乙"
contains "warn 行" "$out" "[WARN] 丙"
contains "skip 行" "$out" "[SKIP] 丁"
contains "總表計數" "$out" "總計：pass 1  fail 1  warn 1  skip 1"
out=$(lib 'print_summary' 2>&1 >/dev/null); contains "起始計數皆為 0" "$out" "總計：pass 0  fail 0  warn 0  skip 0"
out=$(lib 'pass a; pass b; fail 壞掉; warn 注意; print_summary' 2>&1 >/dev/null)
expect "總表重列 fail（原行加重列共兩次）" 2 "$(grep -c '壞掉' <<<"$out" | tr -d ' ')"
lib 'pass a; pass b; finish' >/dev/null 2>&1; expect "無 fail 時 finish 回 0" 0 $?
lib 'pass a; warn b; skip c; finish' >/dev/null 2>&1; expect "warn／skip 不影響 finish 回 0" 0 $?
lib 'pass a; fail b; finish' >/dev/null 2>&1; expect "有 fail 時 finish 回 1" 1 $?
lib 'finish' >/dev/null 2>&1; expect "零筆結果 finish 回 0" 0 $?

echo "[CLI v2] hello 用多選器與結果總表"
d2="$tmp/pick"
out=$(HELLO_DIR="$d2" bash "$SK" hello --pick alpha,gamma 2>&1 >/dev/null </dev/null); rc=$?
expect "--pick alpha,gamma 回 0" 0 "$rc"
[ -d "$d2/alpha" ] && [ -d "$d2/gamma" ] && [ ! -e "$d2/beta" ] && verdict ok "恰建立 alpha、gamma" || verdict ng "建立的目錄不符"
contains "總表 pass 2" "$out" "pass 2"
HELLO_DIR=/dev/null/x bash "$SK" hello --pick alpha >/dev/null 2>"$tmp/err" </dev/null; expect "建立失敗回 1" 1 $?
contains "失敗行出現在 stderr" "$(cat "$tmp/err")" "fail"
d3="$tmp/pick-dry"
out=$(HELLO_DIR="$d3" bash "$SK" hello --pick beta --dry-run 2>&1 </dev/null)
[ ! -e "$d3" ] && verdict ok "--pick 搭配 --dry-run 不建立" || verdict ng "--dry-run 不該建立目錄"
bash "$SK" hello </dev/null >/dev/null 2>&1; expect "hello 無 --pick 且無終端機回 2" 2 $?
bash "$SK" hello --pick delta </dev/null >/dev/null 2>&1; expect "--pick 不認得的名稱回 2" 2 $?
echo "[LIB v2] hello 的選單路徑（覆寫 _is_tty 模擬終端機）"
d4="$tmp/menu-pick"
out=$(HELLO_DIR="$d4" SKELETON_LIB=1 bash -c 'source "$1"; _is_tty() { return 0; }; cmd_hello' _ "$SK" 2>&1 >/dev/null <<<$'2\n\n'); rc=$?
expect "選單路徑回 0" 0 "$rc"
[ -d "$d4/beta" ] && [ ! -e "$d4/alpha" ] && [ ! -e "$d4/gamma" ] && verdict ok "只建立被選的 beta" || verdict ng "選單路徑建立的目錄不符"
contains "選單路徑出現總表" "$out" "總計：pass 1"
HELLO_DIR="$tmp/menu-cancel" SKELETON_LIB=1 bash -c 'source "$1"; _is_tty() { return 0; }; cmd_hello' _ "$SK" >/dev/null 2>&1 <<<$'\n'
expect "選單取消回 1" 1 $?
[ ! -e "$tmp/menu-cancel" ] && verdict ok "選單取消不建立" || verdict ng "選單取消卻建立了目錄"

echo "[回歸 v2] 審查發現的缺陷"
# 輸入行不得依目前目錄的檔名做 glob 展開
mkdir -p "$tmp/globdir" && : >"$tmp/globdir/2" && : >"$tmp/globdir/a"
out=$(cd "$tmp/globdir" && SKELETON_LIB=1 bash -c 'source "$1"; multiselect T a b c' _ "$SK" 2>/dev/null <<<$'*\n\n' | paste -sd, -)
expect "輸入 * 不會被展開成檔名" "" "$out"
# 巨大範圍夾進 1..n，結果正確（不靠跑完迴圈）
ms $'1-999999\n\n' 3; expect "範圍 1-999999 只切換 1..3" "1,2,3" "$MS_OUT"
# --pick 的空值不得靜默成功
bash "$SK" hello --pick , >/dev/null 2>&1 </dev/null; expect "--pick , 回 2" 2 $?
bash "$SK" hello --pick "" >/dev/null 2>&1 </dev/null; expect "--pick 空字串回 2" 2 $?
out=$(bash "$SK" hello --pick "" 2>&1 </dev/null); contains "--pick 空字串訊息指向 --pick" "$out" "--pick"
out=$(cd "$tmp/globdir" && HELLO_DIR="$tmp/globdir/out" bash "$SK" hello --pick '*' 2>&1 </dev/null); rc=$?
expect "--pick * 不被展開、回 2" 2 "$rc"

echo "[LIB v3] pick_by_name：名稱整串精確比對，輸出與 multiselect 同形"
# pn <值>：設定 PN_OUT（stdout 的編號，逗號串接）與 PN_RC
pn() {
  lib 'pick_by_name --pick "$1" alpha beta gamma' "$1" >"$tmp/pn.out" 2>"$tmp/pn.err"; PN_RC=$?
  PN_OUT=$(paste -sd, "$tmp/pn.out")
}
pn 'gamma,alpha'; expect "輸出遞增，不照輸入順序" "1,3" "$PN_OUT"
pn 'beta,beta'; expect "重複的名稱只出現一次" "2" "$PN_OUT"
pn 'alpha beta'; expect "含空白的整串不得對上兩個項目（回 2）" 2 "$PN_RC"
pn 'alpha beta'; expect "含空白的整串 stdout 為空" "" "$PN_OUT"
pn 'Alpha'; expect "大小寫不同回 2" 2 "$PN_RC"
pn '1'; expect "編號不再被接受（回 2）" 2 "$PN_RC"
pn 'alph'; expect "前綴不算對上（回 2）" 2 "$PN_RC"
pn $'alpha\nbeta gamma'; expect "值含換行不得只看第一行（回 2）" 2 "$PN_RC"
pn 'alpha,,beta'; expect "中間的空名稱回 2" 2 "$PN_RC"
pn 'alpha,'; expect "結尾的空名稱回 2（與 PowerShell 一致）" 2 "$PN_RC"
pn 'alpha,,'; expect "結尾連續空名稱回 2" 2 "$PN_RC"
pn 'delta'; contains "可用的名稱以逗號串接，和輸入格式一致" "$(cat "$tmp/pn.err")" "alpha,beta,gamma"
for v in "alpha beta" "Alpha" "1" "alph" "alpha," $'alpha\nbeta'; do
  bash "$SK" hello --pick "$v" >/dev/null 2>&1 </dev/null; expect "CLI --pick「${v//$'\n'/\\n}」回 2" 2 $?
done
pn 'delta'; contains "錯誤訊息列出可用的名稱" "$(cat "$tmp/pn.err")" "alpha"

echo "[文件] 版號與維運說明"
! grep -q 'nameref\|local -n\|declare -n' "$SK" && verdict ok "骨架未用 nameref（bash 4.3 說明為條件式）" || verdict ng "骨架用了 nameref，需確認 bash 4.3 說明"
SM="$(dirname "$SK")/SKILL.md"
contains "SKILL.md 標明 v4" "$(cat "$SM")" "ops-lib v4"
doc=$(cat "$SM" "$(dirname "$SK")"/*.md 2>/dev/null)
contains "維護規則：兩個版號即有一支沒同步" "$doc" "two different version numbers"
contains "陷阱：read 讀到輸入結尾" "$doc" "read -r x ||"
contains "陷阱：grep -q 與 pipefail" "$doc" "SIGPIPE"
contains "陷阱：-u 下的空陣列" "$doc" '${arr[@]}'
contains "陷阱：local x=\$(cmd)" "$doc" 'local x=$(cmd)'
contains "bash 4.3 條目" "$doc" "bash 4.3"
contains "陷阱：空白拼接的成員檢查" "$doc" 'case " $list " in *" $x "*'
contains "挑選旗標收名稱、走 pick_by_name" "$doc" "pick_by_name"
contains "ops-lib 放法：離不開 repo 才可 source 共用檔" "$doc" "scripts/lib/ops-lib.sh"
contains "驗證：shellcheck 未安裝時的 uvx 備援" "$doc" "uvx --from shellcheck-py shellcheck"

echo
if [ $fail -eq 0 ]; then echo "ops-script 骨架測試全部通過。"; else echo "ops-script 骨架測試未通過。"; fi
exit $fail
