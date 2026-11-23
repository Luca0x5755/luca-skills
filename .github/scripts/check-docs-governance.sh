#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-docs-governance.sh（不帶參數、沒有設定檔）。
# 文件治理檢查：
#   PR-DOCS-07  決策日誌 docs/decision-log.md 出現兩種以上的年月（行首 YYYY-MM）。只看檔案內容，不看執行當天的日期。
#   PR-DOCS-08  決策日誌任一行超過 300 字（以 Unicode 字元計），標明行號。docs/decision-log/ 下的封存檔不檢查。
#   PR-DOCS-01  現行文件在程式碼區塊與表格之外出現「票 N」「規格 N」「ISSUE-N」或 YYYY-MM-DD，標明檔案與行號。
#               掃描清單固定（PR-DOCS-14）：docs/03_architecture_design.md、docs/05_frontend_spec.md、
#               docs/capabilities/*.md、docs/test-blueprint.md、docs/test-status.md、GLOSSARY.md、docs/adr/*.md；
#               不存在的檔案略過；docs/uat-cases.md 不在清單內。
# exit 0 全綠；exit 1 有紅燈，逐行列出「位置: 內容 — 原因」；exit 2 檢查工具本身故障。
#
# awk 固定在 LC_ALL=C 下跑（位元組語意，各 locale 結果一致）：
# 字數以字元計 — 先刪掉 UTF-8 的接續位元組（\200-\277），剩下的位元組數就是字元數；
# 「票」「規格」以八進位位元組比對（票 = \347\245\250、規格 = \350\246\217\346\240\274）。
# 方括號裡只放位元組範圍，不放多位元組字元。

set -u

LOG=docs/decision-log.md
bad=0

# 決策日誌（沒有這個檔就略過）。awk exit 3 代表有紅燈。
if [ -f "$LOG" ]; then
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
      exit bad ? 3 : 0
    }
  ' "$LOG"
  case $? in
    0) ;;
    3) bad=1 ;;
    *) echo "docs-governance-check：awk 執行時故障，檢查沒有完成。" >&2; exit 2 ;;
  esac
fi

# 現行文件掃描清單；glob 沒有命中時原樣字串不是檔案，被 -f 擋掉。
files=()
for f in docs/03_architecture_design.md docs/05_frontend_spec.md docs/capabilities/*.md \
         docs/test-blueprint.md docs/test-status.md GLOSSARY.md docs/adr/*.md; do
  [ -f "$f" ] && files+=("$f")
done

if [ ${#files[@]} -gt 0 ]; then
  LC_ALL=C awk '
    function red(what) { printf "%s:%d: %s — PR-DOCS-01 現行文件不放票號、規格號與日期；票號與日期歸 git 與決策日誌\n", FILENAME, FNR, what; bad = 1 }
    FNR == 1 { infence = 0; sub(/^\357\273\277/, "") }
    { sub(/\r$/, "") }
    /^ *```/ { infence = !infence; next }
    infence { next }
    /^\|/ { next }
    {
      if (match($0, /(\347\245\250|\350\246\217\346\240\274) *[0-9]/) ||
          match($0, /ISSUE-[0-9]/) ||
          match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/))
        red($0)
    }
    END { exit bad ? 3 : 0 }
  ' "${files[@]}"
  case $? in
    0) ;;
    3) bad=1 ;;
    *) echo "docs-governance-check：awk 執行時故障，檢查沒有完成。" >&2; exit 2 ;;
  esac
fi

if [ $bad -ne 0 ]; then
  echo "docs-governance-check：以上項目違反文件治理規則。"
  exit 1
fi
echo "docs-governance-check：通過。"
