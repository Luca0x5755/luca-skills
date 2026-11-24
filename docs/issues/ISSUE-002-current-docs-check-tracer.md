# 讓 check-current-docs.sh 在本 repo 的 CI 擋下現行文件裡的票號與日期

## Done when
- `skills/core/setup-skills/check-current-docs.sh` 與 `skills/core/setup-skills/current-docs-check.yml` 存在；workflow 呼叫這支腳本。
- `tests/scripts/test-current-docs-check.sh` 在 `LC_ALL=C` 與 UTF-8 下都通過，涵蓋 PR-DOCS-05～07：
  - 七項之外的檔案不掃，不存在的檔案略過。
  - fenced code 與行內 code 裡的內容不報紅，表格裡的內容要報紅。
  - `ISSUE-12`、` #34`、`2026-01-02` 報紅，並點名 `檔案:行號`。
  - `PR-INSTALL-01`、`v1.2.3`、`page#12`、中文日期不報紅。
- `tests/test-tooling.sh` 呼叫這份測試（`check.sh` [20] 綠）。
- `scripts/check.sh` 新增 [30]：腳本與 workflow 都在，且 workflow 呼叫腳本。
- 本 repo 已複製成 `.github/workflows/current-docs-check.yml` 與 `.github/scripts/check-current-docs.sh`，而且 `bash .github/scripts/check-current-docs.sh` 通過。為此：
  - 三份 ADR 拿掉 `日期：` 行。
  - `docs/capabilities/issue-tracker.md`、`docs/capabilities/ops-script.md` 拿掉「決策紀錄 <日期>」指標。
  - 其餘紅燈修綠。
- `bash scripts/check.sh` 通過（PR-DOCS-11～13 的這一半）。

## Context
規格：`docs/issues/ISSUE-001-current-docs-only.md`。結構比照 `skills/core/setup-skills/check-truth-map.sh` 與 `tests/scripts/test-truth-map-check.sh`。

## Blocked by
Blocked by: none

## Notes
- 中括號表達式裡不能放多位元組字元，要改用選擇式（alternation），並在 `LC_ALL=C` 下也跑一次測試（CI 是 C locale）。
- `#\d+` 的「前一字元不是英數字」要包含行首。
- 決策日誌本身不在清單內，不掃。
