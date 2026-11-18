# Install a heading-tag-only truth-map check through /setup-skills

## Done when
- `skills/core/setup-skills/check-truth-map.sh` and `skills/core/setup-skills/truth-map-check.yml` exist, and the workflow runs the script on PRs.
- The script reads `docs/03_architecture_design.md` and `docs/05_frontend_spec.md`; either may be absent.
- The script fails when a `##`/`###` heading lacks a `（能力：X）` or `（能力：共用）` tag, and when X has no `docs/capabilities/X.md` (PR-TRUTH-07).
  - Multiple capabilities are separated by 「、」.
  - An untagged `###` inherits its parent `##` tag, but `共用` is not inherited.
  - Each red line names the file, the heading and the reason.
- `skills/core/setup-skills/SKILL.md` has a Section G (PR-TRUTH-13):
  - It is proposed only when the target has `docs/capabilities/`.
  - It copies both files byte-for-byte to `.github/scripts/check-truth-map.sh` and `.github/workflows/truth-map-check.yml`.
  - The install report lists the current red items. No baseline file is written and branch protection is not changed.
  - Step 5 tells the user the check blocks only once they mark it required.
  - Step 1 Explore checks whether existing copies still match the source.
- `scripts/test-truth-map-check.sh` has at least one red and one green fixture case for the rule above, plus the inheritance case and the 共用-not-inherited case.
- `scripts/check.sh` gains invariant [13], modelled on [12]: the files are present, SKILL.md names them, the workflow calls the script, and the test is green. The CLAUDE.md invariant list is updated to match.
- `bash scripts/check.sh` is green.

## Context
This is the tracer bullet for spec [`ISSUE-001-truth-volume-slimming.md`](ISSUE-001-truth-volume-slimming.md). It checks one rule only, to prove the pieces connect: template → Section G copy → CI workflow → check.sh invariant. Tickets 003 and 004 extend the script.

## Blocked by
Blocked by: none

## Notes
- Section F is the precedent: `issues-check.yml` plus `check-issues.sh`, tested by `scripts/test-issues-check.sh` and guarded by invariant [12]. Copy its shape. Don't invent a new install mechanism.
- Comments in the script are written in 繁體中文 (repo rule).
- The script must also run under Git Bash on Windows. Matching 「（能力：」 needs UTF-8-aware grep, so a blanket `LC_ALL=C` breaks it. Test on Windows Git Bash.
- Do not mention the reference project that prompted this work (PR-TRUTH-18). Fixtures use generic domains such as 排場 and 訂單.
