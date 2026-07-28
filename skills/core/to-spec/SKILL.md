---
name: to-spec
description: Turn the current conversation into a spec and publish it to the issue tracker.
disable-model-invocation: true
---

# To Spec

Collapse what the current conversation settled into a written spec, then publish it.

**No interview.** This skill synthesises what was already decided. If questions remain open, the conversation was not finished — go back to `/grill-with-docs`. A spec that papers over an unresolved branch buys nothing.

The issue tracker was configured by `/setup-skills` — read `docs/agents/issue-tracker.md`. If it is missing, run `/setup-skills` first.

## Shape

```markdown
# <what is being built>

## Why
The problem, in the user's terms. One paragraph.

## Scope
What this covers.

## Out of scope
What it deliberately does not, and why. Load-bearing — this is the section
that stops the build drifting.

## Decisions
Each decision from the conversation, with the alternative that was rejected.
Link to an ADR where one exists rather than restating it.

## Open questions
What is still unresolved, and what would settle it. Empty is fine. Hiding
one here is not.
```

## Rules

- **Use the project's vocabulary.** Read `CONTEXT.md` first. A spec that invents its own words forces a translation step on every reader.
- **Behaviour, not implementation.** The spec says what must be true. How to build it is `/to-tickets` and `/implement`.
- **Do not invent.** Anything not settled in the conversation goes under Open questions. Filling a gap with a plausible guess is how a spec quietly becomes wrong.
- **Show the draft before publishing.** Let the user edit, then publish.

## Finish

Publish per `docs/agents/issue-tracker.md` and report the URL or path. Say the next step: `/to-tickets` to split it, or `/implement` if it turned out to be one session of work.
