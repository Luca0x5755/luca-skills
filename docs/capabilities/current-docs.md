# 現行文件

持久文件分成現行文件與歷史文件兩類；`/setup-skills` 把分類範本寫進目標專案的 `docs/agents/domain.md`，寫現行文件的技能從那裡讀，並由安裝到目標專案的檢查腳本擋下票號、議題編號與日期。服務對象是維護這套技能的人，與使用這些技能的專案維護者。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-DOCS-01 — `skills/core/setup-skills/docs-classification.md` 把持久文件分成兩類：**現行文件**（`GLOSSARY.md`、ADR、capability 檔、架構與前端合訂本、測試藍圖、測試狀態、`CLAUDE.md`／`AGENTS.md`）與**歷史文件**（決策日誌、git 歷史），每份只屬一類；並註明本機議題、驗收案例、研究報告不在分類內。
PR-DOCS-02 — 範本寫明現行文件不寫票號、議題編號、工作日期、遷移紀錄、教訓與「曾經 X 後改 Y」，也不以決策日誌的日期交代理由（理由值得留就寫 ADR）；ADR 不帶日期行；**承諾** ID 與產品版本號不算歷史。
PR-DOCS-03 — `/setup-skills` 每次執行都把範本原封不動寫成 `docs/agents/domain.md` 的一個小節；重跑時內容不同，就顯示差異並提議更新。
PR-DOCS-04 — setup-skills 以外的技能重述範本內容時，`check.sh` 報紅。
PR-DOCS-05 — `check-current-docs.sh` 只掃寫死的七項：`GLOSSARY.md`、`docs/adr/*.md`、`docs/capabilities/*.md`、`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md`；不存在的略過，沒有設定可調。
PR-DOCS-06 — 在 fenced code 與行內 code 之外，出現 `ISSUE-\d+`、前一字元不是英數字的 `#\d+`、或 ISO 日期 `\d{4}-\d{2}-\d{2}` 時，每處印出 `檔案:行號`，結束碼非零；表格不豁免。
PR-DOCS-07 — 承諾 ID（如 `PR-INSTALL-01`）、產品版本號（如 `v1.2.3`）、中文日期、`page#12` 這類前面接英數字的 `#`，以及 code 內的任何內容，都不報紅。
PR-DOCS-08 — `/setup-skills` 在 Section B 寫了 domain docs 時，提議把 `current-docs-check.yml` 與 `check-current-docs.sh` 原封不動複製到 `.github/workflows/`、`.github/scripts/`；複本與來源不同時顯示差異並提議更新；安裝後跑一次，把紅燈清單列進報告。
PR-DOCS-09 — 既有專案重跑 `/setup-skills` 時，自動刪掉 `docs/adr/*.md` 的 `日期：` 行；其餘紅燈由代理在同一個變更裡修綠、交使用者審查；不寫 baseline 檔。
PR-DOCS-10 — `check.sh` 檢查：範本、腳本、workflow 三個檔都在；setup-skills 的 `SKILL.md` 或 `CHECKS.md` 有提到它們；workflow 有呼叫腳本；`SKILL.md` 仍不超過 150 行。
PR-DOCS-11 — `tests/scripts/test-current-docs-check.sh` 涵蓋 PR-DOCS-05～07，並由 `tests/test-tooling.sh` 呼叫。
PR-DOCS-12 — 本 repo 安裝 `current-docs-check`，且 `bash .github/scripts/check-current-docs.sh` 通過：三份 ADR 沒有日期行，capability 檔不再以決策日誌日期交代理由。
PR-DOCS-13 — `bash scripts/check.sh` 通過。

## 驗證

- `bash tests/scripts/test-current-docs-check.sh`（CI 由 `tests/test-tooling.sh` [31] 跑）：PR-DOCS-05、06、07；PR-DOCS-11 另由 `scripts/check.sh` [20] 確認測試被接上。
- `bash scripts/check.sh` [30]：PR-DOCS-04、10；PR-DOCS-01、02 只擋關鍵字與標記句，語意靠 review。
- `bash scripts/check.sh` 整體通過：PR-DOCS-13。
- `bash .github/scripts/check-current-docs.sh`（CI 由 workflow 跑）：PR-DOCS-12。
- PR-DOCS-03、08、09 是技能執行期行為，沒有機械檢查。
