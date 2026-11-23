#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-docs-governance.sh（不帶參數、沒有設定檔）。
# 文件治理檢查：
#   PR-DOCS-07  決策日誌 docs/decision-log.md 出現兩種以上的年月（行首 YYYY-MM）。只看檔案內容，不看執行當天的日期。
#   PR-DOCS-08  決策日誌任一行超過 300 字（以 Unicode 字元計），標明行號。docs/decision-log/ 下的封存檔不檢查。
#   PR-DOCS-01  現行文件在程式碼區塊與表格之外出現「票 N」「規格 N」「ISSUE-N」或 YYYY-MM-DD，標明檔案與行號。
#               掃描清單固定（PR-DOCS-14）：docs/03_architecture_design.md、docs/05_frontend_spec.md、
#               docs/capabilities/*.md、docs/test-blueprint.md、docs/test-status.md、GLOSSARY.md、docs/adr/*.md；
#               不存在的檔案略過；docs/uat-cases.md 不在清單內。
#   PR-DOCS-02  掃描清單內任一「最小一節」（標題行到下一個標題行；檔首標題前的前言也算一節；程式碼區塊內的 # 不是標題；
#               表格與程式碼區塊照算）超過 40 KB（40960 位元組）。以位元組計，和 PR-DOCS-08 以字元計的行長是兩回事。
#   PR-DOCS-03  docs/03_architecture_design.md、docs/05_frontend_spec.md、docs/test-blueprint.md、docs/test-status.md
#               存在時，第一行必須是下方 READING_GUIDE。capability 檔不要求（讀法要代理先查它，套上去會循環）。
# exit 0 全綠；exit 1 有紅燈，逐行列出「位置: 內容 — 原因」；exit 2 檢查工具本身故障。
#
# awk 固定在 LC_ALL=C 下跑（位元組語意，各 locale 結果一致）：
# 字數以字元計 — 先刪掉 UTF-8 的接續位元組（\200-\277），剩下的位元組數就是字元數；
# 「票」「規格」以八進位位元組比對（票 = \347\245\250、規格 = \350\246\217\346\240\274）。
# 方括號裡只放位元組範圍，不放多位元組字元。

set -u

# 讀法引言的標準文字 — 全 repo 唯一定義處（要補這一行的工具重用這個變數，不要另抄一份）。
# 單引號包住、內容不得含單引號；PR-DOCS-03 要求合訂本與 test 文件的第一行與它逐字相同。
READING_GUIDE='> 不要整份讀：先查 capability 檔的 `## 規格章節`，grep 標題行號，只讀那一段。'

LOG=docs/decision-log.md
MAX_SECTION=40960
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

# PR-DOCS-02、03：逐檔檢查節大小與第一行。最後一行沒有換行時，用 wc -c 的總位元組數校正。
for f in ${files[@]+"${files[@]}"}; do
  need=0
  case "$f" in
    docs/03_architecture_design.md|docs/05_frontend_spec.md|docs/test-blueprint.md|docs/test-status.md) need=1 ;;
  esac
  total=$(wc -c < "$f" | tr -d ' ')
  LC_ALL=C awk -v max="$MAX_SECTION" -v total="$total" -v need="$need" -v guide="$READING_GUIDE" -v file="$f" '
    function red(where, what, why) { printf "%s: %s — %s\n", where, what, why; bad = 1 }
    function flush() {
      if (title == "" && size == 0) return
      if (size > max)
        red(file ":" start, (title == "" ? "（檔首前言）" : title), "PR-DOCS-02 這一節有 " size " 位元組，超過 " max " 位元組（40 KB）；拆成子節，或把細節放進 ADR")
    }
    BEGIN { title = ""; size = 0; start = 1; sum = 0; infence = 0 }
    {
      raw = length($0) + 1; sum += raw
      line = $0; sub(/\r$/, "", line)
      if (FNR == 1) {
        first = line; sub(/^\357\273\277/, "", first)
        if (need && first != guide)
          red(file ":1", "（第一行）", "PR-DOCS-03 第一行必須是讀法引言：" guide)
      }
      if (line ~ /^ *```/) infence = !infence
      else if (!infence && line ~ /^#+ /) { flush(); title = line; size = 0; start = FNR }
      size += raw
    }
    END {
      if (NR == 0) { if (need) red(file ":1", "（空檔）", "PR-DOCS-03 第一行必須是讀法引言：" guide) }
      else { size -= (sum - total); flush() }
      exit bad ? 3 : 0
    }
  ' "$f"
  case $? in
    0) ;;
    3) bad=1 ;;
    *) echo "docs-governance-check：awk 執行時故障，檢查沒有完成。" >&2; exit 2 ;;
  esac
done

if [ $bad -ne 0 ]; then
  echo "docs-governance-check：以上項目違反文件治理規則。"
  exit 1
fi
echo "docs-governance-check：通過。"
