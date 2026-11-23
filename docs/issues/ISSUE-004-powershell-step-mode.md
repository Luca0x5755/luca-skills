# 讓 PowerShell 骨架以 `-Step` 逐步執行 hello

## Done when

- 在終端機中執行 `skeleton.ps1 hello -Step`：每個 `Write-OpsStep` 前印 `== 步驟 N：<標題>` 與說明行，然後停下。停點的 Enter、`a`、`q`、讀到輸入結束、無效輸入重問、無跳過、無總覽，行為都與 bash 版相同（PR-OPS-01、02、04、05）。
- 不帶 `-Step` 時說明行不印，輸出與結束碼都與 v7 相同（PR-OPS-03）。
- 帶 `-Step` 卻沒有終端機時，結束碼 2，訊息點名拿掉 `-Step`，什麼都不做（PR-OPS-06）。
- `-Step` 可與 `-WhatIf`、`-Yes` 並用；確認仍走 `Confirm-Ops`，Enter 停點的 `y` 不算確認（PR-OPS-07、08）。
- 停點由 ops-lib 自寫，不使用 `ShouldProcess`、`-Confirm`、`Set-PSDebug`（PR-OPS-10）。
- 只帶 `-Step`、沒有子命令時，在終端機中進選單，等價指令印成 `-> <腳本名> <子命令> -Step`（PR-OPS-09、18）。
- hello 至少一個步驟帶說明行，可以用 `-Step` 跑完（PR-OPS-15，PowerShell 部分）。
- `skeleton.ps1` 的區段標 `BEGIN ops-lib v8`，`scripts/manage.ps1` 的區段與它逐字相同（PR-OPS-16，PowerShell 部分）。
- `tests/scripts/test-ops-script-skeleton-ps.sh` 對上列每一條都有斷言，5.1 與 7 都跑過；`bash scripts/check.sh` 通過（PR-OPS-17，PowerShell 部分）。

## Context

規格是 `docs/issues/ISSUE-001-ops-script-step-mode.md`，PowerShell 的寫法規則見 `skills/draft/ops-script/POWERSHELL.md`。這張票做的是 ISSUE-002 的 PowerShell 版，兩者沒有程式碼依賴，可以平行做；bash 版先落地的話，就以它的行為當對照。

## Blocked by

Blocked by: none

## Notes

- **參數繫結**：PowerShell 的參數在腳本層的 `param()` 繫結，`-Step` 也跟著加在那裡。主流程啟動時把它存進 `$script:` 變數，比照 `$script:HasPick`，因為函式讀不到腳本的 `$PSBoundParameters`。`Invoke-Main` 在 `$Command` 為空、`-Step` 為真時進選單。
- **為什麼不用 `ShouldProcess`**：實測在 `-NonInteractive` 下，`ShouldProcess` 每一步都丟錯，腳本卻繼續跑，最後結束碼還是 0（decision-log 2026-11-23）。
- **逐字比對**：`tests/scripts/test-manage.ps1` 逐字比對 `manage.ps1` 與骨架的 ops-lib 區段，兩邊要同步。`manage.ps1` 不加 `-Step`。
- **測試接縫**：沒有 pty 可用。在 LIB 接縫 dot-source 之後，重新定義 `Test-OpsTty` 再餵 stdin。斷言一律比對 ASCII，因為 5.1 透過管線輸出時用 OEM 碼頁；要斷言中文，就照現有的選單行檢查做法，以 UTF-8 寫檔再讀。
- **檔案維持 UTF-8 BOM**：5.1 需要 BOM，STATIC 接縫會檢查。
