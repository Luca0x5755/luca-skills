---
name: ops-script
description: 寫或改留在 repo 裡、反覆執行的運維腳本（bash 或 PowerShell）時的規則與骨架。當要新增部署、備份、還原、檢查類腳本（含留在 repo 可重跑的安裝器、連結器，如 manage.sh），要讓腳本同時有互動選單與子命令，要讓排程或 CI 呼叫腳本，或要修改既有運維腳本時使用。只跑一次就丟的引導流程不用它，那是 /wizard。
---

# Ops Script

An **ops script** stays in the repo and gets run again and again by an operator to change or check system state. One script, two ways in: no arguments on a terminal opens a menu; a subcommand runs directly, so a scheduler, CI or another script can call it.

Not this skill: a script run once and thrown away, walking a human through a manual procedure — that is `/wizard`.

Start from [skeleton.sh](skeleton.sh): copy it, rename it, replace the `hello` demo. The block between `# ---- BEGIN ops-lib v7 ----` and `# ---- END ops-lib ----` is **one verbatim unit**, never hand-edited. Where it lives follows whether the script must run alone:

- **Must run alone** (single-file download, `scp`, a USB stick): the block sits inline in the script.
- **Already needs repo files** (compose files, `.env`, migrations, the repo it links): the block may live as `scripts/lib/ops-lib.sh`, holding the block and nothing else, and each script sources it. Project-specific helpers go in a separate file. Check the file exists before sourcing and say what is missing.

To change the block, change the skeleton, bump the version, and sync every copy; two copies in one project carrying two different version numbers means one was missed (`grep -rn "BEGIN ops-lib"` shows them all). Edit the skeleton only; a fix made inside one copy is lost at the next sync.

**PowerShell script?** Read [POWERSHELL.md](POWERSHELL.md) too: same structure from [skeleton.ps1](skeleton.ps1), plus the encoding (UTF-8 with BOM), 5.1-and-7, confirmation and `-WhatIf` rules that exist only there. The rules below are written in bash terms; the function map in that file translates them.

## Rules

Hold every rule below; the skeleton already embodies the ones marked (S).

**Strict mode is a safety net.** Keep `set -euo pipefail` (S), and catch every failure that matters yourself — check, then `die` with a message. Traps the skeleton steers around:

- `read` at end of input returns non-zero: write `read -r x || …` and decide what EOF means (S, `confirm` treats it as No).
- `grep -q` closes the pipe early; under `pipefail` the upstream command dies of SIGPIPE and the pipeline reports failure. Use `grep -c` or capture first.
- `-u` with an empty array: expand it as `${arr[@]+"${arr[@]}"}` (S, `print_summary`); a plain `"${arr[@]}"` aborts on older bash.
- `local x=$(cmd)` swallows `cmd`'s failure, because `local` returns 0. Declare, then assign on the next line.
- `set -e` is ignored inside `if`/`||` conditions, so a function on the left of `||` never aborts midway; `((n++))` returns 1 when `n` is 0 — count with `n=$((n + 1))` (S).
- A membership test built by joining with spaces, `case " $list " in *" $x "*)`, passes `x="a b"` as one valid item; a later check that compares the whole string then sees a different value and skips its guard. Match a value from a fixed list with `pick_by_name` (S), which compares each name whole.

**Messages and diagnostics.**

- Diagnostics go to stderr; stdout carries only the output a caller would pipe (S).
- An error says what failed first, then how to fix it: `✗ title`, then indented fix lines (S, `die`).
- Colour turns off when stdout is not a terminal, `NO_COLOR` is non-empty, or `TERM=dumb` (S).
- Message language follows the target project's own language.

**Exit codes.** `0` done, `1` failed or the operator cancelled, `2` usage error (S). A cancel that returns `0` tells the calling script the action happened. Check-style subcommands report the check result through the exit code.

**No terminal.** Look at stdin only (S, `require_tty`). Pass `require_tty` the fix that names the missing option (`require_tty "改用 --pick 指定名稱，或在終端機中執行"`); its generic sentence is a fallback, and an operator told only "pass a value" cannot act on it.

- `--help` is never blocked by any check.
- No subcommand and no terminal: print usage, exit `2` (S). A default is never run silently.
- A subcommand missing a value: ask when stdin is a terminal, otherwise exit `2` — never pick for the operator ("restore the latest" included).
- A destructive action needs `-y` when unattended; interactively it goes through `confirm` (S, `[y/N]`, default No).

**Arguments and help.**

- An unknown argument exits `2` (S).
- `--help` prints only the `#/` lines at the top of the file (S). It is for the operator; notes for whoever edits the script go in plain `#` comments. It ends with the exit codes (S).
- Help syntax: `[ ]` marks optional, `...` (ASCII, never `…`) marks repeatable, as in `--pick 名稱[,名稱...]`; placeholders stay in the message language.
- Message words: an option is an argument starting with `-`; an argument is anything on the command line, so a catch-all that also sees positional values says 參數. An unrecognised one is 未知, never 不認得. Operator messages do not say 旗標.
- One table drives the menu, the `--help` list and the dispatch (S): the table is the `#/` subcommand rows, and a row `x-y` dispatches to `cmd_x_y`. Adding a subcommand is one row plus one function.
- A menu row answers two questions only: what the subcommand does, as verb + object, and whether it stops to ask. Flags, caveats and exit-code meaning go to `--help` (S). In bash that is a per-subcommand group in the `#/` header: a `#/ <name>：caveat` line, then one `#/   -flag  meaning` line per flag — every indented line inside a group starts with `-`, because a `#/` line of three spaces and a lowercase word is a table row. In PowerShell it is `.PARAMETER`; a common parameter such as `-WhatIf` has no `.PARAMETER` of its own, so note it under `.PARAMETER Command` as `<name>：…`. Number, name and description fit in 80 columns, a CJK character counting as two. The operator scans the rows to pick one; every extra clause is read on every run.
- A subcommand that goes through `confirm`, or needs `-y` unattended, carries the confirm marker (`[需確認]`, in the project's message language) between its name and its description; a subcommand without a confirmation never carries it. In bash the marker opens the `#/` description; in PowerShell the row gets `Confirm = $true`. When any row has the marker, the menu pads the others to the same width so descriptions line up, and a table with none gets no marker column (S, `CONFIRM_MARK`/`CONFIRM_PAD` — change both together when translating). Pad the `#/` rows by hand too, so `--help` lines up. The marker and the confirmation change together, and the script's tests pin the set of marked subcommands.
- Square brackets belong to fixed vocabulary only — the confirm marker and `multiselect`'s `[x]`. A description carries no brackets of any kind: the kind of risk (deletion, real money) or a qualifier (read-only) goes into the verb phrase ("唯讀檢查連結狀態"), or to `--help`.
- The subcommand menu is one `select_one` over the table rows (S, `run_menu`), titled 要做什麼？. A menu choice prints the equivalent command line before running it (S).
- Every subcommand that changes the system supports `--dry-run`: print the commands that would run, change nothing (S, `run`).

**Results and picking (S).** `step` titles a phase; `pass`/`fail`/`warn`/`skip` record each outcome and `finish` prints the summary and exits `1` when any `fail` was recorded. A step that can fail is wrapped in `if cmd; then pass …; else fail …; fi` so it is counted, not aborted. `multiselect` takes a title and items and draws each row as `N) [x] name` (number first, padded to the width of the item count, so it lines up with the menu's `N) name`): the operator types `1 3 5-7` to toggle, `a` all, `n` none, Enter to confirm (case-insensitive, out-of-range numbers ignored). Confirmed picks come back on stdout, one number per line; nothing picked, or end of input, returns `1` and the caller decides. `select_one` is the single pick: same title and items, rows drawn as `N) name`, the title line ending in （q 取消）. A valid number picks at once and comes back on stdout; Enter, `q` or end of input returns `1`; anything else is reported and asked again. Every choice from a fixed list goes through these functions — a hand-written number prompt outside ops-lib is a second picker that ops-lib fixes never reach. On a terminal: `multiselect` for any number of items, `select_one` for exactly one (never `multiselect` with a count check). Unattended: a flag of item **names** (`--pick alpha,gamma`) passed to `pick_by_name`, or a one-name flag (`--target beta`) passed to `pick_one_by_name`, which exits `2` when given more than one. Both return the same numbers on stdout as their terminal twin, so both paths share the code after them, and exit `2` naming the valid items when any name is unknown. A flag takes names because numbers follow the list's order: add an item and a scheduled `--pick 2` silently points at another one. Item names are what the operator types, so keep them free of commas.

**Bash version.** The skeleton runs on any bash 4 or newer and uses no nameref. A nameref (`local -n`) needs bash 4.3; if you add one, say so in the script's header.

**Shape.**

- No cap on file length; functions stay short and do one thing; indentation stays within 3 levels.
- Wrap the main flow in `main` and guard its call with the test seam (S): `<script-name>_LIB=1` (rename the skeleton's `SKELETON_LIB` in all three places), compared strictly against `"1"`. Tests source the script under that variable and call functions directly.
- Sourcing without the seam is refused (S), because `exit` and `set -e` would leak into the operator's shell.
- Tests live outside the script folder, in `tests/<source-folder>/test-<script>.sh` (`scripts/backup.sh` → `tests/scripts/test-backup.sh`). Mirror the folder name one level only, flat inside; keep the script folder's top level to entry points so a person scanning it finds the right one. A project that already has its own test convention follows it instead.
- Comments follow the target project's comment language.

**Editing an existing script.** When it breaks these rules, ask the user whether to overhaul the whole script before touching it. Fix only what was asked until they answer.

## Verifying what you wrote

Done when each step below has run, or was skipped with a stated reason:

1. `bash -n <script>` passes.
2. `shellcheck <script>` shows zero findings on default rules. When it is not installed but `uv` is, run `uvx --from shellcheck-py shellcheck <script>` (a temporary download, not an install). With neither, skip it and say so; installing it is the user's call.
3. Exercise it through `--dry-run` and the `<script-name>_LIB=1` seam. Running a changing subcommand for real is the user's call, not part of verification.
4. `--help </dev/null` exits `0`; no arguments with `</dev/null` exits `2`; an unknown option and an unknown subcommand exit `2`.
