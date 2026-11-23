## 現行文件與歷史文件

文件只分兩類，一個檔只屬其中一類。

**現行文件** — 只描述專案此刻狀態、會被就地改寫：合訂本（`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`）、`docs/capabilities/` 的 capability 檔、`docs/test-blueprint.md`、`docs/test-status.md`、`GLOSSARY.md`、ADR。

**歷史文件** — 只增不改、記錄決定如何演變：決策日誌（當月主檔與月份封存檔）與 git 歷史。

現行文件的內容規則：

- 不寫票號、工作日期、遷移紀錄、教訓，也不寫「曾經 X 後改 Y」。這些歸決策日誌、commit 或 ADR。
- 產品版本號不在此限。
- 機械檢查只擋票號與日期；教訓與「曾經」類敘述由 `/audit-truth` 列為發現。
