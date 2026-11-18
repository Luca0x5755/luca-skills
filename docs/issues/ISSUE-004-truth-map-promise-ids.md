# Make the truth-map check fail on cited promise IDs that are undefined or retired

## Done when
- The script collects defined IDs from each capability file's `## Promises` section (PR-TRUTH-09).
  - Line forms are `<ID> — <行為>` and `<ID> — retired：<理由>`.
  - A leading `- ` is optional.
- The script derives ID prefixes by stripping the trailing digits from the defined IDs. No config file is used.
- The script scans `03` and `05` for prefix-plus-digits citations (PR-TRUTH-10).
  - A cited ID that is not defined fails as 「找不到」.
  - A cited ID that is retired fails as 「已退役」.
- The repo's own `docs/capabilities/installer.md` and `docs/capabilities/issue-tracker.md`, unchanged, serve as green fixtures for the parser. They prove the existing format passes without edits.
- `scripts/test-truth-map-check.sh` covers four cases:
  - a defined ID (green)
  - an undefined ID (red, 找不到)
  - a retired ID (red, 已退役)
  - a bullet-prefixed line (green)
- `bash scripts/check.sh` is green.

## Context
This ticket widens the script from ISSUE-002, per spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). It closes a gap: a cited promise could silently stop existing or change meaning. PR-TRUTH-11 makes any change of meaning retire the old ID, so this one rule catches both cases.

## Blocked by
Blocked by: ISSUE-002-truth-map-tracer.md

## Notes
- Accepted miss: a typo in the prefix itself (`PR-AUHT-03`) is not caught. Do not add a config to fix it.
- The separator `—` is a UTF-8 character, so the grep caveat in ISSUE-002 applies here too.
