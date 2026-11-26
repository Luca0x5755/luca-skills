---
name: git-merge
description: 把指定分支合併進當前分支；發生衝突時停下來分析與建議，解法是使用者的決定。
disable-model-invocation: true
allowed-tools: Bash(git merge:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git fetch:*), Bash(git add:*), Bash(git commit:*)
---

# Git Merge

Merge a target branch (e.g. `main`) into the current branch. A clean merge just completes; a conflicted one switches into analysis mode — **this skill analyzes conflicts, it does not resolve them**.

## 1. Preflight

```bash
git status --short
git fetch origin
git log --oneline origin/<target>..<target>   # local-only commits
git log --oneline <target>..origin/<target>   # remote-only commits
```

Tracked files with uncommitted changes → stop and report. Uncommitted changes mixed into a merge become impossible to attribute afterwards. Untracked files pass: `git merge` refuses on its own if one would be overwritten.

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

- **Clean merge** → git writes the merge commit and its message itself. Report the range of commits merged in. Done.
- **`git status` shows Unmerged paths** → **committing is forbidden**. Go to step 3.

## 3. Conflict analysis (not resolution)

1. **List every conflicted file.**
2. For each file, read the `<<<<<<<`, `=======`, `>>>>>>>` markers, and for each conflict block:
   - **Summarize both sides' intent** — not pasted code, but what each side was trying to do. Example: "`main` added a parameter to this function; the current branch rewrote its internal logic."
   - **Suggest a direction** — are the two intents compatible? If yes, describe how to combine them; if mutually exclusive, state the trade-off.
3. Present the analysis and **wait for the user's ruling**.
4. After the ruling, edit the conflicted files as ruled and `git add` each by explicit path; git already staged the auto-merged files. Commit by the `/git-commit` rules — read `git-commit/SKILL.md` in the parent of this skill's base directory first: message as a file via `git commit -F`, commit only, no push. Subject: git's default merge subject (`Merge origin/main into <branch>`). Body: one bullet per conflict stating how it was resolved — the ruling lives in history.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "This conflict is tiny, I'll just resolve it" | Size is a property of the code; the ruling belongs to the user. |
| "The two sides touch different lines — the machine flagged it, that's all" | Then report exactly that: "intents compatible, suggest keeping both" — and still wait. |
| "This is a mess, let me `git merge --abort` and retry" | Abort throws away a merge the user initiated. Whether to give up is their question. |
| "Halfway resolved, I'll just commit to wrap up" | Every second Unmerged paths exist, committing is forbidden. Fully resolved and user-confirmed, then commit. |
| "Git's default message is fine — `git commit --no-edit`" | It drops the ruling. Write the body with one bullet per conflict and commit with `-F`. |
