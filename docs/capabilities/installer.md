# 安裝器

兩平台的操作方式與安裝目的目錄見 [README 安裝說明](../../README.md#安裝)。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-INSTALL-01 — 兩支腳本無參數時顯示相同代理順序：1 claude、2 copilot、3 codex。
PR-INSTALL-02 — 接受空白分隔的多個編號，例如 1 3；重複編號只安裝一次。
PR-INSTALL-03 — 選定後顯示所選代理並直接安裝，不再要求 y 確認。
PR-INSTALL-04 — 空白輸入、逗號輸入及越界等無效編號提示錯誤後重問；Ctrl+C 取消。
PR-INSTALL-05 — 保留代理名稱參數直接安裝，供自動化使用。
PR-INSTALL-06 — 保留外來同名技能保護、代理間獨立安裝與 Git Bash/MSYS 防護。

## 驗證

- `scripts/test-install.sh`：Bash 入口、實際 symlink 與保護行為。
- `scripts/test-install.ps1`：PowerShell 入口；Windows 上驗證實際 Junction 與保護行為。
