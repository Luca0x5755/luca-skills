# 現行文件與歷史文件的治理：按節讀、節上限、日誌月輪替與機械檢查

## Why

目標專案的大型**現行文件**（合訂本、capability 檔、test-blueprint、test-status）已經長到代理無法整份讀：整份超過 Read 單次上限好幾倍，單一節也可能超過。現行文件裡又夾著票號、日期和遷移紀錄，代理讀到的不是現況。決策日誌是一份只增不改的單檔，每寫一行都要先讀整份，成本跟著檔案長度一起漲。這份規格把 `/grill-with-docs` 定下的治理規則落到技能與 /setup-skills 安裝的檢查裡，讓這些規則由機器擋，而不是靠代理記得。

## Scope

- **現行文件**與**歷史文件**的分類，以及現行文件的內容規則（GLOSSARY 已定義兩詞）。
- 現行文件的機械檢查：禁用模式、最小一節大小、第一行讀法。
- 決策日誌的月輪替合約與檢查（ADR 0005）。
- 合訂本按節讀（ADR 0004）。
- 重跑 /setup-skills 時的導入行為。
- 本 repo 的 `check.sh` 與測試，對應每一條新規則。

## Promises

PR-DOCS-01 — PR-DOCS-14 清單中的檔案在程式碼區塊與表格之外出現 `票 \d+`、`規格 \d+`、`ISSUE-\d+` 或 `YYYY-MM-DD` 時，檢查報紅（error 級），並標明檔案與行號；產品版本號（例如 `v2.3`）不受此限，照常通過。
PR-DOCS-02 — PR-DOCS-14 清單中任何最小一節（沒有子標題的那一層，從標題行到下一個標題行）超過 40 KB 時，檢查報紅，並標明標題與大小；表格與程式碼區塊照算，不豁免。
PR-DOCS-03 — `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md` 存在時，第一行是讀法引言：不要整份讀，先查 capability 檔的 `## 規格章節`，grep 標題行號，只讀那一段。缺這一行時檢查報紅；檢查只驗證這一行存在，不驗證代理是否照做。
PR-DOCS-04 — 現行文件的內容規則寫明：不寫票號、工作日期、遷移紀錄、教訓或「曾經 X 後改 Y」，這些歸決策日誌、commit 或 ADR；產品版本號不在此限。
PR-DOCS-05 — `/audit-truth` 把現行文件中的「教訓／曾經」類敘述列為發現；這類用詞不進機械檢查。
PR-DOCS-06 — `/domain-modeling` 的決策日誌合約改為：路徑 `docs/decision-log.md` 不變，只放當月的行；寫入新月份的第一行前，把上個月的行搬到 `docs/decision-log/YYYY-MM.md`；封存檔搬出後不再修改。原本的「Single file, append-only」移除。
PR-DOCS-07 — `docs/decision-log.md` 裡出現兩種以上的年月時，檢查報紅；判斷只看檔案內容，不看執行當天的日期。
PR-DOCS-08 — `docs/decision-log.md` 任一行超過 300 字（以 Unicode 字元計）時，檢查報紅並標明行號；`docs/decision-log/` 下的封存檔不檢查。
PR-DOCS-09 — 在已有決策日誌的目標專案重跑 /setup-skills 時，機械地把非當月的行依年月搬進 `docs/decision-log/YYYY-MM.md`，並替 PR-DOCS-03 列名的文件補上缺少的讀法引言；不寫遷移腳本，不寫 baseline 檔；安裝報告列出其餘仍為紅的項目。
PR-DOCS-10 — 本 repo 的檢查腳本測試對 PR-DOCS-01、02、03、07、08 各有一組紅、綠案例，在 C.UTF-8 與 C 兩種 locale 下都要跑；`bash scripts/check.sh` 通過。
PR-DOCS-11 — 本 repo 的 `check.sh` 強制技能文字的措辭：`/domain-modeling` 不再寫「Single file, append-only」，並寫明 PR-DOCS-06 的輪替合約；/setup-skills 安裝新檢查的模板檔都存在，且有被引用。
PR-DOCS-12 — 技能文字、GLOSSARY、decision-log 與 commit 訊息不提及促成這次改動的參考專案，也不取它的內容或數字當範例。
PR-DOCS-13 — 現行文件與歷史文件的分類、PR-DOCS-04 的內容規則，只住在 /setup-skills 旁的一份範本；/setup-skills 每次執行都把它逐字複製進目標專案的 `docs/agents/domain.md`，成為一節，內容不同就顯示 diff 並提議更新。`to-architecture`、`frontend-spec`、`test-blueprint`、`domain-modeling`、`audit-truth` 都指向那一節，不重述規則；本 repo 的 `check.sh` 對重述報紅。
PR-DOCS-14 — 文件治理檢查的掃描清單固定為 `docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/capabilities/*.md`、`docs/test-blueprint.md`、`docs/test-status.md`、`GLOSSARY.md`、`docs/adr/*.md`；不存在的檔案略過、不報紅；沒有設定檔；`docs/uat-cases.md` 不在清單內。
PR-DOCS-15 — /setup-skills 新增 Section H「文件治理檢查」：目標專案有 `docs/` 就提議；逐字複製獨立的檢查腳本與 workflow，不併進 `check-truth-map.sh`；安裝後告知使用者，要在 branch protection 把它設為 required，才會擋合併。
PR-DOCS-16 — 本 repo 在同一個 PR 把決策日誌的 9 月、10 月行搬進 `docs/decision-log/2026-09.md`、`docs/decision-log/2026-10.md`，主檔只留當月；並照 Section H 裝上文件治理檢查，CI 會跑。

## Out of scope

- **擁有者與日期欄位**：單一維護者；研究顯示工具多半只檢查欄位存在，不檢查內容是否新鮮。
- **合訂本拆成每章一檔**：被 ADR 0004 否決。
- **test-blueprint／test-status 的內部結構清理**：只套 PR-DOCS-01–03 的通用規則，結構問題要先看過實際內容，延後另開 `/grill-with-docs`。
- **「教訓／曾經」類用詞的機械檢查**：誤報太多，交 `/audit-truth`（PR-DOCS-05）。
- **baseline 檔與遷移腳本**：變紅由代理在同一 PR 修綠、使用者審查。
- **branch protection**：技能不改儲存庫保護規則。

## Decisions

- 現行文件與歷史文件分兩類，一個檔只屬一類；GLOSSARY 已定義。否決：不分類、靠作者自律。
- 合訂本維持單檔、按節讀、最小一節 ≤ 40 KB、第一行寫讀法 → [ADR 0004](../adr/0004-consolidated-volumes-stay-single-files-read-by-section.md)。
- 決策日誌固定路徑只放當月、月輪替、同期檢查 → [ADR 0005](../adr/0005-decision-log-rotates-monthly-behind-a-fixed-path.md)。否決：改成目錄、每個決策一份 ADR、年輪替。
- 現行文件零歷史。否決：外部「歷史收進可刪區塊、過幾版再刪」的做法，那服務的是產品版本的讀者（decision-log 2026-11-23）。
- 機械檢查只用窄 regex、設 error 級、產品版本號例外。否決：warning 級，代理常把它當雜訊略過（decision-log 2026-11-23）。
- 行長檢查只看主檔。否決：日期常數門檻（decision-log 2026-11-23）。
- 導入靠重跑 /setup-skills 加同一 PR 修綠。否決：baseline 檔、遷移腳本（decision-log 2026-11-23）。
- 規則文字比照 capability 檔形狀，只有一個家。否決：各技能各寫一段（decision-log 2026-11-23）。
- 掃描範圍用固定清單。否決：glob 推導、設定檔（decision-log 2026-11-23）。
- 第一行讀法不涵蓋 capability 檔。否決：納入，因為會循環（decision-log 2026-11-23）。
- 新檢查用獨立的 Section H。否決：併進 Section G，因為 G 只在有 `docs/capabilities/` 時才提議（decision-log 2026-11-23）。
- 本 repo 同一 PR 輪替並裝上檢查。否決：本 repo 不裝（decision-log 2026-11-23）。

## Open questions
