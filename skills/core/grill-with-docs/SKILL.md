---
name: grill-with-docs
description: 窮追不捨的訪談，磨利一個計畫，並沿路留下紙本軌跡 — 術語表與 ADR。
disable-model-invocation: true
---

# Grill With Docs

Run a `/grilling` session against this codebase, driving `/domain-modeling` throughout.

The difference from bare `/grilling`: this one is **stateful**. What the interview settles gets written down, so the next session starts from the decision instead of re-litigating it.

## Step 0 — load the sub-skills

Two Skill tool calls, both mandatory, before the first question:

1. Load `/grilling` — it defines the interview loop this skill runs.
2. Load `/domain-modeling` — it defines the two artifacts this skill writes.

Running the interview from memory of what those skills say is how their rules silently drop.

## During the interview

Respond in the session's language throughout, whatever language this file is written in.

Read `CONTEXT.md` before the first question so the vocabulary you use is the project's, not invented. Read any ADRs covering the area being discussed — a question already settled by an ADR is a fact to look up, not a decision to ask.

When a question turns on **what a word means**, stop and run `/domain-modeling` on that term before continuing. An interview built on an overloaded word produces decisions that dissolve on contact with code.

## After the interview

Write, before doing anything else:

- **New or sharpened terms** → `CONTEXT.md`, inline
- **Every hard-to-reverse decision** → an ADR under `docs/adr/`, one per decision, recording the alternatives that were rejected and why. Written here, the ADR is `Status: Proposed` — the work does not exist yet, and a Proposed ADR must not read as current reality. `/implement` flips it to `Accepted` when the work lands.

A decision is hard to reverse if undoing it means touching code you have not written yet. Those are the ones that earn an ADR. Reversible choices do not — an ADR per preference is noise that buries the three that matter.

Then hand back to the main flow: `/to-spec` for a multi-session build, `/implement` for a small one.
