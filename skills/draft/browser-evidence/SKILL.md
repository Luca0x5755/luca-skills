---
name: browser-evidence
description: 開一個真的瀏覽器跑過既定步驟，把每一步拍成可交付的證據 — 截圖、網路紀錄與被測版本 manifest，存進獨立的 evidence 分支。
disable-model-invocation: true
---

# Browser Evidence

Drive a real browser through a given list of cases and leave behind an **exhibit**: numbered screenshots, a network log, and a record of what version was under test. The exhibit outlives the session and crosses to another person — an acceptance reviewer, a client, whoever fixes what it shows.

That is the line against `/run`. `/run` is *let me see it work*: a screenshot, glanced at, discarded. This is *let me prove it worked* — captured for someone who was not watching.

## Scope

Capture only. The case list arrives from outside — by default from `/uat-cases`, whose ledger holds the other half of the ID discipline; a list from any other source is equally welcome as long as it meets the contract below. The verdict is a human's.

So: record a `403`, and leave whether it should have been a `200` to the reader. Every temptation to judge inside this skill is the skill exceeding itself.

## 0. Check the contract

Each case needs exactly two things:

- a **stable ID** (`TC-ONSITE-01`) — it becomes the evidence directory name
- an **ordered step list** — the order becomes the screenshot filename prefix

Either one missing means the numbering cannot be generated and every file lands unnamed. Stop and ask for it before launching anything.

The other fields a case may carry — 狀態, 負責人, 來源, 角色, 前置條件, 期望結果 — are welcome and **flow into the case report** verbatim. A field the list didn't provide is printed as 「未提供」, never silently dropped: a visible gap gets filled, an invisible one doesn't. Priorities stay ignored — a UAT list is run whole.

**IDs are frozen once issued** — a case whose content changed keeps its number, and a retired number is never reissued. Holding that line is the list generator's half of the discipline. This skill's half is the reconciliation in step 1, which only tells the truth while the numbers hold still.

## 1. Open the evidence worktree

Evidence lives on `evidence`, an **orphan branch** — no common ancestor with `main`, so it never merges in by accident and never tangles the graph. The worktree mounts at `.evidence/` **inside the project**, so the exhibit travels with the repo instead of sitting in a sibling directory the next person never finds.

`.evidence/` goes into the project's `.gitignore` **before the first mount**. That directory is a working tree for another branch; left untracked-but-visible, it turns `git status` on `main` permanently dirty and any `git add .` sweeps the whole exhibit onto the wrong branch. The leading dot also keeps test runners, linters and IDE indexers out of it by default. So:

```bash
echo '.evidence/' >> .gitignore    # once, committed to main
git worktree add --detach .evidence
git -C .evidence checkout --orphan evidence
```

Thereafter `git worktree add .evidence evidence`. The main working tree stays untouched — capture runs while code stays checked out on the branch under test.

Layout on that branch is keyed by **run first, case second**: `<YYYY-MM-DD>-<short-SHA>/<TC-ID>/NN-slug.png`, with `REPORT.md`, `manifest.json`, `network.json` and `console.json` beside the shots, and the driver plus the run index `REPORT.md` at the root of the run directory.

The run key carries a date for the human and a short SHA for the machine. The date alone collides the moment a build is captured twice in a day; the SHA states which build the exhibit tested without opening a single file.

**A run directory is never overwritten.** Each one is a complete exhibit of one build, so pinning a release means keeping its directory — not checking out an old commit to reconstruct what was captured. Within a run, re-capturing a case does overwrite that case's directory; across runs, nothing is ever touched again.

Storage therefore grows monotonically, by design. When that starts to hurt, retention is a policy decision and belongs in the project's `docs/test-blueprint.md` alongside the other scheduling policy — not a rule this skill invents.

**Reconcile before capturing.** Compare this run's ID list against the **most recent previous run directory**, never against every directory on the branch — the whole history would come back as orphans. Report every ID that run captured and this list no longer claims: those are cases retired or renumbered upstream. Report them; deleting is the user's call.

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

Done when every ID on the list has a directory, every step of every case has a numbered shot, and every case's report has its 觀察 lines filled. A run that covered five of eight cases is reported as five of eight.

## 4. The report — capture made readable

A pile of PNGs and JSON is raw material; the reader was promised an exhibit. Two files per run:

- `<RUN>/<TC-ID>/REPORT.md` — one per case, the document a reviewer actually reads. The driver writes the skeleton (see [DRIVER.md](DRIVER.md)), so a report *exists* for every captured case by construction; the agent fills the 觀察 lines **the moment the case finishes**, while the frame is still up. A description reconstructed later from stale screenshots is where "should" and "probably" creep in.
- `<RUN>/REPORT.md` — the run index: operator, which cases ran (five of eight is five of eight), a link per case report, every skip, every redaction, orphan directories. **It lists, it never restates** — a copy of case content is a second document waiting to diverge.

In the case report, steps expand one by one, each step's screenshot embedded under it, followed by two lines:

- **機器事實** — what the capture files recorded: status codes, console errors, final URL.
- **觀察** — the literal words of the frame. The line between observation and verdict: **a sentence that still reads without the 期望結果 is an observation; one that only means something against it is a verdict.** 「覆核率統計顯示 100%」 stands on its own — write it. 「覆核率符合要求」 doesn't — verdicts live in `docs/uat-cases.md`'s 最近判定, registered by the human who read this report.

Every sentence names its exhibit (`03-escalation.png`, `network.json`); "should", "probably" and "seems" have no place here — a statement without an exhibit behind it is an opinion, and opinions are the reviewer's department.

```markdown
## TC-COMPLIANCE-05 — SOP 未經 family review 不得 adopt
- **狀態**：active ／ **負責人**：未提供 ／ **角色**：知識審核者
- **來源**：Excel ch11／FR-REF-03、NFR-Aud-004
- **前置條件**：一份未經 family review 的 SOP draft
- **期望結果**：adopt 必須失敗；覆核率 100%

### 步驟 1 — 直接對該 draft 執行 adopt
![](01-adopt.png)
- **機器事實**：`POST /api/sop/adopt → 403`（network.json）
- **觀察**：畫面顯示紅字「需完成 family review」，adopt 按鈕呈灰階（01-adopt.png）
```

## 5. Record the chain of custody

One `manifest.json` per case directory — per case, so that rerunning a single case leaves the others' records honest:

```json
{ "tc": "TC-ONSITE-01", "commit": "<SHA under test>", "env": "<base URL>",
  "ran_at": "<ISO 8601>", "browser": "<chromium version>", "operator": "<who drove>" }
```

`operator` is who drove the browser this run — an attribute of the execution. Who *owns* the case (負責人) is an attribute of the case and lives upstream in `docs/uat-cases.md`. Often the same person; by coincidence, never by design.

The `commit` is the whole point: evidence on an orphan branch has no other link back to the code it tested. It also makes *is this exhibit stale?* a question a machine can answer.

## 6. Hand off

Stage the files this run produced — the case directories and the driver, by path. Then stop: **committing is the user's move.** They run `/git-commit`, which owns the message format, the branch check, and the push. That pause is the last place a frame that should have been redacted can still be caught, and a push cannot be taken back.

In the conversation, say **where to read and what went wrong**: the run directory path, five of eight if it was five of eight, every skip, every redaction, orphan directories — and nothing more. The content lives in the reports now; restating it here is a copy that evaporates with the session. Skips and redactions are said out loud *here*, not just in the index, because this pause is the last gate before an irreversible push.

Once they have committed, `git worktree remove .evidence`. The worktree goes; **the branch stays.** `evidence` accumulates every exhibit ever captured — the defects one documents getting fixed is not a reason to retire it. An abandoned worktree, meanwhile, stays invisible until `git worktree list` is long enough to hurt.

## Where this sits

Downstream of `/implement` and `/code-review`: the manifest pins a commit, so there has to be a built, reviewed version to pin.

When a run happens — pre-release, periodic — is scheduling policy and lives in the project's `docs/test-blueprint.md` when one exists. This skill captures; it does not schedule.
