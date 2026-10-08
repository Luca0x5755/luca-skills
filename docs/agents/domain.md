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
`hooks/guard-git.sh` 與 `hooks/guard-secrets.sh` 掛載。
本 repo 維護護欄原始碼，既有檢查會驗證掛載與 hook 地圖一致。
