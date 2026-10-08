$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $PSScriptRoot 'install.ps1'
$pwsh = (Get-Process -Id $PID).Path
$testHome = Join-Path ([System.IO.Path]::GetTempPath()) "luca-skills-install-test-$PID"
$previousHome = $env:HOME
$previousOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Remove-TestDirectory {
  param([string]$Path)

  $resolved = [System.IO.Path]::GetFullPath($Path)
  $testRoot = [System.IO.Path]::GetFullPath($testHome)
  if ($resolved -ne $testRoot -and -not $resolved.StartsWith($testRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw "Refusing to remove a path outside the test directory: $resolved"
  }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}

function Invoke-Installer {
  param(
    [string[]]$Arguments,
    [string]$StandardInput
  )

  $env:HOME = $testHome
  if ($PSBoundParameters.ContainsKey('StandardInput')) {
    $inputFile = Join-Path $testHome 'input.txt'
    $outputFile = Join-Path $testHome 'output.txt'
    Set-Content -LiteralPath $inputFile -Value $StandardInput
    $windowOptions = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{} }
    # Redirected child output must preserve Chinese and Unicode on Windows CI.
    $escapedInstaller = $installer.Replace("'", "''")
    $childCommand = "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(`$false); & '$escapedInstaller'"
    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($childCommand))
    $process = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-EncodedCommand', $encodedCommand) -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -PassThru @windowOptions
    if (-not $process.WaitForExit(15000)) {
      $process.Kill()
      $process.WaitForExit()
      throw 'installer did not finish within 15 seconds'
    }
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = Get-Content -LiteralPath $outputFile }
  }

  $output = & $pwsh -NoProfile -File $installer @Arguments 2>&1
  [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

try {
  New-Item -ItemType Directory -Path $testHome | Out-Null

  Write-Host 'all is rejected'
  $result = Invoke-Installer -Arguments @('-Target', 'all')
  if ($result.ExitCode -eq 0) {
    throw "install.ps1 accepted the removed all target: $($result.Output -join [Environment]::NewLine)"
  }

  Write-Host 'end of input cancels without installation'
  $result = Invoke-Installer -StandardInput ''
  if ($result.ExitCode -eq 0) { throw 'install.ps1 accepted end of input' }
  if (Test-Path (Join-Path $testHome '.agents\skills')) { throw 'end of input installed skills' }

  Write-Host 'end of input after an error cancels without installation'
  $result = Invoke-Installer -StandardInput '1,3'
  if ($result.ExitCode -eq 0) { throw 'install.ps1 accepted end of input after an error' }
  if (Test-Path (Join-Path $testHome '.claude\skills')) { throw 'invalid selection partially installed Claude' }

  if ($IsWindows) {
    Write-Host 'direct Codex target installs only Codex'
    $result = Invoke-Installer -Arguments @('-Target', 'codex')
    $codexSkill = Join-Path $testHome '.agents\skills\ask-luca'
    if ($result.ExitCode -ne 0 -or -not (Test-Path $codexSkill)) {
      throw "direct Codex installation failed: $($result.Output -join [Environment]::NewLine)"
    }
    if (Test-Path (Join-Path $testHome '.claude\skills')) {
      throw 'direct Codex installation unexpectedly installed Claude skills'
    }

    Remove-TestDirectory (Join-Path $testHome '.agents')
    Write-Host 'interactive selection installs only Codex without confirmation'
    $result = Invoke-Installer -StandardInput "3"
    if ($result.ExitCode -ne 0 -or -not (Test-Path $codexSkill)) {
      throw "interactive Codex installation failed: $($result.Output -join [Environment]::NewLine)"
    }
    if (Test-Path (Join-Path $testHome '.claude\skills')) {
      throw 'interactive Codex selection unexpectedly installed Claude skills'
    }
    if ($result.Output -match '確認繼續') { throw 'interactive selection still requested confirmation' }

    Remove-TestDirectory (Join-Path $testHome '.agents')
    Write-Host 'space-separated selection installs each selected agent once'
    $result = Invoke-Installer -StandardInput "  3  1`t3  "
    if ($result.ExitCode -ne 0 -or -not (Test-Path $codexSkill) -or -not (Test-Path (Join-Path $testHome '.claude\skills\ask-luca'))) {
      throw "multi-selection did not install both selected agents: $($result.Output -join [Environment]::NewLine)"
    }
    if (Test-Path (Join-Path $testHome '.copilot\skills')) { throw 'multi-selection installed an unselected agent' }
    if (@($result.Output -match '^→ codex :').Count -ne 1) { throw "Expected one Codex heading; captured output: $($result.Output -join ' | ')" }
    if (-not ($result.Output -match '即將安裝：codex, claude$')) { throw 'selection summary does not match the selected agents' }
    foreach ($menuLine in @('  1. claude', '  2. copilot', '  3. codex')) {
      if ($result.Output -notcontains $menuLine) { throw "menu is missing: $menuLine" }
    }
    Remove-TestDirectory (Join-Path $testHome '.agents')
    Remove-TestDirectory (Join-Path $testHome '.claude')

    Write-Host 'invalid selections retry without installing partially selected agents'
    $result = Invoke-Installer -StandardInput "`n   `n1,3`n0`n4`n-1`n1 x`n13`n999999999999999999999999999999`n2"
    if ($result.ExitCode -ne 0 -or -not (Test-Path (Join-Path $testHome '.copilot\skills\ask-luca'))) {
      throw "valid selection after errors did not install Copilot: $($result.Output -join [Environment]::NewLine)"
    }
    if (@($result.Output -match '請輸入一個或多個有效編號').Count -ne 9) { throw 'invalid selections were not all retried' }
    if ((Test-Path (Join-Path $testHome '.claude\skills')) -or (Test-Path (Join-Path $testHome '.agents\skills'))) {
      throw 'invalid selection partially installed agents'
    }
    Remove-TestDirectory (Join-Path $testHome '.copilot')

    $foreignSkill = Join-Path $testHome '.agents\skills\ask-luca'
    New-Item -ItemType Directory -Path $foreignSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $foreignSkill 'sentinel.txt') -Value 'keep me'

    Write-Host 'foreign same-name skill is preserved'
    $result = Invoke-Installer -Arguments @('-Target', 'codex')
    if ($result.ExitCode -eq 0) { throw 'install.ps1 overwrote a foreign skill' }
    if (-not (Test-Path (Join-Path $foreignSkill 'sentinel.txt'))) { throw 'foreign skill was modified' }
    if (Test-Path (Join-Path $testHome '.agents\skills\tdd')) { throw 'agent was partially installed after a collision' }

    Write-Host 'a collision does not block another selected agent'
    $result = Invoke-Installer -StandardInput "1 3"
    if ($result.ExitCode -eq 0) { throw 'multi-agent installation reported success despite a collision' }
    if (-not (Test-Path (Join-Path $testHome '.claude\skills\ask-luca'))) { throw 'collision blocked the independent Claude installation' }
  }
}
finally {
  [Console]::OutputEncoding = $previousOutputEncoding
  $env:HOME = $previousHome
  Remove-TestDirectory $testHome
}
