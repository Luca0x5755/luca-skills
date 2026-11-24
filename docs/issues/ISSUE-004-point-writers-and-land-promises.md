# 讓寫現行文件的技能指向分類小節，並把承諾移入真相層

## Done when
- 以下 6 個技能各加一行，指向目標專案 `docs/agents/domain.md` 的 `## 現行文件與歷史文件`，不重述內容：`domain-modeling`、`to-architecture`、`frontend-spec`、`test-blueprint`、`implement`、`bootstrap-truth`。
- `scripts/check.sh` [15]、[16]、[18] 仍然是綠的。
- 新增 `docs/capabilities/current-docs.md`：
  - `## Promises` 收錄 PR-DOCS-01～13。
  - 形狀依 `docs/agents/domain.md`。
- `git rm docs/issues/ISSUE-001-current-docs-only.md`。
- `bash scripts/check.sh` 與 `bash .github/scripts/check-current-docs.sh` 都通過。

## Context
規格：`docs/issues/ISSUE-001-current-docs-only.md`。名單來自 grep 七項檔名、只留會寫的技能，已由使用者核可。

## Blocked by
Blocked by: ISSUE-003-setup-skills-installs-classification.md

## Notes
- 必須先載入 `/writing-for-agents`。
- `domain-modeling` 是模型觸發的技能，可能在沒有跑過 setup-skills 的專案裡被叫用，所以要寫成「有這個小節就先讀它」。
- 承諾文字裡的 regex 一律放在行內 code 裡，不然會被自己的檢查打紅。
