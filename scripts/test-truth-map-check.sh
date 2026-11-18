#!/usr/bin/env bash
# check-truth-map.sh 的回歸規格。每個案例在暫存目錄裡搭一個假專案（docs/ 與 capabilities），
# 在其根目錄跑檢查，看 exit code，紅燈時再看輸出是否點名檔案、標題與原因。
# 行為變更必須先改這份規格 — 沒有檢查的規則不是規則，是願望。
# 執行：bash scripts/test-truth-map-check.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")/.."
CHECK="$PWD/skills/core/setup-skills/check-truth-map.sh"
A=docs/03_architecture_design.md
F=docs/05_frontend_spec.md

fail=0
tmp=$(mktemp -d)
trap 'cd / && rm -rf "$tmp"' EXIT

verdict() {  # verdict <want-exit> <name> <got-exit> [output]
  if [ "$3" = "$1" ]; then
    printf '  ✓ exit %s  %s\n' "$1" "$2"
  else
    printf '  ✗ want exit %s, got %s  %s\n%s\n' "$1" "$3" "$2" "${4:-}" | sed '2,$s/^/      /'
    fail=1
  fi
}

n=0
# fixture <shell body>：搭一個新的假專案根目錄（已有 docs/capabilities/排場.md 與 訂單.md），路徑放進 $root。
# 不能用 $(fixture …) 取值：子殼裡的 n 遞增會遺失，案例就共用同一個目錄。
fixture() {
  n=$((n + 1))
  root="$tmp/c$n"
  mkdir -p "$root/docs/capabilities" && : > "$root/docs/capabilities/排場.md" && : > "$root/docs/capabilities/訂單.md"
  (cd "$root" && eval "$1")
}

# case_ <locale> <want-exit> <name> <shell body> [must-mention...]
case_() {
  local loc="$1" want="$2" name="$3" root out code m; shift 3
  fixture "$1"; shift
  out=$(cd "$root" && LC_ALL="$loc" bash "$CHECK" 2>&1)
  code=$?
  last_out=$out
  verdict "$want" "$name" "$code" "$out"
  for m in "$@"; do
    printf '%s' "$out" | grep -qF -- "$m" || { printf '  ✗ 輸出沒有點名「%s」\n' "$m"; fail=1; }
  done
}

# ends_with <name> <期望的最後幾行>：上一個 case_ 的輸出必須以這幾行逐字收尾。
ends_with() {
  local want_n got
  want_n=$(printf '%s\n' "$2" | wc -l)
  got=$(printf '%s\n' "$last_out" | tail -n "$want_n")
  if [ "$got" = "$2" ]; then
    printf '  ✓ 收尾  %s\n' "$1"
  else
    printf '  ✗ 輸出收尾不符  %s\n      want:\n%s\n      got:\n%s\n' "$1" "$2" "$got"
    fail=1
  fi
}

# sec <能力> [<卷> <標題文字>]…：寫 docs/capabilities/<能力>.md，內含 ## 規格章節 與這些條目。
# 在 fixture 的 shell body 裡呼叫（工作目錄是假專案根目錄）。
sec() {
  local c="$1"; shift
  { printf '# %s\n\n## 規格章節\n\n' "$c"
    while [ $# -ge 2 ]; do printf -- '- `%s` %s\n' "$1" "$2"; shift 2; done
  } > "docs/capabilities/$c.md"
}

suite() {  # suite <locale>
  local L="$1"
  case_ "$L" 0 "## 帶單一能力標記，capability 檔存在 → 過" \
    "printf '# 架構\n\n## 排場資料模型（能力：排場）\n' > $A && sec 排場 $A 排場資料模型"
  case_ "$L" 1 "## 沒有能力標記 → 擋，點名檔案、標題與原因" \
    "printf '## 排場資料模型\n' > $A" \
    "$A" "## 排場資料模型" "缺少（能力：X）"
  case_ "$L" 1 "標記的能力沒有 capability 檔 → 擋，點名缺的檔案" \
    "printf '## 會員登入（能力：會員）\n' > $A" \
    "$A" "## 會員登入（能力：會員）" "docs/capabilities/會員.md"
  case_ "$L" 0 "（能力：共用）→ 過" \
    "printf '## 部署拓撲（能力：共用）\n' > $A"
  case_ "$L" 0 "多個能力以「、」分隔，都有檔 → 過" \
    "printf '## 訂單與排場的關聯（能力：排場、訂單）\n' > $A && sec 排場 $A 訂單與排場的關聯 && sec 訂單 $A 訂單與排場的關聯"
  case_ "$L" 1 "以「、」分隔的其中一個能力沒有檔 → 擋，點名缺的那個" \
    "printf '## 訂單與會員（能力：訂單、會員）\n' > $A" \
    "docs/capabilities/會員.md"
  case_ "$L" 0 "能力名稱前後的半形與全形空白不算名稱的一部分 → 過" \
    "printf '## 排場（能力： 排場　、　訂單 ）\n' > $A && sec 排場 $A 排場 && sec 訂單 $A 排場"
  case_ "$L" 0 "沒標記的 ### 繼承父 ## 的能力 → 過" \
    "printf '## 排場資料模型（能力：排場）\n\n### 欄位與關係\n' > $A && sec 排場 $A 排場資料模型"
  case_ "$L" 1 "父 ## 是共用，沒標記的 ### 不繼承 → 擋，原因寫明共用不繼承" \
    "printf '## 部署拓撲（能力：共用）\n\n### 排場服務的節點\n' > $A" \
    "### 排場服務的節點" "共用不往下繼承"
  case_ "$L" 0 "父 ## 是共用，### 自己標記 → 過" \
    "printf '## 部署拓撲（能力：共用）\n\n### 訂單服務的節點（能力：訂單）\n' > $A && sec 訂單 $A 訂單服務的節點"
  case_ "$L" 1 "新的 ## 會切斷上一個 ## 的繼承 → 擋" \
    "printf '## 排場（能力：排場）\n\n## 雜項\n\n### 子節\n' > $A" \
    "## 雜項" "### 子節"
  case_ "$L" 1 "# 標題也切斷繼承 → 擋" \
    "printf '## 排場（能力：排場）\n\n# 附錄\n\n### 子節\n' > $A" \
    "### 子節" "父 ## 也沒有可繼承的能力"
  case_ "$L" 1 "標記缺收尾「）」→ 擋" \
    "printf '## 排場（能力：排場\n' > $A" "缺少收尾"
  case_ "$L" 1 "標記只有空項 → 擋；子節的原因不是「共用不繼承」" \
    "printf '## 雜項（能力：、）\n\n### 子節\n' > $A" \
    "空項" "### 子節 — 缺少（能力：X）或（能力：共用）標記，父 ## 也沒有可繼承的能力"
  case_ "$L" 1 "檔首 UTF-8 BOM 不讓第一個標題逃過檢查 → 擋" \
    "printf '\xef\xbb\xbf## 無標記\n' > $A" "## 無標記"
  case_ "$L" 0 "03 與 05 都不存在 → 過" ":"
  case_ "$L" 1 "只有 03 存在也照樣檢查 → 擋" \
    "printf '## 未標記\n' > $A" "$A"
  case_ "$L" 1 "只有 05 存在也照樣檢查 → 擋，點名 05" \
    "printf '## 訂單頁\n' > $F" "$F" "## 訂單頁"
  case_ "$L" 0 "圍欄程式碼區塊裡的 ## 不是標題 → 過" \
    "printf '## 部署（能力：共用）\n\n\`\`\`bash\n## 不是標題\n\`\`\`\n' > $A"
  case_ "$L" 0 "四個反引號的圍欄包住三個反引號的圍欄，內層 ## 仍不是標題 → 過" \
    "printf '## 部署（能力：共用）\n\n\`\`\`\`md\n\`\`\`\n## 不是標題\n\`\`\`\n\`\`\`\`\n' > $A"
  case_ "$L" 0 "# 與 #### 不在規則內 → 過" \
    "printf '# 架構總覽\n\n## 排場（能力：排場）\n\n#### 細節\n' > $A && sec 排場 $A 排場"

  # PR-TRUTH-12：輸出末尾列出所有（能力：共用）標題與總數，不影響 exit code。
  case_ "$L" 0 "只有共用標題 → 過，末尾列出全部共用標題與總數" \
    "printf '## 部署拓撲（能力：共用）\n\n### 節點（能力：共用）\n' > $A && printf '## 版面（能力：訂單、共用）\n' > $F && sec 訂單 $F 版面"
  ends_with "共用清單跨 03 與 05、含多能力標記，以總數收尾" "（能力：共用）標題：
  $A: ## 部署拓撲（能力：共用）
  $A: ### 節點（能力：共用）
  $F: ## 版面（能力：訂單、共用）
（能力：共用）標題共 3 個。"
  case_ "$L" 1 "有紅燈時共用清單照樣列在末尾 → 擋" \
    "printf '## 部署（能力：共用）\n\n## 未標記\n' > $A" "## 未標記"
  ends_with "紅燈的輸出也以共用清單收尾" "（能力：共用）標題：
  $A: ## 部署（能力：共用）
（能力：共用）標題共 1 個。"
  case_ "$L" 0 "沒有共用標題 → 過，總數為 0" ":"
  ends_with "沒有共用標題時列出 0 個" "（能力：共用）標題共 0 個。"

  # PR-TRUTH-08：標題標記與 capability 檔的 ## 規格章節 雙向一致。
  # sec 寫出的檔：第 3 行是 ## 規格章節，條目從第 5 行起。
  C=docs/capabilities/排場.md
  case_ "$L" 1 "標了能力的標題，capability 檔沒有 ## 規格章節 → 擋，點名 capability 檔" \
    "printf '## 排場資料模型（能力：排場）\n' > $A" \
    "$C: ## 規格章節 — 缺少這一節"
  case_ "$L" 1 "有 ## 規格章節 但沒列這個標題 → 擋，點名合訂本與標題" \
    "printf '## 排場資料模型（能力：排場）\n\n## 排場狀態機（能力：排場）\n' > $A && sec 排場 $A 排場資料模型" \
    "$A: ## 排場狀態機（能力：排場） — $C 的 ## 規格章節 沒有列出"
  case_ "$L" 1 "條目找不到對應標題（文字不符）→ 擋，點名 capability 檔行號" \
    "printf '## 排場資料模型（能力：排場）\n' > $A && sec 排場 $A 排場資料模型 $A 已刪除的章節" \
    "$C:6:" "已刪除的章節"
  case_ "$L" 1 "條目指錯合訂本 → 擋" \
    "printf '## 排場資料模型（能力：排場）\n' > $A && sec 排場 $A 排場資料模型 $F 排場資料模型" \
    "$C:6:"
  case_ "$L" 1 "條目指向標給別的能力的標題 → 擋" \
    "printf '## 訂單明細（能力：訂單）\n' > $A && sec 訂單 $A 訂單明細 && sec 排場 $A 訂單明細" \
    "$C:5:" "（能力：排場）"
  case_ "$L" 1 "規格章節裡格式不符的條目 → 擋" \
    "printf '## 排場資料模型（能力：排場）\n' > $A && sec 排場 $A 排場資料模型 && printf -- '- 排場狀態機\n' >> $C" \
    "$C:6:" "條目格式"
  case_ "$L" 0 "標記在標題中間、條目多餘空白、條目指向 05 → 過" \
    "printf '## 排場（能力：排場） 規則\n' > $A && printf '## 排場頁（能力：排場）\n' > $F && sec 排場 $A '  排場 規則  ' $F 排場頁"
  case_ "$L" 0 "規格章節之後的 ## Promises 條目不算規格章節 → 過" \
    "printf '## 排場資料模型（能力：排場）\n' > $A && sec 排場 $A 排場資料模型 && printf '\n## Promises\n\n- PR-SCH-01 — 排場可預約\n' >> $C"
  case_ "$L" 1 "條目列了靠繼承的 ###（沒有自己的標記）→ 擋，原因寫明繼承的不列" \
    "printf '## 排場（能力：排場）\n\n### 子節\n' > $A && sec 排場 $A 排場 $A 子節" \
    "$C:6:" "靠繼承的 ### 不列"
  case_ "$L" 0 "CRLF 換行的 capability 檔照樣比對 → 過" \
    "printf '## 排場資料模型（能力：排場）\n' > $A && printf '## 規格章節\r\n\r\n- \`$A\` 排場資料模型\r\n' > $C"
  case_ "$L" 0 "沒有任何輸入檔（連 capability 檔都沒有）→ 過，不等 stdin" \
    "rm -f docs/capabilities/*.md"
  case_ "$L" 0 "沒有標題標到的 capability 檔可以沒有 ## 規格章節 → 過" \
    "printf '## 訂單明細（能力：訂單）\n' > $A && sec 訂單 $A 訂單明細 && printf '# 排場\n\n現況\n' > $C"

  # PR-TRUTH-03：05 不得有核取方塊行。
  case_ "$L" 1 "05 有 - [ ] 行 → 擋，點名行號" \
    "printf '## 部署（能力：共用）\n\n說明\n- [ ] 待驗收\n' > $F" \
    "$F:4:" "- [ ] 待驗收"
  case_ "$L" 1 "05 有縮排的 - [x] 行 → 擋，點名行號" \
    "printf '## 部署（能力：共用）\n  - [x] 已驗收\n' > $F" \
    "$F:2:"
  case_ "$L" 0 "05 的一般清單、圍欄裡的核取方塊、03 的核取方塊都不擋 → 過" \
    "printf '## 部署（能力：共用）\n- 一般項目\n\n\`\`\`md\n- [ ] 範例\n\`\`\`\n' > $F && printf '## 部署（能力：共用）\n- [ ] 不歸本規則\n' > $A"
}

# 全形字串比對在 UTF-8 locale 與 LC_ALL=C 都必須成立（Git Bash 的 grep/awk 在兩者下行為不同）。
for loc in C.UTF-8 C; do
  echo "[locale: $loc]"
  suite "$loc"
done

# 工具本身故障（awk 不能跑）必須 exit 2，不能偽裝成內容違規或靜默通過。
echo "[工具故障]"
shim="$tmp/shim" && mkdir -p "$shim" && printf '#!/bin/sh\nexit 2\n' > "$shim/awk" && chmod +x "$shim/awk"
fixture "printf '## 排場（能力：排場）\n' > $A"
out=$(cd "$root" && PATH="$shim:$PATH" bash "$CHECK" 2>&1)
verdict 2 "awk 故障 → exit 2" $? "$out"

[ $fail -eq 0 ] && echo "全部通過。"
exit $fail
