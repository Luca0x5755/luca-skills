# Migration branch — no governance, scattered documents

The fallback branch of [`bootstrap-truth`](SKILL.md), taken only when the brake check found **no** living governance and the documents are genuinely scattered (loose `.md`/`.txt` everywhere, no canon, no ledger). It replaces Phase A step 5; everything else in `SKILL.md` — evidence discipline, questionnaire, Phase B commit rules — applies unchanged. The target is the same shape: consolidated volumes plus `capabilities/`.

## Phase A step 5 (migration variant) — the mapping proposal

1. **Sweep everything.** Every document that could hold behaviour claims — `docs/`, READMEs, wiki dumps, loose files anywhere. An unswept file is an unfound conflict.
2. **Write the mapping table** — every swept file → `keep` / `merge into <target volume/section>` / `archive` / `drop`, one row each, with reason. A `drop` row names the destination of every live claim inside it — a file dropped whole with an unplaced claim is an unfinished inventory. Done means every swept file has a row.
3. The proposal still carries the capability-layer list, the cross-mapping plan, and the `資訊缺失` gaps, per `SKILL.md`.

## Phase B additions

- Build each consolidated volume per the mapping: **move and dedupe, never rewrite** — slimming comes after the moves settle, as fact-neutral cut-commits per `SKILL.md`. Merged passages cite their sources (`file:line`) in the commit body.
- `git mv` fully-absorbed sources into `docs/archive/`; append `old path → new home` rows to `docs/archive/MAPPING.md`. Inbound links break silently when files vanish — update every reference to the old paths (grep for them, CLAUDE.md pointers included).

| Excuse | Reality |
| --- | --- |
| "This doc is obviously dead, just delete it" | Links you never found still point at it. Archive; deletion saves nothing. |
| "Newer version is truer, take it" | Newer is not truer. Divergent facts go through the questionnaire. |
