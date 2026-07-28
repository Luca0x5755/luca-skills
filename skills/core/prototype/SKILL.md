---
name: prototype
description: Build a throwaway prototype to answer one design question — a runnable program for state and logic, or several toggleable variations for UI. Use when a design question cannot be settled on paper.
---

# Prototype

A small, disposable program that answers **one** design question. Throwaway from day one: keep the answer, delete the code.

## Before writing anything

State the question in one sentence, and state what answer would change the design. "Does this state machine handle a mid-flight cancellation cleanly?" is a question. "Explore the checkout flow" is not — it has no failure condition, so it never finishes.

If you cannot name what result would make you choose differently, you do not have a prototype question. Go back to `/grilling`.

## Two shapes

**State and logic** → a runnable program with no UI. A CLI, a script, a test file. Drive it with the awkward cases directly: the concurrent edit, the expired token mid-request, the empty collection. What you are looking for is whether the model *forces* you into special cases. Three `if` branches for conditions the model should have made impossible means the model is wrong.

**UI and shape** → several **radically different** variations, toggleable from one place. Not three shades of the same layout — genuinely different structures, so the comparison teaches something. Static data, no backend, no state persistence.

## Rules

- **Real constraints, fake everything else.** The awkward part of the domain must be real. Auth, persistence, error handling, styling — fake all of it.
- **No tests.** Tests pin behaviour down; this code is being deleted. Testing a prototype is the clearest sign it stopped being one.
- **No reuse.** Prototype code that graduates into production carries every shortcut with it, unlabelled. Rebuild against the answer instead.
- **Stop when the question is answered.** Not when the prototype is finished — it is never finished.

## Finish

Write down: the question, the answer, and the one or two surprises. That paragraph is the deliverable.

If this was a detour from a main-flow session, `/handoff` that paragraph back and delete the prototype.
