# 現行文件只寫現況：分類範本與 CI 檢查

驗收議題：#112（PR 以 `Refs #112` 引用，不自動關閉）

## Why
代理讀現行文件，要的是專案此刻的狀態。文件裡混進票號、日期、「理由見決策紀錄 <日期>」這類東西，代理就會把過時的線索當成現況。現在這條規則只寫在 CLAUDE.md 的文字裡，全靠代理自己記得。這次要讓分類有一個唯一的家，再由 CI 擋下最窄、最確定的那幾種違規。

## Scope
- setup-skills 旁新增分類範本，每次執行都原封不動帶進目標專案的 `docs/agents/domain.md`。
- 新增一條 CI 檢查（一支腳本加一個 workflow），由 setup-skills 安裝。
- 本 repo 的靜態不變量和行為測試。
- 本 repo 自己安裝這條檢查並修綠。

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

## Success indicators
- 誤報數 ≤ 真違規數；在兩個採用專案導入這條檢查後量測。達不到就停損：降回只留範本、不擋 CI。已複製進驗收議題 #112。

## Out of scope
- 「曾經」類敘述與教訓的偵測：機器誤報太多；交給誰列為發現，記在 GLOSSARY 的未決問題。
- 中文日期：代理寫的文件裡幾乎不出現，模式越窄越好。
- 掃 `CLAUDE.md`／`AGENTS.md`：內容歸使用者，不是 setup-skills 產生的檔。
- 本 repo 補裝 `truth-map-check`：另一個漂移，另案處理。
- 掃描清單可設定、baseline 檔：比照真相地圖檢查寫死；baseline 對單一維護者是過度設計。

## Decisions
- 承諾 ID 豁免、「規格號」一詞拿掉 — 不採「擋規格號」：承諾 ID 本來就該住在現行文件裡。
- 現行文件不引用決策日誌的日期 — 不採為日誌加錨點 ID 或豁免固定句型：前者多一套編號，後者多一個特例。
- 只豁免 code，不豁免表格 — 不採種子文件的表格豁免：表格容易藏遷移對照。
- 規則單獨放一份範本，比照 `capability-shape.md` — 不採散寫在各技能裡：會各改各的。
- 檢查掛在 Section B，不掛 G — 不採綁在 `docs/capabilities/` 上：GLOSSARY 和 ADR 幾乎每個專案都有。
- 直接改 core — 不採 draft：這是 core 技能的增量，靠本 repo 先跑綠和窄模式控制風險。
- 不寫 ADR：都可逆；理由見 `docs/decision-log.md`。

## Open questions
- 哪些技能要加一行指向 `domain.md` 的分類小節（種子文件寫「所有讀寫文件的技能都指向那裡」，但沒列名單）。由 `/to-tickets` 用 grep 找出會寫這七項的技能，交使用者核可。
