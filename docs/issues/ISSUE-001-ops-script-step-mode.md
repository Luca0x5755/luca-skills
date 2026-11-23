# ops-script 逐步模式與繼續指令（ops-lib v8）

## Why

如果操作者不熟悉專案，照現在的運維腳本執行，只看得到一行行 `[PASS]`／`[FAIL]` 一路跑完。每個**步驟**改了什麼、停在哪裡會留下什麼狀態，他都不知道，也沒機會停下來讀。腳本中途停下時，他也不知道怎麼接著做完。這份規格要做兩件事：一是讓操作者能逐個**步驟**讀說明、按 Enter 才往下跑；二是腳本沒做完就停下時，直接告訴他下一步要打哪行指令。

## Scope

- ops-lib 升 v8，bash（`skeleton.sh`）與 PowerShell（`skeleton.ps1`）兩份都改。內容包括：**逐步模式**、`step` 的說明行、**繼續指令**，以及 `resume_arg`／`Add-OpsResumeArg`。
- 骨架的 `hello` 示範加上說明行。
- `SKILL.md`、`POWERSHELL.md` 加入對應規則，其中一條硬規則是「每個步驟都必須可重跑」。
- 為新行為補上骨架測試，bash 與 PowerShell 各一份。
- `scripts/manage.sh`、`scripts/manage.ps1` 依 ADR 0003 同步 ops-lib 區段到 v8，不加新功能。

## Promises

PR-OPS-01 — 帶 `--step`（PowerShell `-Step`）執行子命令時，每次 `step` 呼叫開始前印出該步驟的標題與說明，然後停下等操作者輸入；停點只在 `step`，`run` 前不停。
PR-OPS-02 — 逐步模式下，步驟標題帶流水號，形如 `== 步驟 2：<標題>`；開跑前不印所有步驟的總覽。
PR-OPS-03 — `step "標題" "說明行"...` 接受選填的說明行，說明行只在逐步模式印。不帶 `--step` 時，輸出與結束碼都和 v7 相同。
PR-OPS-04 — 停點只接受三種輸入：Enter 執行這一步；`a` 執行這一步，之後不再停，但仍照印每步的標題與說明；`q` 離開。沒有跳過選項。其他輸入重問，讀到輸入結束等同 `q`。
PR-OPS-05 — 在停點按 `q`（或讀到輸入結束）時，先印總表，再點名停在哪一個步驟之前，然後以結束碼 1 結束。
PR-OPS-06 — 帶 `--step` 但沒有終端機時，結束碼 2，訊息點名要拿掉 `--step`（PowerShell 為 `-Step`）；不執行任何步驟。
PR-OPS-07 — `--step` 可與 `--dry-run`（PowerShell `-WhatIf`）、`-y`（PowerShell `-Yes`）並用。
PR-OPS-08 — 逐步模式不改變**需確認**：帶 `[需確認]` 的子命令照常走 `confirm`（無人值守仍需 `-y`）。同一步驟若有確認，會先在 Enter 停點停一次，再在確認停一次；Enter 永遠不能代替 y。
PR-OPS-09 — `--step` 由各子命令自己解析。`main` 只在唯一參數是 `--step` 時進入選單，並把 `--step` 轉交給選定的子命令。
PR-OPS-10 — PowerShell 的停點由 ops-lib 自寫，不使用 `ShouldProcess`、`-Confirm` 或 `Set-PSDebug`。
PR-OPS-11 — 在逐步模式按 `q` 或讀到輸入結束，以及任何模式下 `finish` 時有任一 fail，都要印出**繼續指令**。繼續指令一律走 stderr，stdout 的內容不變。
PR-OPS-12 — 繼續指令依序組成：子命令名、操作者原本給的參數（由 `run_command` 記下），以及子命令在互動中以 `resume_arg`／`Add-OpsResumeArg` 補登的等價參數。原參數裡沒有 `-y`（PowerShell `-Yes`）時，絕不自動加上。
PR-OPS-13 — 正常做完（沒有 fail，也沒有按 q）時，不印繼續指令。
PR-OPS-14 — `SKILL.md`（bash）與 `POWERSHELL.md` 寫明以下規則：每個步驟都必須可重跑；耗時或不可重做的步驟要先查系統狀態，已完成就呼叫 `skip`；步驟說明選填，寫 1–3 行，內容回答「改什麼、重跑會怎樣、停在這裡系統是什麼狀態」。
PR-OPS-15 — 骨架的 `hello` 示範至少有一個步驟帶說明行，並能以 `--step` 跑完。
PR-OPS-16 — 骨架、`scripts/manage.sh`、`scripts/manage.ps1` 的 ops-lib 區段都標 v8，且與骨架逐字相同；`grep -rn "BEGIN ops-lib"` 列出的版號一致。
PR-OPS-17 — PR-OPS-01～13 在 `tests/` 下的骨架測試有對應斷言，bash 由 `tests/test-tooling.sh` 接上，PowerShell 由 Windows CI 補跑；`bash scripts/check.sh` 通過。

## Out of scope

- **`--from <步驟名稱>` 這類依位置續跑。** 步驟名稱可能不唯一；比對失敗時仍會以結束碼 0 結束；被略過的步驟，它的狀態就遺失了。續跑改靠「依系統狀態收斂」（見 decision-log 2026-11-23）。
- **在行程外記錄完成進度（stamp／ledger）。** 對 ops-lib 太重，而且 stamp 會過期。
- **停點加跳過選項。** 原型實測：閘門掛在 `run` 時，被跳過的步驟會被記成 `[PASS]`。何況步驟本來就可重跑，跳過沒有必要。
- **開跑前印出所有步驟的總覽。** 會多一層要讀、要按的東西，加重習慣化。
- **`scripts/manage.*` 的新功能。** 只同步 ops-lib 區段，不加 `--step` 入口，也不加說明行。
- **翻譯 `[PASS]`／`[FAIL]` 與總計行，或更動選單等價指令的箭頭。** 沿用 decision-log 2026-11-23 的決定。

## Decisions

- **停點掛在 `step`，不掛在 `run`。** 否決：每條 `run` 都停。停點要少而粗，否則操作者很快就習慣性按 Enter；另外，掛在 `run` 時跳過會被記成 `[PASS]`。依據 decision-log 2026-11-23。
- **Enter 閘門與 `[需確認]` 分開。** 否決：在逐步模式下用 Enter 代替 y。Enter 只管節奏，要用 y 才能確認不可逆的動作。依據同上。
- **由子命令解析 `--step`。** 否決：只由 `main` 統一攔截。子命令要能直接帶 `--step` 呼叫，選單只是轉交。
- **PowerShell 自寫停點。** 否決：用 `ShouldProcess`／`-Confirm`。在 `-NonInteractive` 下它每步都丟錯，結束碼卻是 0；`Set-PSDebug -Step` 則是逐行停，粒度不對。依據 decision-log 2026-11-23，以及 2026-11-20 的「PowerShell 維持自寫 confirm」。
- **續跑依系統狀態收斂。** 否決：`--from` 依位置續跑，以及在行程外記錄完成進度。依據 decision-log 2026-11-23。
- **繼續指令＝原參數＋補登的互動值，不自動加 `-y`。** 否決：只印子命令名，或為了省事自動加 `-y`。互動中按過的確認，重跑時要再確認一次。依據 decision-log 2026-11-23。
- **繼續指令走 stderr。** 否決：印到 stdout。stdout 若有程式在讀，多一行會弄壞它。
- **不寫 ADR。** 這些設計尚未實作，也可以回頭，過不了 ADR 的門檻。

## Open questions

- **選單轉交 `--step` 時，印出的等價指令要不要含 `--step`？** 對話沒決定。拍板方式：實作時比照繼續指令，「原參數」算不算包含 `--step`，由使用者決定。
- **繼續指令的開頭怎麼寫（腳本路徑、bash 與 PowerShell 的呼叫形式）？** 要不要沿用選單等價指令的寫法，對話沒決定。拍板方式：實作第一張票時，由使用者看過兩種輸出再選。
- **`hello` 示範要不要示範 `resume_arg`／`Add-OpsResumeArg`？** `hello` 若沒有互動取值，就示範不到。拍板方式：看 `hello` 現有的互動，再決定加不加。
