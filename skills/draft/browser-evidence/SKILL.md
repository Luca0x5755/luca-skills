---
name: browser-evidence
description: 開一個真的瀏覽器跑過既定步驟，把每一步拍成可交付的證據 — 截圖、網路紀錄與被測版本 manifest，存進獨立的 evidence 分支。
disable-model-invocation: true
---

# Browser Evidence

Drive a real browser through a given list of cases and leave behind an **exhibit**: numbered screenshots, a network log, and a record of what version was under test. The exhibit outlives the session and crosses to another person — an acceptance reviewer, a client, whoever fixes what it shows.

That is the line against `/run`. `/run` is *let me see it work*: a screenshot, glanced at, discarded. This is *let me prove it worked* — captured for someone who was not watching.

## Scope

Capture only. The case list arrives from outside — another person, another skill. The verdict is a human's.

So: record a `403`, and leave whether it should have been a `200` to the reader. Every temptation to judge inside this skill is the skill exceeding itself.

## 0. Check the contract

Each case needs exactly two things:

- a **stable ID** (`TC-ONSITE-01`) — it becomes the evidence directory name
- an **ordered step list** — the order becomes the screenshot filename prefix

Either one missing means the numbering cannot be generated and every file lands unnamed. Stop and ask for it before launching anything. Preconditions, expected results and priorities are welcome and ignored.

**IDs are frozen once issued** — a case whose content changed keeps its number, and a retired number is never reissued. Holding that line is the list generator's half of the discipline. This skill's half is the reconciliation in step 1, which only tells the truth while the numbers hold still.

## 1. Open the evidence worktree

Evidence lives on `evidence`, an **orphan branch** — no common ancestor with `main`, so it never merges in by accident and never tangles the graph. Create it once:

```bash
git worktree add --detach ../<repo>-evidence
git -C ../<repo>-evidence checkout --orphan evidence
```

Thereafter `git worktree add ../<repo>-evidence evidence`. The main working tree stays untouched — capture runs while code stays checked out on the branch under test.

Layout on that branch: `<TC-ID>/NN-slug.png`, `<TC-ID>/manifest.json`, `<TC-ID>/network.json`, `<TC-ID>/console.json`, and the driver under `scripts/`.

**Reconcile before capturing.** List the `<TC-ID>/` directories already there against the IDs in this run's list, and report every directory no incoming case claims. Report them; deleting is the user's call.

Re-running a case **overwrites its directory**. Version history is git's job, and a second copy under a dated name is that job done worse.

## 2. Generate the driver

Read [`DRIVER.md`](DRIVER.md) before writing the first line — mandatory. It carries the launch flags, the banner, the numbering, and two pitfalls that have already cost a false defect report.

Python + Playwright, every time. The script sits outside the project's dependency tree, so a Node project keeps its `package.json` clean — and one fixed runtime keeps exhibits looking the same across projects, where a per-project choice lets the format drift.

The script is written into the worktree and committed with the evidence, because *reproducible* is part of *credible* — the reader can rerun it rather than take the pictures on faith. Two rules keep that from rotting:

- **The script is a snapshot, not a library.** The next run generates a fresh one. Selectors differ per project and per sprint; a driver that gets maintained becomes a dependency nobody signed up for.
- **Every credential is read from an out-of-repo file** (`uat-creds.env`) **or the environment.** The file stays out of git. A literal in the script is permanent on a remote branch, and it is also printed into this conversation the moment it is generated. Open the script with a comment naming the keys it expects — otherwise whoever reruns it stalls on the first line.

## 3. Capture

Headed, slowed, and narrated: the operator watches it happen, and the narration is burned into the screenshots so the reviewer needs no separate key.

**Redact before capture, not after.** Before each shot, ask whether the frame holds real people — names, phones, addresses, prices. If it does, rerun that step against test data, or mask before shooting. This branch gets pushed, and a push is permanent.

**A red case does not stop the run.** Capture the failure as carefully as a pass — shots, network, console — then move to the next case. The list is run whole; stopping at the first failure delivers one defect and hides the rest.

Done when every ID on the list has a directory and every step of every case has a numbered shot. A run that covered five of eight cases is reported as five of eight.

## 4. Record the chain of custody

One `manifest.json` per case directory — per case, so that rerunning a single case leaves the others' records honest:

```json
{ "tc": "TC-ONSITE-01", "commit": "<SHA under test>", "env": "<base URL>",
  "ran_at": "<ISO 8601>", "browser": "<chromium version>" }
```

The `commit` is the whole point: evidence on an orphan branch has no other link back to the code it tested. It also makes *is this exhibit stale?* a question a machine can answer.

## 5. Hand off

Stage the files this run produced — the case directories and the driver, by path. Then stop: **committing is the user's move.** They run `/git-commit`, which owns the message format, the branch check, and the push. That pause is the last place a frame that should have been redacted can still be caught, and a push cannot be taken back.

Report: cases captured, orphan directories found, and every step that needed a redaction. **Anything skipped gets said out loud.** Every claim in the report names its exhibit file (`TC-ONSITE-01/03-submit.png`); "should", "probably" and "seems" have no place in one — a statement without an exhibit behind it is an opinion, and opinions are the reviewer's department.

Once they have committed, `git worktree remove ../<repo>-evidence`. The worktree goes; **the branch stays.** `evidence` accumulates every exhibit ever captured — the defects one documents getting fixed is not a reason to retire it. An abandoned worktree, meanwhile, stays invisible until `git worktree list` is long enough to hurt.

## Where this sits

Downstream of `/implement` and `/code-review`: the manifest pins a commit, so there has to be a built, reviewed version to pin.
