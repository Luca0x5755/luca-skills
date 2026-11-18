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
  verdict "$want" "$name" "$code" "$out"
  for m in "$@"; do
    printf '%s' "$out" | grep -qF -- "$m" || { printf '  ✗ 輸出沒有點名「%s」\n' "$m"; fail=1; }
  done
}

suite() {  # suite <locale>
  local L="$1"
  case_ "$L" 0 "## 帶單一能力標記，capability 檔存在 → 過" \
    "printf '# 架構\n\n## 排場資料模型（能力：排場）\n' > $A"
  case_ "$L" 1 "## 沒有能力標記 → 擋，點名檔案、標題與原因" \
    "printf '## 排場資料模型\n' > $A" \
    "$A" "## 排場資料模型" "缺少（能力：X）"
  case_ "$L" 1 "標記的能力沒有 capability 檔 → 擋，點名缺的檔案" \
    "printf '## 會員登入（能力：會員）\n' > $A" \
    "$A" "## 會員登入（能力：會員）" "docs/capabilities/會員.md"
  case_ "$L" 0 "（能力：共用）→ 過" \
    "printf '## 部署拓撲（能力：共用）\n' > $A"
  case_ "$L" 0 "多個能力以「、」分隔，都有檔 → 過" \
    "printf '## 訂單與排場的關聯（能力：排場、訂單）\n' > $A"
  case_ "$L" 1 "以「、」分隔的其中一個能力沒有檔 → 擋，點名缺的那個" \
    "printf '## 訂單與會員（能力：訂單、會員）\n' > $A" \
    "docs/capabilities/會員.md"
  case_ "$L" 0 "能力名稱前後的半形與全形空白不算名稱的一部分 → 過" \
    "printf '## 排場（能力： 排場　、　訂單 ）\n' > $A"
  case_ "$L" 0 "沒標記的 ### 繼承父 ## 的能力 → 過" \
    "printf '## 排場資料模型（能力：排場）\n\n### 欄位與關係\n' > $A"
  case_ "$L" 1 "父 ## 是共用，沒標記的 ### 不繼承 → 擋，原因寫明共用不繼承" \
    "printf '## 部署拓撲（能力：共用）\n\n### 排場服務的節點\n' > $A" \
    "### 排場服務的節點" "共用不往下繼承"
  case_ "$L" 0 "父 ## 是共用，### 自己標記 → 過" \
    "printf '## 部署拓撲（能力：共用）\n\n### 訂單服務的節點（能力：訂單）\n' > $A"
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
    "printf '# 架構總覽\n\n## 排場（能力：排場）\n\n#### 細節\n' > $A"
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
