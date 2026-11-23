# 讓 bash 骨架停下時印出繼續指令

## Done when

- 在逐步模式按 `q` 或讀到輸入結束時，stderr 印出繼續指令；任何模式下 `finish` 有 fail 時也印。正常做完時不印。stdout 與現行相同（PR-OPS-11、13）。
- 繼續指令的寫法是 `→ <腳本名> <子命令> <原參數...> <補登參數...>`，腳本名與選單等價指令相同（PR-OPS-12、19）。
- 原參數裡有 `-y` 才帶 `-y`，不會自動加上（PR-OPS-12）。
- hello 用多選器互動挑選後，以 `resume_arg` 補登 `--pick <名稱,...>`。照印出的繼續指令重跑，不會再進多選器，已存在的目錄也能再跑一次（PR-OPS-20，bash 部分）。
- `skills/draft/ops-script/SKILL.md` 寫明三條：每個步驟都必須可重跑；耗時或不可重做的步驟要先查系統狀態，已完成就呼叫 `skip`；步驟說明選填，寫 1–3 行，回答「改什麼、重跑會怎樣、停在這裡系統是什麼狀態」。另外寫明 `resume_arg` 的用法（PR-OPS-14，bash 部分）。
- `scripts/manage.sh` 的 ops-lib 區段仍與骨架逐字相同。`tests/scripts/test-ops-script-skeleton.sh` 對上列每一條都有斷言。`bash tests/test-tooling.sh` 與 `bash scripts/check.sh` 通過（PR-OPS-16、17，bash 部分）。

## Context

規格是 `docs/issues/ISSUE-001-ops-script-step-mode.md`，**繼續指令**的定義見 `GLOSSARY.md`。至於為什麼續跑依系統狀態、不做 `--from`，見 `docs/decision-log.md` 2026-11-23 的條目。這張票建立在 ISSUE-002 的逐步模式上。

## Blocked by

Blocked by: ISSUE-002-bash-step-mode.md

## Notes

- **原參數由 `run_command` 記下**：它在 ops-lib 區段外，`run_menu` 也是。補登走 `resume_arg <參數...>`，這個函式在區段內，跟著同步到 `manage.sh`。印出時不能把含空白的參數拆開，要用 `printf '%q'` 或同等做法。
- **不做 `--from`，也不在行程外記錄進度**：重跑之所以接得上，是靠每個步驟依系統狀態自行略過。hello 的 `mkdir -p` 本來就可以重跑。
- **互動按過的確認，重跑時要再確認一次**：這是設計，不要為了省一步而自動加 `-y`。
- **觸發點**：`finish` 判斷有 fail 時印；逐步模式的 `q` 也印。兩處要共用同一個函式，不要各寫一份。
