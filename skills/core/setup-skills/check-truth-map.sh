#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-truth-map.sh（不帶參數）。
# 真相地圖檢查：合訂本 docs/03_architecture_design.md 與 docs/05_frontend_spec.md（任一可不存在）
# 的每個 ## / ### 標題都要帶（能力：X）或（能力：共用），X 必須有 docs/capabilities/X.md。
# 多個能力以「、」分隔；沒標記的 ### 繼承父 ## 的能力，但「共用」不往下繼承。
# exit 0 全綠；exit 1 有紅燈，逐行列出「檔案: 標題 — 原因」；exit 2 檢查工具本身故障。
#
# 只用 POSIX awk（以 gawk --posix 驗過）。全形字串只做字面比對與交替（|），
# 從不放進方括號字元類：LC_ALL=C 下方括號會把一個全形字拆成三個位元組，誤傷別的中文字。

set -u
status=0

for f in docs/03_architecture_design.md docs/05_frontend_spec.md; do
  [ -f "$f" ] || continue
  awk -v file="$f" '
    BEGIN { TAG = "（能力："; CLOSE = "）"; SEP = "、"; SHARED = "共用"; inherit = 0; parent_shared = 0; bad = 0 }
    function red(heading, why) { printf "%s: %s — %s\n", file, heading, why; bad = 1 }
    # 檢查一個標題的能力標記。回傳 -1 = 沒有標記；-2 = 標記寫壞（已報紅）；
    # 否則回傳非「共用」的能力數（0 表示只標了共用），缺檔的能力已報紅。
    function check_tag(line,    i, rest, j, n, parts, k, c, p, caps, shared, empty) {
      i = index(line, TAG)
      if (i == 0) return -1
      rest = substr(line, i + length(TAG))
      j = index(rest, CLOSE)
      if (j == 0) { red(line, "能力標記缺少收尾的「）」"); return -2 }
      n = split(substr(rest, 1, j - 1), parts, SEP)
      caps = 0; shared = 0; empty = 0
      for (k = 1; k <= n; k++) {
        c = parts[k]; gsub(/^([ \t]|　)+|([ \t]|　)+$/, "", c)
        if (c == "") { empty = 1; continue }
        if (c == SHARED) { shared = 1; continue }
        caps++
        p = "docs/capabilities/" c ".md"
        if ((getline _ < p) < 0) red(line, "能力「" c "」沒有對應的 " p)
        close(p)
      }
      if (empty || n == 0) red(line, "能力標記裡有空項")
      if (caps == 0 && !shared) return -2
      return caps
    }
    { sub(/\r$/, "") }
    NR == 1 { sub(/^\357\273\277/, "") }
    # 圍欄程式碼區塊裡的 # 不是標題。收尾圍欄要同字元且不短於開頭（```` 可以包住 ```）。
    !fence && match($0, /^[ \t]*(```+|~~~+)/) {
      fence = substr($0, RSTART, RLENGTH); sub(/^[ \t]*/, "", fence); next
    }
    fence {
      line = $0; sub(/^[ \t]*/, "", line); sub(/[ \t]+$/, "", line)
      if (index(line, fence) == 1 && line ~ /^(`+|~+)$/) fence = ""
      next
    }
    /^#[ \t]/ { inherit = 0; parent_shared = 0; next }
    /^##[ \t]/ {
      caps = check_tag($0)
      if (caps == -1) red($0, "缺少（能力：X）或（能力：共用）標記")
      inherit = (caps > 0); parent_shared = (caps == 0)
      next
    }
    /^###[ \t]/ {
      caps = check_tag($0)
      if (caps != -1 || inherit) next
      if (parent_shared) red($0, "缺少能力標記；父 ## 是（能力：共用），共用不往下繼承")
      else red($0, "缺少（能力：X）或（能力：共用）標記，父 ## 也沒有可繼承的能力")
    }
    # 紅燈用 3 回報，好和 awk 自己的故障碼（1、2）分開。
    END { exit bad ? 3 : 0 }
  ' "$f"
  code=$?
  case $code in
    0) ;;
    3) status=1 ;;
    *) echo "truth-map-check：awk 讀取 $f 時故障（exit $code），檢查沒有完成。" >&2; exit 2 ;;
  esac
done

if [ "$status" -ne 0 ]; then
  echo "truth-map-check：以上標題違反能力標記規則。補上（能力：X）並建立 docs/capabilities/X.md，或標（能力：共用）。"
  exit 1
fi
echo "truth-map-check：通過。"
