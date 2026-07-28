# 把 skills/core 的技能連進 ~/.claude/skills。
# 用 Junction 而非 SymbolicLink：Windows 上不需管理員權限或開發者模式。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $HOME '.claude\skills'

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

# 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡
$destItem = Get-Item $dest -Force
if ($destItem.LinkType -and $destItem.Target -like "$repo*") {
  throw "$dest 指向本 repo（$($destItem.Target)）。移除它再重跑。"
}

Get-ChildItem (Join-Path $repo 'skills\core') -Directory | ForEach-Object {
  $target = Join-Path $dest $_.Name
  if (Test-Path $target) { Remove-Item $target -Recurse -Force }
  New-Item -ItemType Junction -Path $target -Target $_.FullName | Out-Null
  Write-Host "linked $($_.Name) -> $($_.FullName)"
}

Write-Host ""
Write-Host "完成。重開 Claude Code 後輸入 /ask-luca 確認。"
