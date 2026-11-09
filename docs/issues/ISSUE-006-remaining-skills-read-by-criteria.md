# Make run-queue, audit-truth, diagram and feasibility read by the criteria

## Done when
- `run-queue` 的前提由「追蹤器是本機 markdown」改為「有本機票」；遠端規格不歸它管。
- `audit-truth` 的漂移票固定只讀遠端；沒有 remote 時只看宿主漂移帳本。
- `diagram` 讀判準指到的位置。
- `feasibility` 對本機規格把報告追加成規格檔末節 `## Feasibility`；對遠端規格維持貼成留言。

## Context
規格：`docs/issues/ISSUE-001-hybrid-issue-tracker.md`，本票對應 PR-TRACKER-10、11、12。這四個技能各自寫死單一追蹤器的假設：`run-queue` 第 17 行、`audit-truth` 第 48 行、`diagram` 第 75 行、`feasibility` 第 13 與 46 行。

## Blocked by
Blocked by: ISSUE-002-tracer-issue-tracker-format.md

## Notes
- 四個都在 `skills/draft/`，改動小，各自幾行。
- 本機規格的 `## Feasibility` 節跟著規格一起 commit、一起在 PR 內刪除。
- 寫或改技能前先載入 `/writing-for-agents`。
