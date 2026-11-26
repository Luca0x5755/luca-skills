---
name: git-merge
description: 把目標分支（通常是 main）合併進當前分支並自己解衝突；兩邊意圖可並存就解掉，取捨衝突或受保護檔案就退出合併、交分析。只提交合併 commit、不推送。當使用者要「合併 main」「同步 main」「解衝突」、PR 顯示有衝突，或 git status 出現 Unmerged paths、"merge conflict" 時使用。
allowed-tools: Bash(git merge:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git fetch:*), Bash(git add:*), Bash(git commit:*), Bash(git branch --show-current)
---

# Git Merge

Merge a target branch (usually `main`) into the current branch and resolve the conflicts yourself. A conflict you can resolve gets resolved; a **trade-off conflict** gets aborted and handed over as analysis. The result is one local merge commit — pushing belongs to `/git-pr`.

## 0. When to run

Run when the user asks to merge or sync with a branch, or when a conflict is visible: `git status` lists Unmerged paths, or the pull request reports `mergeable: CONFLICTING`. A branch that is only behind its base is not a reason — leave it.

## 1. Preflight

```bash
git branch --show-current
git status --short
git fetch origin
git log --oneline origin/<target>..<target>   # local-only commits
git log --oneline <target>..origin/<target>   # remote-only commits
```

- Current branch is `main` or `master` → stop and report. A local merge into the default branch bypasses the pull request, and the commit a clean merge writes slips past the commit guard.
- A merge already in progress (`git status` lists Unmerged paths) → skip the rest of this step and step 2; classify that merge's conflicts in step 3.
- Tracked files with uncommitted changes → stop and report. Uncommitted changes mixed into a merge become impossible to attribute afterwards. Untracked files pass: `git merge` refuses on its own if one would be overwritten.

Pick the **merge source** — `fetch` updates `origin/<target>`, never the local `<target>`:

- Local-only list empty → `origin/<target>`.
- Remote-only list empty → `<target>`.
- Both lists non-empty → stop and show both; which to merge is the user's call.
- No `origin/<target>` → `<target>`.

Then `git log --oneline HEAD..<source>` shows what is about to come in. Empty → report that and stop.

## 2. Merge

```bash
git merge <source>
```

- **Clean merge** → git writes the merge commit and its message itself. Report the range merged in. Done.
- **Unmerged paths** → go to step 3. Committing waits until every path is resolved.

## 3. Classify every conflict block

List every conflicted file, read each `<<<<<<<` / `=======` / `>>>>>>>` block, and state both sides' intent — what each side was trying to do, not pasted code. Then put each block in one class:

- **Resolvable** — the two intents coexist and the merged result keeps both (each side appended, or changed different things), or one side's change fully contains the other's.
- **Trade-off conflict** — both sides set the same thing to different values, so keeping one discards the other (a version number, a config value, two rewrites of one piece of logic); or judging which side is right needs information outside the diff.
- **Protected path** — the file sits under `.claude/`, `hooks/`, `.github/workflows/`, `.claude-plugin/`, or is `.mcp.json`. These files carry the guardrails and the release; a wrong automatic resolution silently disables one.
- **Generated file** — a lockfile or build output. Regenerate it with the project's own command (from `package.json` scripts, the build config, or `CLAUDE.md`) instead of editing markers. No such command known → treat it as a trade-off conflict.

Any block in the trade-off or protected class → step 5 for the whole merge. Otherwise → step 4.

## 4. Resolve and commit

1. Edit each conflicted file to its resolution, and regenerate generated files.
2. Confirm no markers remain: `git diff --check` and `git status` show no Unmerged paths.
3. `git add` each resolved file by explicit path; git already staged the auto-merged files.
4. Commit by the `/git-commit` rules — read `git-commit/SKILL.md` in the parent of this skill's base directory first. Message as a file via `git commit -F`, commit only. Subject: git's default merge subject (`Merge origin/main into <branch>`). Body: one bullet per conflict — where it was, how it was resolved, and why it counted as resolvable. Nobody reviewed these resolutions; the body is their only record.

Report the range merged in, each resolution, and that the merge commit is local until `/git-pr` pushes it.

## 5. Abort and hand over

```bash
git merge --abort
```

The tree is back to its pre-merge state. Report, per conflict block: both sides' intent, its class and why, and a suggested direction — for a trade-off, which side to keep and what the other side loses. The user decides; a later run merges again once they have.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "Both values look plausible — I'll pick the newer one" | Two values for one thing is the trade-off class by definition. Abort and hand it over. |
| "It's only a workflow file / a hook, the change is obvious" | Protected paths carry the guardrails. An obvious-looking resolution there is exactly the one nobody re-reads. Abort. |
| "I'll resolve the easy blocks and leave the hard one for the user" | A half-resolved merge leaves the tree stuck mid-merge. One trade-off block aborts the whole merge. |
| "Git's default message is fine — `git commit --no-edit`" | It drops every resolution. Write the body with one bullet per conflict and commit with `-F`. |
| "The branch is just behind `main`, I'll sync it while I'm here" | Behind is not conflicting. An unasked merge commit muddies the pull request's diff. |
| "Resolved and committed — pushing saves the user a step" | The exception that lets this skill commit covers a local merge commit only. Pushing is `/git-pr`'s. |
