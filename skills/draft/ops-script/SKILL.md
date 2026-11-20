---
name: ops-script
description: 寫或改留在 repo 裡、反覆執行的運維腳本（bash 或 PowerShell）時的規則與骨架。當要新增部署、備份、還原、檢查類腳本，要讓腳本同時有互動選單與子命令，要讓排程或 CI 呼叫腳本，或要修改既有運維腳本時使用。只跑一次就丟的引導流程不用它，那是 /wizard。
---

# Ops Script

An **ops script** stays in the repo and gets run again and again by an operator to change or check system state. One script, two ways in: no arguments on a terminal opens a menu; a subcommand runs directly, so a scheduler, CI or another script can call it.

Not this skill: a script run once and thrown away, walking a human through a manual procedure — that is `/wizard`.

Start from [skeleton.sh](skeleton.sh): copy it, rename it, replace the `hello` demo. The block between `# ---- BEGIN ops-lib v2 ----` and `# ---- END ops-lib ----` is **copied verbatim** into every script, never hand-edited — a script must run alone on a machine where the repo does not exist, so there is no shared file to `source`. To change the block, change the skeleton, bump the version, and sync it back into each script; two scripts in one project carrying two different version numbers means one was missed (`grep -rn "BEGIN ops-lib"` shows them all). Edit the skeleton only; a fix made inside one script is lost at the next sync.

**PowerShell script?** Read [POWERSHELL.md](POWERSHELL.md) too: same structure from [skeleton.ps1](skeleton.ps1), plus the encoding (UTF-8 with BOM), 5.1-and-7, confirmation and `-WhatIf` rules that exist only there. The rules below are written in bash terms; the function map in that file translates them.

## Rules

Hold every rule below; the skeleton already embodies the ones marked (S).

**Strict mode is a safety net.** Keep `set -euo pipefail` (S), and catch every failure that matters yourself — check, then `die` with a message. Traps the skeleton steers around:

- `read` at end of input returns non-zero: write `read -r x || …` and decide what EOF means (S, `confirm` treats it as No).
- `grep -q` closes the pipe early; under `pipefail` the upstream command dies of SIGPIPE and the pipeline reports failure. Use `grep -c` or capture first.
- `-u` with an empty array: expand it as `${arr[@]+"${arr[@]}"}` (S, `print_summary`); a plain `"${arr[@]}"` aborts on older bash.
- `local x=$(cmd)` swallows `cmd`'s failure, because `local` returns 0. Declare, then assign on the next line.
- `set -e` is ignored inside `if`/`||` conditions, so a function on the left of `||` never aborts midway; `((n++))` returns 1 when `n` is 0 — count with `n=$((n + 1))` (S).

**Messages and diagnostics.**

- Diagnostics go to stderr; stdout carries only the output a caller would pipe (S).
- An error says what failed first, then how to fix it: `✗ title`, then indented fix lines (S, `die`).
- Colour turns off when stdout is not a terminal, `NO_COLOR` is non-empty, or `TERM=dumb` (S).
- Message language follows the target project's own language.

**Exit codes.** `0` done, `1` failed or the operator cancelled, `2` usage error (S). A cancel that returns `0` tells the calling script the action happened. Check-style subcommands report the check result through the exit code.

**No terminal.** Look at stdin only (S, `require_tty`).

- `--help` is never blocked by any check.
- No subcommand and no terminal: print usage, exit `2` (S). A default is never run silently.
- A subcommand missing a value: ask when stdin is a terminal, otherwise exit `2` — never pick for the operator ("restore the latest" included).
- A destructive action needs `-y` when unattended; interactively it goes through `confirm` (S, `[y/N]`, default No).

**Arguments and help.**

- An unknown argument exits `2` (S).
- `--help` prints only the `#/` lines at the top of the file (S).
- One table drives the menu, the `--help` list and the dispatch (S): the table is the `#/` subcommand rows, and a row `x-y` dispatches to `cmd_x_y`. Adding a subcommand is one row plus one function.
- A menu choice prints the equivalent command line before running it (S).
- Every subcommand that changes the system supports `--dry-run`: print the commands that would run, change nothing (S, `run`).

**Results and picking (S).** `step` titles a phase; `pass`/`fail`/`warn`/`skip` record each outcome and `finish` prints the summary and exits `1` when any `fail` was recorded. A step that can fail is wrapped in `if cmd; then pass …; else fail …; fi` so it is counted, not aborted. `multiselect` takes a title and items: the operator types `1 3 5-7` to toggle, `a` all, `n` none, Enter to confirm (case-insensitive, out-of-range numbers ignored). Confirmed picks come back on stdout, one number per line; nothing picked, or end of input, returns `1` and the caller decides. An action that needs picks also accepts them as a flag (`--pick 1,3`) so it runs unattended.

**Bash version.** The skeleton runs on any bash 4 or newer and uses no nameref. A nameref (`local -n`) needs bash 4.3; if you add one, say so in the script's header.

**Shape.**

- No cap on file length; functions stay short and do one thing; indentation stays within 3 levels.
- Wrap the main flow in `main` and guard its call with the test seam (S): `<script-name>_LIB=1` (rename the skeleton's `SKELETON_LIB` in all three places), compared strictly against `"1"`. Tests source the script under that variable and call functions directly.
- Sourcing without the seam is refused (S), because `exit` and `set -e` would leak into the operator's shell.
- Comments follow the target project's comment language.

**Editing an existing script.** When it breaks these rules, ask the user whether to overhaul the whole script before touching it. Fix only what was asked until they answer.

## Verifying what you wrote

Done when each step below has run, or was skipped with a stated reason:

1. `bash -n <script>` passes.
2. `shellcheck <script>` shows zero findings on default rules. When it is not installed, skip it and say so; installing it is the user's call.
3. Exercise it through `--dry-run` and the `<script-name>_LIB=1` seam. Running a changing subcommand for real is the user's call, not part of verification.
4. `--help </dev/null` exits `0`; no arguments with `</dev/null` exits `2`; an unknown option and an unknown subcommand exit `2`.
