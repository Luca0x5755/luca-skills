# Record two trackers in setup-skills Section A

## Done when
- `/setup-skills` Section A 同時記錄兩套；有 remote 時，遠端小節包含該追蹤器的指令與非關閉引用寫法。
- GitLab 的非關閉引用寫法，是讀過 GitLab 官方文件後記下的，不憑記憶。
- 沒有 remote 時，遠端小節寫「不存在」。
- Section F 的 `issues-check` 行為不變，只對本機議題。
- 第 4 節 `issue-tracker.md` 必記項更新為雙套格式。

## Context
規格：`docs/issues/ISSUE-001-hybrid-issue-tracker.md`，本票對應 PR-TRACKER-03、04。格式範本是 tracer 票寫好的本 repo `docs/agents/issue-tracker.md`。

## Blocked by
Blocked by: ISSUE-002-tracer-issue-tracker-format.md

## Notes
- 現行 Section A 寫「每個 repo 只選一套」，這句要改，別留兩個互相矛盾的敘述。
- 第 41 行「Work that outlives the branch belongs in a real tracker」與新定義對齊，用**遠端議題**一詞。
- 寫或改技能前先載入 `/writing-for-agents`。
