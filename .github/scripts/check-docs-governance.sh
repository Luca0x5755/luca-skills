#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-docs-governance.sh（不帶參數）。
# 文件治理檢查，目前涵蓋決策日誌 docs/decision-log.md（沒有這個檔就略過）：
#   PR-DOCS-07  主檔出現兩種以上的年月（行首 YYYY-MM）。只看檔案內容，不看執行當天的日期。
#   PR-DOCS-08  主檔任一行超過 300 字（以 Unicode 字元計），標明行號。docs/decision-log/ 下的封存檔不檢查。
# exit 0 全綠；exit 1 有紅燈，逐行列出「位置: 內容 — 原因」；exit 2 檢查工具本身故障。
#
# 字數以字元計：awk 固定在 LC_ALL=C 下跑（位元組語意，各 locale 結果一致），
# 先刪掉 UTF-8 的接續位元組（\200-\277），剩下的位元組數就是字元數。
# 方括號裡只放位元組範圍，不放多位元組字元。

set -u

LOG=docs/decision-log.md
[ -f "$LOG" ] || { echo "docs-governance-check：通過。"; exit 0; }

LC_ALL=C awk -v log_file="$LOG" '
  BEGIN { MAX = 300; bad = 0; nm = 0 }
  function red(where, what, why) { printf "%s: %s — %s\n", where, what, why; bad = 1 }
  { sub(/\r$/, "") }
  FNR == 1 { sub(/^\357\273\277/, "") }
  {
    if (match($0, /^[0-9][0-9][0-9][0-9]-[0-9][0-9]/)) {
      ym = substr($0, 1, RLENGTH)
      if (!(ym in seen)) { seen[ym] = 1; months[++nm] = ym }
    }
    s = $0; gsub(/[\200-\277]/, "", s)
    if (length(s) > MAX)
      red(log_file ":" FNR, substr($0, 1, 10), "PR-DOCS-08 這一行有 " length(s) " 字，超過 " MAX " 字；寫短，或把細節放進 ADR")
  }
  END {
    if (nm > 1) {
      list = months[1]; for (i = 2; i <= nm; i++) list = list "、" months[i]
      red(log_file, "出現 " nm " 種年月（" list "）", "PR-DOCS-07 主檔只放當月；把其餘月份的行搬進 docs/decision-log/YYYY-MM.md")
    }
    if (bad) print "docs-governance-check：以上項目違反文件治理規則。"
    else print "docs-governance-check：通過。"
    exit bad ? 3 : 0
  }
' "$LOG"
code=$?
case $code in
  0) exit 0 ;;
  3) exit 1 ;;
  *) echo "docs-governance-check：awk 執行時故障（exit $code），檢查沒有完成。" >&2; exit 2 ;;
esac
