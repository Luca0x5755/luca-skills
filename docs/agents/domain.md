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

持久文件分兩類，每份只屬一類。

**現行文件**只寫專案此刻的狀態，代理讀它就是在讀現況：`GLOSSARY.md`、ADR（`docs/adr/`）、capability 檔（`docs/capabilities/`）、架構與前端合訂本（`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`）、測試藍圖（`docs/test-blueprint.md`）、測試狀態（`docs/test-status.md`）、`CLAUDE.md`／`AGENTS.md`。

**歷史文件**記錄過去：決策日誌（`docs/decision-log.md`）與 git 歷史。

本機議題、驗收案例、研究報告不在分類內。

現行文件不寫票號、議題編號、工作日期、遷移紀錄與教訓，也不寫「曾經 X 後改 Y」這類改動前後的敘述。

現行文件也不以決策日誌的日期交代理由；理由值得留，就寫成 ADR。ADR 不帶 `日期：` 行。

承諾 ID 與產品版本號不算歷史，可以留在現行文件裡。
