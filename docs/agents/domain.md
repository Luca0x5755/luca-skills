# Domain docs

- Context: single-context
- Collaboration: shared
- Glossary: `GLOSSARY.md`
- ADRs: `docs/adr/`，需要 ADR 時才建立。
- Decision log: `docs/decision-log.md`

技能產出納入版控；沒有 private 排除路徑。

程式註解使用繁體中文，規範記於 `CLAUDE.md`。
此慣例延續現有腳本，屬於所有程式碼讀者都應看見的團隊事實；
本檔只供工具導航，團隊規範應維護於共同閱讀的文件。

Guard hooks 保留 `.claude/settings.json` 已有的
`hooks/guard-git.sh`、`hooks/guard-secrets.sh` 與 `hooks/guard-penpot.sh` 掛載。
本 repo 維護護欄原始碼，既有檢查會驗證掛載與 hook 地圖一致。

## 現行文件與歷史文件

文件只分兩類，一個檔只屬其中一類。

**現行文件** — 只描述專案此刻狀態、會被就地改寫：合訂本（`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`）、`docs/capabilities/` 的 capability 檔、`docs/test-blueprint.md`、`docs/test-status.md`、`GLOSSARY.md`、ADR。

**歷史文件** — 只增不改、記錄決定如何演變：決策日誌（當月主檔與月份封存檔）與 git 歷史。

現行文件的內容規則：

- 不寫票號、工作日期、遷移紀錄、教訓，也不寫「曾經 X 後改 Y」。這些歸決策日誌、commit 或 ADR。
- 產品版本號不在此限。
- 機械檢查只擋票號與日期；教訓與「曾經」類敘述由 `/audit-truth` 列為發現。

大型現行文件的讀寫（`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`、`docs/test-blueprint.md`、`docs/test-status.md`）：

- 按節讀：先查 capability 檔的 `## 規格章節`，grep 標題行號，只讀要用的那幾節。
- 第一行是讀法引言：新建檔案、或動到第一行不是它的檔案時，從已安裝的 `.github/scripts/check-docs-governance.sh` 讀出 `READING_GUIDE` 寫入，不另抄；腳本不在就不寫，並回報「Section H 未裝」。
- 最小一節（沒有子標題的那一層）不超過 40 KB：這次動到而超過的節，在同一檔往下切標題，新標題帶能力標記並列進 capability 檔的 `## 規格章節`；沒動到的超大節只回報，不切。
- 補讀法引言與切節都放內容 commit，不放只刪字的 cut-commit。
- commit 前：已安裝檢查腳本就先跑；這次寫的行報紅就修，其他紅燈只回報。
