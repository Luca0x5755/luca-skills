# 議題追蹤器：本機與遠端並存、依規模分流

## Why
現在每個 repo 只能選一套追蹤器。實務上兩種議題都存在：一個 PR 做完就丟的，和要活得比分支久的。同一個真實專案已經同時有本機議題和遠端議題，還手動把一張從本機搬到遠端。流程要承認這件事，不能再二選一。

## Scope
- `/setup-skills` Section A 與 `issue-tracker.md` 的格式。
- 十個技能依判準選追蹤器：`to-spec`、`to-tickets`、`wayfinder`、`triage`、`implement`、`implement-spec`、`run-queue`、`audit-truth`、`diagram`、`feasibility`。
- 本 repo 自己的 `docs/agents/issue-tracker.md` 與 `CLAUDE.md` 的「Agent skills / Issue tracker」小節。

## Promises
- PR-TRACKER-01 — `docs/agents/issue-tracker.md` 頂部寫分流判準，判準只寫這一處；下接本機與遠端兩小節，各記建立、列出、阻塞關係、正文位置。
- PR-TRACKER-02 — 判準是：預期一個 PR 內做完並刪除走本機；需多個 PR、合併後有維護或驗收、或 PR 之外有人需要追蹤它的狀態（回報者、驗收者、別的團隊）走遠端。整份規格連同票由 `/run-queue` 或 `/implement-spec` 在一個 PR 內整合，算本機。
- PR-TRACKER-03 — 沒有 remote 時，遠端小節寫「不存在」，所有技能退化為只用本機。
- PR-TRACKER-04 — `/setup-skills` Section A 同時記錄兩套，遠端小節包含該追蹤器的非關閉引用寫法。
- PR-TRACKER-05 — `to-spec`、`to-tickets`、`wayfinder` 發佈前提議一次去向並附一行理由，使用者確認一次；不加標記欄位。規格與它的票永遠同一邊。
- PR-TRACKER-06 — `/triage` 的外來議題、`/wayfinder` 的 map 與決策票固定走遠端，不提議、不詢問。
- PR-TRACKER-07 — `to-spec` 發佈規格時問一句有沒有驗收議題；有就在遠端同時建一張，PR 用非關閉引用，由人驗收後手動關。規格本身已在遠端時，驗收是它的一張票。
- PR-TRACKER-08 — 本機議題做不完時，在遠端建議題並引用原內容，同一次 commit 以 `git rm` 刪本機檔案。不設反向流程。
- PR-TRACKER-09 — `implement`、`implement-spec` 依判準指到的位置讀取與完成議題；`implement-spec` 現有的跨追蹤器行為不退步。
- PR-TRACKER-10 — `run-queue` 的前提由「追蹤器是本機 markdown」改為「有本機票」；遠端規格不歸它管。
- PR-TRACKER-11 — `audit-truth` 的漂移票固定只讀遠端；沒有 remote 時只看宿主漂移帳本。`diagram` 讀判準指到的位置。
- PR-TRACKER-12 — `feasibility` 對本機規格，把報告追加成規格檔末節 `## Feasibility`；對遠端規格維持貼成留言。
- PR-TRACKER-13 — 本 repo 的 `issue-tracker.md` 與 `CLAUDE.md` 的追蹤器小節改成雙套；`GLOSSARY.md` 遠端議題條的措辭與 PR-TRACKER-02 一致。
- PR-TRACKER-14 — `bash scripts/check.sh` 通過。

## Out of scope
- `git-commit`：只舉例提到 `gh issue create -F`，不讀追蹤器路徑。
- 遠端升回本機的反向流程：沒有需求，也會讓位置失去紀錄意義。
- `check.sh` 新規則與 ADR：分流是語意判斷、本機半邊已有 `issues-check`、改動隨時可逆（見決策紀錄）。
- 版本號：發版時由 `git-release` 處理。
- 標記欄位：位置本身就是紀錄。
- 一份規格的票跨兩邊拆。

## Decisions
- 並存、依規模分流，而不是二選一：見 `docs/decision-log.md` 2026-11-09 第一條。被否決的是「每 repo 選一套」，因為真實專案已經打破它。
- 範圍加上 `run-queue`、`diagram`、`audit-truth`、`feasibility`：見 2026-11-09 第二條。
- 判準措辭用「有人需要追蹤它的狀態」，不用「看見」：試跑中一張一個 PR 修完的使用者回報 bug 讓兩條判準打架，原措辭太模糊。
- 判準只寫在 `issue-tracker.md` 頂部，技能不各自重述。

## Open questions
- GitLab 的非關閉引用寫法：實作時讀官方文件確認，這次研究沒驗證。
- `implement-spec` 現在怎麼處理遠端規格：實作時先讀，再決定要改多少。
- 持久內容落點：`implement` 完成時，這些 promise 會移入 `docs/capabilities/` 的新檔（與現有 `installer.md` 同層）。檔名到時再定。
