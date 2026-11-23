# 讓 bash 骨架以 `--step` 逐步執行 hello

## Done when

- `bash skills/draft/ops-script/skeleton.sh hello --step` 在終端機中：每個 `step` 前印 `== 步驟 N：<標題>` 與說明行，停下等輸入。Enter 執行這一步；`a` 執行之後各步、不再停但照印說明；`q` 或讀到輸入結束時，先印總表、點名停在哪一步之前，結束碼 1；其他輸入重問。沒有跳過選項，開跑前也沒有總覽（PR-OPS-01、02、04、05）。
- 不帶 `--step` 時，`step` 的說明行不印；hello 的輸出與結束碼都和 v7 相同（PR-OPS-03）。
- `hello --step` 沒有終端機時結束碼 2，訊息點名拿掉 `--step`，什麼都不做（PR-OPS-06）。
- `--step` 可與 `--dry-run`、`-y` 並用。有確認的步驟先停在 Enter，再停在 `confirm`；在 Enter 停點輸入 `y` 不會被當成確認（PR-OPS-07、08）。
- `skeleton.sh --step`（唯一參數）在終端機中進選單，選定的子命令帶 `--step` 執行，開跑前印的等價指令是 `→ <腳本名> <子命令> --step`（PR-OPS-09、18）。
- hello 至少一個步驟帶說明行，並能以 `--step` 跑完（PR-OPS-15，bash 部分）。
- `skeleton.sh` 的區段標 `BEGIN ops-lib v8`，`scripts/manage.sh` 的區段與它逐字相同（PR-OPS-16，bash 部分）。
- `tests/scripts/test-ops-script-skeleton.sh` 對上列每一條都有斷言。`bash tests/test-tooling.sh` 與 `bash scripts/check.sh` 通過（PR-OPS-17，bash 部分）。

## Context

規格是 `docs/issues/ISSUE-001-ops-script-step-mode.md`，詞彙（**逐步模式**、**步驟**、**需確認**）見 `GLOSSARY.md`，ops-lib 的改法見 ADR 0003。這張票是第一顆曳光彈：只做 bash 骨架的逐步模式，繼續指令留給 ISSUE-003。

## Blocked by

Blocked by: none

## Notes

- **ops-lib 逐字同步**：`tests/scripts/test-manage.sh` 會逐字比對 `manage.sh` 與骨架的 ops-lib 區段。改了骨架區段卻沒同步，測試就紅。這張票只同步區段，不給 `manage.sh` 加 `--step` 入口。
- **閘門的位置**：閘門掛在 `step()` 裡，不掛在 `run()` 裡。原型實測過，掛在 `run` 時，被跳過的步驟會記成 `[PASS]`。`step "標題" "說明行"...`：第一個參數是標題，其餘每個參數各印成一行說明。`manage.sh` 現有的 `step "x"` 呼叫不能壞。
- **`--step` 的解析**：由子命令解析，`cmd_hello` 的 while/case 加一支。`main` 只在 `$1` 是 `--step` 且沒有其他參數時，轉交 `run_menu --step`；`run_menu` 已經會把轉交參數印進等價指令。
- **測試接縫**：測試環境沒有 pty。終端機分支用 LIB 接縫測：source 之後，在片段裡重新定義 `_is_tty` 讓它回 0，再從 stdin 餵入 `\n`、`a`、`q` 或空輸入。無終端機那條（結束碼 2）用 CLI 接縫測，並 `</dev/null`。
- **停點提示讀 stdin，寫 stderr**：比照 `confirm`。`[PASS]` 等固定詞彙與總計行不翻譯。
