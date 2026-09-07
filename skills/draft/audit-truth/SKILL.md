---
name: audit-truth
description: 持續性稽核刀：掃描真相層找語意矛盾（只收文件↔程式碼、文件↔文件兩類），出問卷逐條裁決；裁決落在 ticket 與 commit，不另開帳本，宿主已有漂移總帳才寫進宿主格式。/bootstrap-truth 的成對守衛。
disable-model-invocation: true
---

# Audit Truth

The standing guard of the truth layer. `/bootstrap-truth` establishes truth once; this knife audits it for as long as the project lives. It is the **only contradiction engine** in the skill set — a skill that needs contradiction detection dispatches a sub-agent to apply these rules, never reimplements them.

This knife audits and files. It never rewrites the documents it audits — fixes are separate changes, filed as tickets in the project's tracker.

## Scope — two classes, everything else keeps

A finding is a **semantic contradiction** in exactly one of two classes:

- **document ↔ code** — the truth layer claims X; the code does Y.
- **document ↔ document** — two documents state divergent versions of one fact.

Everything else — style complaints, staleness suspicion with no contradicting counterpart, missing documentation — defaults to **keep**: note it in the report, never put it in the questionnaire. Missing docs are `/bootstrap-truth`'s territory; taste is nobody's.

## Evidence form — how a source is named

Every source, in the questionnaire and in the tickets, is named as **file + anchor + quote**: the path, the symbol or heading that contains it (`applyNext`, `§3.2`), and a short verbatim quote. A line number is optional garnish. Lines move under every refactor; a symbol and a quote are what `grep` finds back next month.

```
docs/03_architecture_design.md §3.2 「連續上限是最高優先硬規則」
packages/server/src/domain/commands.ts applyNext — `if (!feas.adjustedCap) return`
```

## The record — tickets while open, commits once settled

There is no ledger file. A verdict lives in two places over its life:

- **Open** — the ticket that carries it. The tracker's open drift tickets are the list of adjudicated-but-unfixed contradictions.
- **Settled** — the commit that closed it. Its body carries one **Adjudicated bullet** per verdict, in the `/git-commit` bullet shape:

  ```
  - Adjudicated 程式碼對: docs/03 §3.2 vs commands.ts applyNext — cap applies only to auto-scheduling
  ```

  `git log --grep=Adjudicated` lists every verdict the project has ever made. A body bullet, never a trailer — `/git-commit` forbids trailers and `guard-git` blocks them.

A host that already keeps a drift ledger (a spec-drift-ledger, a doc-debt register — anything recording doc↔code divergence and its adjudications) is the exception: write verdicts **in the host's format, into the host's file**, mapping onto the host's verdict classes; a verdict that fits no host class → ask the user, never invent a class. Never open a ledger where none exists, and never a second one beside a living one.

## Run

1. **Scope.** The user names the truth documents and code areas to scan; unnamed → the whole truth layer. Locate the host ledger, if any. Read the tracker's open drift tickets (`docs/agents/issue-tracker.md` says where tickets live) — a contradiction already on a ticket is skipped and listed in the report as already filed.
2. **Card claims.** Fan out sub-agents: each truth document → verbatim claims in the evidence form, each claim checked against the code it describes and against sibling documents. Sub-agents must never invoke this skill.
3. **Questionnaire the contradictions**, applying the `/to-questionnaire` rules — read its `SKILL.md` first if the rules are not in context (the Skill tool cannot load user-triggered skills). Write the file to the scratchpad, never into the repo. One question per contradiction: both sources in the evidence form, the divergence, options drawn from the host ledger's verdict classes when adapting, else 文件對／程式碼對／都錯／不確定. Each question carries a recommended verdict (`➡️`) with a one-line evidence basis — the `/grilling` split applies: evidence is this skill's to gather, the verdict is the user's. Before recommending, run `git log --grep=Adjudicated -- <file>` for both sources; a prior verdict on either goes into the evidence basis verbatim — newer is not truer, and the user decided this once already. No evidence basis → recommend 不確定.
4. Stop; the user adjudicates.
5. **File the tickets**, applying the `/to-tickets` rules — read its `SKILL.md` first if the rules are not in context. Ticket shape, sizing, and cite-truth-by-name apply; a drift ticket has no tracer bullet. When adapting to a host ledger, record the verdicts there first, then file.
   - One ticket per verdict, 不確定 included; verdicts changing the same file merge into one. The title or Context carries the word **drift** so step 1 of the next run recognises it.
   - **Done when** follows from the verdict — 文件對: the code behaves as the document states, with a test covering it; 程式碼對: the document states what the code does; 都錯: both; 不確定: one side changed to match the other, with the basis named in the commit.
   - **Context** carries both sources in the evidence form and the divergence. The ticket is the record while it is open; nothing points elsewhere.
   - **Notes** carries the Adjudicated bullet verbatim, for the closing commit's body.
   - Publish directly — the human gate is step 4, and the ticket list goes in the step 7 report. `/to-tickets`' show-before-publishing gate is intentionally skipped here: the tickets carry verdicts the user already made.
   - Done when every verdict from step 4 maps to a ticket id. A verdict without a ticket is a finding buried at the scene.
6. **Commit** when the tracker is local files (or a host ledger was written), following the `/git-commit` rules — **mandatory**; read its `SKILL.md` first if the rules are not in context. Stage only the tickets and the host ledger. The body says which tickets were filed; the Adjudicated bullets belong to the closing commits, not this one.
7. **Report**: scope and the commit SHA scanned, mechanical-check status at scan time, contradictions found, tickets filed (ids), contradictions already filed, items noted-but-kept.

## Cadence

No scan cadence lives in this skill. The user runs it when drift hurts — before a release, after a big merge, when the docs stop being trusted.

## When dispatched by another skill

`/bootstrap-truth` runs this knife inside a sub-agent during its Phase A: the sub-agent executes steps 1–3 only (scope, card, draft the questionnaire) and returns the contradiction material — the human gate and any writes belong to the host skill. A sub-agent running this skill must not invoke it again.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "This doc is old, it's surely stale" | Staleness without a contradicting counterpart is not a finding. Two sources or it keeps. |
| "The fix is one line, I'll edit the doc now" | An audit that edits its own subject can't be trusted next run. Verdicts to tickets; the fix rides the ticket's commit. |
| "The host ledger's classes don't fit, I'll start a clean one" | Two ledgers means neither is trusted. Map onto the host's classes or ask. |
| "The code is newer, so the code is right" | Newer is not truer. Divergent facts go to the user, with evidence on both sides. |
| "Options are enough — recommending would bias the user" | An adjudicator who read both sources and says nothing is withholding its homework. Recommend with the evidence basis; the verdict stays the user's. |
| "While scanning I found a bug" | A bug found is a ticket, not a detour. The scan finishes its coverage. |
| "I'll note this one in the report / in a doc, a ticket is overkill" | A finding parked in prose is a finding buried — four sat in a ledger's tail for a week, unexecuted. Anything that demands a change is a ticket. |
| "The ticket gets deleted when done, so the verdict is lost" | The closing commit's Adjudicated bullet is the durable record; `git log --grep=Adjudicated` finds it without a file. |
| "`file:line` is precise, that's enough" | A line number points into a file that moves under it. Symbol and quote survive the next refactor; the line does not. |
