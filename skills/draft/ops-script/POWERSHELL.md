# Ops Script in PowerShell

The PowerShell half of `/ops-script`. The bash rules in [SKILL.md](SKILL.md) hold here too (one script two ways in, exit codes, `--dry-run` as `-WhatIf`, ops-lib copied verbatim); this file carries only what differs.

Start from [skeleton.ps1](skeleton.ps1). The block between `# ---- BEGIN ops-lib v3 ----` and `# ---- END ops-lib ----` is copied verbatim, same sync rule and same version number as the bash block. The test seam is `SKELETON_LIB=1` (rename it per script), compared strictly against `"1"`; dot-sourcing without it is refused.

## Rules

**Encoding: UTF-8 with BOM, always.** Windows PowerShell 5.1 reads a BOM-less file in the machine's ANSI code page, so a script holding any non-ASCII character fails to parse on a Traditional or Simplified Chinese machine while passing on a UTF-8 developer box. Most file-writing tools emit no BOM: after writing, check the first three bytes are `EF BB BF` (`head -c3 file | od -An -tx1`).

**Runs on both Windows PowerShell 5.1 (`powershell.exe`) and PowerShell 7 (`pwsh`).** Stay inside the 5.1 language: no ternary, no `??`, no `&&`/`||` between pipelines, no `$PSStyle`. Verify on both — the parser (`[System.Management.Automation.Language.Parser]::ParseFile`), `-WhatIf`, and the no-terminal exit code.

**Confirmation is hand-written, default No.** The built-in `-Confirm` prompt and `ShouldContinue` run on Enter; a destructive action must not. `Confirm-Ops` answers `$true` only for `y`/`yes`, and end of input is No. `SupportsShouldProcess` exists only to provide `-WhatIf`: `Invoke-OpsRun` prints the command, then asks `$PSCmdlet.ShouldProcess`. It also exposes `-Confirm`, which is that built-in prompt and not this project's confirmation path. `Invoke-OpsRun` discards the action's output (the screen shows the `+` line); an action whose output matters returns it through its own variable.

**No terminal: look at stdin only, with `[Console]::IsInputRedirected`.** Never detect it by letting `Read-Host` fail — 5.1 and 7 fail differently. Read input with `[Console]::In.ReadLine()`; `$null` means end of input. No subcommand and no terminal: usage, exit `2`.

**Errors: `$ErrorActionPreference = 'Stop'` is a net, external programs need their own check.** It does not cover native commands, so check `$LASTEXITCODE` after each one (`Invoke-OpsRun` zeroes it before the action and throws when it is non-zero). Cmdlets that report failure by returning nothing need a check of their result: `New-Item -Force` silently does nothing when the parent path is a file, so the skeleton verifies the directory exists afterwards.

**Two channels: data in the pipeline, screen on the host.** A function's return value is data (`Select-OpsMulti` emits the picked numbers); menus, prompts, steps and results go through `Write-Host`. `Write-Host` is allowed here because it is the operator interface — PSScriptAnalyzer's `PSAvoidUsingWriteHost` aims at code that should return data but prints it. Suppress the rule once, at the top of the script, with a stated reason:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'operator interface; data goes through the pipeline')]
```

Colour uses `-ForegroundColor`, never ANSI escapes (5.1's console may not render them), and follows the same off-switches as bash: output redirected, `NO_COLOR` non-empty, `TERM=dumb`.

**Exit codes match bash (`0` done, `1` failed or cancelled, `2` usage), with one gap.** An unknown subcommand is rejected by the `ValidateSet` binder before the script runs, so under `-File` it exits `1`, not `2`. Keep `ValidateSet` (it gives tab completion and `Get-Help` the list) and keep the `$SubCommands` table equal to it — a test compares them. Every usage error the script detects itself exits `2`.

**Help is comment-based.** `Get-Help ./script.ps1` reads the header block; `-Help` prints it. Keep `.SYNOPSIS`, `.DESCRIPTION`, one `.PARAMETER` per parameter and an `.EXAMPLE`.

## Function map

| bash v3 | PowerShell v3 |
| --- | --- |
| `_is_tty` | `Test-OpsTty -Stream In\|Out` |
| `color_init` | `Test-OpsColor` |
| `die`, `die_with` | `Stop-OpsScript -Code -Title -Fix` |
| `confirm` | `Confirm-Ops` |
| `require_tty` | `Assert-OpsTty` |
| `step`, `pass`, `fail`, `warn`, `skip` | `Write-OpsStep`, `Write-OpsPass`, `Write-OpsFail`, `Write-OpsWarn`, `Write-OpsSkip` |
| `print_summary`, `finish` | `Write-OpsSummary`, `Complete-OpsRun` |
| `multiselect` | `Select-OpsMulti` (cancel = no output; test with `@(...).Count`) |
| `pick_by_name` | `Resolve-OpsPick -Flag -Raw -Items` (ordinal, case-sensitive: `[Array]::IndexOf`, never `-eq` or `-contains`) |
| `run` | `Invoke-OpsRun -Display -Action` (throws on failure; the caller records it with `try`/`catch`) |

## Verifying what you wrote

Done when each step has run on both 5.1 and 7, or was skipped with a stated reason:

1. The parser reports zero errors and the first three bytes are `EF BB BF`.
2. PSScriptAnalyzer shows no findings beyond the suppressed `PSAvoidUsingWriteHost`. When the module is not installed, skip it and say so; installing it is the user's call.
3. Exercise it through `-WhatIf` and the `SKELETON_LIB=1` seam. Running a changing subcommand for real is the user's call.
4. `-File script.ps1 </dev/null` with no subcommand exits `2`; `-Help` exits `0`.
