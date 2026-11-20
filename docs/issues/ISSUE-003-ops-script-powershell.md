# 為 `/ops-script` 加上 PowerShell 骨架與規則

## Done when

- `skills/draft/ops-script/skeleton.ps1` 存在，編碼為 UTF-8 with BOM（前 3 個 byte 為 `EF BB BF`）。
- 結構與 bash 版一致：
  - comment-based help，`Get-Help` 讀得到。
  - `param` 區塊以 `ValidateSet` 限定子命令。
  - `[CmdletBinding(SupportsShouldProcess)]` 提供 `-WhatIf`。
  - 共用段以 `# ---- BEGIN ops-lib v2 ----` / `# ---- END ops-lib ----` 框住，函式組與 bash v2 一一對應：自寫 `[y/N]` 確認（預設 No）、錯誤輸出（標題＋怎麼修）、`NO_COLOR` 判斷、`step`、結果總表、多選器。
  - `$ErrorActionPreference = 'Stop'`；外部程式另外檢查 `$LASTEXITCODE`。
  - 測試模式（`SKELETON_LIB=1` 或等效參數）只定義函式、不跑主流程。
- 在 Windows PowerShell 5.1 與 PowerShell 7 都通過：語法解析器零錯誤、`-WhatIf` 不做事、stdin 被重導且沒給子命令時回 2。
- `SKILL.md`（或拆出的 `POWERSHELL.md`）寫清楚：BOM 必要、同時支援 5.1 與 7、確認自寫且預設 No（內建確認按 Enter 即執行）、`-WhatIf` 走 `SupportsShouldProcess`、`Write-Host` 為何允許用在操作者介面以及如何抑制 PSScriptAnalyzer 對應規則並註明理由、`$LASTEXITCODE` 檢查。
- `bash scripts/check.sh` 全綠。

## Context

ISSUE-002 完成後的 bash `ops-lib v2` 是要對照的 API。PowerShell 規則的理由見 `docs/decision-log.md` 2026-11-20 關於 PowerShell 的那一行。

## Blocked by

Blocked by: ISSUE-002-ops-script-bash-full.md

## Notes

- Write 工具寫出的檔案沒有 BOM；寫完要補上 BOM 並以 byte 檢查驗證。
- 互動輸入在 5.1 與 7 行為不同：以 `[Console]::IsInputRedirected` 判斷無終端機，不要靠 `Read-Host` 失敗來偵測。
- 不得出現任何實際專案、服務或外部專案的名稱。
