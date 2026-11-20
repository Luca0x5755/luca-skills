$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$manage = Join-Path $PSScriptRoot 'manage.ps1'
# 預設用跑測試的 pwsh 當子行程；MANAGE_TEST_SHELL=powershell.exe 可改驗 Windows PowerShell 5.1
$pwsh = if ($env:MANAGE_TEST_SHELL) { $env:MANAGE_TEST_SHELL } else { (Get-Process -Id $PID).Path }
$testHome = Join-Path ([System.IO.Path]::GetTempPath()) "luca-skills-manage-test-$PID"
$previousHome = $env:HOME
$previousNoColor = $env:NO_COLOR
$previousOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$env:NO_COLOR = '1'

function Remove-TestDirectory {
  param([string]$Path)

  $resolved = [System.IO.Path]::GetFullPath($Path)
  $testRoot = [System.IO.Path]::GetFullPath($testHome)
  if ($resolved -ne $testRoot -and -not $resolved.StartsWith($testRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw "Refusing to remove a path outside the test directory: $resolved"
  }
  if (-not (Test-Path -LiteralPath $resolved)) { return }
  # 先拆掉 Junction 本身，避免 Remove-Item -Recurse 在 5.1 跟進去刪到 repo 的檔案
  Get-ChildItem -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LinkType } | ForEach-Object { [System.IO.Directory]::Delete($_.FullName) }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}

function Assert-That {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

# 在子行程跑 manage.ps1：stdin 一律重導（不是終端機），輸出以 UTF-8 收回。
# -Tty 時改為 dot-source 後覆寫終端機探針、呼叫 Invoke-Main，用來測互動入口。
function Invoke-Manage {
  param([string[]]$Arguments = @(), [string]$StandardInput = '', [switch]$Tty)

  $env:HOME = $testHome
  $inputFile = Join-Path $testHome 'input.txt'
  $outputFile = Join-Path $testHome 'output.txt'
  Set-Content -LiteralPath $inputFile -Value $StandardInput -NoNewline
  $quotedPath = $manage.Replace("'", "''")
  # 帶引號的 -WhatIf 會變成字串而不是參數，所以旗標要原樣放行，其餘才加引號
  $quotedArgs = ($Arguments | ForEach-Object {
      if ($_ -match '^-[A-Za-z]+$') { $_ } else { "'" + $_.Replace("'", "''") + "'" }
    }) -join ' '
  $body = if ($Tty) {
    "`$env:MANAGE_LIB = '1'; . '$quotedPath'; function Test-OpsTty { param([string]`$Stream = 'In') `$true }; Invoke-Main"
  } else {
    # 參數繫結失敗（如 ValidateSet 擋下）不會設 $LASTEXITCODE，要靠例外轉成結束碼 1
    "`$ErrorActionPreference = 'Stop'; try { & '$quotedPath' $quotedArgs; exit `$LASTEXITCODE } catch { exit 1 }"
  }
  $childCommand = "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(`$false); $body"
  $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($childCommand))
  $windowOptions = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{} }
  $process = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded) `
    -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -PassThru @windowOptions
  if (-not $process.WaitForExit(30000)) {
    $process.Kill()
    $process.WaitForExit()
    throw 'manage.ps1 did not finish within 30 seconds'
  }
  [pscustomobject]@{ ExitCode = $process.ExitCode; Output = @(Get-Content -LiteralPath $outputFile) }
}

function Get-SkillPath {
  param([string]$Agent, [string]$Name = 'ask-luca')
  $dir = switch ($Agent) { 'claude' { '.claude\skills' } 'copilot' { '.copilot\skills' } 'codex' { '.agents\skills' } }
  Join-Path $testHome (Join-Path $dir $Name)
}

function Test-Linked {
  param([string]$Agent, [string]$Name = 'ask-luca')
  $item = Get-Item -LiteralPath (Get-SkillPath $Agent $Name) -Force -ErrorAction SilentlyContinue
  [bool]($item -and $item.LinkType)
}

function Remove-SkillLinkForTest {
  param([string]$Path)
  [System.IO.Directory]::Delete($Path)
}

function Reset-Home {
  if (Test-Path -LiteralPath $testHome) {
    foreach ($d in '.claude', '.copilot', '.agents') { Remove-TestDirectory (Join-Path $testHome $d) }
  }
}

try {
  New-Item -ItemType Directory -Path $testHome | Out-Null

  Write-Host 'an unknown subcommand or the removed all target is rejected'
  $result = Invoke-Manage -Arguments @('all')
  Assert-That ($result.ExitCode -ne 0) 'manage.ps1 accepted the removed all target'

  if ($IsWindows) {
    Write-Host 'install codex links only Codex'
    $result = Invoke-Manage -Arguments @('install', 'codex')
    Assert-That ($result.ExitCode -eq 0) "install codex failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (Test-Linked 'codex') 'install codex did not link ask-luca'
    Assert-That (-not (Test-Path (Join-Path $testHome '.claude\skills'))) 'install codex touched Claude'
    Assert-That (-not (Test-Path (Join-Path $testHome '.copilot\skills'))) 'install codex touched Copilot'

    Write-Host 'a bare agent name is an alias of install'
    Reset-Home
    $result = Invoke-Manage -Arguments @('claude')
    Assert-That ($result.ExitCode -eq 0 -and (Test-Linked 'claude')) "bare agent alias failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (-not (Test-Path (Join-Path $testHome '.agents\skills'))) 'bare agent alias touched another agent'

    Write-Host 'foreign same-name skill is preserved'
    Reset-Home
    $foreignSkill = Get-SkillPath 'codex'
    New-Item -ItemType Directory -Path $foreignSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $foreignSkill 'sentinel.txt') -Value 'keep me'
    $result = Invoke-Manage -Arguments @('install', 'codex')
    Assert-That ($result.ExitCode -ne 0) 'install overwrote a foreign skill'
    Assert-That (Test-Path (Join-Path $foreignSkill 'sentinel.txt')) 'foreign skill was modified'
    Assert-That (-not (Test-Path (Get-SkillPath 'codex' 'tdd'))) 'agent was partially installed after a collision'

    Write-Host 'a collision does not block another selected agent'
    $result = Invoke-Manage -Arguments @('install', 'codex', 'claude')
    Assert-That ($result.ExitCode -ne 0) 'multi-agent install reported success despite a collision'
    Assert-That (Test-Linked 'claude') 'collision blocked the independent Claude installation'
    Assert-That (Test-Path (Join-Path $foreignSkill 'sentinel.txt')) 'foreign skill was modified by the multi-agent run'

    Write-Host 'duplicate agent names install once'
    Reset-Home
    $result = Invoke-Manage -Arguments @('install', 'codex', 'codex')
    Assert-That ($result.ExitCode -eq 0) 'duplicate agent names failed'
    Assert-That (@($result.Output -match '^== codex').Count -eq 1) "duplicate agent installed twice: $($result.Output -join ' | ')"

    Write-Host 'a dangling link left by graduation is replaced'
    Reset-Home
    $staleLink = Get-SkillPath 'codex'
    New-Item -ItemType Directory -Path (Split-Path -Parent $staleLink) -Force | Out-Null
    # New-Item 拒絕指向不存在目標的 junction；mklink 才建得出畢業後的斷鏈
    cmd /c mklink /J "$staleLink" "$(Join-Path $repo 'skills\draft\ask-luca')" | Out-Null
    Assert-That ($LASTEXITCODE -eq 0) 'could not create the dangling junction fixture'
    $result = Invoke-Manage -Arguments @('install', 'codex')
    Assert-That ($result.ExitCode -eq 0) "install refused its own dangling link: $($result.Output -join [Environment]::NewLine)"
    Assert-That (Test-Path (Join-Path $staleLink 'SKILL.md')) 'dangling link was not repointed to core'
  }

  if ($IsWindows) {
    Write-Host 'install -WhatIf prints the commands and changes nothing'
    Reset-Home
    $result = Invoke-Manage -Arguments @('install', 'codex', '-WhatIf')
    Assert-That ($result.ExitCode -eq 0) "install -WhatIf failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (@($result.Output -match '^\+ link').Count -gt 0) 'install -WhatIf did not print the commands it would run'
    Assert-That (-not (Test-Path (Join-Path $testHome '.agents'))) 'install -WhatIf changed the filesystem'

    Write-Host 'uninstall removes only this repo links and keeps the rest'
    Reset-Home
    $null = Invoke-Manage -Arguments @('install', 'codex', 'claude')
    $own = Join-Path $testHome '.agents\skills\my-own-skill'
    New-Item -ItemType Directory -Path $own -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $own 'sentinel.txt') -Value 'keep me'
    # 指向已封存技能的斷鏈：目標在 core/ 底下但已不存在，仍是本 repo 建的
    cmd /c mklink /J "$(Get-SkillPath 'codex' 'ghost-skill')" "$(Join-Path $repo 'skills\core\ghost-skill')" | Out-Null
    $result = Invoke-Manage -Arguments @('uninstall', 'codex', '-Yes')
    Assert-That ($result.ExitCode -eq 0) "uninstall failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (-not (Test-Linked 'codex')) 'uninstall left a repo link behind'
    Assert-That (-not (Test-Path -LiteralPath (Get-SkillPath 'codex' 'ghost-skill'))) 'uninstall left the dangling link behind'
    Assert-That (Test-Path (Join-Path $own 'sentinel.txt')) 'uninstall deleted a skill the repo did not create'
    Assert-That (Test-Path (Join-Path $testHome '.agents\skills')) 'uninstall removed the skills directory itself'
    Assert-That (Test-Linked 'claude') 'uninstall codex touched Claude'
    Assert-That (Test-Path (Join-Path $repo 'skills\core\ask-luca\SKILL.md')) 'uninstall deleted files inside the repo'

    Write-Host 'uninstall skips a foreign same-name skill'
    $foreign = Get-SkillPath 'claude'
    Remove-SkillLinkForTest $foreign
    New-Item -ItemType Directory -Path $foreign | Out-Null
    Set-Content -LiteralPath (Join-Path $foreign 'sentinel.txt') -Value 'keep me'
    $result = Invoke-Manage -Arguments @('uninstall', 'claude', '-Yes')
    Assert-That ($result.ExitCode -eq 0) "uninstall failed on a foreign skill: $($result.Output -join [Environment]::NewLine)"
    Assert-That (Test-Path (Join-Path $foreign 'sentinel.txt')) 'uninstall deleted a foreign same-name skill'
    Assert-That (-not (Test-Linked 'claude' 'tdd')) 'uninstall left other repo links behind'

    Write-Host 'uninstall without a terminal needs -Yes'
    Reset-Home
    $null = Invoke-Manage -Arguments @('install', 'codex')
    $result = Invoke-Manage -Arguments @('uninstall', 'codex')
    Assert-That ($result.ExitCode -eq 2) "unattended uninstall without -Yes should exit 2, got $($result.ExitCode)"
    Assert-That (Test-Linked 'codex') 'unattended uninstall without -Yes removed links'

    Write-Host 'uninstall -WhatIf changes nothing'
    $result = Invoke-Manage -Arguments @('uninstall', 'codex', '-WhatIf')
    Assert-That ($result.ExitCode -eq 0 -and (Test-Linked 'codex')) 'uninstall -WhatIf changed the filesystem'

    Write-Host 'uninstall on an agent that was never installed succeeds quietly'
    $result = Invoke-Manage -Arguments @('uninstall', 'copilot', '-Yes')
    Assert-That ($result.ExitCode -eq 0) 'uninstall of an absent agent failed'
    Assert-That (-not (Test-Path (Join-Path $testHome '.copilot'))) 'uninstall of an absent agent created a directory'
  }

  if ($IsWindows) {
    Write-Host 'status reports a missing install with exit 1 and changes nothing'
    Reset-Home
    $result = Invoke-Manage -Arguments @('status', 'codex')
    Assert-That ($result.ExitCode -eq 1) "status of an empty agent should exit 1, got $($result.ExitCode)"
    Assert-That (-not (Test-Path (Join-Path $testHome '.agents'))) 'status created a directory'

    Write-Host 'status of a complete install exits 0'
    $null = Invoke-Manage -Arguments @('install', 'codex')
    $result = Invoke-Manage -Arguments @('status', 'codex')
    Assert-That ($result.ExitCode -eq 0) "status of a complete install should exit 0: $($result.Output -join [Environment]::NewLine)"

    Write-Host 'status names the broken, stale and conflicting entries'
    $ask = Get-SkillPath 'codex' 'ask-luca'
    Remove-SkillLinkForTest $ask
    cmd /c mklink /J "$ask" "$(Join-Path $repo 'skills\draft\ask-luca')" | Out-Null
    cmd /c mklink /J "$(Get-SkillPath 'codex' 'ghost-skill')" "$(Join-Path $repo 'skills\core\ghost-skill')" | Out-Null
    $tdd = Get-SkillPath 'codex' 'tdd'
    Remove-SkillLinkForTest $tdd
    New-Item -ItemType Directory -Path $tdd | Out-Null
    $before = @(Get-ChildItem -LiteralPath (Split-Path -Parent $ask) -Force).Count
    $result = Invoke-Manage -Arguments @('status', 'codex')
    Assert-That ($result.ExitCode -eq 1) 'status of a damaged install should exit 1'
    foreach ($word in 'ask-luca', 'ghost-skill', 'tdd') {
      Assert-That (@($result.Output -match $word).Count -gt 0) "status did not mention $word : $($result.Output -join ' | ')"
    }
    $after = @(Get-ChildItem -LiteralPath (Split-Path -Parent $ask) -Force).Count
    Assert-That ($before -eq $after) 'status changed the skills directory'
  }

  if ($IsWindows) {
    Write-Host 'install prunes stale repo links but leaves everything else'
    Reset-Home
    $skillsDir = Join-Path $testHome '.agents\skills'
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    $ghost = Get-SkillPath 'codex' 'ghost-skill'
    cmd /c mklink /J "$ghost" "$(Join-Path $repo 'skills\core\ghost-skill')" | Out-Null
    # 指向 repo 之外的連結不是本 repo 建的，不能動
    $outside = Join-Path $testHome 'outside-target'
    New-Item -ItemType Directory -Path $outside | Out-Null
    cmd /c mklink /J "$(Join-Path $skillsDir 'outside-link')" "$outside" | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $skillsDir 'my-own-skill') | Out-Null

    $result = Invoke-Manage -Arguments @('install', 'codex', '-WhatIf')
    Assert-That ($result.ExitCode -eq 0 -and (Test-Path -LiteralPath $ghost)) 'install -WhatIf pruned a stale link'

    $result = Invoke-Manage -Arguments @('install', 'codex')
    Assert-That ($result.ExitCode -eq 0) "install with a stale link failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (-not (Test-Path -LiteralPath $ghost)) 'install left the stale link behind'
    Assert-That (Test-Path -LiteralPath (Join-Path $skillsDir 'outside-link')) 'install pruned a link the repo did not create'
    Assert-That (Test-Path -LiteralPath (Join-Path $skillsDir 'my-own-skill')) 'install pruned a plain directory'
    Assert-That (Test-Linked 'codex') 'install did not link the skills'
    $result = Invoke-Manage -Arguments @('status', 'codex')
    Assert-That ($result.ExitCode -eq 0) 'status is not clean right after install'
  }

  Write-Host 'exit codes: help 0, usage errors 2, no subcommand without a terminal 2'
  $result = Invoke-Manage -Arguments @('-Help')
  Assert-That ($result.ExitCode -eq 0) '-Help did not exit 0'
  $result = Invoke-Manage
  Assert-That ($result.ExitCode -eq 2) "no arguments without a terminal should exit 2, got $($result.ExitCode)"
  $result = Invoke-Manage -Arguments @('install')
  Assert-That ($result.ExitCode -eq 2) "install without an agent and without a terminal should exit 2, got $($result.ExitCode)"
  $result = Invoke-Manage -Arguments @('install', 'nope')
  Assert-That ($result.ExitCode -eq 2) "an unknown agent should exit 2, got $($result.ExitCode)"
  $result = Invoke-Manage -Arguments @('bogus')
  Assert-That ($result.ExitCode -ne 0) 'an unknown subcommand was accepted'

  Write-Host 'end of input cancels the menu and the agent prompt'
  Reset-Home
  $result = Invoke-Manage -Tty -StandardInput ''
  Assert-That ($result.ExitCode -eq 1) 'end of input at the menu should exit 1'
  $result = Invoke-Manage -Tty -StandardInput '1'
  Assert-That ($result.ExitCode -eq 1) 'end of input at the agent prompt should exit 1'
  $result = Invoke-Manage -Tty -StandardInput "1`n1,3"
  Assert-That ($result.ExitCode -eq 1) 'end of input after an error should exit 1'
  Assert-That (-not (Test-Path (Join-Path $testHome '.claude\skills'))) 'a cancelled selection installed skills'

  if ($IsWindows) {
    Write-Host 'the menu picks the action first, then installs only the chosen agent without confirmation'
    Reset-Home
    $result = Invoke-Manage -Tty -StandardInput "1`n3"
    Assert-That ($result.ExitCode -eq 0 -and (Test-Linked 'codex')) "menu install failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (-not (Test-Path (Join-Path $testHome '.claude\skills'))) 'menu selection installed an unselected agent'
    Assert-That (-not ($result.Output -match '確認繼續')) 'install still asked for confirmation'
    Assert-That (@($result.Output -match '^-> manage\.ps1 install codex$').Count -eq 1) "the menu did not print the equivalent command: $($result.Output -join ' | ')"
    foreach ($line in '  1) install', '  2) uninstall', '  3) status') {
      Assert-That (@($result.Output | Where-Object { $_ -like "$line*" }).Count -eq 1) "menu is missing: $line"
    }

    Write-Host 'space-separated selection installs each selected agent once, in the order given'
    Reset-Home
    $result = Invoke-Manage -Tty -StandardInput "1`n  3  1`t3  "
    Assert-That ($result.ExitCode -eq 0 -and (Test-Linked 'codex') -and (Test-Linked 'claude')) 'multi-selection did not install both agents'
    Assert-That (-not (Test-Path (Join-Path $testHome '.copilot\skills'))) 'multi-selection installed an unselected agent'
    Assert-That (@($result.Output -match '^== codex').Count -eq 1) 'duplicate selection installed Codex more than once'
    Assert-That (@($result.Output -match '即將安裝：codex, claude$').Count -eq 1) 'selection summary does not match'
    foreach ($line in '  1. claude', '  2. copilot', '  3. codex') {
      Assert-That ($result.Output -contains $line) "agent prompt is missing: $line"
    }

    Write-Host 'invalid selections retry without installing partially selected agents'
    Reset-Home
    $result = Invoke-Manage -Tty -StandardInput "1`n`n   `n1,3`n0`n4`n-1`n1 x`n13`n999999999999999999999999999999`n2"
    Assert-That ($result.ExitCode -eq 0 -and (Test-Linked 'copilot')) "valid selection after errors failed: $($result.Output -join [Environment]::NewLine)"
    Assert-That (@($result.Output -match '請輸入一個或多個有效編號').Count -eq 9) 'invalid selections were not all retried'
    Assert-That (-not (Test-Path (Join-Path $testHome '.claude\skills')) -and -not (Test-Path (Join-Path $testHome '.agents\skills'))) 'invalid selection partially installed agents'

    Write-Host 'uninstall from the menu asks once, default No'
    $result = Invoke-Manage -Tty -StandardInput "2`n2`n"
    Assert-That ($result.ExitCode -eq 1 -and (Test-Linked 'copilot')) 'an empty answer should cancel the uninstall and keep the links'
    $result = Invoke-Manage -Tty -StandardInput "2`n2`nn"
    Assert-That ($result.ExitCode -eq 1 -and (Test-Linked 'copilot')) 'answering n should cancel the uninstall'
    $result = Invoke-Manage -Tty -StandardInput "2`n2`ny"
    Assert-That ($result.ExitCode -eq 0 -and -not (Test-Linked 'copilot')) "answering y should uninstall: $($result.Output -join [Environment]::NewLine)"

    Write-Host 'status from the menu reads only'
    $result = Invoke-Manage -Tty -StandardInput "3`n2"
    Assert-That ($result.ExitCode -eq 1) 'status of an uninstalled agent should exit 1'
  }

  Write-Host 'ops-lib is copied verbatim from the skeleton'
  function Get-OpsLib {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path).TrimStart([char]0xFEFF) -replace "`r`n", "`n"
    $m = [regex]::Match($text, '(?ms)^# ---- BEGIN ops-lib.*?^# ---- END ops-lib[^
]*')
    Assert-That $m.Success "找不到 ops-lib 區段：$Path"
    $m.Value
  }
  $skeletonPs1 = Join-Path $repo 'skills\draft\ops-script\skeleton.ps1'
  Assert-That ((Get-OpsLib $manage) -ceq (Get-OpsLib $skeletonPs1)) 'manage.ps1 的 ops-lib 區段與骨架不一致'

  Write-Host 'ValidateSet equals the subcommand table plus the agent names'
  $manageText = [System.IO.File]::ReadAllText($manage) -replace "`r`n", "`n"
  $setMatch = [regex]::Match($manageText, '\[ValidateSet\(([^)]*)\)\]\s*\[string\]\s*\$Command')
  Assert-That $setMatch.Success '找不到 $Command 的 ValidateSet'
  $setValues = @([regex]::Matches($setMatch.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
  $tableBlock = [regex]::Match($manageText, '(?ms)^\$SubCommands = \[ordered\]@\{.*?^\}').Value
  $tableKeys = @([regex]::Matches($tableBlock, '(?m)^\s{4}(\w+)\s+= @\{') | ForEach-Object { $_.Groups[1].Value })
  $expected = @($tableKeys) + @('claude', 'copilot', 'codex')
  Assert-That (($setValues -join ',') -ceq ($expected -join ',')) "ValidateSet [$($setValues -join ',')] 與子命令表 [$($expected -join ',')] 不一致"

  Write-Host 'PSScriptAnalyzer reports nothing (skipped when not installed)'
  # ops-lib 區段是骨架逐字複製的，骨架自己有 3 類警告（PSUseShouldProcess…、PSUseSingularNouns、
  # PSShouldProcess），要修得改骨架、升版號再同步，不在這支腳本裡動；故只掃區段以外的行。
  # 另排除兩條對本腳本是誤報的規則：參數經腳本範圍的 $Command／$Yes／$Help 讀取（PSReviewUnusedParameter）；
  # 移除類函式的呼叫端已在 ShouldProcess 之內（PSUseShouldProcessForStateChangingFunctions）。
  if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    $lines = [System.IO.File]::ReadAllText($manage) -split "`r?`n"
    $libStart = 1 + [array]::FindIndex($lines, [Predicate[string]]{ param($l) $l -like '# ---- BEGIN ops-lib*' })
    $libEnd = 1 + [array]::FindIndex($lines, [Predicate[string]]{ param($l) $l -like '# ---- END ops-lib*' })
    $findings = @(Invoke-ScriptAnalyzer -Path $manage -Severity Warning, Error `
        -ExcludeRule PSReviewUnusedParameter, PSUseShouldProcessForStateChangingFunctions |
        Where-Object { $_.Line -lt $libStart -or $_.Line -gt $libEnd })
    Assert-That ($findings.Count -eq 0) "PSScriptAnalyzer：$(($findings | ForEach-Object { "$($_.RuleName):$($_.Line)" }) -join ' ')"
  } else {
    Write-Host '  - PSScriptAnalyzer 未安裝，略過'
  }

  # <<SLICE>>
}
finally {
  [Console]::OutputEncoding = $previousOutputEncoding
  $env:HOME = $previousHome
  $env:NO_COLOR = $previousNoColor
  Remove-TestDirectory $testHome
}
