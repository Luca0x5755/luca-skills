---
name: run-queue
description: spec 草稿核可後，無人看管地逐張做完 docs/issues/ 裡的票並開出 PR；卡住的票擱置、其餘照做，merge 仍歸使用者。
disable-model-invocation: true
---

# Run Queue

Drain the ticket queue to an opened PR. **The one human gate is the approved spec**; everything after it runs unattended and ends at the PR. Merging is the user's button.

The queue is the directory `docs/issues/` on the current branch. A ticket is a file with `## Done when` and `## Blocked by` sections; the spec is the file without them. **Done = the file is gone** (`/implement` removes it in its own commit). No progress file exists, so there is no second state to drift.

## 0. Preconditions

All must hold; any miss → stop and say which:

- Current branch is a feature branch, working tree clean.
- The spec was approved by the user, in this conversation or an earlier one.
- The tracker is local markdown. Any other tracker → stop; this skill does not drive it.
- The commands the loop runs (git, the project's test/lint commands, `gh pr create`) are allowlisted in `.claude/settings.json`. A permission prompt is a human wait; one that appears mid-run → stop and name the command.

## 1. Pick a ticket

**Ready** = every ticket named in its `Blocked by` is gone, and it carries no `STALLED:` marker. Take the first ready ticket in numeric order. No ready ticket → go to §4.

## 2. Run one ticket

Dispatch a **fresh subagent** per ticket — one ticket per context is `/implement`'s own contract. Subagents never invoke this skill. The Skill tool cannot load a user-triggered skill, so the subagent reads `skills/core/implement/SKILL.md` (or the installed copy) and follows it, with one substitution:

**§2 "Wait for confirmation on the seams" becomes a reviewer gate.** The implementer writes the seams into the ticket's `## Notes`. A separate reviewer subagent checks each *Done when* condition against them: observable through a seam, or not. Verdict PASS or FAIL. FAIL sends the implementer back to revise the seams, and that pass is a round (below). No testable seam exists → STALLED at once: that is `/implement`'s existing "the finding", routed to the user at the end instead of mid-run.

### The retry loop

One **round** = one fix attempt plus one verify; verify is `/implement` §4 (full suite, typecheck, lint, `/code-review`, every *Done when* condition). The counter resets per ticket; tickets are not rounds. A *failure signature* is the failing check's name plus its first error line; equal signatures on consecutive rounds mean no progress.

1. **Rounds 1–3**: the same implementer continues, given the failing output.
2. **Handover to a fresh subagent** at round 4, or earlier the moment a signature repeats on consecutive rounds. It gets the ticket and the last failing output only.
3. **STALLED** when round 5 is red, or when a signature repeats on consecutive rounds after the handover.

Each round states what changed and what is still red, as one line.

## 3. Close a ticket

- **Green** → `/implement` has committed and removed the ticket. Back to §1.
- **STALLED** → return the tree to the last commit (`git reset --hard HEAD` is the one reset the guard allows; delete this ticket's untracked files by explicit path). Append the marker below to the ticket file.

```markdown
STALLED: <what was built · which check is red · why the loop stopped>
```

Commit step, mandatory: read `skills/core/git-commit/SKILL.md` and follow its rules, staging the ticket file by explicit path.

Every ticket that names a STALLED ticket in `Blocked by`, directly or through another parked ticket, is **parked**. It stays untouched and is never picked.

## 4. Open the PR

The loop is over when no ready ticket remains. List `docs/issues/` and classify every remaining file: STALLED, parked, or spec. A spec stays while any ticket cites it; `/implement` removes it with the last one.

Follow `skills/core/git-pr/SKILL.md` §A. `/branch-cleanup` is skipped: it needs the user to select scope. Two differences from a plain PR:

- STALLED or parked tickets exist → `gh pr create --draft`, with each one listed under 未驗證 together with its `STALLED:` line.
- Nothing remains → a normal PR.

**Done when**: `docs/issues/` holds no ready ticket, and the PR URL is reported.

## Report

Per ticket: green, STALLED, or parked, with rounds used. Then the PR URL. **Anything skipped is said out loud** — a parked ticket that goes unmentioned reads as shipped.

## Rails

Hooks stay on. `guard-git` and `guard-secrets` are what make unattended commits safe: a block is feedback to follow, never an obstacle to route around. A hook block that persists after one correction → STALLED.
