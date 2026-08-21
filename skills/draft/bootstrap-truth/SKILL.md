---
name: bootstrap-truth
description: 為只有程式碼、沒有文件的接管專案冷啟動真相層：讀碼盤點→提案報告（capability 清單、Stack、資料模型）→行為規則出問卷逐條裁決→核准後分批寫入 docs/。有零星舊文件先跑 /consolidate-docs 搬完，這把刀只讀碼補洞。
disable-model-invocation: true
---

# Bootstrap Truth

One-time cold start: reverse-engineer the **truth layer** for an inherited project that has code but no documents. `/consolidate-docs` migrates documents; this skill reads code. A project with scattered docs runs `/consolidate-docs` first — this skill fills only the holes left. After bootstrap, maintenance is the pipeline's job (`/to-architecture`, `/frontend-spec`, `/implement`).

The output is the persistent truth layer, not a report — a throwaway walkthrough is `/study-repo`'s job.

Two phases with a human gate between them. Phase A never writes; Phase B never invents.

## What may be reverse-engineered

The truth layer's own shape decides. Three grades:

- **Global facts** (`docs/architecture.md`): stack table and data model — code-verifiable, land directly. The data model is tables or a Mermaid ER diagram, whichever is shorter — same rule as `/to-architecture`, which maintains it per change afterwards. The ADR column reads `資訊缺失：無決策紀錄`; never backfill a plausible rationale.
- **API surface** (`docs/specs/<capability>.md`): contracts from routes and schemas, each carrying its source (`src/routes/order.ts:41`).
- **Behaviour rules**: code states what the system does, not whether that is a rule or an accident. Every inferred rule goes through the questionnaire (Phase A step 5); only user-confirmed rules land. Rejected → dropped. Unsure → a `資訊缺失` line.

Anything else — implementation walkthroughs, module inventories, prose paraphrases of code — does not land: it is a cache that will go stale.

## Evidence discipline

- Claims name their source (`file:line`); a claim with no path is a hypothesis and says so.
- Quantities are counted by commands run against the repo.
- Absence is a finding: `資訊缺失：無部署設定`.
- The proposal declares coverage — the list of files actually read.

## Phase A — read the code, propose (read-only)

1. **Measure.** File count, language mix, entry points, schema locations. State the reading budget out loud.
2. **Card the code.** Fan out sub-agents by area; each returns cards: modules, routes, schemas, DB tables, invented vocabulary, inferred behaviour claims (verbatim intent, with `file:line`). Sub-agents must never invoke this skill.
3. **Propose capabilities** from the code's native vocabulary (route groups, module names, DB tables). No `CONTEXT.md`? List the native vocabulary as a report appendix; the formal glossary stays `/domain-modeling`'s job — do not produce one here.
4. **Write the proposal report**: the target tree; a capability table (name, evidence files, proposed spec file); the stack table and data model draft; the coverage list.
5. **Questionnaire the behaviour rules**, applying the `/to-questionnaire` rules — read its `SKILL.md` first if the rules are not in context (the Skill tool cannot load user-triggered skills). One question per inferred rule: the rule, its `file:line` evidence, options 規則／巧合／不確定.
6. Stop for approval of the report and the questionnaire verdicts.

## Phase B — write (after approval)

One batch per branch and PR: `docs/architecture.md` first, then one capability per batch.

1. Branch from the base branch.
2. Write only what Phase A evidenced and the user confirmed — an unevidenced, unconfirmed fact does not land, however plausible.
3. Commit following the `/git-commit` rules — **mandatory**; read its `SKILL.md` first if the rules are not in context. Stage only the files this batch touched.
4. Report the batch: files written, `資訊缺失` lines left open, questionnaire verdicts applied. Next step: `/git-pr` per batch.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "The code obviously intends this, skip the questionnaire" | Code states behaviour, not intent. An unconfirmed rule written as truth is a guess the pipeline will trust forever. |
| "Fill the ADR column with a plausible rationale" | An invented why is worse than a missing why. `資訊缺失` is a finding. |
| "A spec file per module is more complete" | A capability is a business ability, not a directory. A module inventory reads as thorough and teaches nothing. |
| "Those scattered old docs look dead, skip /consolidate-docs" | Unswept files are unfound conflicts. Docs first, code second. |
| "While reading I can fix this small bug" | Phase A never writes. A bug found is a ticket, not a detour. |
