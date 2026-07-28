---
name: implement-all
description: 從議題追蹤器抓出可動工的票，依阻塞邊排程，每張票派一個子代理跑 /implement，彙整回報。只編排不動手，合併永遠留給使用者。
disable-model-invocation: true
argument-hint: 可選 — 限定票號或標籤
---

# Implement All

Clear the open tickets: schedule by blocking edges, run each ticket through the `/implement` skill in an isolated subagent, aggregate one report. This skill orchestrates; it never builds anything itself.

## 1. Load the ticket list

Read `docs/agents/issue-tracker.md` for the exact list command and how blocking edges are expressed. No such file → stop and ask the user to run `/setup-skills` first.

List open tickets, narrowed by the argument if one was given. Zero tickets → report that and stop.

## 2. Schedule by blocking edges

Build the run order from the tickets' declared blocking edges:

- A ticket whose blockers are all closed is **ready**.
- Ready tickets that touch disjoint files may run in parallel, each in its own git worktree on its own branch.
- Unsure whether two tickets overlap → run them sequentially. A wrong parallel guess costs a merge conflict; a wrong sequential guess costs minutes.

Present the schedule — waves, what runs in parallel, what waits — and **wait for the user's approval before dispatching anything**. This one checkpoint replaces N mid-run interruptions: subagents cannot ask the user questions.

## 3. Dispatch

One subagent per ticket, hard turn limit, each instructed to:

- Run the `/implement` skill on its ticket, on its own branch (parallel tickets: own worktree).
- Treat the approved schedule as the seam confirmation `/implement` step 2 asks for. A ticket that names no seam is **blocked** — report it, never invent a seam mid-flight.
- Return a structured result and nothing else:

```
ticket: <id>
status: done | blocked
branch: <name>
commits: <n>
blocker: <one line, only when blocked>
```

A subagent that stalls or dies is recorded as `blocked`; its branch stays as-is for a human to pick up. Failed work is never cleaned away.

## 4. Report

One table: ticket, status, branch, blocker. Then:

- Blocked tickets: quote each blocker verbatim and ask the user how to proceed.
- Done tickets: branches are ready for review. **Never merge, never open PRs, never delete branches** — those are the user's buttons.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "These two tickets look independent, parallelize" | Looking independent is not being independent. Unsure → sequential. |
| "The subagent is stuck, I'll finish its ticket myself" | An orchestrator that starts building loses the plot. Record blocked, move on. |
| "All green — I'll merge the branches to save the user a step" | Merge is the trust boundary. It is the user's button. |
| "The ticket names no seam, I'll pick a reasonable one" | Seams are agreed with humans before dispatch. That ticket is blocked. |
