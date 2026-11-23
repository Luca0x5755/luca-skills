---
name: salvage-branch
description: 從棄置分支相對 main 的增量（含 git 歷史與中途刪掉的議題）回收最終設計與其理由，每個功能寫成一份不進 git 的種子文件（故事、概念、最終設計、為什麼），供從 main 重新開發。
disable-model-invocation: true
---

# Salvage Branch

Recover the design of an **abandoned branch** — a feature branch that will not merge — so the user can restart from `main`. The output is one **seed** per feature, under `AI_SALVAGE-<branch-slug>/` at the repo root, untracked. A seed is the conclusion, never the journey: its reader has given up on the branch and wants the final design and the reasons for it.

The branch is evidence. Read it with `git show` / `git log` / `git diff` only — no checkout, no commit, no delete, rename or tag. Its commit hashes are the seeds' citations.

Two facts shape every step:

- **The tip lies.** A branch closed out before abandonment has had its interim decisions condensed into a final state; ADRs rewritten in place and decision-log entries folded leave no trace at the tip. Reversals — and the reasons behind the final design — live only in `git log -p` and in issue files deleted mid-branch.
- **Drift reaches intent.** Stories and glossary terms written mid-branch absorb the solution being built — routes, screens, columns, endpoints. So a seed describes what a user can see and the concepts behind it, at the altitude of a story; the build's mechanics stay on the branch.

## 1. Bound the increment

Take the branch name from the user (a local branch or `origin/<name>`); ask when none is given. The start is `git merge-base <branch> main`, or the merge-base with `dev` when `dev` exists and is the integration branch — the nearer candidate wins, a tie or no common ancestor → ask for a start commit. Branch tip equals start → nothing to salvage; say so and stop.

Locate the design documents through the host's `docs/agents/domain.md` (glossary, capability files, ADRs, decision log) and `docs/agents/issue-tracker.md` (where specs and tickets live, local or remote). Either file missing → infer locations from paths and headings; step 4 shows the inference to the user.

Done when the start commit is fixed and every document role has a location, recorded or inferred.

## 2. Inventory, history included

Scope is the branch's increment only. Collect:

- **Living** — `git diff --name-status <start>..<branch>` on the design locations.
- **Deleted mid-branch** — `git log --diff-filter=D --name-only <start>..<branch>`. Read each at its last version, `git show <deleting-commit>^:<path>`; earlier versions through `git log -p -- <path>`.
- **Pre-existing files the branch edited** — keep only the branch's hunks. A hunk that rewrote `main`'s own text carries both sides, before and after.
- **Remote issues** — when the tracker is remote, the specs and tickets the branch's commits reference, fetched with the tracker file's command.

Code is out of scope, except as evidence for which decision actually got built.

Done when every design-document path the branch touched is in the inventory or noted as skipped, with the reason, for step 4.

## 3. Trace the reversals

This step is working material: no seed prints it. Its one product is the reasons a seed's 為什麼 quotes.

Walk `git log -p --reverse <start>..<branch>` over the inventory. A **reversal** is a settled statement later replaced, deleted or contradicted: a glossary definition or `_Avoid_` line, a promise, an ADR body rewritten under the same number, a decision-log entry edited or folded, an option once rejected and later adopted. A wording polish is no reversal, and neither is a later commit date alone. Note each with the original, the replacement, the commits and the reason — a quote from a commit message, document or deleted issue, or `理由未記` where none states one. Read the Why or background section of every deleted spec and ticket that has one.

What survives at the tip is the final design, however it got there: a decision first made to fix friction in what the branch had already built is still final design when the tip keeps it, and its stated reason is still a reason.

Done when every decision that survives at the tip has its reason or `理由未記`, and every reversal has its commits.

## 4. Split by feature

A **feature** is one user goal: it holds at least one user story that stands alone — take every other part away and the story still holds. A part with no story of its own (a menu's wording, a button's place) joins the feature it serves. Attribute by hunk or document section, never by commit: a commit touching two features splits between them. A part that rewrote a feature already on `main` — B fixed midway through A — is a feature of its own, named after B. A part the branch itself later rewrote is a reversal inside one feature; the tip's version is the one that counts.

Send the user one message: each feature with a one-line note of what it holds, the suggested order (rewritten `main` features first, then the features they unblock), the document locations inferred in step 1 and the paths skipped in step 2. Wait for approval; the user may merge, split or rename. A single feature skips the wait.

Done when the split is approved (or single), every story, rule and surviving decision belongs to one feature, and every term sits in each feature that uses it.

## 5. Write the seeds

Write `AI_SALVAGE-<branch-slug>/<feature-slug>.md` for each approved feature, headings in the session's language:

```markdown
# <feature, in the user's words>

狀態：<完成, or 做到一半：what the branch never finished>

## 使用者故事
- 身為<role>，我想<goal>，以便<value>。

## 概念
**<term>**：<one or two sentences>

## 最終設計
<one to three paragraphs: the result as the user meets it, with its rules>

## 為什麼這樣設計
- <choice>：<reason>。（曾試過 <X>，因 <Y> 放棄。）

來源：<commit hashes and documents the seed draws on>
```

- **Prose is yours** — a story or term definition the branch states keeps its original sentence where it reads as behaviour. A section the branch never wrote says `未記`.
- **最終設計 stays at the story's altitude**: what the user can do, what they get, and the rules that decide the result — whatever the tip keeps at that altitude, however it began. Screens, fields, buttons, dialogs and their states are the build's mechanics; the restart designs those afresh. A decision several features touch is told in the feature whose story it serves, and the others name only its result.
- **為什麼 is told in your own words.** One reason per choice, in a sentence a user would follow; the document it came from is named only in `來源`.
- **為什麼 rests on evidence.** Each reason comes from a commit message or document — an ADR's rejected options and a glossary `_Avoid_` line count; where none states one, write `理由未記` — a plausible reason supplied from your own reading is a fabricated citation the user will trust. A rejected approach earns its clause only when a restart could propose it again.
- **The template is the whole seed.** 狀態 is the only line before the first section; the `來源` line is the only place for hashes and paths.
- Leave the directory untracked; stage nothing.

Done when every approved feature has its seed, every reason in 為什麼 rests on evidence or says `理由未記`, and 最終設計 reads as what a user does and gets — no screen, field, button, route, column, endpoint, file path or command in it.

## 6. Hand over

Report the directory path and the seeds in the suggested order with their 狀態. Then say:

- Keep the abandoned branch until the restart has landed; the seeds cite its commits. Deleting, renaming or tagging it is the user's call.
- Clearing is `rm -r AI_SALVAGE-<branch-slug>/`.

Next step, one hop: `/grill-with-docs` on a new branch from `main`, one seed per session, in the suggested order, after the user's own edit.
