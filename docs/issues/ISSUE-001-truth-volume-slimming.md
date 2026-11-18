# 合訂本瘦身：只引用 ID、能力標記與真相地圖檢查

Blocked by: none

## Why

`/to-architecture` 與 `/frontend-spec` 產出的兩份合訂本（`03`、`05`）在真實專案裡長到上千行。原因不是內容變多：同一份承諾在 capability 檔、`03`、`05` 各寫一次，`05` 又多了一份打勾驗收清單；`03` 抄了程式碼本來就能回答的欄位型別與預設值；舊內容沒有機制清。技能裡「沒標能力的章節要報紅」這條規則沒有任何檢查在執行，只是願望。

## Scope

- 五個技能的文字：`to-architecture`、`frontend-spec`、`implement`、`to-spec`、`bootstrap-truth`。
- `setup-skills` 新增 Section G：一支真相地圖檢查腳本、一個 workflow、capability 檔形狀寫入目標專案的 `docs/agents/domain.md`。
- 檢查腳本的測試，放在本 repo。

## Promises

- PR-TRUTH-01 — `to-architecture` 與 `frontend-spec` 寫入 `03`／`05` 時只引用承諾 ID，不重述承諾內文；`implement` 落地行為規則時只寫進 capability 檔，「或合訂本章節」的退路移除。
- PR-TRUTH-02 — `05` 的每一頁恰好四項：使用者故事、主導區域、承諾 ID、board 名單。可測的互動細節回上游登記成承諾；純視覺細節畫在 board 上。
- PR-TRUTH-03 — `05` 不含 `- [ ]` 或 `- [x]` 行；檢查腳本遇到即報紅。
- PR-TRUTH-04 — 專案已有 schema 程式碼時，`03` 的資料模型只列實體、擁有者、關係與判斷型約束；欄位型別與種子／設定預設值改成指向程式檔。
- PR-TRUTH-05 — 一次執行只清它改到的章節：文件快取資訊與重述放在獨立的 cut-commit，只刪字、不改事實；沒改到的章節不動。不設行數上限。
- PR-TRUTH-06 — `frontend-spec` 的前置條件檢查專案 `CLAUDE.md` 有 `## Penpot` 標題，缺少就停下；Penpot 操作經驗寫在這個標題下。
- PR-TRUTH-07 — `03`／`05` 的每個 `##`、`###` 標題帶 `（能力：X）`，X 是 `docs/capabilities/X.md` 的檔名主幹，多個以「、」分隔；跨全專案的章節標 `（能力：共用）`。`###` 沒有標記時繼承父 `##` 的能力標記；`共用` 不往下繼承。違反即報紅。
- PR-TRUTH-08 — 每個 capability 檔有 `## 規格章節`，條目寫成 `` - `docs/03_architecture_design.md` <標題全文去掉標記> ``；檢查腳本驗證標題標記與這份清單雙向一致，任一方向缺漏即報紅。
- PR-TRUTH-09 — capability 檔的承諾放在 `## Promises` 下，承諾行格式為 `<ID> — <行為>`，退役行為 `<ID> — retired：<理由>`；行首的 `- ` 可有可無。現有寫法的 capability 檔不需改動即可通過。
- PR-TRUTH-10 — `03`／`05` 引用的承諾 ID 必須在某個 capability 檔有定義且未退役；違反即報紅，並標明「找不到」或「已退役」。ID 前綴由已定義的 ID 去掉尾端數字推導，不需設定檔。
- PR-TRUTH-11 — `/to-spec` 的 Promise IDs 規則區分兩種改動：只改措辭沿用原 ID；意思改了（既有測試的任一斷言需要跟著改）就發新 ID，舊行改為 `retired：由 <新 ID> 取代`。
- PR-TRUTH-12 — 檢查腳本每次執行，在輸出末尾列出所有 `（能力：共用）` 標題與總數；這份列表不影響通過與否。
- PR-TRUTH-13 — `/setup-skills` Section G 只在目標專案有 `docs/capabilities/` 時提議；逐字複製 `check-truth-map.sh` 與 workflow；安裝報告列出現有紅燈項；不寫 baseline 檔，不動 branch protection。
- PR-TRUTH-14 — `/setup-skills` 把 capability 檔形狀（現況、服務對象、`## 規格章節`、`## Promises`，含 PR-TRUTH-09 的行格式，以及選用的 `## 驗證`）寫進目標專案的 `docs/agents/domain.md`；`to-architecture`、`frontend-spec`、`implement`、`bootstrap-truth` 從那裡讀，不各自重述。
- PR-TRUTH-15 — `bootstrap-truth` 第 4 步安裝與 Section G 同一支檢查腳本，取代原本的雙向孤兒檢查描述。
- PR-TRUTH-16 — 技能文字裡「孤兒章節報紅」一類的規則，改寫成「由 /setup-skills 安裝的檢查擋下」；不再宣稱沒有檢查在執行的規則。
- PR-TRUTH-17 — 檢查腳本的測試留在本 repo，對 PR-TRUTH-03、07、08、10、12 各有一組紅、綠案例；`bash scripts/check.sh` 通過。
- PR-TRUTH-18 — 技能文字、GLOSSARY、decision-log 與 commit 訊息不提及促成這次改動的參考專案，也不取它的內容當範例；範例一律用通用情境。

## Out of scope

- 行數上限：高星專案的上限都只是 prompt 軟規則，沒有程式強制；我們不設。
- 「不寫標準章節」維持散文規則，不做檢查。
- 沒改到的章節的清理：一次性的大掃除歸 `bootstrap-truth`。
- 渲染承諾內文的預覽：補救「只有 ID 不好讀」等於把重複抄回來。
- 承諾的指紋或版本號：PR-TRUTH-11 讓「引用退役 ID」被 PR-TRUTH-10 抓到，不需要另一套機制。
- `TC-` 編號是否套用 PR-TRUTH-11：等 `/uat-cases` 下次修改時決定。
- 修改任何其他專案。

## Decisions

- 承諾內文只住 capability 檔，合訂本只引用 ID。否決：合訂本保留摘要。
- 合訂本保留，做成骨架形。否決：像逐功能規格那樣完全不寫合訂本（找不到系統全貌）。
- 舊內容只在改到的章節清，並獨立 commit。否決：一次性全面重寫、行數預算。
- 能力標記用 capability 檔名主幹；`共用` 是明確標記且不繼承。否決：英文章節白名單、顯示名稱。
- 雙向檢查以 capability 檔的 `## 規格章節` 為反向端。否決：只做單向（只看標題有沒有標記）。
- 檢查腳本由 `/setup-skills` 逐字複製到目標專案，測試留在本 repo。先例：Section F。否決：放 hook、放在技能裡讓模型自律。
- 舊專案照裝，紅燈先列清單；使用者在 branch protection 設成必過之前不擋合併。否決：baseline 檔。
- 承諾意思改變就換新 ID。否決：雜湊指紋（Doorstop 式）、ID 內含版本號（OpenFastTrace 式；作者忘了升版就失效）。
- ID 前綴自動推導。否決：在 `domain.md` 設定 ID regex。代價：打錯的前綴抓不到。
- `共用` 只列出不報紅。否決：報紅或要求理由。
- capability 檔形狀遷就現有寫法：承諾標題沿用 `## Promises`（與 `/to-spec` 規格形狀一致），行首 `- ` 可有可無，`## 驗證` 為選用小節。否決：改用 `## 承諾` 加強制 `- ` 前綴（現有 capability 檔的承諾會全部判成「找不到」）。

## Open questions

（無）
