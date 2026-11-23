---
name: to-architecture
description: 在規格與拆票之間定架構：技術棧、資料模型、API 合約 — 直接寫進 feature branch 上的架構合訂本（docs/03_architecture_design.md），章節標能力、只引用承諾 ID，與程式碼同 PR 合併。每個取捨仍寫成獨立 ADR，文件只引用不重述。多 session 建置才需要，可選。
disable-model-invocation: true
---

# To Architecture

Turn a spec into the technical decisions the tickets will depend on: tech stack, data model, API contracts. Runs after `/to-spec`, before `/to-tickets` — architecture decisions directly change how work should be split, so settle them first.

**Optional step.** A one-session change, or a change inside an architecture that already exists, does not need this. Reach for it when the spec spans multiple sessions and the tech choices are genuinely open.

The issue tracker and docs layout were configured by `/setup-skills` — read `docs/agents/`. If missing, run `/setup-skills` first.

## Truth layer, branch as staging

This skill edits the **truth layer** — the documents describing what the system *is*:

- `docs/03_architecture_design.md` — the consolidated architecture volume: stack, data model, and the API contracts this spec touches. Specs stay consolidated — never split contracts into per-capability spec files.
- `docs/capabilities/<name>.md` — when a new section lands in `03`, the owning capability file's spec-section list gains the pointer (and a new capability gets its file). The capability-file shape lives in the target's `docs/agents/domain.md`; read it there before writing one.

**Promises are cited by ID.** A section of `03` names the promises it serves by ID (`PR-ORDER-03`) and never restates promise text — that text lives only in the capability file.

**Cross-mapping is mechanical.** Every `##` heading this skill writes or touches in `03` carries its capability tag (`## 3.4 REST API（能力：訂單）`; a project-wide section takes `（能力：共用）`); an untagged `###` inherits its parent's tag, except `共用`. The capability file lists the heading back. A heading missing either side is blocked by the check /setup-skills installs.

Current docs follow the **現行文件與歷史文件** section of the target's `docs/agents/domain.md` — read it there before writing; this skill does not restate it.

**Edit only on the feature branch.** The edits merge in the same PR as the code they describe, so `main`'s documents never claim anything `main`'s code doesn't do — no draft markers, no fold-back step, no sync ritual. No truth layer yet? An inherited legacy project goes through `/bootstrap-truth` first; a young project just starts its `03` and first capability file here.

## Shape

Touch only the sections this spec changes; neighbouring prose stays as it is.

In `docs/03_architecture_design.md`:

```markdown
## Stack（能力：共用）
| Layer | Choice | ADR |
| --- | --- | --- |
| <db / queue / framework…> | <choice> | [ADR-007](adr/ADR-007-….md) |

## Data model（能力：共用）
Core entities, who owns each, the relations that matter,
and judgment constraints ("an order has at most one open payment").
Tables or a Mermaid ER diagram — whichever is shorter.
Schema code exists → column types and seed or config defaults are a
pointer to the file (`db/schema.sql`), never a copy.

## <API section>（能力：<capability>、…）
Endpoints and payload shapes the tickets will build against.
Promises served: PR-ORDER-03, PR-ORDER-07.
Only the contracts tickets need — not a full REST catalogue.
Measured constraints (latency budgets, quotas) sit beside the contract
they bound; no measured target → no constraints prose.
```

## Rules

- **Views are generated, never hand-drawn.** When machine-readable edge files exist (ownership maps, route tables, module graphs), an architecture view is produced by a generator that joins them; a hand-drawn copy of a derivable view is a cache that drifts.
- **One ADR per decision — the documents link, never restate.** Every Stack row that involved a real trade-off gets its own ADR via `/domain-modeling` (its three-part gate decides; a choice with no alternative considered gets no ADR and no apology).
- **Clean what you touch, in a cut-commit.** Before writing new content into a section, delete its 文件快取資訊 (anything code, config or one lookup already answers) and its restated text (promise text, ADR trade-offs), then commit that alone, under the same `/git-commit` rules as Finish, as a fact-neutral cut-commit: words removed, no fact changed. Untouched sections stay as they are. There is no line budget.
- **Write the post-merge truth.** Contract prose states what is true once this PR merges — no "we will", no changelog voice, no history of what it used to be (git holds that).
- **Do not invent.** The material is the spec and the conversation. An open tech choice goes back to `/grill-with-docs` or gets a `/prototype` detour — it does not get a plausible default.
- **Use the project's vocabulary.** Read `GLOSSARY.md` first; the data model must use its terms.
- **Show the draft before writing.** Let the user edit, then write the files and the ADRs.

## Finish

**Commit — mandatory, commit only.** Follow the `/git-commit` rules for the files this skill wrote; read `git-commit/SKILL.md` first, in the parent of this skill's base directory. The cut-commit is already in; this is the content commit. Nothing written → no commit.

Report the files edited and the ADRs created, then the rest of the route as **one chain**, each hop tagged with its trigger: `/frontend-spec` (UI surface) when the spec has one, then `/to-tickets` (multi-session) or `/implement` (one session). Tickets cite the contracts and entities by name; the truth-layer edits ride the feature branch and merge with the code.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "I'll batch the trade-offs into the document, ADRs later" | Later is never. The document restating decisions is a second source of truth that starts lying the day an ADR changes. |
| "Faster to edit the docs on main directly" | Then main describes code that doesn't exist. The branch is the staging area; the PR is the atomic unit of truth. |
| "While I'm here, that stale neighbouring section needs a rewrite" | Scope creep hiding fact drift in an unrelated PR. Touch what this spec changes; stale prose gets its own change. |
| "A C4 diagram makes it look complete" | Ceremony is not completeness. Diagrams earn their place by answering a question a ticket will ask. |
| "The spec didn't pick a database, Postgres is a safe default" | A guessed default is a decision nobody made. Unsettled choices go back upstream. |
