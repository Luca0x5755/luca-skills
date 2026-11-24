# 文件治理

文件分**現行文件**與**歷史文件**兩類，現行文件只寫此刻狀態。規則只住 `skills/core/setup-skills/docs-classification.md`，目標專案的 `docs/agents/domain.md`〈現行文件與歷史文件〉一節是它的逐字副本。由 `/setup-skills` Section H 安裝的 `check-docs-governance.sh` 機械擋下票號、日期、超大節、缺少的讀法引言，以及決策日誌混月與過長的行。決策日誌固定路徑只放當月、按月封存（ADR 0005）；合訂本維持單檔、按節讀（ADR 0004）。
服務對象：在目標專案讀寫文件的代理，以及審查文件改動的維護者。
本檔保留已發佈規格的 promise ID；只改措辭沿用原 ID，意思改了就換新 ID。

## Promises

PR-DOCS-01 — PR-DOCS-14 清單中的檔案在程式碼區塊與表格之外出現 `票 \d+`、`規格 \d+`、`ISSUE-\d+` 或 `YYYY-MM-DD` 時，檢查報紅（error 級），並標明檔案與行號；產品版本號（例如 `v2.3`）不受此限，照常通過。
PR-DOCS-02 — PR-DOCS-14 清單中任何最小一節（沒有子標題的那一層，從標題行到下一個標題行）超過 40 KB 時，檢查報紅，並標明標題與大小；表格與程式碼區塊照算，不豁免。
PR-DOCS-03 — `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md` 存在時，第一行是讀法引言：不要整份讀，先查 capability 檔的 `## 規格章節`，grep 標題行號，只讀那一段。缺這一行時檢查報紅；檢查只驗證這一行存在，不驗證代理是否照做。
PR-DOCS-04 — 現行文件的內容規則（哪些內容不寫、歸到哪裡、產品版本號例外）寫在 `docs-classification.md`，即目標專案 `docs/agents/domain.md` 的〈現行文件與歷史文件〉一節；本檔不重述。
PR-DOCS-05 — `/audit-truth` 把現行文件中的「教訓／曾經」類敘述列為發現；這類用詞不進機械檢查。
PR-DOCS-06 — `/domain-modeling` 的決策日誌合約：路徑 `docs/decision-log.md` 固定，只放當月的行；寫入新月份的第一行前，把上個月的行搬到 `docs/decision-log/YYYY-MM.md`；封存檔搬出後不再修改。合約不寫「Single file, append-only」。
PR-DOCS-07 — `docs/decision-log.md` 裡出現兩種以上的年月時，檢查報紅；判斷只看檔案內容，不看執行當天的日期。
PR-DOCS-08 — `docs/decision-log.md` 任一行超過 300 字（以 Unicode 字元計）時，檢查報紅並標明行號；`docs/decision-log/` 下的封存檔不檢查。
PR-DOCS-09 — 在已有決策日誌的目標專案重跑 /setup-skills 時，機械地把非當月的行依年月搬進 `docs/decision-log/YYYY-MM.md`，並替 PR-DOCS-03 列名的文件補上缺少的讀法引言；不寫遷移腳本，不寫 baseline 檔；安裝報告列出其餘仍為紅的項目。
PR-DOCS-10 — 本 repo 的檢查腳本測試對 PR-DOCS-01、02、03、07、08 各有一組紅、綠案例，在 C.UTF-8 與 C 兩種 locale 下都要跑；`bash scripts/check.sh` 通過。
PR-DOCS-11 — 本 repo 的 `check.sh` 強制技能文字的措辭：`/domain-modeling` 不寫「Single file, append-only」，並寫明 PR-DOCS-06 的輪替合約；/setup-skills 安裝新檢查的模板檔都存在，且有被引用。
PR-DOCS-12 — 技能文字、GLOSSARY、decision-log 與 commit 訊息不提及促成文件治理規則的參考專案，也不取它的內容或數字當範例。
PR-DOCS-13 — 現行文件與歷史文件的分類、PR-DOCS-04 的內容規則，只住在 /setup-skills 旁的一份範本；/setup-skills 每次執行都把它逐字複製進目標專案的 `docs/agents/domain.md`，成為一節，內容不同就顯示 diff 並提議更新。`to-architecture`、`frontend-spec`、`test-blueprint`、`domain-modeling`、`audit-truth` 都指向那一節，不重述規則；本 repo 的 `check.sh` 對重述報紅。
PR-DOCS-14 — 文件治理檢查的掃描清單固定為 `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/capabilities/*.md`、`docs/test-blueprint.md`、`docs/test-status.md`、`GLOSSARY.md`、`docs/adr/*.md`；不存在的檔案略過、不報紅；沒有設定檔；`docs/uat-cases.md` 不在清單內。
PR-DOCS-15 — /setup-skills 有 Section H「文件治理檢查」：目標專案有 `docs/` 就提議；逐字複製獨立的檢查腳本與 workflow，不併進 `check-truth-map.sh`；安裝後告知使用者，要在 branch protection 把它設為 required，才會擋合併。
PR-DOCS-16 — 本 repo 的決策日誌主檔只留當月，9 月、10 月的行在 `docs/decision-log/2026-09.md`、`docs/decision-log/2026-10.md`；本 repo 照 Section H 裝上文件治理檢查，CI 會跑。
PR-DOCS-17 — 大型現行文件的讀寫規則住在 PR-DOCS-13 的同一份範本：按節讀；新建或動到第一行不是讀法引言的檔案時，從已安裝的檢查腳本讀出 PR-DOCS-03 的引言寫入，腳本不在就不寫並回報 Section H 未裝。`to-architecture`、`frontend-spec`、`test-blueprint`、`bootstrap-truth` 只指向該段，不重述。
PR-DOCS-18 — 同一份範本規定：這次動到而超過 PR-DOCS-02 上限的最小一節，在同一檔切成子標題，帶能力標記並列進 `## 規格章節`，沒動到的只回報；補引言與切節放內容 commit；已安裝文件治理檢查時 commit 前先跑，這次寫的紅就修，其他紅只回報。

## 驗證

- `bash tests/scripts/test-docs-governance-check.sh`（CI 由 `tests/test-tooling.sh` [31] 跑）：PR-DOCS-01、02、03、07、08、14 的紅綠案例，在 C.UTF-8 與 C 兩種 locale 下跑，含本 repo 根目錄的綠燈案例。
- `bash scripts/check.sh`：[30] Section H 模板、引用、安裝副本一致與 domain-modeling 合約（PR-DOCS-06、09、11、15、16）；[32] 現行文件規則只有一個家（PR-DOCS-05、13）；[19] 私有名單詞（PR-DOCS-12，只涵蓋列入名單的詞）。
- `bash scripts/check.sh` [33]：範本的大型現行文件段落寫齊、四個技能指向它、無人抄讀法引言（PR-DOCS-17、18）。
- PR-DOCS-09、13、17、18 的對話行為（實際搬移、補行、顯示 diff、切節）只由措辭檢查覆蓋，未對真實目標專案實跑。
