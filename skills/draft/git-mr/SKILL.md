---
name: git-mr
description: GitLab 版 git-pr——檢視分支 commit 撰寫並開 MR：有 glab 直接建立並回連結，沒有就分開給連結、標題、內文讓你自己貼；合併後同步預設分支、清理本地與遠端分支。
disable-model-invocation: true
argument-hint: 開 MR；或 MR 已合併後輸入 cleanup 做清理
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git push:*), Bash(git switch:*), Bash(git pull:*), Bash(git branch:*), Bash(git fetch:*), Bash(git rebase:*), Bash(git remote:*), Bash(git ls-remote:*), Bash(glab auth status), Bash(glab mr view:*), Bash(glab mr create:*)
---

# Git MR

The head and tail of a branch's lifecycle on **GitLab**: opening the MR and cleaning up after merge. Decide which phase from the argument or the current state — if the current branch's MR is already merged, go to cleanup. (GitHub remotes belong to `/git-pr`, not here.)

## A. Open the MR

### 1. Gather material

```bash
git log --oneline <base>..HEAD   # the MR's content is these commits, not your memory
git status                       # uncommitted changes → stop, ask the user to deal with them first
```

`<base>` is the branch this MR will merge into — usually the remote's default branch, but ask when the user named a different one. **Every commit that range prints must be yours.** Foreign commits in the range inflate the diff and charge other people's work to your MR. Resolve before opening: point the MR at the branch you actually cut from, or

```bash
git rebase --onto <base> <fork-point> <branch>   # replant your commits on the real base
```

Report which you did and why.

### 2. Write it

- **Title (English)**: first letter capitalized, no trailing period, 70 characters max. Cover the whole branch's intent, not a restatement of the last commit.
- **Body (Traditional Chinese)**, sections in this order. Drop a section only when it truly has nothing to say — never pad one:

```markdown
## 摘要
一段話：這個 MR 做了什麼、動到哪些面。

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

### 3. Open — two tracks, checked at runtime

```bash
git push -u origin <branch>   # keep the push output — GitLab prints the create-MR URL in it
glab auth status              # decides the track; not installed or not authenticated → no-glab track
```

**With glab** — create directly and report the URL. Body goes through a file, never inline as a quoted multi-line string. Check `glab mr create --help` first for the description-from-file flag of the installed version (`--description-file` on newer builds); absent that, `--description "$(cat <path>)"` — the file is still the source of truth:

```bash
glab mr create --source-branch <branch> --target-branch <base> --title "..." --description-file <path>
```

**Without glab** — hand the user three separate copy-paste blocks:

1. **Link**: the `…/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branch>` URL from the push output. If the push didn't print one (branch already pushed), build the same shape from `git remote get-url origin`. The URL carries the source-branch parameter **only** — never encode title or description into it; long values get mangled by URL length limits and shell quoting, and the user asked to paste them himself.
2. **Title**: plain text.
3. **Body**: plain markdown block.

Either track: **do not merge** — merging is the user's button to press.

## B. Cleanup after merge

### 1. Verify, don't trust

- **With glab**: `glab mr view <branch>` — the `state` must read `merged`. Anything else → stop the cleanup and report the actual state.
- **Without glab**: git evidence, both pieces required —

```bash
git fetch --prune
git diff origin/<base> <branch>        # empty = every change landed (squash gives it a new SHA)
git ls-remote --heads origin <branch>  # gone = GitLab deleted it on merge, corroborating evidence
```

Empty diff → merged, proceed. Non-empty diff → work on this branch never reached `<base>`; stop and report, whatever the user said. "已經合併了" is input to verify, not a fact.

### 2. Sync and delete

```bash
git switch <base>
git pull --ff-only origin <base>
git branch -d <branch>
git push origin --delete <branch>  # only if the remote branch still exists
git fetch --prune
```

- **`git pull --ff-only` refused** → something other than this MR moved the base. Stop and report; a plain `git pull` would bury the surprise in a merge commit.
- **`git branch -d` refused** → get the evidence before escalating: `git diff origin/<base> <branch>` empty means every change landed under a new SHA (squash merge), and `-D` is then correct. Non-empty is the real warning — stop and report.

Also check `git branch -v` for other branches marked `[gone]`. List them and ask whether to clean them too — **list and ask, never delete outright**.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "No glab, so I'll just trust the user that it merged" | The evidence is two git commands. An empty diff plus a gone remote branch costs seconds; deleting an unmerged branch costs the branch. |
| "I'll tuck the title and description into the URL so it's one click" | The user explicitly banned it. Long values hit URL limits and quoting bugs, and a mangled description lands in the MR silently. Three blocks, pasted by the user. |
| "`-d` refused, switch to `-D`" | `-D` needs the evidence first: `git diff origin/<base> <branch>` empty. Without it, the refusal means commits never reached the base. |
| "`--ff-only` refused, drop the flag and pull again" | The refusal *is* the finding. Dropping the flag merges whatever moved the base and duplicates this change in its history. |
| "I'll write the MR body from memory" | The material is `git log <base>..HEAD`. The branch in your memory and the actual branch are not the same branch. |
