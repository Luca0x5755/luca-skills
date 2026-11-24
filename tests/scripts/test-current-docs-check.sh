#!/usr/bin/env bash
# check-current-docs.sh 的回歸規格（PR-DOCS-05～07）。每個案例在暫存目錄搭一個假專案，
# 在其根目錄跑檢查，看 exit code，紅燈時再看輸出是否點名「檔案:行號」。
# 行為變更必須先改這份規格 — 沒有檢查的規則不是規則，是願望。
# 執行：bash tests/scripts/test-current-docs-check.sh（tests/test-tooling.sh 會跑）
set -u
cd "$(dirname "$0")/../.."
REPO=$PWD
CHECK="$REPO/skills/core/setup-skills/check-current-docs.sh"
G=GLOSSARY.md
A=docs/03_architecture_design.md

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
# fixture <shell body>：搭一個新的假專案根目錄（已有 docs/adr、docs/capabilities），路徑放進 $root。
# 不能用 $(fixture …) 取值：子殼裡的 n 遞增會遺失，案例就共用同一個目錄。
fixture() {
  n=$((n + 1))
  root="$tmp/c$n"
  mkdir -p "$root/docs/adr" "$root/docs/capabilities" "$root/docs/issues"
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
  # PR-DOCS-05：只掃寫死的七項。
  case_ "$L" 0 "七項都不存在 → 過，不等 stdin" ":"
  case_ "$L" 0 "七項之外的檔案不掃 → 過" \
    "printf 'ISSUE-12 2026-01-02 #34\n' > README.md && printf 'ISSUE-12\n' > docs/issues/x.md && printf 'ISSUE-12\n' > docs/decision-log.md && mkdir docs/capabilities/sub && printf 'ISSUE-12\n' > docs/capabilities/sub/x.md && printf 'ISSUE-12\n' > docs/other.md"
  case_ "$L" 1 "GLOSSARY.md 有違規 → 擋，點名檔案" "printf '# 詞彙\n\n見 ISSUE-12\n' > $G" "$G:3:"
  case_ "$L" 1 "docs/adr/*.md 有違規 → 擋" "printf '日期：x\n2026-11-14\n' > docs/adr/0001-x.md" "docs/adr/0001-x.md:2:"
  case_ "$L" 1 "docs/capabilities/*.md 有違規 → 擋" "printf 'x\nISSUE-1\n' > docs/capabilities/a.md" "docs/capabilities/a.md:2:"
  case_ "$L" 1 "03 有違規 → 擋" "printf 'ISSUE-1\n' > $A" "$A:1:"
  case_ "$L" 1 "05 有違規 → 擋" "printf 'ISSUE-1\n' > docs/05_frontend_spec.md" "docs/05_frontend_spec.md:1:"
  case_ "$L" 1 "test-blueprint 有違規 → 擋" "printf 'ISSUE-1\n' > docs/test-blueprint.md" "docs/test-blueprint.md:1:"
  case_ "$L" 1 "test-status 有違規 → 擋" "printf 'ISSUE-1\n' > docs/test-status.md" "docs/test-status.md:1:"

  # PR-DOCS-06：三種模式、行號、表格不豁免。
  case_ "$L" 1 "ISSUE-12 → 擋，點名行號與內容" "printf 'a\nb ISSUE-12 c\n' > $G" "$G:2:" "ISSUE-12"
  case_ "$L" 1 "空白後的 #34 → 擋" "printf 'a 見 #34\n' > $G" "$G:1:"
  case_ "$L" 1 "行首的 #34 → 擋" "printf '#34 是舊票\n' > $G" "$G:1:"
  case_ "$L" 1 "中文全形括號接 #34 → 擋" "printf '（#34）\n' > $G" "$G:1:"
  case_ "$L" 1 "ISO 日期 → 擋" "printf '完成於 2026-01-02\n' > $G" "$G:1:"
  case_ "$L" 1 "表格列裡的違規 → 擋，不豁免" "printf '| a | b |\n|---|---|\n| ISSUE-9 | 2026-01-02 |\n' > $G" "$G:3:"
  case_ "$L" 1 "同檔多處違規各印一行" "printf 'ISSUE-1\nok\n#2 x\n' > $G" "$G:1:" "$G:3:"
  case_ "$L" 1 "code 之外另有違規 → 擋，行內 code 只遮住它自己" "printf '\`ISSUE-1\` 與 ISSUE-2\n' > $G" "$G:1:"
  case_ "$L" 1 "CRLF 換行照樣判定 → 擋" "printf 'x\r\nISSUE-1\r\n' > $G" "$G:2:"
  case_ "$L" 1 "檔首 UTF-8 BOM 不讓第一行逃過 → 擋" "printf '\xef\xbb\xbfISSUE-1\n' > $G" "$G:1:"

  # PR-DOCS-07：不報紅的東西。
  case_ "$L" 0 "承諾 ID、版本號、中文日期 → 過" \
    "printf 'PR-INSTALL-01 與 v1.2.3，2026年1月2日\n' > $G"
  case_ "$L" 0 "page#12、abc#34（# 前接英數字）→ 過" "printf 'see page#12 and abc#34\n' > $G"
  case_ "$L" 0 "標題的 # 與 ## 後接空白 → 過" "printf '# 標題\n\n## 小節 1\n' > $G"
  case_ "$L" 0 "行內 code 裡的內容 → 過" "printf '寫成 \`ISSUE-12\`、\`#34\`、\`2026-01-02\`\n' > $G"
  case_ "$L" 0 "fenced code（反引號）裡的內容 → 過" \
    "printf '\`\`\`md\nISSUE-12\n#34\n2026-01-02\n\`\`\`\n' > $G"
  case_ "$L" 0 "fenced code（波浪線）裡的內容 → 過" "printf '~~~\nISSUE-12\n~~~\n' > $G"
  case_ "$L" 0 "四個反引號的圍欄包住三個反引號，內層內容仍是 code → 過" \
    "printf '\`\`\`\`md\n\`\`\`\nISSUE-12\n\`\`\`\n\`\`\`\`\n' > $G"
  case_ "$L" 1 "圍欄收尾之後的違規 → 擋，行號正確" \
    "printf '\`\`\`\nx\n\`\`\`\nISSUE-12\n' > $G" "$G:4:"
}

# 全形字串與位元組處理在 UTF-8 locale 與 LC_ALL=C 都必須成立（CI 是 C locale）。
for loc in C.UTF-8 C; do
  echo "[locale: $loc]"
  suite "$loc"
done

# 工具本身故障（awk 不能跑）必須 exit 2，不能偽裝成內容違規或靜默通過。
echo "[工具故障]"
shim="$tmp/shim" && mkdir -p "$shim" && printf '#!/bin/sh\nexit 2\n' > "$shim/awk" && chmod +x "$shim/awk"
fixture "printf 'ok\n' > $G"
out=$(cd "$root" && PATH="$shim:$PATH" bash "$CHECK" 2>&1)
verdict 2 "awk 故障 → exit 2" $? "$out"

[ $fail -eq 0 ] && echo "全部通過。"
exit $fail
