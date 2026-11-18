#!/usr/bin/env bash
# 用法：在 repo 根目錄執行 check-truth-map.sh（不帶參數）。
# 真相地圖檢查，對象是合訂本 docs/03_architecture_design.md、docs/05_frontend_spec.md（任一可不存在）
# 與 docs/capabilities/*.md：
#   1. 能力標記：合訂本每個 ## / ### 標題都要帶（能力：X）或（能力：共用），X 必須有 docs/capabilities/X.md。
#      多個能力以「、」分隔；沒標記的 ### 繼承父 ## 的能力，但「共用」不往下繼承。
#   2. 雙向一致：標了（能力：X）的標題，要列在 X.md 的「## 規格章節」，條目寫成
#      - `docs/03_architecture_design.md` <標題全文去掉標記>（05 的標題就寫 05 的路徑）；反過來每個條目都要有對應的標題。
#      只比對自己帶標記的標題；靠繼承的 ### 不必列。
#   3. 05 不得有 - [ ] / - [x] 核取方塊行。
#   4. 承諾 ID：capability 檔「## Promises」的每一承諾行定義一個 ID，行格式以 docs/agents/domain.md 的 capability 檔形狀為準；
#      — 之後以 retired 開頭的是退役 ID。
#      ID 前綴由已定義的 ID 去掉尾端數字推導（不用設定檔）；03／05 裡「前綴＋數字」的引用沒定義報「找不到」，退役報「已退役」。
#      前綴本身打錯（PR-AUHT-03）抓不到，這是刻意接受的漏網。
# 輸出末尾一律列出所有（能力：共用）標題與總數；這份列表不影響 exit code。
# exit 0 全綠；exit 1 有紅燈，逐行列出「位置: 內容 — 原因」；exit 2 檢查工具本身故障。
#
# 只用 POSIX awk（以 gawk --posix 驗過）。全形字串只做字面比對與交替（|），
# 從不放進方括號字元類：LC_ALL=C 下方括號會把一個全形字拆成三個位元組，誤傷別的中文字。

set -u

set --
for f in docs/03_architecture_design.md docs/05_frontend_spec.md docs/capabilities/*.md; do
  [ -f "$f" ] && set -- "$@" "$f"
done

# 沒有任何輸入檔時 awk 會改讀 stdin，所以 stdin 接 /dev/null。
awk '
  BEGIN {
    TAG = "（能力："; CLOSE = "）"; SEP = "、"; SHARED = "共用"; SECTION = "規格章節"
    PROMISES = "Promises"; DASH = "—"; RETIRED = "retired"; nc = 0
    CAPDIR = "docs/capabilities/"; bad = 0; nt = 0; ne = 0; ns = 0
  }
  function red(where, what, why) { printf "%s: %s — %s\n", where, what, why; bad = 1 }
  function trim(s) { gsub(/^([ \t]|　)+|([ \t]|　)+$/, "", s); return s }
  function cap_exists(c,    p) {
    if (!(c in known)) { p = CAPDIR c ".md"; known[c] = ((getline _ < p) >= 0); close(p) }
    return known[c]
  }
  # 檢查一個標題的能力標記，並記下它標到的能力（供雙向比對）與共用。
  # 標題記錄：nt 筆，tcap/tfile/ttext/thead = 能力、合訂本、標題全文去掉 # 與標記、原始標題行；
  # tagged[能力,合訂本,文字] 供反向查詢。共用標題：ns 筆，shared_line。
  # 回傳 -1 = 沒有標記；-2 = 標記寫壞（已報紅）；否則回傳非「共用」的能力數（0 表示只標了共用）。
  function check_tag(line,    i, rest, j, n, parts, k, c, caps, shared, empty, text) {
    i = index(line, TAG)
    if (i == 0) return -1
    rest = substr(line, i + length(TAG))
    j = index(rest, CLOSE)
    if (j == 0) { red(FILENAME, line, "能力標記缺少收尾的「）」"); return -2 }
    # 規格章節條目要寫的文字：標題全文去掉 # 前綴與能力標記。
    text = substr(line, 1, i - 1); sub(/^#+[ \t]+/, "", text)
    text = trim(text substr(rest, j + length(CLOSE)))
    n = split(substr(rest, 1, j - 1), parts, SEP)
    caps = 0; shared = 0; empty = 0
    for (k = 1; k <= n; k++) {
      c = trim(parts[k])
      if (c == "") { empty = 1; continue }
      if (c == SHARED) { shared = 1; continue }
      caps++
      if (!cap_exists(c)) { red(FILENAME, line, "能力「" c "」沒有對應的 " CAPDIR c ".md"); continue }
      nt++; tcap[nt] = c; tfile[nt] = FILENAME; ttext[nt] = text; thead[nt] = line
      tagged[c SUBSEP FILENAME SUBSEP text] = 1
    }
    if (empty || n == 0) red(FILENAME, line, "能力標記裡有空項")
    if (shared) shared_line[++ns] = FILENAME ": " line
    if (caps == 0 && !shared) return -2
    return caps
  }
  # 「## Promises」的一行：是 <ID> — … 就記下 ID（live 或 retired）與它的前綴；其他行不是定義。
  function define(line,    id, rest, p) {
    sub(/^[ \t]*(-[ \t]+)?/, "", line)
    if (!match(line, /^[A-Za-z][A-Za-z0-9_-]*[0-9]/)) return
    id = substr(line, 1, RLENGTH); rest = trim(substr(line, RLENGTH + 1))
    if (index(rest, DASH) != 1) return
    rest = trim(substr(rest, length(DASH) + 1))
    defs[id] = (index(rest, RETIRED) == 1) ? RETIRED : "live"
    p = id; sub(/[0-9]+$/, "", p); prefix[p] = 1
  }
  # 在合訂本的一行裡找「前綴＋數字」的引用並逐一判定。前綴前一字若是 ID 字元，就是別的 ID 的一部分，不算。
  function cite_scan(where, line,    p, s, i, at, id, prev) {
    for (p in prefix) {
      s = line; at = 0
      while ((i = index(s, p)) > 0) {
        # 行首沒有前一字；gawk 的 substr(s, 0, 1) 會回第 1 字，不能拿來當「前一字」。
        prev = (at + i > 1) ? substr(line, at + i - 1, 1) : ""
        s = substr(s, i + length(p)); at += i + length(p) - 1
        if (prev ~ /[A-Za-z0-9_-]/ || !match(s, /^[0-9]+/)) continue
        id = p substr(s, 1, RLENGTH)
        if (!(id in defs)) red(where, line, "承諾 " id " 找不到：沒有任何 capability 檔的 ## " PROMISES " 定義它")
        else if (defs[id] == RETIRED) red(where, line, "承諾 " id " 已退役：改引用取代它的新 ID")
      }
    }
  }
  { sub(/\r$/, "") }
  FNR == 1 {
    sub(/^\357\273\277/, "")
    fence = ""; inherit = 0; parent_shared = 0; insec = 0; inprom = 0
    capf = (index(FILENAME, CAPDIR) == 1)
    cname = substr(FILENAME, length(CAPDIR) + 1); sub(/\.md$/, "", cname)
  }
  # 圍欄程式碼區塊裡的 # 不是標題。收尾圍欄要同字元且不短於開頭（```` 可以包住 ```）。
  !fence && match($0, /^[ \t]*(```+|~~~+)/) {
    fence = substr($0, RSTART, RLENGTH); sub(/^[ \t]*/, "", fence); next
  }
  fence {
    line = $0; sub(/^[ \t]*/, "", line); sub(/[ \t]+$/, "", line)
    if (index(line, fence) == 1 && line ~ /^(`+|~+)$/) fence = ""
    next
  }

  # ── capability 檔：只讀「## 規格章節」，到下一個 # 或 ## 為止。
  capf && /^##?[ \t]/ {
    insec = ($0 ~ /^##[ \t]/ && trim(substr($0, 3)) == SECTION)
    if (insec) hassec[cname] = 1
    inprom = ($0 ~ /^##[ \t]/ && trim(substr($0, 3)) == PROMISES)
    next
  }
  capf && insec && /^[ \t]*-[ \t]/ {
    if (match($0, /^[ \t]*-[ \t]+`[^`]+`/)) {
      path = substr($0, RSTART, RLENGTH); sub(/^[ \t]*-[ \t]+`/, "", path); sub(/`$/, "", path)
      text = trim(substr($0, RSTART + RLENGTH))
      if (text != "") {
        ne++; ecap[ne] = cname; epath[ne] = path; etext[ne] = text; eline[ne] = FNR; eraw[ne] = $0
        listed[cname SUBSEP path SUBSEP text] = 1
        next
      }
    }
    red(FILENAME ":" FNR, $0, "條目格式應為 - `docs/03_architecture_design.md` <標題全文去掉標記>（05 同理）")
    next
  }
  capf && inprom { define($0); next }
  capf { next }

  # ── 合訂本。帶數字的行先存起來：前綴要等所有 capability 檔讀完才知道。
  /[0-9]/ { nc++; cline[nc] = $0; cwhere[nc] = FILENAME ":" FNR }
  # PR-TRUTH-03：05 只放骨架，驗收打勾清單不准回來。
  FILENAME ~ /05_frontend_spec\.md$/ && /^[ \t]*-[ \t]+\[[ xX]\]/ {
    red(FILENAME ":" FNR, $0, "05 不得有核取方塊行；驗收條件寫成 capability 檔的承諾"); next
  }
  /^#[ \t]/ { inherit = 0; parent_shared = 0; next }
  /^##[ \t]/ {
    caps = check_tag($0)
    if (caps == -1) red(FILENAME, $0, "缺少（能力：X）或（能力：共用）標記")
    inherit = (caps > 0); parent_shared = (caps == 0)
    next
  }
  /^###[ \t]/ {
    caps = check_tag($0)
    if (caps != -1 || inherit) next
    if (parent_shared) red(FILENAME, $0, "缺少能力標記；父 ## 是（能力：共用），共用不往下繼承")
    else red(FILENAME, $0, "缺少（能力：X）或（能力：共用）標記，父 ## 也沒有可繼承的能力")
  }

  END {
    for (i = 1; i <= nc; i++) cite_scan(cwhere[i], cline[i])
    # 正向：帶標記的標題要列在該能力的規格章節。
    for (i = 1; i <= nt; i++) {
      c = tcap[i]
      if (!(c in hassec)) {
        if (!(c in told)) red(CAPDIR c ".md", "## " SECTION, "缺少這一節；有標題標了（能力：" c "）")
        told[c] = 1
      } else if (!((c SUBSEP tfile[i] SUBSEP ttext[i]) in listed))
        red(tfile[i], thead[i], CAPDIR c ".md 的 ## " SECTION " 沒有列出 - `" tfile[i] "` " ttext[i])
    }
    # 反向：每個條目都要有標了這個能力的標題。
    for (i = 1; i <= ne; i++)
      if (!((ecap[i] SUBSEP epath[i] SUBSEP etext[i]) in tagged))
        red(CAPDIR ecap[i] ".md:" eline[i], eraw[i], "找不到 " epath[i] " 裡自己標了（能力：" ecap[i] "）的對應標題；靠繼承的 ### 不列")
    if (bad) print "truth-map-check：以上項目違反真相地圖規則。補上（能力：X）並建立 docs/capabilities/X.md 或標（能力：共用）；讓 ## 規格章節 與標題一一對應；05 拿掉核取方塊；引用的承諾 ID 要有定義且未退役。"
    else print "truth-map-check：通過。"
    if (ns) print "（能力：共用）標題："
    for (i = 1; i <= ns; i++) print "  " shared_line[i]
    printf "（能力：共用）標題共 %d 個。\n", ns
    # 紅燈用 3 回報，好和 awk 自己的故障碼（1、2）分開。
    exit bad ? 3 : 0
  }
' "$@" < /dev/null
code=$?
case $code in
  0) exit 0 ;;
  3) exit 1 ;;
  *) echo "truth-map-check：awk 執行時故障（exit $code），檢查沒有完成。" >&2; exit 2 ;;
esac
