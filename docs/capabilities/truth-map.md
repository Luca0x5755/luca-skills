# 真相地圖

合訂本（`docs/03_architecture_design.md`、`docs/05_frontend_spec.md`）只引用承諾 ID，承諾內文只住 capability 檔；標題帶能力標記，並與 capability 檔的 `## 規格章節` 雙向比對。比對由 `/setup-skills` Section G 安裝到目標專案的 `check-truth-map.sh` 強制，capability 檔形狀由 `/setup-skills` 寫進目標專案的 `docs/agents/domain.md`。
本檔保留已發佈規格的 promise ID；只改措辭沿用原 ID，意思改了就換新 ID。

## Promises

PR-TRUTH-01 — `to-architecture` 與 `frontend-spec` 寫入 `03`／`05` 時只引用承諾 ID，不重述承諾內文；`implement` 落地行為規則時只寫進 capability 檔，「或合訂本章節」的退路移除。
PR-TRUTH-02 — `05` 的每一頁恰好四項：使用者故事、主導區域、承諾 ID、board 名單。可測的互動細節回上游登記成承諾；純視覺細節畫在 board 上。
PR-TRUTH-03 — `05` 不含 `- [ ]` 或 `- [x]` 行；檢查腳本遇到即報紅。
PR-TRUTH-04 — 專案已有 schema 程式碼時，`03` 的資料模型只列實體、擁有者、關係與判斷型約束；欄位型別與種子／設定預設值改成指向程式檔。
PR-TRUTH-05 — 一次執行只清它改到的章節：文件快取資訊與重述放在獨立的 cut-commit，只刪字、不改事實；沒改到的章節不動。不設行數上限。
PR-TRUTH-06 — `frontend-spec` 的前置條件檢查專案 `CLAUDE.md` 有 `## Penpot` 標題，缺少就停下；Penpot 操作經驗寫在這個標題下。
PR-TRUTH-07 — `03`／`05` 的每個 `##`、`###` 標題帶 `（能力：X）`，X 是 `docs/capabilities/X.md` 的檔名主幹，多個以「、」分隔；跨全專案的章節標 `（能力：共用）`。`###` 沒有標記時繼承父 `##` 的能力標記；`共用` 不往下繼承。違反即報紅。
PR-TRUTH-08 — 被標題標到的 capability 檔有 `## 規格章節`，條目寫成 `` - `docs/03_architecture_design.md` <標題全文去掉標記> ``；檢查腳本驗證標題標記與這份清單雙向一致，任一方向缺漏即報紅。
PR-TRUTH-09 — capability 檔的承諾放在 `## Promises` 下，承諾行格式為 `<ID> — <行為>`，退役行以 `retired` 開頭並附理由；行首的 `- ` 可有可無。現有寫法的 capability 檔不需改動即可通過。
PR-TRUTH-10 — `03`／`05` 引用的承諾 ID 必須在某個 capability 檔有定義且未退役；違反即報紅，並標明「找不到」或「已退役」。ID 前綴由已定義的 ID 去掉尾端數字推導，不需設定檔。
PR-TRUTH-11 — `/to-spec` 的 Promise IDs 規則區分兩種改動：只改措辭沿用原 ID；意思改了（既有測試的任一斷言需要跟著改）就發新 ID，舊行改為 `retired：由 <新 ID> 取代`。
PR-TRUTH-12 — 檢查腳本每次執行，在輸出末尾列出所有 `（能力：共用）` 標題與總數；這份列表不影響通過與否。
PR-TRUTH-13 — `/setup-skills` Section G 只在目標專案有 `docs/capabilities/` 時提議；逐字複製 `check-truth-map.sh` 與 workflow；安裝報告列出現有紅燈項；不寫 baseline 檔，不動 branch protection。
PR-TRUTH-14 — `/setup-skills` 把 capability 檔形狀（現況、服務對象、`## 規格章節`、`## Promises`，含 PR-TRUTH-09 的行格式，以及選用的 `## 驗證`）寫進目標專案的 `docs/agents/domain.md`；`to-architecture`、`frontend-spec`、`implement`、`bootstrap-truth` 從那裡讀，不各自重述。
PR-TRUTH-15 — `bootstrap-truth` 第 4 步照 `/setup-skills` Section G 安裝同一支檢查腳本，取代原本的雙向孤兒檢查描述。
PR-TRUTH-16 — 技能文字裡「孤兒章節報紅」一類的規則，改寫成「由 /setup-skills 安裝的檢查擋下」；不再宣稱沒有檢查在執行的規則。
PR-TRUTH-17 — 檢查腳本的測試留在本 repo，對 PR-TRUTH-03、07、08、10、12 各有一組紅、綠案例；`bash scripts/check.sh` 通過。
PR-TRUTH-18 — 技能文字、GLOSSARY、decision-log 與 commit 訊息不提及促成這次改動的參考專案，也不取它的內容當範例；範例一律用通用情境。

## 驗證

- `bash tests/scripts/test-truth-map-check.sh`（CI 由 `tests/test-tooling.sh` [26] 跑）：PR-TRUTH-03、07、08、10、12，在 C.UTF-8 與 C 兩種 locale 下跑紅綠案例。
- `bash scripts/check.sh`：[13] 檢查模板檔案與引用、[14] capability 檔形狀只有一個家、[15]–[18] 各技能的措辭（PR-TRUTH-01、02、05、06、11、14、15、16）。
- PR-TRUTH-04、18 與技能在真實專案的執行行為沒有機械檢查。
