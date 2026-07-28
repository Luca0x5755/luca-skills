---
name: ask-luca
description: Ask which skill or flow fits the situation. A router over the skills in this repo.
disable-model-invocation: true
---

# Ask Luca

You don't remember every skill, so ask.

A **flow** is a path through the skills. Most work runs along one **main flow**; three **on-ramps** merge onto it. Everything else is standalone or a vocabulary layer running underneath.

## Precondition

**`/setup-skills`** — run once per repo before any engineering flow. It records where issues live and where domain docs go. Skills that publish to a tracker are wrong without it.

## Main flow: idea → ship

1. **`/grill-with-docs`** — sharpen the idea by interview, leaving a paper trail in `CONTEXT.md` and ADRs. No codebase to write into? Run `/grilling` on its own.
2. **Branch — does a question need a runnable answer?** State model, business logic, a UI you have to see. Detour: **`/handoff`** out → fresh session → **`/prototype`** → **`/handoff`** back.
3. **Branch — is this more than one session of build?**
   - **Yes** → **`/to-spec`**, then **`/to-tickets`**. Each ticket declares its blocking edges. Run **`/implement`** once per ticket, clearing context between each.
   - **No** → **`/implement`** right here.

`/implement` drives `/tdd` internally and closes with `/code-review` before committing. Reach for `/tdd` alone to build one concrete behaviour test-first; `/code-review` alone to review any branch against a fixed point.

### Context hygiene

Steps 1–3 stay in **one unbroken context window** — no compact, no clear, until `/to-tickets` is done. The limit is the window where the model still reasons sharply (~120k tokens). Approaching it early means `/handoff`, not pushing on degraded.

`/handoff` forks into a new session. `/compact` (built-in) continues the same one. Compact at phase boundaries only.

## On-ramps

- **Incoming bugs and requests piling up** → **`/triage`**. Only for issues you did *not* create. Tickets from `/to-tickets` are already agent-ready — do not triage them. Output merges at `/implement`.
- **Something is broken** → **`/diagnosing-bugs`**. For the ones that resist a first glance: intermittent flakes, regressions between two known-good states. When the finding is "there was no seam to lock this down", it merges at `/improve-codebase-architecture`.
- **A fog too big for one session** → **`/wayfinder`**. Charts a map of decision tickets and resolves them one at a time, producing **decisions, not deliverables**. When the fog clears it merges at **`/to-spec`** — never straight into `/implement`, which throws the map's linked detail away.

## Codebase health

- **`/improve-codebase-architecture`** — survey for deepening opportunities. Picking one *generates an idea*, which re-enters the main flow at `/grill-with-docs`.

## Vocabulary underneath

Reach for these when the **words**, not the process, are the problem.

- **`/domain-modeling`** — the project's domain language. Challenge a fuzzy term, split an overloaded one, record a hard-to-reverse decision as an ADR.
- **`/grilling`** — the interview primitive `/grill-with-docs` and `/wayfinder` both run.
