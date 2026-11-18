# Rewrite /to-architecture to cite promise IDs, point schema details at code, and clean only touched sections

## Done when
- `skills/core/to-architecture/SKILL.md` says that sections cite promise IDs only and never restate promise text (PR-TRUTH-01).
- When schema code exists, the data model lists only entities, owners, relations and judgment constraints. Column types and seed or config defaults are replaced by a pointer to the file (PR-TRUTH-04).
- A run cleans 文件快取資訊 and restatement only in the sections it touches (PR-TRUTH-05):
  - The cleanup goes in a separate fact-neutral cut-commit: it deletes words and changes no facts.
  - Untouched sections stay as they are.
  - There is no line budget.
- Headings carry the capability tag (PR-TRUTH-16).
  - Replace the sentence "a section naming no capability is an orphan and goes red" with "blocked by the check /setup-skills installs".
- The skill reads the capability-file shape from the target's `docs/agents/domain.md` and does not restate it.
- grep finds no mention of the reference project (PR-TRUTH-18).
- `bash scripts/check.sh` is green.

## Context
This ticket implements the `to-architecture` part of spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). ISSUE-002 provides the tag format and the check. ISSUE-005 provides the shape's home.

## Blocked by
Blocked by: ISSUE-002-truth-map-tracer.md, ISSUE-005-capability-shape-in-domain.md

## Notes
- 文件快取資訊 is an existing GLOSSARY term. Use it as defined there.
- Load `/writing-for-agents` first. Use a generic example domain.
