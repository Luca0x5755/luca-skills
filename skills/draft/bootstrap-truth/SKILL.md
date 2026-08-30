---
name: bootstrap-truth
description: 一次性正規化刀：把接管專案的文件重構成「編號合訂本＋能力薄檔」的真相層 — 在宿主既有治理的形狀內提瘦身方案、補業務能力層、標上能力對應；砍字與改事實分開 commit，事實變更一律問卷裁決。持續稽核交給成對的 /audit-truth。
disable-model-invocation: true
---

# Bootstrap Truth

One-time normalization: refactor an inherited project's documents into a truth layer that is **short, precise, and cross-mapped** — a few consolidated spec volumes plus one thin file per business capability. The deliverable is slimmer, truer documents inside the host's own structure; a relocation plan is not a deliverable (a 900-row moving table got reverted in the field — propose cuts, not moves). Paired knife: this one establishes truth once; `/audit-truth` guards it. Day-to-day maintenance is the pipeline's job (`/to-architecture`, `/frontend-spec`, `/implement`).

Two phases with a human gate between them. Phase A never writes; Phase B never invents.

## Target shape

```
docs/
├── 01_project_brief_prd.md      # business: positioning, roles, user stories, scope
├── capabilities/<name>.md       # one thin file per capability: what the system does NOW
├── 03_architecture_design.md    # consolidated spec: stack, data model, API, events
├── 04_adr.md + adr/ADR-NNN.md   # decision index + full decision texts
├── 05_frontend_spec.md          # consolidated frontend spec (only if the project has UI)
└── mockup/<page>.pen            # screen mockups (only if the project has UI)
```

- **Specs stay consolidated.** Spec content never splits into per-capability spec files — scattered specs are the disease, not the cure.
- **Capability files are thin and current-state**: what the ability does, for whom, its core behaviour rules, and which spec sections carry its contracts. The PRD records what was asked for; capability files record what the system now does.
- **Cross-mapping is mechanical.** Spec section headings name their capabilities (`## 3.5 Socket.IO 事件（能力：排場、計分）`); each capability file lists its spec sections. Orphans go red both ways: a spec section naming no capability, a capability file naming no spec section.
- **Short by method, not by quota.** No line budgets. Shortness comes from the cuts: duplicated passages, process narrative, and any fact the code or config can answer.
- The shape is the contract, not the filenames: a host whose governance already has an equivalent set (business doc / capability layer / consolidated specs / decision records / mockups) keeps its own names and numbering.

## The brake — normalize inside the host's governance

The first act of Phase A: does the target already govern its documents — numbered canon, drift ledger, doc CI, an SSOT chain in its CLAUDE.md? Found → all work happens **within that shape**: the proposal slims the host's own documents and adds only the layers the shape is missing (usually `capabilities/` and the cross-mapping tags). Never lay a second system beside a living one; never rename or renumber what already works. Only a project with no governance and genuinely scattered documents takes the migration branch — read [`MIGRATION.md`](MIGRATION.md) and follow it instead of Phase A step 5 below.

## Layer declaration (LAYERS.yaml)

> **Pending Smart-Lock validation.** The four-layer mechanism (truth / generated / history / tooling; declaration via path prefixes + orphan-goes-red check) is awaiting its first real deployment. Until that survives, this section carries no instructions — do not improvise layer content here.

## What may be reverse-engineered from code

- **Global facts** (`03`): stack table and data model — code-verifiable, land directly. Tables or a Mermaid ER diagram, whichever is shorter. The ADR column reads `資訊缺失：無決策紀錄`; never backfill a plausible rationale.
- **API surface** (`03`'s API sections, capability-tagged): contracts from routes and schemas, each carrying its source (`src/routes/order.ts:41`).
- **Behaviour rules** (capability files): code states what the system does, not whether that is a rule or an accident. Every inferred rule goes through the questionnaire; only user-confirmed rules land. Rejected → dropped. Unsure → a `資訊缺失` line.
- Views are generated, never hand-drawn: when machine-readable edge files exist (ownership maps, route tables), architecture views come from joining them; a hand-drawn copy of a derivable view is a cache.

Anything else — implementation walkthroughs, module inventories, prose paraphrases of code — does not land.

## Evidence discipline

- Claims name their source (`file:line`); a claim with no path is a hypothesis and says so.
- Quantities are counted by commands run against the repo.
- Absence is a finding: `資訊缺失：無部署設定`.
- The proposal declares coverage — the list of files actually read.

## Phase A — read and propose (read-only)

1. **Brake check** (above): pick the branch — in-host slimming (default) or migration (`MIGRATION.md`).
2. **Measure.** File count, language mix, entry points, doc and schema locations. State the reading budget out loud.
3. **Card the documents, then the code.** Fan out sub-agents: every document returns topics, behaviour claims (verbatim, with line refs), duplication and staleness signals; code areas return modules, routes, schemas, DB tables, inferred behaviour claims (`file:line`). Docs first — code fills only the holes the documents left. Sub-agents must never invoke this skill.
4. **Contradiction scan — delegated.** This skill does not implement contradiction detection. Dispatch a sub-agent that applies the `/audit-truth` rules — the sub-agent reads `skills/draft/audit-truth/SKILL.md` first (the Skill tool cannot load user-triggered skills) and returns the contradiction material; it must not invoke this skill.
5. **Write the slimming proposal**, then stop for approval. One section per document:
   - **cuts** — duplicated passages, process narrative, code-derivable facts, each with line refs and where the surviving copy lives;
   - **merges** — passages absorbed into a consolidated volume, with destination section;
   - **capability layer** — the proposed `capabilities/<name>.md` list, each with its evidence and the spec sections it will point at;
   - **cross-mapping plan** — which spec sections get which capability tags;
   - **fact changes** — anything whose meaning would change goes to the questionnaire, never silently into a cut;
   - coverage and the explicit `資訊缺失` gap list.
6. **Questionnaire** the contradictions and inferred behaviour rules, applying the `/to-questionnaire` rules — read its `SKILL.md` first if the rules are not in context. One question per item: `file:line` evidence on both sides, closed options, and a recommended answer (`➡️`) with a one-line evidence basis — the `/grilling` split applies: evidence is this skill's to gather, the verdict is the user's. No evidence basis → recommend 不確定.
7. Stop for approval of the proposal and the questionnaire verdicts.

## Phase B — execute (after approval)

One document per batch, each batch its own branch and PR. The capability layer and cross-mapping tags are their own batch; mechanical checks another.

1. Branch from the base branch.
2. **Cut-commits are fact-neutral.** A slimming commit adds and removes zero facts — wording, structure, and deletion of duplicated or code-derivable content only. Every fact change rides its own commit and cites its questionnaire verdict. A reviewer must be able to trust that a cut-commit changed nothing true.
3. **Write the capability files and stamp the spec headings** per the cross-mapping plan. Capability content comes from Phase A evidence and confirmed verdicts only.
4. **Install mechanical checks** (once): the two-way orphan check (spec section without capability, capability without spec section — red), plus regen-diff or append-only checks where the host's shape calls for them. A host with partial governance gets only the missing checks, and no templates.
5. Commit following the `/git-commit` rules — **mandatory**; read its `SKILL.md` first if the rules are not in context. Stage only the files this batch touched.
6. Report the batch: cuts applied, facts changed (each with its verdict), capability files written, `資訊缺失` lines left open. Next step: `/git-pr` per batch.

## Finish

Report the whole run: per-document before/after line counts, capability files written, checks installed, and the open `資訊缺失` gap list. Hand over the guard duty: `/audit-truth` is the standing contradiction engine from here on.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "Their governance is clumsy, mine is cleaner" | Two systems on one project means neither is trusted. Slim what exists; add only what is missing. |
| "A relocation plan is progress" | The deliverable is shorter, truer documents. A moving table nobody asked for gets reverted; propose cuts, not moves. |
| "I'll fix this fact while trimming the wording" | A cut-commit that changes a fact hides drift in style diff. Facts change in their own commit, with a verdict. |
| "The code confirms this claim, keep it for completeness" | A fact code can answer is a cache that goes stale. Keep the why, drop the what. |
| "The code obviously intends this, skip the questionnaire" | Code states behaviour, not intent. An unconfirmed rule written as truth is a guess the pipeline will trust forever. |
| "Fill the ADR column with a plausible rationale" | An invented why is worse than a missing why. `資訊缺失` is a finding. |
| "A spec file per capability is cleaner" | Scattered specs are the disease this knife cures. Specs stay consolidated; capabilities point into them. |
| "One big PR is more efficient" | A PR nobody can review is a merge nobody performed. One document, one PR. |
| "While reading I can fix this small bug" | Phase A never writes. A bug found is a ticket, not a detour. |
