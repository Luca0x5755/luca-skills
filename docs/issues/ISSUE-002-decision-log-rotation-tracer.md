# 決策日誌依月輪替，並由 Section H 的檢查擋下

## Done when
- `skills/core/setup-skills/` 有一支文件治理檢查腳本與它的 workflow 範本：`docs/decision-log.md` 出現兩種以上的年月時報紅（PR-DOCS-07）；主檔任一行超過 300 字（以 Unicode 字元計）時報紅並標明行號，`docs/decision-log/` 下的封存檔不檢查（PR-DOCS-08）。判斷只看檔案內容，不看當天日期。
- `tests/scripts/` 有這支腳本的紅、綠案例，涵蓋 PR-DOCS-07、08，在 C.UTF-8 與 C 兩種 locale 下都要跑；`tests/test-tooling.sh` 接上它。
- `setup-skills` 有 Section H「文件治理檢查」：目標專案有 `docs/` 就提議，逐字複製腳本與 workflow，不併進 `check-truth-map.sh`；安裝後告知要在 branch protection 設為 required 才會擋合併（PR-DOCS-15）。細節寫在 `CHECKS.md`，`SKILL.md` 不超過 150 行。
- `domain-modeling/SKILL.md` 的決策日誌合約改為：路徑不變、只放當月、寫入新月份第一行前把上月搬到 `docs/decision-log/YYYY-MM.md`、封存檔不再修改；「Single file, append-only」移除（PR-DOCS-06）。
- `scripts/check.sh` 新增一條：Section H 的範本檔都在、`SKILL.md` 或 `CHECKS.md` 有引用、`domain-modeling` 不再寫「Single file, append-only」（PR-DOCS-11 的日誌部分）。
- 本 repo 的 9 月、10 月行搬進 `docs/decision-log/2026-09.md`、`docs/decision-log/2026-10.md`，主檔只留當月；本 repo 照 Section H 裝上檢查，CI 會跑（PR-DOCS-16）。
- `bash scripts/check.sh` 與 `bash tests/test-tooling.sh` 通過。

## Context
規格：`docs/issues/ISSUE-001-docs-governance.md`（PR-DOCS-06、07、08、10、11、15、16）。決策：`docs/adr/0005-decision-log-rotates-monthly-behind-a-fixed-path.md`。這是 tracer：先只做日誌的兩條檢查，掃描現行文件的規則由 ISSUE-003、004 加進同一支腳本。

## Blocked by
none

## Notes
- 比照 Section G：腳本範本與測試的寫法看 `skills/core/setup-skills/check-truth-map.sh` 與 `tests/scripts/test-truth-map-check.sh`；`check.sh` 的模板檢查看 [13]。
- 改技能文字前先載入 `/writing-for-agents`（CLAUDE.md）。
- regex 的 `[...]` 裡不放多位元組字元，用 alternation；兩種 locale 都要測。
- 字數以字元計，不是位元組：bash 在 C locale 下 `${#line}` 算的是位元組，用 awk 前先確認 locale 行為，或改用能數字元的工具。
- 搬移時是依行首的 `YYYY-MM` 分檔，行內容逐字不改。
- 不提及促成這次改動的參考專案（PR-DOCS-12、`check.sh` [19]）。
