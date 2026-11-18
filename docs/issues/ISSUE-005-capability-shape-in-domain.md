# Have /setup-skills write the capability-file shape into the target's domain.md

## Done when
- `/setup-skills` writes the capability-file shape into the target's `docs/agents/domain.md` (PR-TRUTH-14). The shape has five parts:
  - current state
  - who it serves
  - `## 規格章節`, with the entry format from PR-TRUTH-08
  - `## Promises`, with the line format from PR-TRUTH-09, including the retired form
  - an optional `## 驗證`
- The shape text appears once, in the setup-skills folder. No other skill restates it.
- `skills/core/setup-skills/SKILL.md` stays at about 150 lines or fewer.
  - The Section F and Section G details move into `skills/core/setup-skills/CHECKS.md`, which SKILL.md links to by a relative path.
  - Invariant [12], and [13] if ISSUE-002 has landed, must still find the file references they grep for. Adjust the greps if those references move.
- `bash scripts/check.sh` is green.

## Context
Per spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md), four skills will read the shape from the target's `domain.md` instead of each carrying its own copy: `to-architecture`, `frontend-spec`, `implement` and `bootstrap-truth`. This ticket creates that single home.

## Blocked by
Blocked by: none

## Notes
- If ISSUE-002 has not landed yet, the CHECKS.md split covers Section F only, and ISSUE-002 adds Section G there. Whichever ticket lands second does the merge.
- Load `/writing-for-agents` before editing a skill (repo rule).
