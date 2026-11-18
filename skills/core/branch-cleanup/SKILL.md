---
name: branch-cleanup
description: 在最後提交前收斂功能分支反覆修訂的文件與無用交付內容。
disable-model-invocation: true
---

# Branch Cleanup

Prepare one feature branch for its final squash or PR. Repeated revisions can
leave superseded ADRs, swollen user stories, interim decisions, and stale spec
passages. Card the evidence, let the user choose, then leave a verified working
tree that states the final facts. The user owns the final commit.

## 1. Bound the current branch

Read the current branch name. Run this skill only on a feature branch: stop on
`main`, `dev`, or a detached HEAD. Check `git status` next. An uncommitted
worktree has no settled boundary: stop and ask the user to commit, discard, or
otherwise place those changes before continuing.

Find the branch's start with `git merge-base HEAD main` and
`git merge-base HEAD dev`, for whichever local branches exist. Deduplicate the
commits and choose the one with the fewest commits between it and `HEAD`. If
distinct candidates tie, or no common ancestor exists, ask for a start commit.
Read `git log <start>..HEAD` and `git diff <start>..HEAD`. This scope comes from
local history; upstream tracking and PR metadata are irrelevant. Read the host
repo's rules for ADRs, user stories, specs, decision logs, and document checks.

## 2. Card the branch debris

Trace the changed feature documents through branch commits and their current
state. Follow their indexes, capability links, and references across the repo.
Search the changed code and config for evidence of the final behavior. Keep
the scan about this branch's feature, not unrelated repository cleanup.

Give every candidate its own line in this form:

```
<evidence> → <final fact and source> → <proposed action> → <files and references>
```

Separate document candidates from code and config candidates. Look for:

- branch-created ADRs wholly or partly superseded by a later decision;
- repeated or obsolete user-story prose and acceptance criteria, including
  broken cross-references;
- spec passages and branch-local decision-log entries recording intermediate
  states rather than the final behavior;
- a document passage duplicated elsewhere in the feature's current truth;
- **document cache information** that the changed code, config, or one mechanical
  lookup answers directly;
- code, test helpers, comments, or configuration introduced by this branch and
  now demonstrably unreferenced or superseded.

Later commit time alone does not establish a final fact. Use explicit
supersession, current governing documents, and implementation evidence. Where
sources conflict without a clear winner, show the conflicting passages and ask
the user to decide before editing that fact. Route unrelated repository-wide
truth drift to `/audit-truth`, behavior-preserving structural changes to
`/refactor`, and repo-wide document normalization to `/bootstrap-truth`.

Offer numbered items and clear groupings. Wait for the user to select the exact
items or groups and settle any open fact conflicts. Unselected and forwarded
items stay in the session report only.

## 3. Apply the selected closeout

Follow the host repo's document roles. Keep final behavior in its governing
spec, decision reasons and trade-offs in active ADRs, and testable acceptance
conditions in user stories. Within the same decision lineage, fold useful
reasons from a branch-created, fully superseded ADR into the surviving ADR;
delete the old file and update every index and reference. Retain any distinct
decision in a partly superseded ADR. Condense repeated prose within or across
same-goal stories while preserving story ID traceability and every testable
behavior that remains in the final design. Collapse branch-local interim
decision-log entries when host rules allow it, retaining any final rationale.
If a host rule conflicts with a selected action, show the conflict to the user.
Apply each user verdict to every downstream document it affects.

Group selected work by purpose and verification method. For each group:

1. Make the smallest deletion or consolidation that realizes the selected action.
2. Search for every reference to removed ADRs, story IDs, acceptance-criterion
   numbers, and changed rules. Verify document changes with the repo's document
   checks; verify code changes with affected tests, typecheck, build, or
   reference search as appropriate.
3. On a failed check, report the command, output, and affected files. Repair
   within the selected scope or ask the user to narrow or adjudicate it.

Leave the changes unstaged and uncommitted for the user's final squash.

## 4. Close

No candidates, or no selected candidates: report the start commit, scan scope,
and that no files changed.

After edits, review `git diff <start>` and `git status --short`; inspect any
untracked files separately. Run `git diff --check` and the affected checks.
Report the start commit, selected candidates, final facts retained, files
changed, verification, unresolved conflicts, and items left untouched. Hand
the working tree back for the user's final commit, squash, and remote update;
`/git-pr` follows once the final commit is on the remote branch.
