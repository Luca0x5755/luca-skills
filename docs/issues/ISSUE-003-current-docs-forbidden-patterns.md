# 現行文件裡的票號與日期由檢查擋下

## Done when
- 文件治理檢查掃描固定清單：`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/capabilities/*.md`、`docs/test-blueprint.md`、`docs/test-status.md`、`GLOSSARY.md`、`docs/adr/*.md`；不存在的檔案略過、不報紅；沒有設定檔；`docs/uat-cases.md` 不掃（PR-DOCS-14）。
- 清單中的檔案在程式碼區塊與表格之外出現 `票 \d+`、`規格 \d+`、`ISSUE-\d+` 或 `YYYY-MM-DD` 時報紅，標明檔案與行號；`v2.3` 這類產品版本號通過（PR-DOCS-01）。
- 測試對 PR-DOCS-01、14 各有紅、綠案例，涵蓋程式碼區塊與表格的豁免、缺檔略過，在兩種 locale 下都要跑。
- 本 repo 的 ADR 拿掉「日期：」行（0003、0004、0005），本 repo 跑這支檢查是綠的。
- `bash scripts/check.sh` 與 `bash tests/test-tooling.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-docs-governance.md`（PR-DOCS-01、14）。腳本、workflow 與測試檔由 ISSUE-002 建立，這張往同一支腳本加規則。

## Blocked by
ISSUE-002-decision-log-rotation-tracer.md

## Notes
- ADR 的日期行是用移除來處理，不在檢查裡加豁免（decision-log 2026-11-23）。`取代：0002` 不是票號格式，可以保留。
- 「教訓／曾經」類用詞不進機械檢查，那是 ISSUE-005 交給 `/audit-truth` 的。
- 表格的判斷以行首 `|` 為準；程式碼區塊以 ``` 圍欄為準，圍欄要成對計算。
