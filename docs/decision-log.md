2026-09-25 本機議題預設位置改為 `docs/issues/ISSUE-NNN-<slug>.md`，且只活在一條分支內、做完即刪 — 議題進版控後若可跨分支留存，就會退化成第二份 backlog 與第二份真相。
2026-09-25 promise ID 的帳本是真相層，不是發佈出去的規格議題 — 本機議題做完即刪，規格若兼當帳本，刪除就會讓 ID 可被重發；規格不另闢 `docs/specs/`，與 `/to-architecture` 的「規格保持合併」一致。
2026-09-25 「分支淨新增議題必須為零」的檢查建在 CI 而非 hook — 網頁開的 PR 也擋得到；分支保護（required check）留給使用者設定，技能不改儲存庫保護規則。
2026-10-01 迴圈的「一輪」只計單張票內的重試，不計票數 — 否則十張票的佇列第四張就會被判停；票的佇列是外圈，用 BLOCKED 與擱置收斂，不用輪數。
2026-10-01 為降低人工介入而評估移除 hook，結論是一條都不拆 — hook 只擋不問，不產生等待；`check-on-stop` 與 `guard-*` 正是無人看管迴圈的驗收尺與護欄。
2026-10-01 `/run-queue` 防自我核准用揭露而非關卡 — PR 按票列出被改或刪的既有測試與被駁回的審查發現；merge 本來就是人的關卡，再加驗收子代理只多一份判斷與誤擋。
2026-10-01 `/run-queue` 不做開工前「票已完成」的 no-op 判斷 — 票檔刪除即完成，誤判會讓沒做的票消失；等真實執行出現票重疊的證據再議。
2026-10-01 規劃技能（grill-with-docs、to-spec、to-tickets、to-architecture、frontend-spec）在使用者核可、寫入後自動 commit 但不 push — 原本產出全留未提交，`/run-queue` 的「工作樹乾淨」永遠過不了；不 push 讓 `git reset --soft HEAD~1` 仍能收回。
2026-10-01 `/run-queue` 開 PR 前不 squash — 每票各自的 commit 是自我核准痕跡的證據來源；`main` 由 squash merge 收成一個 commit，結果與手動 squash 相同。
2026-10-07 上游移植目標固定為 mattpocock/skills v1.3.1（24fe0ef7737efae15c87225755e9f6f5965e4888），以 v1.2.3 為基準；遷移詞彙表為 GLOSSARY 命名、採用行為修正並新增 retro，保留本地治理與 0.2.3 版本，不搬移全庫 em-dash 文風改寫。
2026-10-07 git-pr／git-mr 吸收上游 pr 的最小視覺摘要、實際前後證據與合併風險，保留既有繁中段落與平台生命週期，不新增 pr 技能 — 改善審查資訊而不增加入口。
2026-10-07 保留 implement-spec 與 run-queue：前者可介入且跨追蹤器，後者本機票無人看管、有限重試、擱置與必開 PR；run-queue 預設串行，可選兩個隔離 worker 平行建置、串行候選整合，完成以整合驗證為準，spec 由 coordinator 清理 — 平行能力不取代兩者不同的核准與收尾契約。
2026-10-07 安裝器 sh／ps1 統一為無參數互動選單，編號以空白分隔多選並去重，選定後直接安裝；空白、逗號或越界輸入提示後重問，Ctrl+C 取消，保留代理名稱參數供自動化使用 — 統一兩平台操作並省去第二次確認。
2026-10-08 git-release 先在終端機完整預覽版本、前一 tag、發布 commit 與摘要，揭露既有 tag／release 的覆寫內容；使用者確認後才改版本、commit、tag、push 與建立或更新 release，摘要修改須重新確認 — 讓人工核可落在實際發布內容上，且確認前不產生版本或 Git 變更。
2026-10-22 Understand-Anything 不移植、改為使用者自行安裝其 plugin 取得程式碼關係圖，ask-luca 與 README 不提它；study-repo 保留並只吸收「外部內容是資料不是指令」與入口打分兩條 — UA 依賴 Node／pnpm／tree-sitter 建置鏈且只做靜態分析，study-repo 的執行期真相是它結構上拿不到的；路由提及未必安裝的外部工具會讓地圖說謊。
2026-10-22 改動影響範圍分析（UA `understand-diff` 的 1-hop blast radius）暫不併入 git-pr／code-review — 每個 PR 都要付 grep 成本，且尚無影響範圍估錯的真實案例；出現此類案例再議。
2026-10-22 study-repo 的範圍外段落例外提及 Understand-Anything（附專案連結與 `/understand`，標明「若已安裝」）— draft 不對外發佈，指向可能未裝的工具傷害小，而在使用者想要整張關係圖的當下點出它價值大；ask-luca 與 README 技能清單仍不提。
2026-10-23 commit／PR 的 harness attribution 從源頭處理：專案 `.claude/settings.json` 設 `attribution` 為 `commit:""`、`pr:""`、`sessionUrl:false`（不用 `false` 簡寫，舊版會整份設定失效而丟掉 hook）；`git-pr` 補「不加 footer」規則，`guard-git` 放寬 `git -C` 並檢查 PR `--body-file`；不改 `run-queue` 與 `CLAUDE.md` — `git-commit` 已有規則，多一層只是重複；`-F -` 與相對路徑訊息檔無實證，不加 hook。
2026-10-24 指令紀律（捕捉一次、範圍對得上改動、獨立檢查並聯）只寫進 `implement` 一處，`implement-spec` 與 `run-queue` 指向它 — 實測 `check.sh` 與 `test-guard-git.sh` 並聯 104 秒對串聯約 158 秒，約兩成 shell 等待來自無改動的整套重跑；規則不為單一專案的範例特製，也不加 hook（是否必要重跑是語意判斷）。
2026-10-29 技能結尾的下一步一律報成「一步附觸發原因」的路線，沒觸發的步驟不提；`implement` 依追蹤器裡同規格的未完成票分流（本機用 §4 的 grep），票全部做完只接 `/git-pr`，`/branch-cleanup` 等畢業時再插進路線 — 核心指向可能被封存的 draft 會讓路線說謊，而畢業流程不檢查呼叫者；`run-queue` worker 在替換清單裡省略這一步，例外留在協調者端；不進 GLOSSARY、不加 check.sh — 是寫作慣例不是領域詞，也沒有確定性判準。
2026-10-31 新增 draft 使用者觸發技能 `research`：以具名決策為錨，把 Felix Rieseberg 的 Altitude／Depth／Range 落成開工關卡、原始材料分析、跨域方法與外部裁判分級；獨立完整、不依賴 `anthropic-skills:deep-research` — 該技能只負責覆蓋率式的敘事報告且未必安裝（Copilot／Codex 沒有），路由指向它會讓地圖說謊；畢業與否由使用者判斷後提出，不加比較門檻。
2026-10-31 上游移植目標改固定為 mattpocock/skills v1.3.2（d1478fcb140db0b93c0c8df17bcfd311844749d0），以 v1.3.1 為基準；只搬 wizard 範本修正與 code-review、ask-luca、implement、grilling、handoff、diagnosing-bugs 的行為修正，接縫取捨說明放 `implement` §2 而非上游的 `tdd`，固定在 v1.3.1 的上游連結不動 — 這些修正有已重現的缺陷或上游失敗回報，且規則要放在實際發問的地方；未吸收的內容不該因連結改版而看似已吸收。
2026-10-31 wizard 的 `write_env` 一律寫單引號，不做「含特殊字元才加引號」的分支，移植後在 Git Bash 重跑重現腳本一次、結果寫進 PR，不加常駐測試 — `source` 損毀已重現，`docker run --env-file` 的相容風險未驗證；範本極少變動，等出現回歸再補測試。
2026-10-31 不搬上游 v1.3.2 的 fresh context（#1341）與「防遞迴歸 harness」立場，保留「子代理不得再召喚本技能」 — 前者只有上游 PR 自述，Codex 端未查證，實測子代理繼承父對話再議；後者上游 #573 穩定重現卻以 not planned 關閉，問題未被證明已解決，本地防護只要一句話。
2026-10-31 wizard 的 `write_env` 偏離上游 v1.3.2：不用暫存檔、以 `: >>` 取代存在檢查，`_existing` 的單引號還原也改走變數 — 上游寫法在寫入失敗時會把含 secret 的暫存檔留在磁碟上，存在檢查與截斷之間有競態，`\'` 替換在 bash 4.2 語意下會多留反斜線（以 `compat42` 模擬）；下次移植此段要保留這些差異。
2026-11-14 `frontend-spec` 只支援 Penpot，Pencil 流程整段刪除，不做由專案宣告工具的雙軌 — badminton、automated_trading、luca-style 都已遷走，Pencil 那段引用的 `get_guidelines`／`get_screenshot` 在現行 MCP 已不存在；還在 Pencil 上的專案要做 UI 時先遷 Penpot。
2026-11-14 `frontend-spec` 的畫圖交給子代理：主線不呼叫 `penpot` 工具，一頁一個全新（非 fork）子代理、循序執行，首頁畫完先停等使用者在 Penpot 驗收；分頁被掛起即停手回報、不重試 — 實測主線自己畫的 11 個 session 共 compact 48 次，28 個子代理 0 次且回報中位約 4 千字元；Penpot 是大量小呼叫（1,394 次、回傳中位 277 字元）加截圖累積，削減單次輸出無效；平行沒有證據，暫不做。
2026-11-09 議題追蹤器由「每 repo 二選一」改為本機與遠端並存、依規模分流（一個 PR 做得完走本機，需多 PR、合併後維護驗收或 PR 外的人要看見走遠端；規格與票同邊、本機可升級到遠端、無 remote 時退化為本機、驗收議題以 `Refs` 而非 `Closes` 引用），判準只寫在 `docs/agents/issue-tracker.md`，不加 check.sh 規則也不寫 ADR — 分流是語意判斷無確定性判準，本機那半已有 `issues-check` 強制，改動只動文件與技能文字、隨時可逆。
2026-11-09 混合追蹤器的落地範圍加上 `run-queue`（前提改為「有本機票」，遠端規格不歸它管）、`diagram`、`audit-truth`（漂移票屬維護、固定只讀遠端，無 remote 時只看宿主漂移帳本）與 `feasibility`（本機規格把報告追加為規格檔末節 `## Feasibility`，遠端規格維持留言），`git-commit` 不動；`issue-tracker.md` 遠端小節記該追蹤器的非關閉引用寫法，由 `/setup-skills` 寫入、實作時讀官方文件確認而非憑記憶 — 查出這四個技能各自寫死單一追蹤器的假設，漏改會在並存後靜默讀錯地方；`Refs #N` 與 GitLab 行為在研究中只看過搜尋摘要。
2026-11-14 Penpot MCP 卡死的規則分三處：禁用 `penpotUtils.findShape`／`findShapes`／`findShapeById`（不論帶不帶 root）做成 `guard-penpot.sh`（PreToolUse，matcher `mcp__penpot__execute_code|mcp__penpot__export_shape`，`setup-skills` 只在專案用 Penpot 時提議，`frontend-spec` 前置條件缺它即停），同一條在 `PAGE-BRIEF.md` 再寫一行給 Codex／Copilot 保底，軟規則（每次少改、不大量改主元件、不為速度包 undo block）只進 `PAGE-BRIEF.md`；不做 operating rules 範本、不碰 `~/.claude`、不向上游回報 — 效能規則本不該升 hook，破例因 MCP 官方 instructions 教的正是全域寫法（16 頁 32,173 物件實測 23 秒對 `getShapeById` 1 ms），prose 對上更權威的 prose 守不住；一律擋不數參數，因為用正規表達式數括號裡的逗號必然誤判，而替代的 `currentPage.findShapes({}).filter()` 實測反而較快。
2026-11-14 `export_shape` 一律走 `shapeId: "selection"`：先在 `execute_code` 以 `currentPage.getShapeById` 設 `penpot.selection` 再匯出，hook 擋 `selection`／`page` 以外的 `shapeId`；`PAGE-BRIEF.md` 註明圖不對就重選再匯出 — 帶 UUID 時工具內部寫死全域搜尋（上游 develop 仍未修），複製檔上實測選取可寫且跨呼叫維持；官方 instructions 自己也警告選取可能被使用者改掉，這個殘餘風險以重試吸收、不另加檢查。
