#!/usr/bin/env bash
# PreToolUse hook（matcher: mcp__penpot__execute_code|mcp__penpot__export_shape）。
# 擋下會搜尋整份設計檔、讓瀏覽器分頁凍結的 Penpot MCP 呼叫。
# 契約：exit 2 = 擋下這次工具呼叫；stderr = 該改寫成什麼。
#
# 為什麼是 hook：這是效能規則，照 /writing-hooks 本該留在 prose。破例是因為 Penpot MCP
# 官方 instructions 教的正是全域寫法 — 我們的 prose 對上更權威的 prose 守不住。
# 16 頁、32,173 物件的檔案上，不帶 root 的 penpotUtils 搜尋實測 23 秒，getShapeById 1 ms。

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

deny() { printf '%s\n' "$@" >&2; exit 2; }

case "$tool" in
  mcp__penpot__execute_code)
    code=$(printf '%s' "$input" | jq -r '.tool_input.code // empty' 2>/dev/null)
    # 一律擋，不數參數：用 regex 數括號裡的逗號必然誤判，而替代寫法實測更快。
    # 先把換行攤平，`?.` 與斷行的鏈式寫法才比得到。
    printf '%s' "$code" | tr '\n' ' ' \
      | grep -qE 'penpotUtils[[:space:]]*\??\.[[:space:]]*findShape(s|ById)?[[:space:]]*\(' || exit 0
    deny "Blocked: penpotUtils.findShape / findShapes / findShapeById walk every page of the file and build a proxy per shape — about 23 s on a large file, freezing the Penpot tab." \
         "Search the current page instead:" \
         "  by id:                penpot.currentPage.getShapeById(id)" \
         "  by name or type:      penpot.currentPage.findShapes({ name | nameLike | type })" \
         "  by any predicate:     penpot.currentPage.findShapes({}).filter(pred)" \
         "  on another page:      page.getShapeById(id) on that page (penpotUtils.getPageForShape does this)"
    ;;
  mcp__penpot__export_shape)
    id=$(printf '%s' "$input" | jq -r '.tool_input.shapeId // empty' 2>/dev/null)
    case "$id" in ''|selection|page) exit 0 ;; esac
    deny "Blocked: export_shape with a shape id runs penpotUtils.findShapeById internally — a whole-file search that can freeze the Penpot tab for 20+ s." \
         "Export through the selection, in two calls:" \
         "  1. execute_code: penpot.selection = [penpot.currentPage.getShapeById(\"$id\")]" \
         "  2. export_shape({ shapeId: \"selection\" })" \
         "If the image is not the shape you selected, the selection changed in between — select again and re-export."
    ;;
esac
exit 0
