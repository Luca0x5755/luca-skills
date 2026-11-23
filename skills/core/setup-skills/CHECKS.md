# CI checks

The CI checks [`/setup-skills`](SKILL.md) can install. Each section's skip condition lives in `SKILL.md` step 2; this file holds what happens once a section is asked.

## Section F — Issues check

A GitHub Actions check that fails a PR whose net change adds files under `docs/issues/` — every issue the branch created must be gone by merge. Propose it, one nod for the pair.

- **Source**: `issues-check.yml` and `check-issues.sh`, beside this file.
- **Copy byte-for-byte** to `.github/workflows/issues-check.yml` and `.github/scripts/check-issues.sh`. The tests stay in luca-skills; the copy is verbatim, so a green source is a green copy.
- **Drift**: copies present but differing from source → show the diff, propose refreshing.

## Section G — Truth map check

A GitHub Actions check that fails a PR when a `##`/`###` heading in `docs/03_architecture_design.md` or `docs/05_frontend_spec.md` lacks its `（能力：X）` / `（能力：共用）` tag, or names a capability with no `docs/capabilities/X.md`. Propose it, one nod for the pair.

- **Source**: `truth-map-check.yml` and `check-truth-map.sh`, beside this file.
- **Copy byte-for-byte** to `.github/workflows/truth-map-check.yml` and `.github/scripts/check-truth-map.sh`. The tests stay in luca-skills; the copy is verbatim, so a green source is a green copy.
- **Drift**: copies present but differing from source → show the diff, propose refreshing.
- **Current red**: after copying, run `bash .github/scripts/check-truth-map.sh` at the repo root and put every red line it prints in the install report. An existing project installs as-is with its red list in hand: write no baseline file, and leave branch protection as it is.

## Section H — Docs governance check

A GitHub Actions check that fails a PR when `docs/decision-log.md` holds lines of more than one year-month, or any line longer than 300 characters (archives under `docs/decision-log/` are not checked), or when a scanned current doc has a section over 40 KB (40,960 bytes, smallest section between two headings) or a consolidated volume (`docs/03_architecture_design.md`, `docs/05_frontend_spec.md`, `docs/test-blueprint.md`, `docs/test-status.md`) lacks the standard reading-guide first line, defined once as `READING_GUIDE` in `check-docs-governance.sh`. It judges file content only, never today's date. Propose it, one nod for the pair. It is a separate script — never merged into `check-truth-map.sh`, because Section G is offered only with `docs/capabilities/`.

- **Source**: `docs-governance-check.yml` and `check-docs-governance.sh`, beside this file.
- **Copy byte-for-byte** to `.github/workflows/docs-governance-check.yml` and `.github/scripts/check-docs-governance.sh`. The tests stay in luca-skills; the copy is verbatim, so a green source is a green copy.
- **Drift**: copies present but differing from source → show the diff, propose refreshing.
- **Current red**: after copying, run `bash .github/scripts/check-docs-governance.sh` at the repo root and put every red line it prints in the install report. Write no baseline file.
- **Required check**: tell the user it blocks merging only once they mark `docs-governance-check` required in branch protection; until then its red list is a to-do, not a gate.
