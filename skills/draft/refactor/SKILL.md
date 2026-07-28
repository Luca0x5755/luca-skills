---
name: refactor
description: Restructure existing code without changing its observable behaviour. Use when the user says "refactor", "clean this up", "extract this", "this is duplicated", or asks for a structural change that must not alter behaviour.
---

# Refactor

Change the structure. Do not change the behaviour. That line is the entire definition — a diff that alters what callers observe is not a refactor, whatever it is called.

**Observable** means what crosses a seam: return values, thrown errors, persisted data, outgoing requests. Private names, internal structure, call counts are fair game — unless something external depends on them (an SLA on latency, a parser on log format). When in doubt, treat it as behaviour.

## 0. Name the trigger

State, in one sentence, which of these applies:

- **Preparatory** — a coming change is hard; this restructuring makes it easy.
- **Rule of three** — the same thing now exists in a third place.
- **Comprehension** — it took real effort to understand; write the understanding back into the code.

No trigger → stop. "It could be cleaner" is not a trigger; clean has no finish line, triggers do. The trigger goes in the commit message — it is also the stop condition.

## 1. The net comes first

Before touching structure, there must be tests that pin the behaviour being moved, and they must be green.

None exist → write **characterization tests** first: tests that record what the code *does now*, including the parts that look wrong — someone may depend on them. Pin the seam's outputs, the boundary values (empty, zero, one, huge, null), and every branch that will move. Do not chase coverage; chase *goes red when I break it*.

**From this point until done, the test files are frozen.** A test edited mid-refactor is a net you cut yourself. If a test truly must change, that is a behaviour change — stop, finish or revert the refactor, do it separately.

## 2. One transform at a time

Extract function. Move function. Rename. Inline. Introduce value type. Split phase. Pick **one**, apply it, run the tests, commit. Message names the transform: `refactor: extract calculateTax`.

- **Red** → `git reset --hard` to the last green commit and retry smaller. Never debug a half-applied refactor — that is two unknowns at once.
- Use the IDE's rename/extract where it exists. The tool does not typo; you do.
- Leaf to root: smallest independent transform first, each one making the next simpler.
- A bug found along the way gets an issue, not a fix in this diff. Mixed commits force a choice between keeping the bug and losing the refactor at revert time.

Inlining is a refactor too. An abstraction with one implementation and no second in sight gets removed, not admired. Only-ever-more-abstract is how a codebase reaches a different kind of mud.

## 3. Stop when the trigger dies

Preparatory → the change is now easy: stop and go make it. Rule of three → the duplication is gone: stop. Comprehension → it reads: stop.

Close-out, all three literally:

1. Full suite green, and the test files byte-identical to step 1.
2. Re-read the diff asking of each hunk: does this change anything a caller observes?
3. The trigger sentence is in the commit or PR description.

## When not to

- Code about to be rewritten or deleted.
- No tests and no way to write them — that inability is the real problem; hand it to `/improve-codebase-architecture`.
- Against a deadline: the payoff is in the future, the deadline is not.
- The only reason is taste.

## Boundaries

This skill is the **middle scale**. The few lines just written are `/tdd`'s refactor step — no ceremony needed. A restructuring that spans modules or changes a design decision goes through `/improve-codebase-architecture` and the main flow — too big for a single frozen-net session. And the inverse invariant of `/tdd` is the reason this is a separate skill: there, behaviour changes and a test goes red first; here, behaviour holds and nothing goes red, ever.
