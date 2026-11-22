# 安裝器

兩平台的操作方式與安裝目的目錄見 [README 安裝說明](../../README.md#安裝)。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-INSTALL-01 — 兩支腳本無參數且有終端機時，先選動作（install、uninstall、status），再以相同的代理順序選代理：1 claude、2 copilot、3 codex。
PR-INSTALL-02 — 接受空白分隔的多個編號，例如 1 3；重複編號只處理一次。
PR-INSTALL-03 — install 選定後顯示所選代理並直接安裝，不再要求 y 確認。
PR-INSTALL-04 — 空白輸入、逗號輸入及越界等無效編號提示錯誤後重問；Ctrl+C 或輸入結束取消，結束碼 1。
PR-INSTALL-05 — 保留代理名稱參數直接安裝，供自動化使用：`manage <代理>` 等同 `manage install <代理>`。
PR-INSTALL-06 — 保留外來同名技能保護、代理間獨立安裝與 Git Bash/MSYS 防護；MSYS 防護涵蓋 install、uninstall、status，只放行 --help。
PR-INSTALL-07 — uninstall 只移除本 repo 建立的連結（含斷鏈與過期連結）；外來同名技能與非連結的資料夾不動，並列為略過；技能目錄本身保留。
PR-INSTALL-08 — uninstall 互動時確認一次，預設不移除；沒有終端機必須帶 -y（PowerShell 為 -Yes），否則結束碼 2 且不移除。
PR-INSTALL-09 — install 與 uninstall 支援預演（--dry-run／-WhatIf）：只印將執行的指令，不改動任何檔案。
PR-INSTALL-10 — install 結束前移除本 repo 建立、但名字已不在 core/、draft/ 的過期連結；外來連結與一般資料夾不動。
PR-INSTALL-11 — status 唯讀：分別列出缺少、斷鏈、同名衝突、過期連結；全部正常結束碼 0，否則 1。
PR-INSTALL-12 — 沒有子命令又沒有終端機、缺代理、未知代理、未知選項，一律印用法並結束碼 2（PowerShell 的未知子命令由參數繫結擋下，結束碼 1）。

## 驗證

- `tests/scripts/test-manage.sh`：Bash 入口、實際 symlink 與保護行為；互動入口靠測試接縫 `MANAGE_LIB=1` 覆寫 `_is_tty` 模擬終端機。Git Bash 依設計拒絕執行，要在 Linux／macOS／WSL 跑。
- `tests/scripts/test-manage.ps1`：PowerShell 入口；Windows 上驗證實際 Junction 與保護行為，`MANAGE_TEST_SHELL=powershell.exe` 改以 Windows PowerShell 5.1 驗證。
