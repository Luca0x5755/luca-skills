---
name: implement-spec
description: 依規格與票的阻塞圖，在隔離工作樹平行建置整份規格並整合至單一分支；支援已設定的追蹤器，可由操作者介入，PR 視需要建立。
disable-model-invocation: true
---

# Implement Spec

Implement a whole approved spec on one **integration branch**. Tickets form a **task graph**; the ready **frontier** contains tickets whose blockers have landed and passed integration checks. Adapted from [upstream v1.3.1](https://github.com/mattpocock/skills/blob/v1.3.1/skills/engineering/implement-spec/SKILL.md).

For committed local tickets that must run unattended with bounded retries, STALLED/parked outcomes and mandatory PR closeout, tell the user to choose `/run-queue` instead. Never invoke that user-triggered entry automatically. Workers and merger agents must never invoke either orchestrator.

## 0. Inputs and environment

Read the spec, every ticket, blocking edges, `GLOSSARY.md` (or the relevant `GLOSSARY-MAP.md` entry), and covering ADRs. Read `docs/agents/issue-tracker.md`; missing configuration: tell the user to run `/setup-skills` and stop.

Confirm approval from the supplied conversation or tracker evidence. Local markdown must be committed, with a clean feature branch. An unapproved spec is a decision to settle before building.

Use background implementer agents in independent branches/worktrees. Limit actual concurrency to available agent slots and isolated resources; reserve capacity for review/integration. Unsupported background/worktree execution: report and execute serially. The current approved feature branch may serve as integration; otherwise create one from the agreed base, preserving unrelated work.

## 1. Map and prepare

Validate the starting graph for missing references and cycles. During execution compute readiness from **verified integration results**, not remote blocked-by counts that only change after PR merge.

Keep claimed/running IDs and integrated commit pointers in session memory. Never dispatch a ticket twice. After interruption, inspect surviving branches/worktrees and resolve uncertain ownership before writing.

Optional: dispatch an exploration agent to save shared notes outside the repository. Send pointers to the spec, tickets, exact shared names/contracts and notes rather than duplicated summaries.

Before concurrent admission, inspect shared files, registries, migrations, truth documents and external resources. Overlap or uncertain isolation: serialize those tickets. Bootstrap ignored fixtures, environment and dependencies by the project's procedure; skipped required checks are not green. Verify active guards inspect the worker's real checkout. Worktrees isolate tracked files, not ports, databases or credentials.

## 2. Dispatch and build

Create each worker branch/worktree from the current integration tip; confirm its absolute root and branch before writing. Only the coordinator controls integration.

Each implementer:

1. Reads agreed seams from the approved spec/ticket. Missing or changed seams: present them to the user and wait for confirmation. This flow retains human seam approval.
2. Calls the Skill tool with `tdd` — mandatory, before tests — and builds one behavioral slice at a time.
3. Runs required tests, typecheck and lint; verifies every Done when condition. Commits only its work under the sibling `git-commit/SKILL.md` rules, read from the parent of this skill's base directory; commit only, no push.
4. Reports committed branch and observed checks. It does not close remote tickets, delete specs, update integration or open a PR.

A local worker may delete only its own ticket in its candidate commit. The coordinator preserves the spec until all referencing tickets are integrated and its promises are in the truth layer. Remote closure remains the coordinator's closeout step.

Failure or unresolved decision: preserve the candidate and evidence, report the blocker, and ask whether to repair, defer or stop. Independent work may continue if authorized and unaffected. This flow has no automatic five-round/STALLED policy; `/run-queue` supplies that contract.

## 3. Integrate serially

Dispatch a merger agent with exclusive ownership of a **candidate integration worktree**, based on the latest integration tip. It merges the worker branch there, preserves specs, and runs required combined-tree checks plus literal ticket acceptance conditions.

A conflict needing a behavioral choice is reported to the user. Repair a failing combined check only in the candidate checkout and revalidate. Preserve the last validated integration tip.

Before promotion, verify integration still equals the candidate's recorded base. A moved tip requires resynchronization and revalidation. The coordinator fast-forwards integration to the validated candidate, releases claims and computes the next frontier. The candidate may contain merge commits; earlier worker synchronization alone does not guarantee fast-forward landing.

PR required by tracker or requested by user: open a draft **after the first validated promotion**, following sibling `git-pr/SKILL.md` or `git-mr/SKILL.md` by reading it. Preserve platform language, body-file and human-merge rules. Otherwise no PR is required. Add closing references only for completed tickets; add the spec reference once all its tickets are complete.

## 4. Review and close out

All intended tickets integrated: call the Skill tool with `code-review` — mandatory — once against the agreed integration base, supplying the full spec. Send supported findings to one repair implementer in an isolated candidate checkout. Record written reasons for any rejected finding.

Run focused regression checks for repaired findings and final required suites. Do not automatically start another broad review. A new blocker is reported for the user's decision; final red or a deferred ticket keeps the PR draft and spec incomplete. Promote repair work through the same candidate integration gate.

Only after final green:

- Update implemented Proposed ADRs to Accepted and owning truth documents if not already updated.
- Local tracker: verify every promise ID/retired line is in the truth layer and no remaining ticket references its spec before deleting it; commit cleanup and validate relevant checks.
- Remote tracker: resolve tickets by configured commands. Closure through PR merge leaves tickets open with correct closing references; never report them already closed.
- Existing draft PR: mark ready only when all intended tickets and required checks are complete. Report URL. No PR: report integration branch and resolved-ticket evidence. Merge remains the user's action.

## 5. Preserve and clean

Stop workers before cleanup. Remove only this run's clean, stopped worktrees whose tracked work is integrated and whose evidence no longer needs untracked files. Verify absolute paths; use ordinary `git worktree remove`, never force. Keep unfinished branches/checkouts with pointers; no reset or deletion of another agent's work.

Permission denial or persistent guard block: stop dispatch and promotion, safely stop workers, preserve candidates and report local state. Hooks remain enabled.

Done when integration contains the complete spec, final checks are green, tracker/PR closeout matches reality, and created worktrees are cleaned or explicitly retained with reasons. Report partial work as incomplete, with blockers and branch pointers.
