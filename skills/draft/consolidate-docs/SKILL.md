---
name: consolidate-docs
description: 對專案內凌散的規格文件動一次 brownfield 手術：全量盤點→提案報告（目標樹、映射表、衝突表）→核准後按 capability 分批遷移成 docs/specs/ 真相層，原檔進 archive 不刪。日常維護走管線，不重跑這把刀。
disable-model-invocation: true
---

# Consolidate Docs

One-time brownfield surgery: turn a project's scattered spec documents into the **truth layer** — documents stating what the system *is now*, one fact per home. Day-to-day maintenance is the pipeline's job (`/to-architecture`, `/frontend-spec`, `/implement` edit the truth layer per change); this skill only bootstraps it, or recovers it after neglect. A project with code but no documents is `/bootstrap-truth`'s job — it reverse-engineers from code; mixed legacy runs this skill first, then `/bootstrap-truth` fills the holes.

Two phases with a human gate between them. Phase A never writes; Phase B never decides.

## Truth layer

The target shape this skill migrates into:

```
docs/
├── specs/<capability>.md    # per capability: behaviour rules + its API surface
├── architecture.md          # global: stack, data model
└── design-system.md         # global: style tokens (only if the project has UI)
```

- A **capability** is a business ability named in the project's vocabulary (read `CONTEXT.md` first) — not a code directory. One file each; split into a folder only past ~500 lines, never pre-emptively.
- **Truth vs change.** These files describe current state. Proposals, feature specs, plans are *changes* — they live in the issue tracker, not here.
- **The environment answers "what"; documents answer "why".** A fact derivable by reading code or config does not migrate — it is a cache that will go stale. Migrate what code cannot say: behaviour rules, rationale, conventions, gotchas.

## Phase A — inventory and proposal (read-only)

1. **Sweep everything.** Find every document that could hold behaviour claims — `docs/`, READMEs, wiki dumps, loose `.md`/`.txt` anywhere. Behaviour facts hide in README paragraphs and workflow comments; an unswept file is an unfound conflict.
2. **Card every file.** Fan out sub-agents (tens of thousands of lines do not fit one context); each returns one inventory card per file: topics, behaviour claims (verbatim, with line refs), freshness signals (last git touch, contradictions with code), inbound/outbound references. Sub-agents must never invoke this skill.
3. **Cluster claims into capabilities** using the project's vocabulary.
4. **Adjudicate freshness**: claim vs code vs git log. Code outranks prose on "what"; prose outranks code on "why".
5. **Write the proposal report**, then stop for approval:
   - the target tree;
   - a **mapping table** — every swept file → `keep` / `merge into <target>` / `archive`, one row each, with reason. Done means every swept file has a row; a file without a row is an unfinished inventory, not a footnote.
   - a **conflict table** — same fact, divergent versions: each row cites both sources (`file:line`) and carries a recommendation. Conflicts are the user's to judge. More than ~10 conflicts → produce a questionnaire instead, applying the `/to-questionnaire` rules — read its `SKILL.md` first if the rules are not in context (the Skill tool cannot load user-triggered skills).

A scope argument ("only these capabilities") narrows Phase B, never the sweep — conflicts only surface when everything is on the table.

## Phase B — migrate (after approval)

One capability per batch, each batch its own branch and PR — a ten-thousand-line PR gets rubber-stamped, not reviewed.

1. Branch from the base branch.
2. Build the capability file per the mapping: **move and dedupe, never rewrite**. When passages must merge, keep their meaning and cite the sources (`file:line`) in the commit body so the diff is auditable.
3. `git mv` fully-absorbed sources into `docs/archive/` — inbound links break silently when files vanish, and `git mv` costs nothing. Append `old path → new home` rows to `docs/archive/MAPPING.md`.
4. Update every inbound reference to the old paths (grep for them — CLAUDE.md pointers included).
5. Commit following the `/git-commit` rules — **mandatory**; read its `SKILL.md` first if the rules are not in context (the Skill tool cannot load user-triggered skills). Stage only the files this batch touched.
6. Report the batch: capability file written, sources archived, references updated, conflict judgements applied. Next step: `/git-pr` per batch.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "This doc is obviously dead, just delete it" | Links you never found still point at it. Archive; deletion saves nothing. |
| "I'll polish the wording while moving it" | A rewrite hides fact drift inside style diff. Move verbatim; polish is a separate, later change. |
| "The code confirms this claim, keep it for completeness" | A fact code can answer is a cache that goes stale. Keep the why, drop the what. |
| "Both versions look fine, I'll take the newer one" | Newer is not truer. Divergent facts go in the conflict table for the user. |
| "One big migration PR is more efficient" | A PR nobody can review is a merge nobody performed. One capability, one PR. |
