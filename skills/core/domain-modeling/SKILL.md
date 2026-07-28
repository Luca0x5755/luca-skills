---
name: domain-modeling
description: Build and sharpen a project's domain language — challenge fuzzy terms, split overloaded words, record hard-to-reverse decisions as ADRs. Use when naming is the problem, when a term means different things in different places, or when a decision needs a written record.
---

# Domain Modeling

The active discipline of keeping the project's words precise. Merely *reading* `CONTEXT.md` for vocabulary is not this skill — that is a one-line lookup. This skill is for when the words themselves need work.

## The two artifacts

**`CONTEXT.md`** — the glossary. One entry per domain term:

```markdown
**Session**:
A single authenticated period for one user, bounded by login and expiry. Holds no
request state.
_Avoid_: connection, login (a login is the event that starts a Session)
```

The `_Avoid_` line is the load-bearing part. A glossary that only says what a word means does not stop the wrong word being used.

**`docs/adr/NNNN-<slug>.md`** — one decision per file. Title states the decision, not the topic: `0007-sessions-expire-after-30-days`, never `0007-session-handling`. Body covers what was decided, what was rejected, and why. No template ceremony beyond that.

## Sharpening a term

**Test for overload.** Grep the term across the codebase and docs. If it names three different things, it is doing three jobs — split it. "Account" that means the billing entity, the login identity, and the org is three terms wearing one word.

**Test for emptiness.** Ask what the term *excludes*. A term that excludes nothing is decoration. "Manager", "handler", "service", "data" usually fail this.

**Stress with scenarios.** Push edge cases at the definition until it breaks: what happens on a refund? A partial one? Two at once? The definition that survives is the one to write down.

**Prefer the word the users already say.** Inventing vocabulary buys precision at the cost of every future conversation.

## Rules

- Update `CONTEXT.md` **inline, during the work** — not in a cleanup pass afterwards. A glossary written at the end is a glossary written from memory.
- One ADR per decision. Never batch.
- Renaming a term means renaming it in the code too, in the same change. A glossary the code disagrees with is worse than no glossary.
- Record flagged ambiguities you could not resolve at the bottom of `CONTEXT.md`, with what would settle them. An open question written down beats a false definition.
