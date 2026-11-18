# Make the truth-map check verify reverse links, block checkboxes, and list 共用 headings

## Done when
- Every `docs/capabilities/*.md` file that a heading tags has a `## 規格章節` section.
  - Each entry has the form ``- `docs/03_architecture_design.md` <heading text minus the tag>``.
  - The script fails when a tagged heading is missing from that list.
  - The script also fails when a listed entry has no matching tagged heading (PR-TRUTH-08).
- Any `- [ ]` or `- [x]` line in `docs/05_frontend_spec.md` fails, reported with its line number (PR-TRUTH-03).
- The output ends with every `（能力：共用）` heading and the total count. This list never changes the exit code (PR-TRUTH-12).
- `scripts/test-truth-map-check.sh` has a red case and a green case for each of the three rules.
- `bash scripts/check.sh` is green.

## Context
This ticket widens the script from ISSUE-002, per spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). PR-TRUTH-14 defines the capability-file shape, including `## 規格章節`. ISSUE-005 writes that shape into target projects.

## Blocked by
Blocked by: ISSUE-002-truth-map-tracer.md

## Notes
- Compare headings with the tag stripped and whitespace trimmed. Use the full heading text, not a slug: the spec chose full text.
- Under the default serial `/run-queue` this ticket does not collide with ISSUE-004. In parallel mode both edit the same script, so expect a merge conflict.
