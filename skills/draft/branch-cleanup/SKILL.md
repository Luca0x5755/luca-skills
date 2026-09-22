---
name: branch-cleanup
description: 在開 PR 前盤點並整理此分支反覆修改留下的交付雜質。
disable-model-invocation: true
---

# Branch Cleanup

Tighten one branch before its PR. This is a **branch closeout**, not a general
cleanup pass: find the delivery debris created by repeated work on this branch,
let the user choose it, then remove only the chosen items in reviewable commits.

## 1. Establish the comparison

Find the **target base branch** from the branch upstream or PR metadata. If
neither gives a reliable answer, ask the user; `main` is not a fallback.

Read the branch's history and its diff against that base. Check `git status`
first. An uncommitted worktree has no settled boundary: stop and ask the user to
commit, discard, or otherwise place those changes before continuing.

## 2. Card the branch debris

Search only the branch diff and the areas it changed. Give every candidate its
own line in this form:

```
<evidence> → <kind> → <proposed action> → <files>
```

Eligible candidates have direct evidence:

- a document passage duplicated by, or explicitly superseded within, this branch;
- **document cache information** that the changed code, config, or one mechanical
  lookup answers directly;
- code, test helpers, comments, or configuration introduced by this branch and
  now demonstrably unreferenced or superseded.

State the evidence, not a suspicion. A fact whose correct version is uncertain
goes to `/audit-truth`; a behaviour-preserving structural transformation goes to
`/refactor`; a repo-wide document normalization goes to `/bootstrap-truth`.

Offer numbered items and any clear file or kind groupings. Wait for the user to
select the exact items or groups. Unselected and forwarded items stay in the
session report only.

## 3. Apply the selected closeout

Group selected work only when it has one purpose and one verification method.
Keep a fact decision out of a structural or duplicate-removal commit.

For each group:

1. Make the smallest deletion or consolidation that realizes the selected action.
2. Verify code changes with the affected tests, typecheck, build, or reference
   search as appropriate. Verify document-only changes with the repository's
   existing mechanical checks.
3. A failed verification stops the skill without a commit for this group. Report the command,
   output, and affected files; the user decides whether to repair, narrow scope,
   or use the routed skill.
4. When green, stage only the files in this group and commit through the
   `/git-commit` rules. The commit describes the cleanup purpose.

## 4. Close

No candidates, or no selected candidates: report the base, scan scope, and that
no files changed. Hand back to `/git-pr`.

After one or more groups commit, load `/code-review` via the Skill tool —
mandatory — and review the branch against its base. Fix findings that belong to
the selected closeout; verify each fix with its affected check, then stage and
commit it through the `/git-commit` rules before handing off. Report any
disagreement or out-of-scope finding. Then report the base, candidates selected,
commits, verification evidence, and items left untouched. Hand back to `/git-pr`.
