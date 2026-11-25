# 現行文件

持久文件分成現行文件與歷史文件兩類；`/setup-skills` 把分類範本寫進目標專案的 `docs/agents/domain.md`，寫現行文件的技能從那裡讀。範本是指引，不由 CI 強制，也不強迫既有文件遷移。服務對象是維護這套技能的人，與使用這些技能的專案維護者。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-DOCS-01 — `skills/core/setup-skills/docs-classification.md` 把持久文件分成兩類：**現行文件**（`GLOSSARY.md`、ADR、capability 檔、架構與前端合訂本、測試藍圖、測試狀態、`CLAUDE.md`／`AGENTS.md`）與**歷史文件**（決策日誌、git 歷史），每份只屬一類；並註明本機議題、驗收案例、研究報告不在分類內。
PR-DOCS-02 — 範本寫明現行文件不寫票號、議題編號、工作日期、遷移紀錄、教訓與「曾經 X 後改 Y」，也不以決策日誌的日期交代理由（理由值得留就寫 ADR）；ADR 不帶日期行；**承諾** ID 與產品版本號不算歷史。
PR-DOCS-03 — `/setup-skills` 每次執行都把範本原封不動寫成 `docs/agents/domain.md` 的一個小節；重跑時內容不同，就顯示差異並提議更新。
PR-DOCS-04 — setup-skills 以外的技能重述範本內容時，`check.sh` 報紅。
PR-DOCS-05 — retired：分類不由 CI 檢查強制。
PR-DOCS-06 — retired：分類不由 CI 檢查強制。
PR-DOCS-07 — retired：分類不由 CI 檢查強制。
PR-DOCS-08 — retired：`/setup-skills` 不安裝現行文件的 CI 檢查。
PR-DOCS-09 — retired：`/setup-skills` 不強迫既有文件遷移。
PR-DOCS-10 — retired：由 PR-DOCS-14 取代。
PR-DOCS-11 — retired：分類不由 CI 檢查強制。
PR-DOCS-12 — retired：本 repo 不安裝現行文件的 CI 檢查。
PR-DOCS-13 — `bash scripts/check.sh` 通過。
PR-DOCS-14 — `check.sh` 檢查：範本存在且內容完整；setup-skills 的 `SKILL.md` 在同一行把範本寫進 `docs/agents/domain.md`；`SKILL.md` 仍不超過 150 行；本 repo 的 `docs/agents/domain.md` 帶有範本全文。

## 驗證

- `bash scripts/check.sh` [30]：PR-DOCS-04、14；PR-DOCS-01、02 只擋關鍵字與標記句，語意靠 review。`SKILL.md` 的 150 行上限由 [14] 擋。
- `bash scripts/check.sh` 整體通過：PR-DOCS-13。
- PR-DOCS-03 是技能執行期行為，沒有機械檢查。
