#!/usr/bin/env bash
# 行為測試：hook、安裝器、setup-skills 模板與 ops-script 骨架。編號與 check.sh 共用，
# [8]、[11]、[25]–[28] 住這裡；check.sh 只放靜態不變量（[20] 強制）。
# 這些測試慢，不進 Stop hook，由 CI 跑；本機改了受測檔案（hooks/、scripts/、
# setup-skills 模板、ops-script 骨架）就手動跑一次 — 在 Linux（Windows 上用 WSL）跑，不用 Git Bash；
# 本機跑不了就交給 CI。
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "  ✗ $*"; fail=1; }

echo "[8] hooks/ 每支 hook 在 tests/hooks/ 都有對應測試且跑綠；hook 寫 log 用 >>，不用 tee"
for h in hooks/*.sh; do
  b=$(basename "$h")
  case "$b" in test-*) continue ;; esac
  t="tests/hooks/test-$b"
  if [ ! -f "$t" ]; then err "$b 沒有對應測試 $t — 沒有檢查的 hook 會靜默腐爛"; continue; fi
  bash "$t" >/dev/null 2>&1 || err "$t 未過 — 跑 bash $t 看細節"
done
grep -lE '\btee\b' hooks/*.sh >/dev/null 2>&1 && err "hook 用 tee 寫 log 會把訊息漏進 stdout — 改用 >>：$(grep -lE '\btee\b' hooks/*.sh | tr '\n' ' ')"

echo "[11] 安裝器的安裝、移除、檢查：拒絕已移除的目標，且不覆寫、不刪外來同名技能"
# 這裡只測 manage.sh；manage.ps1 的測試在 Windows 跑（pwsh -File tests/scripts/test-manage.ps1，CI 的 Windows job）。
bash tests/scripts/test-manage.sh >/dev/null 2>&1 || err "tests/scripts/test-manage.sh 未過 — 跑 bash tests/scripts/test-manage.sh 看細節"

run_test() {  # run_test <腳本名>：輸出丟掉，失敗時指路
  bash "tests/scripts/$1.sh" >/dev/null 2>&1 || err "tests/scripts/$1.sh 未過 — 跑 bash tests/scripts/$1.sh 看細節"
}

echo "[25] setup-skills 的議題檢查模板（[12] 的行為測試）"
run_test test-issues-check

echo "[26] setup-skills 的真相地圖檢查模板（[13] 的行為測試）"
run_test test-truth-map-check

echo "[27] ops-script bash 骨架：CLI 與 LIB 兩個接縫的行為、語法、結構"
run_test test-ops-script-skeleton

# ubuntu 只有 pwsh；Windows PowerShell 5.1 由 Windows job 跑到，缺哪個版本會在細節輸出明說
echo "[28] ops-script PowerShell 骨架：BOM、STATIC／CLI／LIB 三個接縫（5.1 與 7 各跑）"
if command -v pwsh >/dev/null 2>&1; then
  run_test test-ops-script-skeleton-ps
else
  echo "  - 找不到 pwsh，略過 PowerShell 骨架測試（CI 的 ubuntu 與 Windows job 都會跑）"
fi

echo
if [ $fail -eq 0 ]; then echo "全部通過。"; else echo "檢查未通過，見上列 ✗。"; fi
exit $fail
