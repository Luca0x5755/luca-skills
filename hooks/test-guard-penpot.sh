#!/usr/bin/env bash
# guard-penpot.sh 的回歸規格。每條餵一份真實形狀的 PreToolUse payload，斷言擋或放行。
# 行為變更必須先改這張表 — 沒有檢查的規則不是規則，是願望。
# 執行：bash hooks/test-guard-penpot.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")"
HOOK="$PWD/guard-penpot.sh"

fail=0

# check <名稱> <payload JSON> <want ALLOW|BLOCK>
check() {
  local name="$1" payload="$2" want="$3"
  printf '%s' "$payload" | bash "$HOOK" >/dev/null 2>&1
  local code=$?
  local got=ALLOW
  [ "$code" = 2 ] && got=BLOCK
  if [ "$got" = "$want" ]; then
    printf '  ✓ %-5s %s\n' "$want" "$name"
  else
    printf '  ✗ want=%s got=%s(exit %s)  %s\n' "$want" "$got" "$code" "$name"
    fail=1
  fi
}

# code <名稱> <execute_code 的程式碼> <want>
code() {
  check "$1" "$(jq -nc --arg c "$2" '{tool_name:"mcp__penpot__execute_code",tool_input:{code:$c}}')" "$3"
}

# 不帶 root 時走遍整份檔案，32,173 物件實測 23 秒
code "findShapeById 全域搜尋" 'return penpotUtils.findShapeById("ba03a825-35a1");' BLOCK
code "findShapes 單一參數"   "return penpotUtils.findShapes(s => s.type === 'text');" BLOCK
# 一律擋、不數參數：數括號裡的逗號必然誤判，替代寫法反而更快
code "findShapes 帶 root 也擋" 'return penpotUtils.findShapes(pred, penpot.root);' BLOCK
code "findShape 夾在多行中間" $'const a = 1;\nconst s = penpotUtils.findShape(\n  x => x.name === "Hero"\n);\nreturn s.id;' BLOCK
code "optional chaining 也擋"  'return penpotUtils?.findShapes(s => s.visible);' BLOCK
code "函式名與括號之間換行"     $'return penpotUtils\n  .findShapes\n  (s => s.visible);' BLOCK

# 相鄰的 API 不得誤擋
code "currentPage.getShapeById"   'return penpot.currentPage.getShapeById("ba03a825-35a1").name;' ALLOW
code "currentPage.findShapes 條件物件" "return penpot.currentPage.findShapes({ name: 'Hero' }).length;" ALLOW
code "penpotUtils 其他函式"        'const p = penpotUtils.getPageForShape(s); return penpotUtils.shapeStructure(s, 2);' ALLOW

# export_shape <名稱> <shapeId> <want>
export_shape() {
  check "$1" "$(jq -nc --arg s "$2" '{tool_name:"mcp__penpot__export_shape",tool_input:{shapeId:$s}}')" "$3"
}

# 帶 UUID 時工具內部寫死 penpotUtils.findShapeById
export_shape "export 帶 UUID"      'ba03a825-35a1-8011-8008-dddb182d908c' BLOCK
export_shape "export selection"    'selection' ALLOW
export_shape "export page"         'page'      ALLOW

# 管轄外
check "其他工具不歸它管" "$(jq -nc '{tool_name:"Bash",tool_input:{command:"echo penpotUtils.findShapes("}}')" ALLOW
check "payload 沒有 tool_input" '{"tool_name":"mcp__penpot__export_shape"}' ALLOW

exit $fail
