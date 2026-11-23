#!/usr/bin/env bash
# check-docs-governance.sh 的回歸規格（PR-DOCS-07、08）。每個案例在暫存目錄搭假專案，
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

[ $fail -eq 0 ] && echo "全部通過。"
exit $fail
