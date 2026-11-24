#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-current-docs.sh（不帶參數）。
# 現行文件檢查：只掃寫死的七項（不存在的略過，沒有設定可調）：
#   GLOSSARY.md、docs/adr/*.md、docs/capabilities/*.md、docs/03_architecture_design.md、
#   docs/05_frontend_spec.md、docs/test-blueprint.md、docs/test-status.md
# 在 fenced code 與行內 code 之外，下列三種出現就報紅（表格不豁免）：
#   ISSUE-<數字>、前一字元不是英數字（行首算）的 #<數字>、ISO 日期 YYYY-MM-DD。
# 承諾 ID（PR-INSTALL-01）、版本號（v1.2.3）、中文日期、page#12 都不在這三種模式內。
# exit 0 全綠；exit 1 有紅燈，逐行列出「檔案:行號: 內容 — 原因」；exit 2 檢查工具本身故障。
#
# 只用 POSIX awk。模式全是 ASCII；中括號裡從不放多位元組字元（LC_ALL=C 下會被拆成位元組）。

set -u

set --
for f in GLOSSARY.md docs/adr/*.md docs/capabilities/*.md docs/03_architecture_design.md \
         docs/05_frontend_spec.md docs/test-blueprint.md docs/test-status.md; do
  [ -f "$f" ] && set -- "$@" "$f"
done

# 沒有任何輸入檔時 awk 會改讀 stdin，所以 stdin 接 /dev/null。
awk '
  function red(where, what, why) { printf "%s: %s — %s\n", where, what, why; bad = 1 }
  { sub(/\r$/, "") }
  FNR == 1 { sub(/^\357\273\277/, ""); fence = "" }
  # 圍欄程式碼區塊整段略過。收尾圍欄要同字元且不短於開頭（```` 可以包住 ```）。
  !fence && match($0, /^[ \t]*(```+|~~~+)/) {
    fence = substr($0, RSTART, RLENGTH); sub(/^[ \t]*/, "", fence); next
  }
  fence {
    line = $0; sub(/^[ \t]*/, "", line); sub(/[ \t]+$/, "", line)
    if (index(line, fence) == 1 && line ~ /^(`+|~+)$/) fence = ""
    next
  }
  {
    s = $0; gsub(/`[^`]*`/, "", s)
    where = FILENAME ":" FNR
    if (s ~ /ISSUE-[0-9]+/) red(where, $0, "現行文件不寫議題編號；歷史歸決策日誌與 git 歷史")
    if (s ~ /(^|[^A-Za-z0-9])#[0-9]+/) red(where, $0, "現行文件不寫票號 #N；歷史歸決策日誌與 git 歷史")
    if (s ~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) red(where, $0, "現行文件不寫日期；理由值得留就寫 ADR")
  }
  END {
    if (bad) print "current-docs-check：以上項目違反現行文件只寫現況的規則。拿掉票號與日期；理由值得留就寫 ADR；歷史歸決策日誌與 git 歷史。"
    else print "current-docs-check：通過。"
    # 紅燈用 3 回報，好和 awk 自己的故障碼（1、2）分開。
    exit bad ? 3 : 0
  }
' "$@" < /dev/null
code=$?
case $code in
  0) exit 0 ;;
  3) exit 1 ;;
  *) echo "current-docs-check：awk 執行時故障（exit $code），檢查沒有完成。" >&2; exit 2 ;;
esac
