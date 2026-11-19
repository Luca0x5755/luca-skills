---
name: salvage-branch
description: 從棄置分支相對 main 的增量（含 git 歷史與中途刪掉的議題）回收故事、情境、概念與被推翻的過程，寫成不進 git 的種子文件，供從 main 重新開發；只標記不改寫。
disable-model-invocation: true
---

# Salvage Branch

Recover the design intent of an **abandoned branch** — a feature branch that will not merge — so the user can edit it and restart from `main`. The output is a **seed document**: `AI_SALVAGE-<branch-slug>.md` at the repo root, untracked. It is an agenda for the restart, not a spec: every entry is an open question.

The branch is evidence. Read it with `git show` / `git log` / `git diff` only — no checkout, no commit, no delete, rename or tag. Its commit hashes are the seed's citations.

Two facts shape every step:

- **The tip lies.** A branch closed out before abandonment has had its interim decisions condensed into a final state; ADRs rewritten in place and decision-log entries folded leave no trace at the tip. Reversals live only in `git log -p` and in issue files deleted mid-branch.
- **Drift reaches intent.** Stories and glossary terms written mid-branch absorb the solution being built — routes, screens, columns, endpoints. Copying them across carries the failure into the restart. So this skill **marks**; rewriting is a design decision and belongs to the user.

## 1. Bound the increment

Take the branch name from the user (a local branch or `origin/<name>`); ask when none is given. The start is `git merge-base <branch> main`, or `dev` when that is the integration branch — the nearer candidate wins, a tie or no common ancestor → ask for a start commit. Branch tip equals start → nothing to salvage; say so and stop.

Locate the design documents through the host's `docs/agents/domain.md` (glossary, capability files, ADRs, decision log) and `docs/agents/issue-tracker.md` (where specs and tickets live, local or remote). Either file missing → infer locations from paths and headings, and record the inference in the seed's header so the user can correct it.

Done when the start commit is fixed and every document role has a location, recorded or inferred.

## 2. Inventory, history included

Scope is the branch's increment only. Collect:

- **Living** — `git diff --name-status <start>..<branch>` on the design locations.
- **Deleted mid-branch** — `git log --diff-filter=D --name-only <start>..<branch>`. Read each at its last version, `git show <deleting-commit>^:<path>`; earlier versions through `git log -p -- <path>`.
- **Pre-existing files the branch edited** — keep only the branch's hunks. A hunk that rewrote `main`'s own text carries both sides, before and after.
- **Remote issues** — when the tracker is remote, the specs and tickets the branch's commits reference, fetched with the tracker file's command.

Code is out of scope, except as evidence for which decision actually got built.

Done when every design-document path the branch touched is in the inventory or listed in the seed's header as skipped, with the reason.

## 3. Trace the reversals

Walk `git log -p --reverse <start>..<branch>` over the inventory. A **reversal** is a settled statement later replaced, deleted or contradicted: a glossary definition or `_Avoid_` line, a promise, an ADR body rewritten under the same number, a decision-log entry edited or folded, an option once rejected and later adopted. A wording polish is no reversal, and neither is a later commit date alone.

Record each reversal with: the original, the replacement, the commits, the reason, and one **layer** — story, concept, rule, UI, data model, architecture/API, process. The reason is a quote from a commit message or document; where neither states one, write `未記`. A plausible reason supplied from your own reading is a fabricated citation the user will trust.

Then find the **drift point**: the earliest spec or decision whose stated reason starts from friction in what the branch had already built — "the page currently…", "the structure is now…" — rather than from a user need. Mass promise rewrites near it are corroboration.

Done when every reversal has commits and a layer, and the drift point is named or declared not found with the reason.

## 4. Write the seed document

Write `AI_SALVAGE-<branch-slug>.md` at the repo root in the shape of [`SEED-TEMPLATE.md`](SEED-TEMPLATE.md), headings in the session's language. Write it straight away — the user's edit of the seed is the confirmation step.

- **Intent** — one entry per story, scenario, glossary term and business rule, never one per passage. The text is quoted verbatim from its final version on the branch, or its last version before deletion. History collapses to one line per entry.
- Old promise IDs appear as `舊:<ID>`, so a fresh spec numbering from `main` cannot collide with them.
- Leave the seed untracked; stage nothing.

Done when every inventoried story, scenario, term and rule has an entry with every tag of the template filled and its 待決 question, every reversal appears in the timeline, and every abandoned UI, data-model or architecture decision appears under abandoned approaches.

## 5. Hand over

Report the seed's path, the count of intent entries and of reversals per layer, and the drift point in one sentence. Then say:

- Keep the abandoned branch until the restart has landed; the seed cites its commits. Deleting, renaming or tagging it is the user's call.
- Clearing is `rm AI_SALVAGE-<branch-slug>.md`.

Next step, one hop: `/grill-with-docs` (restart) on a new branch from `main`, with the seed as its agenda — one entry at a time, after the user's own edit.
