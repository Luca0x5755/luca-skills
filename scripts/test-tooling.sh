#!/usr/bin/env bash
# 工具測試：hook 與安裝器的行為測試。編號與 check.sh 共用，[8]、[11] 住這裡。
# 受測檔案（hooks/、scripts/）不在 Stop hook 的監看範圍，所以只由 CI 跑；本機改了這些檔案就手動跑一次。
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "  ✗ $*"; fail=1; }

echo "[8] hooks/ 每支 hook 都有對應測試且跑綠；hook 寫 log 用 >>，不用 tee"
for h in hooks/*.sh; do
  b=$(basename "$h")
  case "$b" in test-*) continue ;; esac
  t="hooks/test-$b"
  if [ ! -f "$t" ]; then err "$b 沒有對應測試 $t — 沒有檢查的 hook 會靜默腐爛"; continue; fi
  bash "$t" >/dev/null 2>&1 || err "$t 未過 — 跑 bash $t 看細節"
done
grep -lE '\btee\b' hooks/*.sh >/dev/null 2>&1 && err "hook 用 tee 寫 log 會把訊息漏進 stdout — 改用 >>：$(grep -lE '\btee\b' hooks/*.sh | tr '\n' ' ')"

echo "[11] 安裝器拒絕已移除的目標，且不覆寫外來同名技能"
# 各平台只測自己的安裝器：install.sh 刻意拒絕 Git Bash，install.ps1 只服務 Windows。
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v pwsh >/dev/null 2>&1; then
      pwsh -NoProfile -File scripts/test-install.ps1 >/dev/null 2>&1 || err "scripts/test-install.ps1 未過 — 跑 pwsh -NoProfile -File scripts/test-install.ps1 看細節"
    else
      echo "  - 找不到 pwsh，略過 Windows 安裝器測試（CI 另於 Windows 執行）"
    fi ;;
  *) bash scripts/test-install.sh >/dev/null 2>&1 || err "scripts/test-install.sh 未過 — 跑 bash scripts/test-install.sh 看細節" ;;
esac

echo
if [ $fail -eq 0 ]; then echo "全部通過。"; else echo "檢查未通過，見上列 ✗。"; fi
exit $fail
