# Persist the two-tracker format and have to-spec use it end to end

## Done when
- 本 repo 的 `docs/agents/issue-tracker.md` 頂部有分流判準，下接本機與遠端兩小節，各記建立、列出、阻塞關係、正文位置。
- 遠端小節（GitHub）記 `gh` 指令與非關閉引用寫法；該寫法是讀過 GitHub 官方文件後記下的，不憑記憶。
- `CLAUDE.md` 的「Agent skills / Issue tracker」小節與 `GLOSSARY.md` 遠端議題條，措辭與判準一致。
- `to-spec` 發佈前提議一次去向並附一行理由，使用者確認一次，並問一句有沒有驗收議題；本機路徑照舊寫檔並 commit。

## Context
規格：`docs/issues/ISSUE-001-hybrid-issue-tracker.md`，本票對應 PR-TRACKER-01、02、05（`to-spec` 部分）、07、13（本 repo 部分）。這是 tracer：只用 GitHub、只改 `to-spec`，GitLab 留給 `setup-skills` 那張票。

## Blocked by
Blocked by: none

## Notes
- 判準只寫在 `issue-tracker.md` 頂部，`to-spec` 指過去，不重述。
- 判準措辭用「PR 之外有人需要追蹤它的狀態（回報者、驗收者、別的團隊）」，不用「看見」。
- 驗收議題在 PR 內用非關閉引用，不用 `Closes #N`。
- 寫或改技能前先載入 `/writing-for-agents`；`description` 中文、內文英文。
