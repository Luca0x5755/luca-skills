---
name: setup-skills
description: 為這個 repo 設定工程技能所需的組態 — 議題追蹤器與領域文件位置。每個 repo 跑一次。
disable-model-invocation: true
---

# Setup Skills

Write the per-repo configuration the other skills assume. Prompt-driven, not a script: explore, present, confirm, then write.

Produces:

- `docs/agents/issue-tracker.md` — where issues live
- `docs/agents/domain.md` — where `CONTEXT.md` and ADRs live, and the collaboration mode
- An `## Agent skills` section in `CLAUDE.md` pointing at both
- In private mode: entries in `.git/info/exclude`

## 1. Explore

Read what exists. Assume nothing.

- `git remote -v` — GitHub? GitLab? No remote?
- `CLAUDE.md` / `AGENTS.md` at root — does either exist? Does either already have an `## Agent skills` section?
- `CONTEXT.md`, `docs/adr/` — is a domain layer already here?
- `docs/agents/` — has this skill already run?
- `.scratch/` — sign of a local-markdown issue convention
- Monorepo signals: `pnpm-workspace.yaml`, a `workspaces` field, populated `packages/*`

## 2. Present and ask

Summarise what is present and what is missing. Take the sections in order — one section, one answer, then the next. Lead each with the recommended answer so it can be accepted in a word. Skip a section outright when exploration already settled it.

**Section A — Issue tracker.** Where issues live for this repo. `to-tickets`, `to-spec`, and `triage` read from and write to it; they need to know whether to run `gh issue create`, write a file under `.scratch/`, or follow something you describe.

Propose from the remote: GitHub remote → GitHub Issues (`gh` CLI). GitLab remote → GitLab Issues (`glab` CLI). No remote → local markdown under `.scratch/<feature>/issues/`. Anything else → ask for one paragraph of description and record it as prose.

**Section B — Domain docs.** Default to **single-context**: one `CONTEXT.md` and one `docs/adr/` at the repo root. Write it without asking. Offer **multi-context** — a root `CONTEXT-MAP.md` pointing at per-package `CONTEXT.md` files — only when exploration found monorepo signals.

**Section C — Collaboration mode.** Ask: **does everyone committing to this repo use these skills?** Solo repos answer themselves — skip the question and record `shared`.

- **shared** (solo repo, or the whole team runs the skills): everything the skills write is committed. Current behaviour; nothing extra to set up.
- **private** (mixed-tooling team — teammates never opted into these skills): add `CONTEXT.md`, `docs/agents/`, `docs/decision-log.md`, `docs/architecture.md`, `docs/frontend-spec.md`, and `docs/mockup/` to **`.git/info/exclude`** — per-clone, never committed, invisible to teammates. Two things stay shared regardless: `docs/adr/` (decisions belong next to the code they constrain) and tracker issues (they live where the team already looks).

Record the reasoning in `domain.md` so future sessions apply it: a document only your tooling reads has no rot-detection loop. And a private file must not become a shadow copy of team truth — a fact teammates should read gets promoted into the committed `CLAUDE.md`/`AGENTS.md` or an ADR, never fixed by committing the private file.

## 3. Confirm

Show a draft of every file to be written and the block to be added to `CLAUDE.md`. Let it be edited before anything lands on disk.

## 4. Write

Pick the file to edit: `CLAUDE.md` if it exists, else `AGENTS.md`, else ask which to create. Never create one when the other already exists.

**In private mode, the `## Agent skills` block goes into `CLAUDE.local.md` instead** — a committed file must not point at paths teammates' clones don't have. The committed `CLAUDE.md`/`AGENTS.md` is not touched.

If an `## Agent skills` block is already there, update it in place. Do not touch the surrounding sections.

```markdown
## Agent skills

### Issue tracker

[one line]. See `docs/agents/issue-tracker.md`.

### Domain docs

[one line — "single-context" or "multi-context", and "shared" or "private"]. See `docs/agents/domain.md`.
```

`docs/agents/domain.md` must record the collaboration mode and, in private mode, which paths are excluded — downstream skills read it to know whether their output is committed or personal.

`docs/agents/issue-tracker.md` must record, concretely: the exact command to create an issue, the exact command to list open issues, how a blocking relationship is expressed, and where issue bodies live. Vague prose here makes every downstream skill guess.

## 5. Done

Say which skills now read these files, and that `docs/agents/*.md` can be hand-edited later — re-running this skill is only for switching trackers.
