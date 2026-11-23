# 合訂本與 test 文件的節上限和第一行讀法由檢查擋下

## Done when
- 掃描清單中的任何最小一節（沒有子標題的那一層，從標題行到下一個標題行）超過 40 KB 時報紅，標明標題與大小；表格與程式碼區塊照算（PR-DOCS-02）。
- `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md` 存在時，第一行必須是讀法引言：不要整份讀，先查 capability 檔的 `## 規格章節`，grep 標題行號，只讀那一段。缺少時報紅；只驗證這一行存在。capability 檔不需要這一行（PR-DOCS-03）。
- 讀法引言的標準文字只定義在一個地方（腳本或它的範本），ISSUE-006 補行時用的就是同一段文字。
- 測試對 PR-DOCS-02、03 各有紅、綠案例（含剛好 40 KB 的邊界），在兩種 locale 下都要跑。
- `bash scripts/check.sh` 與 `bash tests/test-tooling.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-docs-governance.md`（PR-DOCS-02、03）。決策：`docs/adr/0004-consolidated-volumes-stay-single-files-read-by-section.md`。往 ISSUE-002 建立的腳本加規則。

## Blocked by
ISSUE-003-current-docs-forbidden-patterns.md

## Notes
- 和 ISSUE-003 改的是同一支腳本與同一份測試檔，所以排在它後面。
- 40 KB 以位元組計（40,960），是讀取成本的上限；這和 ISSUE-002 以字元計的行長是兩回事。
- capability 檔不要求讀法，因為讀法本身要代理「先查 capability 檔」，套在它身上會循環（decision-log 2026-11-23）。
