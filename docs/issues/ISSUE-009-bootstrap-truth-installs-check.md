# Make /bootstrap-truth step 4 install the same truth-map check

## Done when
- `skills/draft/bootstrap-truth/SKILL.md` step 4 installs the truth-map check by following `/setup-skills` Section G. It reads `setup-skills/SKILL.md` from the parent of this skill's base directory, so it installs the same files Section G installs. The old prose description of a two-way orphan check is removed (PR-TRUTH-15).
- The capability-file shape is read from `docs/agents/domain.md` (PR-TRUTH-14).
- grep finds no mention of the reference project (PR-TRUTH-18).
- `bash scripts/check.sh` is green.

## Context
This ticket implements the `bootstrap-truth` part of spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). It needs the complete script from ISSUE-003 and ISSUE-004, and the shape's home from ISSUE-005.

## Blocked by
Blocked by: ISSUE-003-truth-map-reverse-and-checkbox.md, ISSUE-004-truth-map-promise-ids.md, ISSUE-005-capability-shape-in-domain.md

## Notes
- Do not point at the template file path inside the setup-skills folder. That would be a cross-folder deep link, which CLAUDE.md forbids. Reading a whole user-invoked skill's `SKILL.md` in order to follow it is allowed.
