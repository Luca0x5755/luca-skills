# 現行文件規則只有一個家，各技能都指向它

## Done when
- `skills/core/setup-skills/` 旁有一份範本，寫著**現行文件**與**歷史文件**的分類，以及現行文件的內容規則：不寫票號、工作日期、遷移紀錄、教訓或「曾經 X 後改 Y」，這些歸決策日誌、commit 或 ADR；產品版本號不在此限（PR-DOCS-04）。
- `/setup-skills` 每次執行都把這份範本逐字複製進目標專案的 `docs/agents/domain.md`，成為一節；內容不同時顯示 diff 並提議更新（PR-DOCS-13）。
- `to-architecture`、`frontend-spec`、`test-blueprint`、`domain-modeling`、`audit-truth` 都指向 `docs/agents/domain.md` 的那一節，不重述規則。
- `audit-truth` 把現行文件中的「教訓／曾經」類敘述列為發現（PR-DOCS-05）。
- `scripts/check.sh` 強制只有一個家：範本存在、`setup-skills` 指示複製它、其他技能沒有重述範本內容（PR-DOCS-11 的一個家部分，比照 [14]）。
- 技能文字不提及促成這次改動的參考專案（PR-DOCS-12）。
- `bash scripts/check.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-docs-governance.md`（PR-DOCS-04、05、11、12、13）。GLOSSARY 已定義**現行文件**、**歷史文件**。做法比照 capability 檔形狀：`skills/core/setup-skills/capability-shape.md` 與 `check.sh` [14]。

## Blocked by
ISSUE-002-decision-log-rotation-tracer.md

## Notes
- 改任何技能前，先載入 `/writing-for-agents`（CLAUDE.md）。技能的 `description` 用繁體中文，內文用英文；範本是目標專案的內容，用繁體中文。
- `audit-truth` 在 `skills/draft/`，不在 `core/`。
- 和 ISSUE-002 都會改 `domain-modeling/SKILL.md`，所以排在它後面。
- `setup-skills/SKILL.md` 不得超過 150 行（`check.sh` [14]），細節放進參考檔。
