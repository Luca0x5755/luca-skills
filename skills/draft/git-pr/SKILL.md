---
name: git-pr
description: 檢視分支的所有 commit 撰寫並開出 PR；PR 合併後同步 main、清理本地與遠端分支。
disable-model-invocation: true
argument-hint: 開 PR；或 PR 已合併後輸入 cleanup 做清理
allowed-tools: Bash(git log:*), Bash(git push:*), Bash(git switch:*), Bash(git pull:*), Bash(git branch:*), Bash(git fetch:*), Bash(gh pr view:*), Bash(gh pr create:*)
---

# Git PR

The head and tail of a branch's lifecycle: **opening the PR** and **cleaning up after merge**. Decide which phase from the argument or the current state — if the current branch's PR is already MERGED, go to cleanup.

## A. Open the PR

### 1. Gather material

```bash
git log --oneline main..HEAD     # the PR's content is these commits, not your memory
git status                       # uncommitted changes → stop, ask the user to deal with them first
```

### 2. Write it (English)

- **Title**: first letter capitalized, no trailing period, 70 characters max. Cover the whole branch's intent, not a restatement of the last commit.
- **Body:**

```markdown
## Summary
- Bullet points extracted from the commit messages
- Multiple commits on the same thing collapse into one bullet

## Test plan
- [ ] Each item is a concretely executable verification step
- [ ] Not empty phrases like "confirm the feature works"
```

### 3. Open

```bash
git push -u origin <branch>
gh pr create --title "..." --body "..."
```

Report the PR URL. **Do not merge** — merging is the user's button to press.

## B. Cleanup after merge

### 1. Verify, don't trust

```bash
gh pr view <branch> --json state,mergedAt
```

**`state` is not `MERGED` → stop the cleanup** and report the actual state. "The PR passed" is input to verify, not a fact.

### 2. Sync and delete

```bash
git switch main
git pull origin main
git branch -d <branch>            # lowercase -d: if it fails there are unmerged commits → stop, report, -D is forbidden
git push origin --delete <branch> # only if the remote branch still exists; gh may have deleted it on merge
git fetch --prune
```

Also check `git branch -v` for other branches marked `[gone]`. List them and ask whether to clean them too — **list and ask, never delete outright**.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "The user said the PR passed, just delete" | Claims get verified with `gh pr view`. Checking costs three seconds; deleting wrong costs half an hour. |
| "`-d` refused, switch to `-D`" | `-d` failing is git telling you commits never reached main. `-D` is muting the warning. |
| "I'll write the PR body from memory" | The material is `git log main..HEAD`. The branch in your memory and the actual branch are not the same branch. |
