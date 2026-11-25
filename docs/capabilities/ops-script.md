# 運維腳本骨架

`skills/draft/ops-script/` 的 bash（`skeleton.sh`）與 PowerShell（`skeleton.ps1`）骨架，其 ops-lib v8 提供**逐步模式**與**繼續指令**：不熟專案的操作者可以逐個**步驟**讀說明、按 Enter 才往下跑；腳本沒做完就停下時，直接點名下一步要打的指令。寫運維腳本的人複製骨架取得這些行為，`scripts/manage.sh`／`manage.ps1` 只逐字同步 ops-lib 區段。續跑依系統狀態收斂、不做 `--from`。
本檔保留已發佈規格的 promise ID；修改行為時沿用原 ID。

## Promises

PR-OPS-01 — 帶 `--step`（PowerShell `-Step`）執行子命令時，每次 `step` 呼叫開始前印出該步驟的標題與說明，然後停下等操作者輸入；停點只在 `step`，`run` 前不停。
PR-OPS-02 — 逐步模式下，步驟標題帶流水號，形如 `== 步驟 2：<標題>`；開跑前不印所有步驟的總覽。
PR-OPS-03 — `step "標題" "說明行"...` 接受選填的說明行，說明行只在逐步模式印。不帶 `--step` 時，說明行不印，輸出與結束碼與不帶說明行的 `step` 相同。
PR-OPS-04 — 停點只接受三種輸入：Enter 執行這一步；`a` 執行這一步，之後不再停，但仍照印每步的標題與說明；`q` 離開。沒有跳過選項。其他輸入重問，讀到輸入結束等同 `q`。
PR-OPS-05 — 在停點按 `q`（或讀到輸入結束）時，先印總表，再點名停在哪一個步驟之前，然後以結束碼 1 結束。
PR-OPS-06 — 帶 `--step` 但沒有終端機時，結束碼 2，訊息點名要拿掉 `--step`（PowerShell 為 `-Step`）；不執行任何步驟。
PR-OPS-07 — `--step` 可與 `--dry-run`（PowerShell `-WhatIf`）、`-y`（PowerShell `-Yes`）並用。
PR-OPS-08 — 逐步模式不改變**需確認**：帶 `[需確認]` 的子命令照常走 `confirm`（無人值守仍需 `-y`）。同一步驟若有確認，會先在 Enter 停點停一次，再在確認停一次；Enter 永遠不能代替 y。
PR-OPS-09 — `--step` 由各子命令自己解析。`main` 只在唯一參數是 `--step` 時進入選單，並把 `--step` 轉交給選定的子命令。
PR-OPS-10 — PowerShell 的停點由 ops-lib 自寫，不使用 `ShouldProcess`、`-Confirm` 或 `Set-PSDebug`。
PR-OPS-11 — 在逐步模式按 `q` 或讀到輸入結束，以及任何模式下 `finish` 時有任一 fail，都要印出**繼續指令**。bash 的繼續指令走 stderr，stdout 的內容不變；PowerShell 走 `Write-OpsLine`（`Write-Host`，與 `[PASS]` 及總表同一條），成功輸出串流的內容不變。
PR-OPS-12 — 繼續指令依序組成：子命令名、操作者原本給的參數（由 `run_command` 記下），以及子命令在互動中以 `resume_arg`／`Add-OpsResumeArg` 補登的等價參數。原參數裡沒有 `-y`（PowerShell `-Yes`）時，絕不自動加上。
PR-OPS-13 — 正常做完（沒有 fail，也沒有按 q）時，不印繼續指令。
PR-OPS-14 — `SKILL.md`（bash）與 `POWERSHELL.md` 寫明以下規則：每個步驟都必須可重跑；耗時或不可重做的步驟要先查系統狀態，已完成就呼叫 `skip`；步驟說明選填，寫 1–3 行，內容回答「改什麼、重跑會怎樣、停在這裡系統是什麼狀態」。
PR-OPS-15 — 骨架的 `hello` 示範至少有一個步驟帶說明行，並能以 `--step` 跑完。
PR-OPS-16 — 骨架、`scripts/manage.sh`、`scripts/manage.ps1` 的 ops-lib 區段都標 v8，且與骨架逐字相同；`grep -rn "BEGIN ops-lib"` 列出的版號一致。
PR-OPS-17 — PR-OPS-01～13、18～20 在 `tests/` 下的骨架測試有對應斷言，bash 由 `tests/test-tooling.sh` 接上，PowerShell 由 Windows CI 補跑；`bash scripts/check.sh` 通過。
PR-OPS-18 — 從選單進入逐步模式（唯一參數是 `--step`／`-Step`）並選定子命令時，開跑前印的等價指令帶 `--step`（PowerShell `-Step`）。
PR-OPS-19 — 繼續指令與選單等價指令同一種寫法：bash `→ <腳本名> <子命令> <參數...>`，PowerShell `-> <腳本名> <子命令> <參數...>`，腳本名與等價指令相同。
PR-OPS-20 — `hello` 互動挑選目錄後，以 `resume_arg`／`Add-OpsResumeArg` 補登 `--pick <名稱,...>`（PowerShell `-Pick <名稱,...>`），所以它的繼續指令重跑時不再進多選器。

## 驗證

- `bash tests/scripts/test-ops-script-skeleton.sh`（CI 由 `tests/test-tooling.sh` [27] 跑）：bash 的 PR-OPS-01～09、11～13、15、16、18～20，以及 PR-OPS-14 在 `SKILL.md` 的措辭；終端機分支靠 LIB 接縫覆寫 `_is_tty` 模擬，沒有真的 pty。
- `bash tests/scripts/test-ops-script-skeleton-ps.sh`（[28]，Windows CI 補跑 5.1 與 7）：PowerShell 的 PR-OPS-01～13、15、16、18～20，以及 PR-OPS-14 在 `POWERSHELL.md` 的措辭；終端機分支靠覆寫 `Test-OpsTty` 模擬。
- `tests/scripts/test-manage.sh`、`test-manage.ps1`：PR-OPS-16 的 `manage.*` 逐字同步。
- `bash scripts/check.sh`：PR-OPS-17 的整體不變量。
- 骨架沒有 `-y`／`-Yes` 參數，PR-OPS-07、08 的並用以 LIB 片段與「Enter 停點和確認互相獨立」驗證。
