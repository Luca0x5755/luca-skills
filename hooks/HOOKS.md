# Hook 地圖

本 repo 掛載的每一條 hook：它掛在哪個事件、擋什麼、為什麼。技能裡的禁令是模型自律，hook 是機器強制 — 兩者同構，後者不會忘。

三方對齊由 `scripts/check.sh` 強制：`.claude/settings.json` 的掛載 ↔ `hooks/` 目錄的腳本 ↔ 本檔的 `## <腳本名>` 條目，缺一即紅。每支腳本另有同名 `test-*.sh` 測試（check.sh 不變量 8）。

## guard-git.sh

- **事件**：PreToolUse（matcher: Bash）。
- **擋**：`git add -A`／`git add .`、force push、`git reset --hard`（唯一放行 `git reset --hard HEAD`：只丟未提交變更、不動分支指標，/refactor 撤退用）、`--no-verify`、`gh pr merge`（連同 `gh api …/merge` 這條後門）；以及 `git commit` 的三條形狀規則 — 在 main／master 上 commit（同一指令裡先 `git switch -c`／`checkout -b` 的放行）、`-m` 內嵌訊息（要 `-F` 檔案）、`-F` 檔案含 `Co-Authored-By`／`Claude-Session`／`Generated with` trailer。
- **為什麼**：staging 邊界是誰觸發的誰畫；合併是使用者的按鈕；歷史改寫與跳過檢查不是代理的權限。三條 commit 形狀規則本來是 `/git-commit` 的散文，2026-09-04 實測目標專案裡的技能會跳過讀取直接 commit — 散文被跳過，再加散文沒用，升格為機器強制。exit 2，stderr 告訴模型正確做法。
- **關係**：`setup-skills` 會把本腳本逐位元組複製進目標 repo 的 `.claude/hooks/`。

## guard-secrets.sh

- **事件**：PreToolUse（matcher: Bash）。
- **擋**：`git commit` 時掃 staged diff 的新增行，抓憑證字面值（`TEST_PW = "…"`、`"password": "…"`）。讀環境變數、樣板佔位、散文提及都放行。exit 2。
- **為什麼**：這是 `/browser-evidence` 「憑證一律讀環境或庫外檔」那條散文的機器版 — 2026-08-11 實測散文擋不住，密碼進了公開分支，而 force-push 不等於刪除。
- **關係**：與 guard-git.sh 同為 `setup-skills` 外發的護欄組。

## check-on-stop.sh

- **事件**：Stop。
- **擋**：不變量表面（`skills/`、`.claude-plugin/`、`README.md`、`package.json`）有未提交變更且 `check.sh` 紅著，不准收工。查 `stop_hook_active` 防無限迴圈。
- **為什麼**：紅著收工的 session 把爛攤子留給下一個 session。
- **關係**：只在本 repo 掛載，不外發。

## 原則

確定性檢查優先、訊息帶「擋了什麼＋為什麼＋正確做法」、少而必然 — 每加一條 hook 就加一份延遲與誤擋風險。判準與寫法見 `/writing-hooks`。
