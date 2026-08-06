---
name: git-pr
description: 檢視分支的所有 commit 撰寫並開出 PR；PR 合併後同步 main、清理本地與遠端分支。
disable-model-invocation: true
argument-hint: 開 PR；或 PR 已合併後輸入 cleanup 做清理
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git push:*), Bash(git switch:*), Bash(git pull:*), Bash(git branch:*), Bash(git fetch:*), Bash(gh pr view:*), Bash(gh pr create:*)
---

# Git PR

The head and tail of a branch's lifecycle: **opening the PR** and **cleaning up after merge**. Decide which phase from the argument or the current state — if the current branch's PR is already MERGED, go to cleanup.

## A. Open the PR

### 1. Gather material

```bash
git log --oneline main..HEAD     # the PR's content is these commits, not your memory
git status                       # uncommitted changes → stop, ask the user to deal with them first
```

### 2. Write it

- **Title (English)**: first letter capitalized, no trailing period, 70 characters max. Cover the whole branch's intent, not a restatement of the last commit.
- **Body (Traditional Chinese)**, sections in this order. Drop a section only when it truly has nothing to say — never pad one:

```markdown
## 摘要
一段話：這個 PR 做了什麼、動到哪些面。

## 問題
為什麼需要這個改動：症狀 → 根因。有量測就上表格，沒有就寫清楚觀察到什麼。
順手記下這個改法「不會」解決什麼，免得日後被誤引用。

## 變更內容
### `path/to/file`
- 該檔改了什麼、為什麼 — 依檔案或模組分組，不是 commit 的流水帳

## 設計決定
- 每條一行：決定 + 為什麼。只寫真的做過取捨的，不寫理所當然的。

## 測試
| 項目 | 結果 |
| --- | --- |
| 具體可執行的驗證步驟 | ✅ 附證據（數字、輸出），不是「功能正常」 |

**未驗證**：明列沒測到的範圍。沒說出口的缺口，比缺口本身更貴。
```

- Situational sections (遷移、部署提醒…) go between 設計決定 and 測試 when the change genuinely needs them.

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
git pull --ff-only origin main
git branch -d <branch>
git push origin --delete <branch> # only if the remote branch still exists; gh may have deleted it on merge
git fetch --prune
```

A squash merge rewrites the branch's commits into one new SHA on `main`, which trips two of those steps. Each has a defined answer:

- **`git pull --ff-only` refused** → something other than this PR moved `main`. Stop and report. The flag is what makes that visible: a plain `git pull` buries the surprise in a merge commit and lands the same change on `main` twice.
- **`git branch -d` refused** → expected after a squash merge; git cannot find the branch's SHAs in `main`. Get the **evidence** before deleting: `git diff origin/main <branch>` empty means every change landed under a new SHA, and `-D` is then the correct command. Non-empty is the real warning — work on this branch never reached `main`. Stop and report.

Also check `git branch -v` for other branches marked `[gone]`. List them and ask whether to clean them too — **list and ask, never delete outright**.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "The user said the PR passed, just delete" | Claims get verified with `gh pr view`. Checking costs three seconds; deleting wrong costs half an hour. |
| "`-d` refused, switch to `-D`" | `-D` needs the evidence first: `git diff origin/main <branch>` empty. Without it, `-d` refusing means commits never reached main, and `-D` mutes the warning. |
| "`--ff-only` refused, drop the flag and pull again" | The refusal *is* the finding. Dropping the flag merges whatever moved `main` and duplicates this change in its history. |
| "I'll write the PR body from memory" | The material is `git log main..HEAD`. The branch in your memory and the actual branch are not the same branch. |
