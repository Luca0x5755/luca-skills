# 議題追蹤器

本機與遠端兩套並存、依規模分流；判準與兩邊的操作寫在 [`docs/agents/issue-tracker.md`](../agents/issue-tracker.md)，技能一律指向該檔。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-TRACKER-01 — `docs/agents/issue-tracker.md` 頂部寫分流判準，判準只寫這一處；下接本機與遠端兩小節，各記建立、列出、阻塞關係、正文位置。
PR-TRACKER-02 — 判準是：預期一個 PR 內做完並刪除走本機；需多個 PR、合併後有維護或驗收、或 PR 之外有人需要追蹤它的狀態（回報者、驗收者、別的團隊）走遠端。整份規格連同票由 `/run-queue` 或 `/implement-spec` 在一個 PR 內整合，算本機。
PR-TRACKER-03 — 沒有 remote 時，遠端小節寫「不存在」，所有技能退化為只用本機。
PR-TRACKER-04 — `/setup-skills` Section A 同時記錄兩套，遠端小節包含該追蹤器的非關閉引用寫法。
PR-TRACKER-05 — `to-spec`、`to-tickets`、`wayfinder` 發佈前提議一次去向並附一行理由，使用者確認一次；不加標記欄位。規格與它的票永遠同一邊。
PR-TRACKER-06 — `/triage` 的外來議題、`/wayfinder` 的 map 與決策票固定走遠端，不提議、不詢問。
PR-TRACKER-07 — `to-spec` 發佈規格時問一句有沒有驗收議題；有就在遠端同時建一張，PR 用非關閉引用，由人驗收後手動關。規格本身已在遠端時，驗收是它的一張票。
PR-TRACKER-08 — 本機議題做不完時，在遠端建議題並引用原內容，同一次 commit 以 `git rm` 刪本機檔案。不設反向流程。
PR-TRACKER-09 — `implement`、`implement-spec` 依判準指到的位置讀取與完成議題；`implement-spec` 現有的跨追蹤器行為不退步。
PR-TRACKER-10 — `run-queue` 的前提由「追蹤器是本機 markdown」改為「有本機票」；遠端規格不歸它管。
PR-TRACKER-11 — `audit-truth` 的漂移票固定只讀遠端；沒有 remote 時只看宿主漂移帳本。`diagram` 讀判準指到的位置。
PR-TRACKER-12 — `feasibility` 對本機規格，把報告追加成規格檔末節 `## Feasibility`；對遠端規格維持貼成留言。
PR-TRACKER-13 — 本 repo 的 `issue-tracker.md` 與 `CLAUDE.md` 的追蹤器小節改成雙套；`GLOSSARY.md` 遠端議題條的措辭與 PR-TRACKER-02 一致。
PR-TRACKER-14 — `bash scripts/check.sh` 通過。

## 驗證

- `bash scripts/check.sh`：PR-TRACKER-14，整體不變量（含 `issues-check` 的本機議題檢查）。
- 其餘 promise 是語意判斷，沒有機械檢查；依據是決策紀錄 2026-11-09 兩條與各技能的 `SKILL.md`。
- PR-TRACKER-04 的 GitHub 非關閉引用 `Refs #N` 為官方文件推論，未實跑驗證；GitLab 的 `Related to #N` 取自官方文件範例。
