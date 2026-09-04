---
name: audit-truth
description: 持續性稽核刀：掃描真相層找語意矛盾（只收文件↔程式碼、文件↔文件兩類），出問卷逐條裁決；宿主已有漂移總帳就把裁決寫進宿主格式，絕不自開第二本帳。/bootstrap-truth 的成對守衛。
disable-model-invocation: true
---

# Audit Truth

The standing guard of the truth layer. `/bootstrap-truth` establishes truth once; this knife audits it for as long as the project lives. It is the **only contradiction engine** in the skill set — a skill that needs contradiction detection dispatches a sub-agent to apply these rules, never reimplements them.

This knife audits and records verdicts. It never rewrites the documents it audits — fixes are separate changes, filed as tickets in the project's tracker.

## Scope — two classes, everything else keeps

A finding is a **semantic contradiction** in exactly one of two classes:

- **document ↔ code** — the truth layer claims X; the code, read at `file:line`, does Y.
- **document ↔ document** — two documents state divergent versions of one fact.

Everything else — style complaints, staleness suspicion with no contradicting counterpart, missing documentation — defaults to **keep**: note it in the report, never put it in the questionnaire. Missing docs are `/bootstrap-truth`'s territory; taste is nobody's.

## Ledger adapter — where verdicts land

Before writing any verdict, find the host's existing drift ledger (a spec-drift-ledger, a doc-debt register — anything already recording doc↔code divergence and its adjudications).

- **Host has one** → write verdicts in the **host's format, into the host's file**, mapping onto the host's verdict classes. A verdict that fits no host class → ask the user; never invent a class.
- **No ledger** → use the built-in format: one `docs/drift-ledger.md`, append-only, one row per verdict — date, both sources (`file:line`), the divergence, the verdict.

Never open a second ledger beside a living one — two ledgers on one project means neither is trusted.

## Run

1. **Scope.** The user names the truth documents and code areas to scan; unnamed → the whole truth layer. Locate the host ledger (adapter above) before scanning.
2. **Card claims.** Fan out sub-agents: each truth document → verbatim claims with line refs, each claim checked against the code it describes and against sibling documents. Sub-agents must never invoke this skill.
3. **Questionnaire the contradictions**, applying the `/to-questionnaire` rules — read its `SKILL.md` first if the rules are not in context (the Skill tool cannot load user-triggered skills). One question per contradiction: both sources (`file:line`), the divergence, options drawn from the host ledger's verdict classes when adapting, else 文件對／程式碼對／都錯／不確定. Each question carries a recommended verdict (`➡️`) with a one-line evidence basis — the `/grilling` split applies: evidence is this skill's to gather, the verdict is the user's. No evidence basis → recommend 不確定.
4. Stop; the user adjudicates.
5. **Record verdicts** in the ledger (host format when adapting). The completion check is mechanical: `git diff` on the ledger file itself is non-empty — a verdict recorded anywhere else (CHANGELOG, commit message, chat) has not been recorded. If the run's earlier claims contradict what the ledger currently states, the correction goes into the ledger too.
6. **File the tickets**, applying the `/to-tickets` rules — read its `SKILL.md` first if the rules are not in context. Ticket shape, sizing, and cite-truth-by-name apply; a drift ticket has no tracer bullet. A verdict without a ticket is a finding buried at the scene.
   - One ticket per verdict that demands a change; verdicts changing the same file merge into one.
   - **Done when** follows from the verdict — 文件對: the code at `file:line` behaves as the document states, with a test covering it; 程式碼對: the document line states what the code does; 都錯: both.
   - **Context** names the ledger row (date, both `file:line`). The ledger is the record; the ticket points at it.
   - Publish directly — the human gate is step 4, and the ticket list goes in the step 8 report. `/to-tickets`' show-before-publishing gate is intentionally skipped here: the tickets carry verdicts the user already made.
7. **Commit the outputs**, following the `/git-commit` rules — **mandatory**; read its `SKILL.md` first if the rules are not in context. Stage only the ledger and this run's files. The questionnaire file lives beside the ledger while open (never in the repo root); once its verdicts are recorded, delete it in the same commit — the ledger is the durable record.
8. **Report**: contradictions found, verdicts recorded (ledger path + the diff summary), tickets filed (ids), items noted-but-kept.

## Cadence

No scan cadence lives in this skill. The user runs it when drift hurts — before a release, after a big merge, when the docs stop being trusted.

## When dispatched by another skill

`/bootstrap-truth` runs this knife inside a sub-agent during its Phase A: the sub-agent executes steps 1–3 only (scope, card, draft the questionnaire) and returns the contradiction material — the human gate and any writes belong to the host skill. A sub-agent running this skill must not invoke it again.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "This doc is old, it's surely stale" | Staleness without a contradicting counterpart is not a finding. Two sources or it keeps. |
| "The fix is one line, I'll edit the doc now" | An audit that edits its own subject can't be trusted next run. Verdicts to the ledger, fixes to tickets. |
| "The host ledger's classes don't fit, I'll start a clean one" | Two ledgers means neither is trusted. Map onto the host's classes or ask. |
| "The code is newer, so the code is right" | Newer is not truer. Divergent facts go to the user, with evidence on both sides. |
| "Options are enough — recommending would bias the user" | An adjudicator who read both sources and says nothing is withholding its homework. Recommend with the evidence basis; the verdict stays the user's. |
| "While scanning I found a bug" | A bug found is a ticket, not a detour. The scan finishes its coverage. |
| "The CHANGELOG already records the verdicts" | A record nobody can query is not a ledger, and the ledger now lies by omission. Done means the ledger file's diff is non-empty. |
| "The verdicts are in the ledger, tickets can wait" | Verdicts that never became tickets died in the field — 22 of them, never executed. Filing is part of the run, not an afterthought. |
