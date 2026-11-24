# CI checks

The three CI checks [`/setup-skills`](SKILL.md) can install. Each section's skip condition lives in `SKILL.md` step 2; this file holds what happens once a section is asked.

## Section B — Current docs check

A GitHub Actions check that fails a PR when a current document (the seven fixed files the script names) carries an issue number, a ticket number or an ISO date outside code. Run it whenever Section B wrote domain docs; propose it, one nod for the pair.

- **Source**: `current-docs-check.yml` and `check-current-docs.sh`, beside this file.
- **Copy byte-for-byte** to `.github/workflows/current-docs-check.yml` and `.github/scripts/check-current-docs.sh`. The tests stay in luca-skills; the copy is verbatim, so a green source is a green copy.
- **Drift**: copies present but differing from source → show the diff, propose refreshing.
- **Current red**: after copying, run `bash .github/scripts/check-current-docs.sh` at the repo root and put every red line it prints in the install report.
- **Re-run on an existing project**: delete the `日期：` line from every `docs/adr/*.md` without asking; fix every other red line in the same change and hand it to the user for review. Write no baseline file, and leave branch protection as it is.
- The classification these rules enforce is `docs-classification.md`, copied into `docs/agents/domain.md` by `SKILL.md` step 4.

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
