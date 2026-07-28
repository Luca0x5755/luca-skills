# 把 skills/core 與 skills/draft 的技能連進代理的個人技能目錄。
# draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
# 沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。
# archive 不連。
# 用 Junction 而非 SymbolicLink：Windows 上不需管理員權限或開發者模式。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。
#
#   .\scripts\install.ps1            # Claude Code（預設）
#   .\scripts\install.ps1 copilot    # GitHub Copilot
#   .\scripts\install.ps1 all        # 兩邊都裝

param(
  [ValidateSet('claude', 'copilot', 'all')]
  [string]$Target = 'claude'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

# 代理各自的個人技能目錄。Copilot 另外也讀 ~/.agents/skills，
# 但兩個都連會讓同一個技能被載入兩次，所以只挑一個。
$dests = [ordered]@{
  claude  = Join-Path $HOME '.claude\skills'
  copilot = Join-Path $HOME '.copilot\skills'
}

$targets = if ($Target -eq 'all') { $dests.Keys } else { @($Target) }

foreach ($agent in $targets) {
  $dest = $dests[$agent]
  if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

  # 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡
  $destItem = Get-Item $dest -Force
  if ($destItem.LinkType -and $destItem.Target -like "$repo*") {
    throw "$dest 指向本 repo（$($destItem.Target)）。移除它再重跑。"
  }

  Write-Host "→ $agent : $dest"
  foreach ($bucket in @('core', 'draft')) {
    $dir = Join-Path $repo "skills\$bucket"
    if (-not (Test-Path $dir)) { continue }
    Get-ChildItem $dir -Directory | ForEach-Object {
      $link = Join-Path $dest $_.Name
      if (Test-Path $link) { Remove-Item $link -Recurse -Force }
      New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null
      Write-Host "  linked [$bucket] $($_.Name)"
    }
  }
  Write-Host ""
}

if ($targets -contains 'claude') {
  Write-Host "Claude Code：重開後輸入 /ask-luca 確認。"
}
if ($targets -contains 'copilot') {
  Write-Host "Copilot：重開後問「有哪些 skills 可以用？」確認。"
  Write-Host "注意：Copilot 不支援 disable-model-invocation，編排型技能"
  Write-Host "（implement、to-tickets…）在那邊會變成代理可自行呼叫。"
}
