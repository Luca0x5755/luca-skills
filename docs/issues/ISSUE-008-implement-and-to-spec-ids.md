# Make /implement write behaviour only into capability files and /to-spec re-issue IDs on meaning change

## Done when
- `skills/core/implement/SKILL.md` no longer offers "or the consolidated spec section it points at". Behaviour rules land only in the capability file, in the shape read from `docs/agents/domain.md` (PR-TRUTH-01, PR-TRUTH-14).
- `skills/core/to-spec/SKILL.md` Promise IDs distinguishes two kinds of change (PR-TRUTH-11):
  - A wording-only change keeps its ID.
  - A meaning change gets a new ID. It counts as a meaning change when any existing test assertion would have to change.
  - The old line then becomes `<ID> — retired：由 <新 ID> 取代`.
  - "Never reissue" stays.
- grep finds no mention of the reference project (PR-TRUTH-18).
- `bash scripts/check.sh` is green.

## Context
This ticket implements the `implement` and `to-spec` parts of spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). The GLOSSARY entry 承諾 already records the rule, and the skill text must match it.

## Blocked by
Blocked by: ISSUE-005-capability-shape-in-domain.md

## Notes
- Check `implement-spec` and `run-queue` for the same "consolidated spec section" escape hatch. If either has it, fix it there too.
- `/uat-cases` TC- numbering is deliberately left unchanged. It is recorded as an open question in GLOSSARY.
