# 讓 /setup-skills 把分類範本與 current-docs 檢查裝進目標專案

## Done when
- `skills/core/setup-skills/docs-classification.md` 存在，以 `## 現行文件與歷史文件` 為標題，內容涵蓋 PR-DOCS-01、02，用繁體中文寫（它是目標專案的內容）。
- `SKILL.md` 寫明以下行為，`SKILL.md` 仍不超過 150 行：
  - 每次執行都把它原封不動寫成 `docs/agents/domain.md` 的一個小節。
  - 重跑時內容不同，就顯示差異（PR-DOCS-03）。
- `CHECKS.md` 新增一節，掛在 Section B 之下，寫明以下行為（PR-DOCS-08、09）：
  - 提議把腳本與 workflow 原封不動複製進去。
  - 複本與來源不同時顯示差異。
  - 安裝後列出紅燈清單。
  - 重跑時自動刪掉 ADR 的 `日期：` 行，其餘紅燈在同一變更裡修綠，不寫 baseline。
- `scripts/check.sh` [30] 擴充：
  - 範本存在。
  - `SKILL.md` 在同一行把 `docs-classification.md` 寫進 `docs/agents/domain.md`。
  - `SKILL.md` 或 `CHECKS.md` 提到腳本。
  - setup-skills 以外的技能出現範本的標題句，或深連結到 `docs-classification.md`，都報紅（PR-DOCS-04、10）。
- 本 repo 的 `docs/agents/domain.md` 帶有這個小節，內容與範本完全一致。
- `bash scripts/check.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-current-docs-only.md`。同構的先例是 `skills/core/setup-skills/capability-shape.md` 與 `scripts/check.sh` [14]。

## Blocked by
Blocked by: ISSUE-002-current-docs-check-tracer.md

## Notes
- 改技能前，必須先載入 `/writing-for-agents`。
- 範本不得出現 ISO 日期，否則會被自己的檢查打紅。
