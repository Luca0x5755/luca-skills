#!/usr/bin/env bash
# check-docs-governance.sh 的回歸規格（PR-DOCS-01、07、08、14）。每個案例在暫存目錄搭假專案，
# 在其根目錄跑檢查，看 exit code，紅燈時再看輸出是否點名檔案、行號與規則編號。
# 行為變更必須先改這份規格 — 沒有檢查的規則不是規則，是願望。
# 執行：bash tests/scripts/test-docs-governance-check.sh（tests/test-tooling.sh 會跑）
set -u
cd "$(dirname "$0")/../.."
REPO=$PWD
CHECK="$REPO/skills/core/setup-skills/check-docs-governance.sh"
L=docs/decision-log.md

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
# case_ <locale> <want-exit> <name> <shell body> [must-mention...]
case_() {
  local loc="$1" want="$2" name="$3" root out code m; shift 3
  n=$((n + 1)); root="$tmp/c$n"; mkdir -p "$root/docs"
  (cd "$root" && eval "$1"); shift
  out=$(cd "$root" && LC_ALL="$loc" bash "$CHECK" 2>&1)
  code=$?
  verdict "$want" "$name" "$code" "$out"
  for m in "$@"; do
    printf '%s' "$out" | grep -qF -- "$m" || { printf '  ✗ 輸出沒有點名「%s」\n' "$m"; fail=1; }
  done
}

# rep <字> <次數>：重複輸出一個字（多位元組字也能用，不靠 printf 的寬度）
rep() { local i s=""; for ((i = 0; i < $2; i++)); do s="$s$1"; done; printf '%s' "$s"; }

suite() {  # suite <locale>
  local W="$1"
  case_ "$W" 0 "沒有決策日誌 → 過" ":"
  case_ "$W" 0 "同一個年月的多行 → 過" \
    "printf '2026-11-01 甲\n2026-11-23 乙\n' > $L"
  case_ "$W" 1 "兩種年月 → 擋，點名檔案與 PR-DOCS-07" \
    "printf '2026-10-31 甲\n2026-11-01 乙\n' > $L" \
    "$L" "PR-DOCS-07"
  case_ "$W" 0 "只有一個年月且早於今天 → 過（不看當天日期）" \
    "printf '2020-01-01 甲\n2020-01-02 乙\n' > $L"
  case_ "$W" 0 "300 個全形字的一行 → 過（以字元計，不以位元組計）" \
    "{ printf '2026-11-01 '; rep 字 289; printf '\n'; } > $L"
  case_ "$W" 1 "301 個字元的一行 → 擋，點名行號與 PR-DOCS-08" \
    "{ printf '2026-11-01 甲\n2026-11-02 '; rep 字 290; printf '\n'; } > $L" \
    "$L:2:" "PR-DOCS-08"
  case_ "$W" 1 "CRLF 結尾的行不多算字元 → 300 字過、301 字擋" \
    "{ printf '2026-11-01 '; rep a 289; printf '\r\n2026-11-02 '; rep a 290; printf '\r\n'; } > $L" \
    "$L:2:"
  case_ "$W" 0 "封存檔有超長行與別的年月 → 不檢查" \
    "printf '2026-11-01 甲\n' > $L && mkdir docs/decision-log && { printf '2026-09-01 '; rep 字 400; printf '\n'; } > docs/decision-log/2026-09.md"
  case_ "$W" 1 "兩條規則同時違反 → 兩條都報" \
    "{ printf '2026-10-01 '; rep 字 400; printf '\n2026-11-01 乙\n'; } > $L" \
    "PR-DOCS-07" "PR-DOCS-08"

  # --- PR-DOCS-01／14：現行文件的票號與日期 ---
  # 紅案例只放一個清單檔，其餘清單檔皆缺 → 同時驗證缺檔略過
  local f
  for f in docs/03_architecture_design.md docs/05_frontend_spec.md docs/capabilities/a.md docs/capabilities/b.md \
           docs/test-blueprint.md docs/test-status.md GLOSSARY.md docs/adr/0001-x.md docs/adr/0002-y.md; do
    case_ "$W" 1 "PR-DOCS-14 清單檔 $f 的違規 → 擋，點名檔案與行號" \
      "mkdir -p \$(dirname $f) && printf 'ok\n見 ISSUE-12 了\n' > $f" \
      "$f:2:" "PR-DOCS-01"
  done
  case_ "$W" 0 "PR-DOCS-14 docs/uat-cases.md 不掃 → 過" \
    "printf '見 ISSUE-12，2026-11-23，票 5，規格 3\n' > docs/uat-cases.md"
  case_ "$W" 0 "PR-DOCS-14 清單檔全缺 → 過" ":"
  case_ "$W" 1 "PR-DOCS-14 沒有設定檔：假的 docs-governance.json 想排除 GLOSSARY.md 仍擋" \
    "printf '{\"exclude\":[\"GLOSSARY.md\"]}' > docs-governance.json && printf 'ISSUE-1\n' > GLOSSARY.md" \
    "GLOSSARY.md:1:"
  case_ "$W" 1 "PR-DOCS-01 票 12（行中段）→ 擋" "printf '前面 票 12 後面\n' > GLOSSARY.md" "GLOSSARY.md:1:" "PR-DOCS-01"
  case_ "$W" 1 "PR-DOCS-01 規格 3 → 擋" "printf '規格 3\n' > GLOSSARY.md" "GLOSSARY.md:1:" "PR-DOCS-01"
  case_ "$W" 1 "PR-DOCS-01 ISSUE-4 → 擋" "printf 'ISSUE-4\n' > GLOSSARY.md" "GLOSSARY.md:1:" "PR-DOCS-01"
  case_ "$W" 1 "PR-DOCS-01 ISSUE-003 緊接標點 → 擋" "printf '見(ISSUE-003)。\n' > GLOSSARY.md" "GLOSSARY.md:1:"
  case_ "$W" 1 "PR-DOCS-01 YYYY-MM-DD → 擋" "printf '日期 2026-11-23\n' > GLOSSARY.md" "GLOSSARY.md:1:" "PR-DOCS-01"
  case_ "$W" 0 "PR-DOCS-01 反面案例（票後無數字、規格說明、v2.3、年月、月日）→ 過" \
    "printf '票\nISSUE-\n規格說明\nv2.3\n2026-11\n12-31\n投票 數\n' > GLOSSARY.md"
  case_ "$W" 0 "PR-DOCS-01 程式碼區塊內 → 過" \
    "printf '@@@\nISSUE-1\n2026-11-23\n@@@\n' | tr @ \\\\140 > GLOSSARY.md"
  case_ "$W" 1 "PR-DOCS-01 圍欄關閉後恢復掃描 → 擋，行號正確" \
    "printf '@@@\nISSUE-1\n@@@\n票 7\n' | tr @ \\\\140 > GLOSSARY.md" "GLOSSARY.md:4:"
  case_ "$W" 0 "PR-DOCS-01 未成對圍欄：之後的行仍在區塊內 → 過" \
    "printf '@@@\n票 7\n' | tr @ \\\\140 > GLOSSARY.md"
  case_ "$W" 0 "PR-DOCS-01 行首 | 的表格列 → 過" "printf '| ISSUE-1 | 2026-11-23 |\n' > GLOSSARY.md"
  case_ "$W" 1 "PR-DOCS-01 行內 | 但非行首 → 擋" "printf '甲 | ISSUE-1\n' > GLOSSARY.md" "GLOSSARY.md:1:"
  case_ "$W" 1 "PR-DOCS-14 同目錄多個違規檔都被點名" \
    "mkdir -p docs/adr && printf 'ISSUE-1\n' > docs/adr/0001-a.md && printf 'ISSUE-2\n' > docs/adr/0002-b.md" \
    "docs/adr/0001-a.md:1:" "docs/adr/0002-b.md:1:"
  case_ "$W" 1 "決策日誌違規與清單檔違規同時存在 → 兩邊都報" \
    "printf '2026-10-31 甲\n2026-11-01 乙\n' > $L && printf 'ISSUE-1\n' > GLOSSARY.md" \
    "PR-DOCS-07" "PR-DOCS-01"
}

for loc in C.UTF-8 C; do
  echo "[locale: $loc]"
  suite "$loc"
done

# 本 repo 自己的主檔必須通過（PR-DOCS-16：9、10 月已搬走，主檔只留當月）
echo "[本 repo]"
for loc in C.UTF-8 C; do
  out=$(LC_ALL="$loc" bash "$CHECK" 2>&1); verdict 0 "本 repo 根目錄（$loc）→ 過" $? "$out"
done

# PR-DOCS-01：ADR 不放日期行（日期歸決策日誌與 git）
if grep -n '^日期：' docs/adr/*.md >/dev/null 2>&1; then
  printf '  ✗ docs/adr/*.md 仍有「日期：」行
'; fail=1
else
  printf '  ✓ docs/adr/*.md 沒有「日期：」行
'
fi

[ $fail -eq 0 ] && echo "全部通過。"
exit $fail
