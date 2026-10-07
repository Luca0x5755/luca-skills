---
name: run-queue
description: 已核可的本機票佇列無人看管執行並開 PR；預設串行，可選最多兩個工作樹平行建置，卡票擱置，merge 歸使用者。
disable-model-invocation: true
argument-hint: 預設串行；parallel 或 parallel=2 啟用兩個 worker
---

# Run Queue

Drain the local ticket queue to an opened PR. The human gate is the **published spec**: spec and tickets are committed only after the user approves them. The run is unattended after that; merging the PR remains the user's action.

This is the bounded local-queue flow. `/implement-spec` is the separate, steerable whole-spec flow across configured trackers. Suggest that entry when this flow's local-tracker precondition fails; never invoke it automatically. Workers must never invoke either orchestrator.

## 0. Preconditions and mode

- Current branch is a feature branch; working tree clean; every spec and ticket in `docs/issues/` committed. Any miss: report and stop.
- Tracker is local markdown. Tickets have `## Done when` and `## Blocked by`; specs do not.
- **Serial is the default**, retaining one fresh implementer context per ticket. An explicit `parallel` or `parallel=2` argument enables at most two implementer workers. Another limit: report that only 1 or 2 is supported.
- Parallel mode requires background agents, independent branches/worktrees and isolated test resources. If unavailable, report the limitation and use serial execution; do not claim concurrency.
- Read [PARALLEL.md](PARALLEL.md) before creating any worktree or dispatching a parallel worker. It defines preparation, resource admission, integration, denial and cleanup.

The current branch is the **integration branch**, owned by the coordinator. In serial mode it may delegate exclusive checkout ownership to the one worker until that worker stops; no other writer is active. In parallel only the coordinator writes integration. **Done** means the ticket is absent from this branch after its work is integrated and required verification is green. A deletion on a worker branch is only candidate completion.

## 1. Select the frontier

Ready means every `Blocked by` ticket is done on the integration branch and the ticket has no `STALLED` marker. Validate references and cycles against the committed initial graph; a missing dependency with no proof of prior completion is an error, not permission to start.

Choose ready tickets in numeric order. Keep claimed/running ticket IDs, assigned worktrees, retry counts and resource reservations in session memory only; never dispatch an already claimed ticket. No separate persistent progress ledger. After a restart, inspect surviving branches, worktrees and commits before dispatching; an ambiguous active worker is a reason to stop and report.

- Serial: select one ready ticket.
- Parallel: admit up to two ready, unclaimed tickets whose resources can be isolated per [PARALLEL.md](PARALLEL.md).
- No ready ticket but workers exist: wait for their outcomes; do not open the PR yet.
- No ready ticket and no workers: classify remaining tickets, then §4. An unexplained remainder or graph error stops as an incomplete draft, never as all done.

## 2. Build a ticket

Dispatch a fresh implementer subagent. It reads `implement/SKILL.md` from the parent of this skill's base directory and follows it with these explicit substitutions:

1. Seam confirmation becomes a **reviewer gate**. The worker writes proposed seams in the ticket's `## Notes`; a separate reviewer checks every Done when condition is observable through them. PASS permits tests; FAIL revises the proposal and uses a retry round. No testable seam: `STALLED (no-seam)`.
2. The worker deletes only its own ticket in the candidate commit. **It preserves every spec**, even if its checkout has no remaining reference. The coordinator owns final spec cleanup.
3. The worker commits locally by the `/git-commit` rules, read from the sibling `git-commit/SKILL.md`; no push or PR. In parallel it operates only in its assigned worktree and never changes the integration branch.

Every rejected `/code-review` finding is a `Rejected review finding: <finding> — <why>` bullet in that ticket's commit message. This is disclosed self-approval, not a hidden exception.

### Bounded retries

One round is one attempt plus verification: `/implement` §4's checks and every Done when condition. Seam revisions and candidate-integration repairs count against the **same per-ticket budget**; the counter does not reset when changing agents or moving to integration. Tickets are not rounds.

Failure signature = failing check name plus first error line.

- Rounds 1–3: same implementer, with observed failing output.
- At round 4, or immediately when consecutive signatures repeat: a fresh implementer takes over with the ticket, assigned checkout and failing output. The previous worker has stopped before handover.
- Round 5 red, or a repeated signature after handover: STALLED (`round-limit` or `repeat-failure`). No testable seam: `no-seam`.
- A new integration failure after the fifth worker-green round cannot gain a sixth attempt: preserve evidence and mark `round-limit`.

Each round reports what changed and what remains red. An unavailable test environment is reported explicitly; a skipped required test does not count as green.

## 3. Integrate or park

**Serial green:** the worker has committed and removed its ticket on the integration branch after required checks. Release its claim and return to §1.

**Parallel worker green:** follow [PARALLEL.md](PARALLEL.md)'s candidate integration gate. Only coordinator-confirmed integration green releases downstream dependencies and counts as done.

**STALLED:** preserve failing output and any committed candidate work. `git reset --hard HEAD` is limited to the failed ticket's assigned checkout, with no other active writer there; it clears uncommitted changes only. Delete only this ticket's known untracked paths after verifying their absolute paths lie inside that checkout. Never reset the integration branch to erase a committed bad merge.

The coordinator writes the marker on the still-present ticket in the integration branch:

```markdown
STALLED (<rule>): <what was built · which check is red · why the loop stopped>
```

Rules: `round-limit`, `repeat-failure`, `no-seam`, `denied`. Record the observed stop rule, not a speculative diagnosis. Commit only this change under the `/git-commit` rules. Direct and transitive dependents remain **parked**; other ready tickets may continue unless the stop is systemic.

## 4. Close the queue and open the PR

All workers have stopped, and either no ready ticket remains or a systemic denial stopped dispatch. After denial, still-ready tickets are unrun, not completed. Classify every remaining ticket as STALLED, parked, unrun, or unresolved graph error; preserve its spec while it has any remaining reference.

Only now may the coordinator remove an unreferenced spec: verify on the integration branch that every frozen promise ID and retired line is in the truth layer. Missing truth-layer evidence: retain the spec and report incomplete. Commit final cleanup, then run required final integration checks. New failures get focused validation within the affected ticket's remaining budget; unresolved failures remain disclosed, not green.

Follow sibling `git-pr/SKILL.md` §A by reading it. Skip manual squash and `/branch-cleanup`: per-ticket commits are the audit source. Remaining tickets/specs or unresolved validation: draft PR; none: normal PR. A branch with no deliverable diff cannot open a PR; report that exception and the stalled queue instead of inventing a URL.

Under 測試, disclose **自我核准痕跡**, per completed ticket, from all of its integrated commits:

- Modified/deleted existing tests: `git show --name-status --diff-filter=MD <commit>`, restricted to test files.
- `Rejected review finding:` bullets from its commit messages.
- Neither: explicitly `none`.

Under 未驗證, include all unfinished tickets and their markers, integration failures, skipped required checks and retained candidate branch pointers.

Done when every queue file has been accounted for, no worker remains active, and the PR URL (or the no-diff exception) is reported. An incomplete draft is an incomplete result, not an implemented spec.

## Rails and report

Hooks stay enabled. A permission denial is immediately systemic; a hook block becomes systemic if it persists after one correction: stop new dispatch and integration, tell workers to stop at a safe point, preserve committed candidates, mark the current ticket `STALLED (denied)`, then prepare the incomplete report. Creating/pushing a draft still requires working permissions; if denied, report the local branch instead.

Report per ticket: integrated green, STALLED with rule, parked, or unrun; rounds used; worker and integration evidence; then PR/local-branch pointer. Report permission prompts with their commands and reasons. Say every omission out loud.
