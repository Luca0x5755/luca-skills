# 讓 `/ops-script` 叫得動，附一份最小的 bash 骨架

## Done when

- `skills/draft/ops-script/SKILL.md` 存在：frontmatter `name: ops-script`、`description` 用繁體中文並帶觸發語句、不加 `disable-model-invocation`。
- `skills/draft/ops-script/skeleton.sh` 存在，共用段以 `# ---- BEGIN ops-lib v1 ----` / `# ---- END ops-lib ----` 框住，至少含：
  - 顏色設定：stdout 非終端機、`NO_COLOR` 非空、`TERM=dumb` 任一成立即關閉。
  - `die`：`✗` 標題＋縮排的怎麼修，全部走 stderr。
  - `confirm`：`[y/N]`，預設 No。
  - `require_tty`：只看 stdin。
- 骨架主體含：拒絕 `source` 的守衛、`SKELETON_LIB=1` 測試模式（嚴格比對 `"1"`，主流程包進 `main`）、一張子命令表同時產生選單／`--help` 清單／分派、選單選項執行前印出等價指令、`--help` 只印 `#/` 開頭的行、示範子命令 `hello` 支援 `--dry-run`。
- 以下行為可驗證：
  - `bash skeleton.sh --help </dev/null` 回 0。
  - `bash skeleton.sh </dev/null` 印用法並回 2。
  - `bash skeleton.sh --bogus` 與 `bash skeleton.sh hello --bogus` 都回 2。
  - `bash skeleton.sh hello --dry-run` 只印將執行的指令、不做事。
  - `bash -n` 通過；有 shellcheck 時預設規則零警告。
- `SKILL.md` 寫出已定案的行為規則（見 Context 的決策來源）：嚴格模式只是安全網、`NO_COLOR`、無終端機規則、結束碼 0／1／2（取消回 1）、診斷走 stderr 且錯誤先寫什麼錯再寫怎麼修、`<腳本名>_LIB=1` 測試接縫、訊息語言跟目標專案、不限檔案行數但函式短小且縮排不超過 3 層、改既有腳本發現不合規範先問使用者要不要整支翻修、會改系統的子命令一律支援 `--dry-run`、未知參數 exit 2、`--help` 用 `#/`、選單與子命令一表產生、缺值有終端機就問沒有就 exit 2、寫完的驗證步驟（`bash -n`、有 shellcheck 就跑、沒裝就略過並告知、不自行安裝、用 `--dry-run` 與 LIB 模式驗證而非實際執行）。
- `skills/core/wizard/SKILL.md` 補一行：要長期留在 repo、反覆執行的腳本，用 `/ops-script`。
- `README.md`〈試用中〉補一行指向 `./skills/draft/ops-script/SKILL.md`；跑 `scripts/install.ps1` 後 `/ops-script` 叫得動；`bash scripts/check.sh` 全綠。

## Context

定義見 `GLOSSARY.md` 的「運維腳本」；決策見 `docs/decision-log.md` 2026-11-20 的六行與 `docs/adr/0002-ops-script-shared-helpers-are-copied-verbatim-into-each-script.md`。寫技能前先載入 `/writing-for-agents`（mandatory）。這是新推導的技能，依 `CLAUDE.md` 放 `skills/draft/`。

## Blocked by

Blocked by: none

## Notes

- 刻意最薄：多選器、結果總表、`step` 留給 ISSUE-002。
- 技能內文英文；骨架的畫面訊息用中性佔位文字，註解用繁體中文。
- 不得出現任何實際專案、服務或外部專案的名稱（`CLAUDE.md`〈repo 內容的邊界〉）。
- `SKILL.md` 超過約 150 行就把細節拆到同資料夾的參考檔。
