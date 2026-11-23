# 讓 PowerShell 骨架停下時印出繼續指令

## Done when

- 逐步模式按 `q` 或讀到輸入結束時，以及任何模式下 `Complete-OpsRun` 有 fail 時，都印出繼續指令，走 `Write-OpsLine`（即 `Write-Host`，與 `[PASS]` 及總表同一條），不進成功輸出串流。正常做完時不印。成功輸出串流的內容不變（PR-OPS-11、13）。
- 繼續指令的寫法：`-> <腳本名> <子命令> <原參數...> <補登參數...>`，腳本名與選單的等價指令相同。原參數裡沒有 `-Yes`，就絕不自動加上（PR-OPS-12、19）。
- hello 互動挑選後，以 `Add-OpsResumeArg` 補登 `-Pick <名稱,...>`；照繼續指令重跑，不會再進多選器（PR-OPS-20，PowerShell 部分）。
- `skills/draft/ops-script/POWERSHELL.md` 寫明三件事：每個步驟都必須可重跑；耗時或不可重做的步驟先查狀態，已完成就 `Write-OpsSkip`；步驟說明選填、1–3 行。另外寫明 `Add-OpsResumeArg` 的用法（PR-OPS-14，PowerShell 部分）。
- `scripts/manage.ps1` 的 ops-lib 區段仍與骨架逐字相同。`tests/scripts/test-ops-script-skeleton-ps.sh` 對上列每一條都有斷言，5.1 與 7 都跑過；`bash scripts/check.sh` 通過（PR-OPS-16、17，PowerShell 部分）。

## Context

規格見 `docs/issues/ISSUE-001-ops-script-step-mode.md`，**繼續指令**的定義見 `GLOSSARY.md`。這張票是 ISSUE-003 的 PowerShell 版，建立在 ISSUE-004 的 `-Step` 之上。

## Blocked by

Blocked by: ISSUE-004-powershell-step-mode.md

## Notes

- **原參數的來源**：原參數來自腳本層繫結的參數，不是 `$args`。要把子命令名與 `$PSBoundParameters` 依序還原成命令列，switch 參數只印名稱，陣列參數以逗號接起。
- **PR-OPS-11 的「stderr」在 PowerShell 的對應**：PowerShell 骨架的診斷輸出全走 `Write-Host`，沒有一條走 stderr。繼續指令跟著走同一條，原則是不污染成功輸出串流。不要為它改用 `[Console]::Error`，否則只有這一行與其他輸出分流。
- **不做 `--from`**：理由見 decision-log 2026-11-23。互動中按過的確認，重跑時要再確認一次。
