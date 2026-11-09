# Verify the hybrid tracker end to end and land the promises

## Done when
- 對所有技能 grep：沒有任何技能寫死單一追蹤器，也沒有技能各自重述判準。
- `bash scripts/check.sh` 通過。
- 持久內容落進 `docs/capabilities/` 的新檔，promise 與規格一致；規格與所有票以 `git rm` 刪除。

## Context
規格：`docs/issues/ISSUE-001-hybrid-issue-tracker.md`，本票對應 PR-TRACKER-14 並收尾。`docs/capabilities/installer.md` 是同層的既有範例。

## Blocked by
Blocked by: ISSUE-003-route-to-tickets-wayfinder-triage.md, ISSUE-004-setup-skills-two-trackers.md, ISSUE-005-implement-reads-by-criteria-and-escalates.md, ISSUE-006-remaining-skills-read-by-criteria.md

## Notes
- Grep 範圍：`skills/` 下所有 `SKILL.md`，找 `docs/issues`、`gh issue`、`glab issue`、`Closes #` 與「tracker is local」類寫法。
- 這是最後一張票：完成時規格已無其他票引用，一併刪除。
- 版本號不動，發版時由 `git-release` 處理。
