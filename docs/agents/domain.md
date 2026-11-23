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
