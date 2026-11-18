# Rewrite /frontend-spec so each page carries four items and Penpot lessons live under ## Penpot

## Done when
- The page shape in `skills/core/frontend-spec/SKILL.md` has exactly four items: Story, Dominant region, promise IDs and Boards. `PAGE-BRIEF.md` matches wherever it repeats the shape (PR-TRUTH-02).
  - Testable interaction details go upstream as promises.
  - Visual-only details are drawn on boards.
- `05` contains no `- [ ]` / `- [x]` acceptance lists. The installed check now enforces this (PR-TRUTH-03).
- Promises are cited by ID only (PR-TRUTH-01).
- Cleanup is limited to touched pages and goes in a separate cut-commit (PR-TRUTH-05).
- Penpot (PR-TRUTH-06):
  - The precondition checks that the project's `CLAUDE.md` has a `## Penpot` heading, and stops if it is missing.
  - Penpot operating lessons are written under that heading.
- Claims about orphan or untagged headings say "blocked by the check /setup-skills installs" (PR-TRUTH-16).
- The skill reads the capability-file shape from `domain.md`.
- grep finds no mention of the reference project (PR-TRUTH-18).
- `bash scripts/check.sh` is green.

## Context
This ticket implements the `frontend-spec` part of spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). ADR 0001 still holds: the design master may lead main, and `05` lists the boards that count. The Boards item is that list.

## Blocked by
Blocked by: ISSUE-002-truth-map-tracer.md, ISSUE-005-capability-shape-in-domain.md

## Notes
- The "No standards sections" rule stays prose-only. Checking it is out of scope.
- The existing precondition about the `guard-penpot.sh` hook stays. This ticket adds the `## Penpot` heading check beside it.
