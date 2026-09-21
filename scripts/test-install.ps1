$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $PSScriptRoot 'install.ps1'
$pwsh = (Get-Process -Id $PID).Path
$testHome = Join-Path ([System.IO.Path]::GetTempPath()) "luca-skills-install-test-$PID"
$previousHome = $env:HOME

function Invoke-Installer {
  param(
    [string[]]$Arguments,
    [string]$StandardInput
  )

  $env:HOME = $testHome
  if ($StandardInput) {
    $inputFile = Join-Path $testHome 'input.txt'
    $outputFile = Join-Path $testHome 'output.txt'
    Set-Content -LiteralPath $inputFile -Value $StandardInput
    $process = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-File', $installer) -RedirectStandardInput $inputFile -RedirectStandardOutput $outputFile -Wait -PassThru
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

    Remove-Item -LiteralPath (Join-Path $testHome '.agents') -Recurse -Force
    Write-Host 'interactive selection installs only Codex'
    $result = Invoke-Installer -StandardInput "3`ny"
    if ($result.ExitCode -ne 0 -or -not (Test-Path $codexSkill)) {
      throw "interactive Codex installation failed: $($result.Output -join [Environment]::NewLine)"
    }
    if (Test-Path (Join-Path $testHome '.claude\skills')) {
      throw 'interactive Codex selection unexpectedly installed Claude skills'
    }

    Remove-Item -LiteralPath (Join-Path $testHome '.agents') -Recurse -Force
    $foreignSkill = Join-Path $testHome '.agents\skills\ask-luca'
    New-Item -ItemType Directory -Path $foreignSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $foreignSkill 'sentinel.txt') -Value 'keep me'

    Write-Host 'foreign same-name skill is preserved'
    $result = Invoke-Installer -Arguments @('-Target', 'codex')
    if ($result.ExitCode -eq 0) { throw 'install.ps1 overwrote a foreign skill' }
    if (-not (Test-Path (Join-Path $foreignSkill 'sentinel.txt'))) { throw 'foreign skill was modified' }
    if (Test-Path (Join-Path $testHome '.agents\skills\tdd')) { throw 'agent was partially installed after a collision' }

    Write-Host 'a collision does not block another selected agent'
    $result = Invoke-Installer -StandardInput "1,3`ny"
    if ($result.ExitCode -eq 0) { throw 'multi-agent installation reported success despite a collision' }
    if (-not (Test-Path (Join-Path $testHome '.claude\skills\ask-luca'))) { throw 'collision blocked the independent Claude installation' }
  }
}
finally {
  $env:HOME = $previousHome
  if (Test-Path $testHome) { Remove-Item -LiteralPath $testHome -Recurse -Force }
}
