# 統一 Bash 與 PowerShell 安裝選單

## Why
兩支安裝器的無參數行為不同，PowerShell 使用逗號多選。
統一操作方式，讓使用者以空白分隔編號選擇代理。

## Scope
更新 scripts/install.sh、scripts/install.ps1、
既有安裝測試與 README 安裝說明。

## Promises
PR-INSTALL-01 — 兩支腳本無參數時顯示相同代理順序：1 claude、2 copilot、3 codex。
PR-INSTALL-02 — 接受空白分隔的多個編號，例如 1 3；重複編號只安裝一次。
PR-INSTALL-03 — 選定後顯示所選代理並直接安裝，不再要求 y 確認。
PR-INSTALL-04 — 空白輸入、逗號輸入及越界等無效編號提示錯誤後重問；Ctrl+C 取消。
PR-INSTALL-05 — 保留代理名稱參數直接安裝，供自動化使用。
PR-INSTALL-06 — 保留外來同名技能保護、代理間獨立安裝與 Git Bash/MSYS 防護。

## Out of scope
不變更技能來源、目的目錄、連結類型或安裝保護規則。

## Decisions
保留名稱參數；採空白多選；取消第二次確認；
無效輸入重問。裁決見 docs/decision-log.md。

## Open questions
無。

Blocked by: none
