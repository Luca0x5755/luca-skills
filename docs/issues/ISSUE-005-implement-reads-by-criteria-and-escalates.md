# Make implement and implement-spec read by the criteria and escalate

## Done when
- `implement`、`implement-spec` 依判準指到的位置讀取與完成議題。
- `implement` 在本機議題做不完時，在遠端建議題並引用原內容，同一次 commit 以 `git rm` 刪本機檔；沒有反向流程。
- `implement-spec` 現有的跨追蹤器行為不退步。

## Context
規格：`docs/issues/ISSUE-001-hybrid-issue-tracker.md`，本票對應 PR-TRACKER-08、09。PR #70 的描述稱 `implement-spec` 已是「跨追蹤器」，動手前先讀它現在怎麼處理遠端規格，再決定要改多少。

## Blocked by
Blocked by: ISSUE-002-tracer-issue-tracker-format.md

## Notes
- 升級時兩處各自維護會內容分歧，所以建遠端議題與刪本機檔必須在同一次 commit。
- 無 remote 時，升級無處可去：回報使用者，不硬建。
- 寫或改技能前先載入 `/writing-for-agents`。
