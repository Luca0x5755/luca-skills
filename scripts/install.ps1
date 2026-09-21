# 把 skills/core 與 skills/draft 的技能連進代理的個人技能目錄。
# draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
# 沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。
# archive 不連。
# 用 Junction 而非 SymbolicLink：Windows 上不需管理員權限或開發者模式。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。
#
#   .\scripts\install.ps1            # 互動選擇要安裝的代理
#   .\scripts\install.ps1 copilot    # GitHub Copilot
#   .\scripts\install.ps1 codex      # Codex

param(
  [ValidateSet('claude', 'copilot', 'codex')]
  [string]$Target
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$homeRoot = if ($env:HOME) { $env:HOME } else { $HOME }

# 代理各自的個人技能目錄。Codex 讀 ~/.agents/skills；Copilot 也讀這裡，
# 但 Copilot 改連自己的目錄，避免同一個技能被載入兩次。
$dests = [ordered]@{
  claude  = Join-Path $homeRoot '.claude\skills'
  copilot = Join-Path $homeRoot '.copilot\skills'
  codex   = Join-Path $homeRoot '.agents\skills'
}

$skills = foreach ($bucket in @('core', 'draft')) {
  $dir = Join-Path $repo "skills\$bucket"
  if (Test-Path $dir) {
    Get-ChildItem $dir -Directory | ForEach-Object {
      [pscustomobject]@{ Bucket = $bucket; Name = $_.Name; Source = $_.FullName }
    }
  }
}

function Select-Targets {
  Write-Host '選擇要安裝的代理（可用逗號多選）：'
  $dests.Keys | ForEach-Object -Begin { $index = 1 } -Process {
    Write-Host "  $index. $_"
    $index++
  }
  Write-Host -NoNewline '輸入編號（例如 1,3）：'
  $selected = [Console]::In.ReadLine()
  $indexes = @($selected -split ',' | ForEach-Object { $_.Trim() })
  $invalidIndexes = @($indexes | Where-Object { $_ -notmatch '^\d+$' -or [int]$_ -lt 1 -or [int]$_ -gt $dests.Count })
  if ($indexes.Count -eq 0 -or $invalidIndexes.Count -gt 0) {
    throw '請輸入一個或多個有效編號，例如 1,3。'
  }
  $targets = @($indexes | ForEach-Object { @($dests.Keys)[[int]$_ - 1] } | Select-Object -Unique)
  Write-Host "即將安裝：$($targets -join ', ')"
  Write-Host -NoNewline '確認繼續？[y/N]：'
  if ([Console]::In.ReadLine() -notmatch '^[Yy]$') { throw '已取消安裝。' }
  $targets
}

function Test-ManagedSkillLink {
  param(
    [System.IO.FileSystemInfo]$Item,
    [string]$Source
  )

  if (-not $Item.LinkType) { return $false }
  $expected = [System.IO.Path]::GetFullPath($Source).TrimEnd('\', '/')
  foreach ($target in @($Item.Target)) {
    try {
      $actual = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $target -ErrorAction Stop).Path).TrimEnd('\', '/')
      if ($actual -ieq $expected) { return $true }
    }
    catch { }
  }
  $false
}

$targets = if ($Target) { @($Target) } else { Select-Targets }
$hadFailure = $false

foreach ($agent in $targets) {
  $dest = $dests[$agent]

  # 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡
  $destItem = Get-Item $dest -Force -ErrorAction SilentlyContinue
  if ($destItem -and $destItem.LinkType -and $destItem.Target -like "$repo*") {
    throw "$dest 指向本 repo（$($destItem.Target)）。移除它再重跑。"
  }

  $conflicts = foreach ($skill in $skills) {
    $link = Join-Path $dest $skill.Name
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($item -and -not (Test-ManagedSkillLink -Item $item -Source $skill.Source)) { $link }
  }
  if ($conflicts) {
    [Console]::Error.WriteLine("$agent 無法安裝：以下同名技能不由本 repo 管理，未做任何變更：$($conflicts -join ', ')")
    $hadFailure = $true
    continue
  }

  if (-not $destItem) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

  Write-Host "→ $agent : $dest"
  foreach ($skill in $skills) {
    $link = Join-Path $dest $skill.Name
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($item) { Remove-Item -LiteralPath $link -Recurse -Force }
    New-Item -ItemType Junction -Path $link -Target $skill.Source | Out-Null
    Write-Host "  linked [$($skill.Bucket)] $($skill.Name)"
  }
  Write-Host ""
}

if ($hadFailure) { exit 1 }

if ($targets -contains 'claude') {
  Write-Host "Claude Code：重開後輸入 /ask-luca 確認。"
}
if ($targets -contains 'copilot') {
  Write-Host "Copilot：重開後問「有哪些 skills 可以用？」確認。"
  Write-Host "注意：Copilot 不支援 disable-model-invocation，編排型技能"
  Write-Host "（implement、to-tickets…）在那邊會變成代理可自行呼叫。"
}
if ($targets -contains 'codex') {
  Write-Host "Codex：重開後輸入 /skills 查看，並用 `$ask-luca 明確呼叫技能。"
}
