# 重跑 /setup-skills 時自動拆日誌、補讀法

## Done when
- 在已有決策日誌的目標專案重跑 `/setup-skills` 時，非當月的行依行首年月搬進 `docs/decision-log/YYYY-MM.md`，主檔只留當月，行內容逐字不改。
- `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md` 存在但缺讀法引言時，補上 ISSUE-004 定義的那一段標準文字。
- 不寫遷移腳本、不寫 baseline 檔；安裝報告列出文件治理檢查其餘仍為紅的項目（PR-DOCS-09）。
- 已經輪替過、已有讀法引言的專案，重跑時不再改動任何東西。
- `bash scripts/check.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-docs-governance.md`（PR-DOCS-09）。Section H 由 ISSUE-002 建立；讀法引言的標準文字由 ISSUE-004 定義。

## Blocked by
ISSUE-002-decision-log-rotation-tracer.md, ISSUE-004-section-cap-and-reading-guide.md

## Notes
- 「機械部分」是由技能指示代理去做，不是另寫一支遷移腳本（decision-log 2026-11-23）。
- 變紅的其餘項目由代理在同一個 PR 修綠、使用者審查；技能不替使用者自動改寫內容。
- 改技能前先載入 `/writing-for-agents`；`setup-skills/SKILL.md` 不得超過 150 行。
