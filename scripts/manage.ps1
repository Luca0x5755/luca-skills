<#
.SYNOPSIS
把 skills/core 與 skills/draft 的技能連進代理的個人技能目錄，或移除、檢查這些連結。

.DESCRIPTION
draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。archive 不連。
用 Junction 而非 SymbolicLink：Windows 上不需管理員權限或開發者模式。
連結後改這個 repo 的檔案會立刻生效，不需重裝。

只處理「本 repo 建立」的連結（目標落在本 repo 的 core/ 或 draft/ 底下，斷鏈也算）；
外來的同名技能一律不碰。

  - 不帶參數且有終端機：先選動作（install／uninstall／status），再選代理。
  - 代理名稱（claude、copilot、codex）單獨當子命令，等同 install 該代理，供自動化沿用。
  - ops-lib 區段逐字複製、不准手改；要改就改 skills/draft/ops-script/skeleton.ps1 並升版號。
  - 測試接縫：環境變數 MANAGE_LIB=1，只定義函式、不跑主流程。
  - 本檔必須存成 UTF-8 with BOM（Windows PowerShell 5.1 的 ANSI 碼頁會讀壞非 ASCII）。
  - 結束碼：0 完成、1 失敗或操作者取消、2 用法錯誤。未知的子命令由參數繫結器擋下（-File 下結束碼為 1）。

.PARAMETER Command
install、uninstall、status，或直接給代理名稱（claude、copilot、codex）。

.PARAMETER Agent
要處理的代理，可多個、可重複（重複只處理一次）。省略時有終端機就詢問，沒有終端機結束碼 2。

.PARAMETER Yes
uninstall 免互動確認（無終端機時必須給）。

.PARAMETER Help
顯示這份說明。

.EXAMPLE
./manage.ps1 install claude codex
安裝到 Claude Code 與 Codex。

.EXAMPLE
./manage.ps1 claude
同上，只裝 Claude Code（install 的別名）。

.EXAMPLE
./manage.ps1 uninstall claude -WhatIf
只印將移除的連結，什麼都不改。

.EXAMPLE
./manage.ps1 status copilot
檢查 Copilot 的連結狀態；有缺漏、斷鏈、過期或同名衝突時結束碼 1。
#>

# Write-Host 是操作者介面：資料走管線（函式回傳值），畫面走 host。PSAvoidUsingWriteHost 針對的是
# 「該回傳資料卻印出去」，這裡不是，故抑制並註明理由。
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = '操作者介面；資料走管線，畫面走 host')]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'uninstall', 'status', 'claude', 'copilot', 'codex')]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Agent,

    [Alias('y')]
    [switch]$Yes,

    [switch]$Help
)

# 拒絕被 dot-source：exit 會關掉操作者的 shell。要載入函式請用測試接縫。
if ($MyInvocation.InvocationName -eq '.' -and $env:MANAGE_LIB -ne '1') {
    Write-Host '✗ 不可 dot-source 這支腳本'
    Write-Host '    請直接執行；要在測試中載入函式，設定 MANAGE_LIB=1'
    return
}

# 嚴格模式只是安全網：重要的失敗一律自己攔下、用 Stop-OpsScript 回報。
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# ---- BEGIN ops-lib v4 ----
# Write-Host 是操作者介面（選單、提示、步驟、結果）：資料走管線，畫面走 host，兩條路不混。
# 本檔頂端的 SuppressMessage 抑制 PSAvoidUsingWriteHost，理由寫在那裡。

# 終端機探針：全區段唯一碰 IsInputRedirected／IsOutputRedirected 的地方，測試覆寫它來模擬終端機。
function Test-OpsTty {
    param([ValidateSet('In', 'Out')][string]$Stream = 'In')
    if ($Stream -eq 'In') { return -not [Console]::IsInputRedirected }
    return -not [Console]::IsOutputRedirected
}

# 顏色：stdout 非終端機、NO_COLOR 非空、TERM=dumb 任一成立即關閉。可重複呼叫。
function Test-OpsColor {
    if (-not (Test-OpsTty -Stream Out)) { return $false }
    if ($env:NO_COLOR) { return $false }
    if ($env:TERM -eq 'dumb') { return $false }
    return $true
}

# 一行畫面輸出：有色時用 -ForegroundColor，不依賴 ANSI 跳脫碼（5.1 的 conhost 不一定支援）。
function Write-OpsLine {
    param([string]$Text, [string]$Color = '', [switch]$NoNewline)
    if ($Color -and (Test-OpsColor)) {
        Write-Host $Text -ForegroundColor $Color -NoNewline:$NoNewline
    } else {
        Write-Host $Text -NoNewline:$NoNewline
    }
}

# Stop-OpsScript：先寫錯什麼、再寫怎麼修，然後以 Code 結束（die_with）。
function Stop-OpsScript {
    param([int]$Code = 1, [string]$Title = '發生錯誤', [string[]]$Fix = @())
    Write-OpsLine "✗ $Title" -Color Red
    foreach ($line in $Fix) { Write-Host "    $line" }
    exit $Code
}

# Confirm-Ops 提示：預設 No；只有 y／yes（不分大小寫）回 $true，EOF 也是 No。
# 自寫而不用內建確認：內建的按 Enter 即執行，破壞性動作的預設必須是 No。
function Confirm-Ops {
    param([Parameter(Mandatory)][string]$Prompt)
    Write-Host "$Prompt [y/N] " -NoNewline
    $ans = [Console]::In.ReadLine()
    return ($null -ne $ans) -and ($ans -match '^(y|yes)$')
}

# Assert-OpsTty：只看 stdin。缺值要詢問的路徑先過這關，沒有終端機就結束碼 2。
function Assert-OpsTty {
    if (-not (Test-OpsTty -Stream In)) {
        Stop-OpsScript -Code 2 -Title '需要終端機' -Fix '改用旗標或參數傳入所需的值，或在終端機中執行'
    }
}

# ---- 結果回報 ----
# 計數與訊息：每個行程從 0 開始。
$script:NPass = 0; $script:NFail = 0; $script:NWarn = 0; $script:NSkip = 0
$script:Issues = New-Object System.Collections.Generic.List[string]
$script:Cmdlet = $null

function Write-OpsStep { param([string]$Title) Write-OpsLine "== $Title" }

function Write-OpsPass { param([string]$Text) $script:NPass++; Write-OpsLine "[PASS] $Text" }
function Write-OpsSkip { param([string]$Text) $script:NSkip++; Write-OpsLine "[SKIP] $Text" }
function Write-OpsWarn {
    param([string]$Text)
    $script:NWarn++; $script:Issues.Add("[WARN] $Text"); Write-OpsLine "[WARN] $Text"
}
function Write-OpsFail {
    param([string]$Text)
    $script:NFail++; $script:Issues.Add("[FAIL] $Text"); Write-OpsLine "[FAIL] $Text" -Color Red
}

# Write-OpsSummary：總表並重列所有 fail 與 warn。
function Write-OpsSummary {
    Write-OpsLine ('總計：pass {0}  fail {1}  warn {2}  skip {3}' -f $script:NPass, $script:NFail, $script:NWarn, $script:NSkip)
    foreach ($line in $script:Issues) { Write-OpsLine "  $line" }
}

# Complete-OpsRun：印總表後結束；有任何 fail 結束碼為 1，否則 0。
function Complete-OpsRun {
    Write-OpsSummary
    if ($script:NFail -gt 0) { exit 1 }
    exit 0
}

# Invoke-OpsRun：先印將執行的指令；-WhatIf 時到此為止。會改系統的動作都走它。
# 失敗一律丟例外（呼叫端用 try/catch 記帳）：外部程式的 $LASTEXITCODE 非 0 也算失敗，
# 因為 $ErrorActionPreference = 'Stop' 管不到外部程式。
function Invoke-OpsRun {
    param([Parameter(Mandatory)][string]$Display, [Parameter(Mandatory)][scriptblock]$Action)
    Write-OpsLine "+ $Display"
    if ($script:Cmdlet -and -not $script:Cmdlet.ShouldProcess($Display, 'Run')) { return }
    $global:LASTEXITCODE = 0
    & $Action | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "指令結束碼 ${LASTEXITCODE}：$Display" }
}

# ---- 多選器 ----
# Switch-OpsSelection Sel Lo Hi：切換第 Lo～Hi 項（1 起算）；越界的部分夾掉。陣列是參考型別，原地修改。
function Switch-OpsSelection {
    param([int[]]$Sel, [long]$Lo, [long]$Hi)
    if ($Lo -gt $Hi) { $Lo, $Hi = $Hi, $Lo }
    if ($Lo -lt 1) { $Lo = 1 }
    if ($Hi -gt $Sel.Count) { $Hi = $Sel.Count }
    for ($i = $Lo; $i -le $Hi; $i++) { $Sel[$i - 1] = 1 - $Sel[$i - 1] }
}

# Update-OpsSelection Sel Line：a 全選、n 全不選、「3」「5-7」切換；不認得的記號忽略。
function Update-OpsSelection {
    param([int[]]$Sel, [string]$Line)
    foreach ($tok in ($Line -split '\s+' | Where-Object { $_ })) {
        if ($tok -match '^[aA]$') { for ($i = 0; $i -lt $Sel.Count; $i++) { $Sel[$i] = 1 } }
        elseif ($tok -match '^[nN]$') { for ($i = 0; $i -lt $Sel.Count; $i++) { $Sel[$i] = 0 } }
        elseif ($tok -match '^([0-9]{1,6})-([0-9]{1,6})$') { Switch-OpsSelection $Sel ([long]$Matches[1]) ([long]$Matches[2]) }
        elseif ($tok -match '^[0-9]{1,6}$') { Switch-OpsSelection $Sel ([long]$tok) ([long]$tok) }
    }
}

# Select-OpsMulti -Title -Items：畫面與提示走 host；確定後管線輸出每個選中的編號（1 起算、遞增）。
# 取消（什麼都沒選就 Enter，或讀到 EOF）什麼都不輸出，由呼叫端用 @(...).Count 決定怎麼收尾。
function Select-OpsMulti {
    param([Parameter(Mandatory)][string]$Title, [Parameter(Mandatory)][string[]]$Items)
    $sel = New-Object 'int[]' $Items.Count
    $w = "$($Items.Count)".Length
    while ($true) {
        Write-Host $Title
        # 編號在前、標記在後，編號欄寬依項目數；與選單的 `N) 名稱` 對齊。
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $mark = if ($sel[$i]) { 'x' } else { ' ' }
            Write-Host ('  {0}) [{1}] {2}' -f "$($i + 1)".PadLeft($w), $mark, $Items[$i])
        }
        Write-Host '輸入編號切換（例：1 3 5-7；a 全選、n 全不選、Enter 確定）：' -NoNewline
        $line = [Console]::In.ReadLine()
        if ($null -eq $line) { return }
        if (-not $line.Trim()) { break }
        Update-OpsSelection $sel $line
    }
    for ($i = 0; $i -lt $Items.Count; $i++) { if ($sel[$i]) { $i + 1 } }
}

# Resolve-OpsPick -Flag -Raw -Items：無人值守時的挑選。Raw 是逗號分隔的項目名稱，逐一與項目整串精確比對（分大小寫）；
# 輸出與 Select-OpsMulti 相同（管線輸出每個編號、1 起算、遞增、不重複），呼叫端兩條路共用同一段收尾。
# 收名稱不收編號：編號跟著清單順序走，清單一改，排程裡的編號就指到別的項目。
# 空值或任何一個不認得的名稱都以結束碼 2 結束，訊息列出可用的名稱。
function Resolve-OpsPick {
    param([Parameter(Mandatory)][string]$Flag, [string[]]$Raw, [Parameter(Mandatory)][string[]]$Items)
    $hint = "可用的名稱（逗號分隔）：$($Items -join ',')"
    $vals = @($Raw | ForEach-Object { $_ -split ',' })
    if ($vals.Count -eq 0) { Stop-OpsScript -Code 2 -Title "$Flag 沒有值" -Fix $hint }
    $sel = New-Object 'bool[]' $Items.Count
    foreach ($v in $vals) {
        # IndexOf 用字串的 Equals：序數比對、分大小寫；-eq／-contains 不分大小寫，不能用。
        $i = [Array]::IndexOf($Items, $v)
        if ($i -lt 0) {
            $shown = if ($v) { $v } else { '（空）' }
            Stop-OpsScript -Code 2 -Title "$Flag 的值無效：$shown" -Fix $hint
        }
        $sel[$i] = $true
    }
    for ($i = 0; $i -lt $Items.Count; $i++) { if ($sel[$i]) { $i + 1 } }
}
# ---- END ops-lib ----

$SelfPath = $PSCommandPath
$ScriptName = Split-Path -Leaf $SelfPath
$repo = Split-Path -Parent $PSScriptRoot
$homeRoot = if ($env:HOME) { $env:HOME } else { $HOME }

# 代理各自的個人技能目錄。Codex 讀 ~/.agents/skills；Copilot 也讀這裡，
# 但 Copilot 改連自己的目錄，避免同一個技能被載入兩次。
$Dests = [ordered]@{
    claude  = Join-Path $homeRoot '.claude\skills'
    copilot = Join-Path $homeRoot '.copilot\skills'
    codex   = Join-Path $homeRoot '.agents\skills'
}
$AgentNames = @($Dests.Keys)

# 目標落在本 repo 的 core/ 或 draft/ 底下就算本 repo 管理，不要求目標仍存在：
# 技能畢業或封存後舊連結成了斷鏈，它仍是本 repo 建的，要能被替換或移除。
$Buckets = @('core', 'draft') | ForEach-Object { [System.IO.Path]::GetFullPath((Join-Path $repo "skills\$_")) }

function Get-RepoSkill {
    foreach ($bucket in @('core', 'draft')) {
        $dir = Join-Path $repo "skills\$bucket"
        if (Test-Path -LiteralPath $dir) {
            Get-ChildItem -LiteralPath $dir -Directory | ForEach-Object {
                [pscustomobject]@{ Bucket = $bucket; Name = $_.Name; Source = $_.FullName }
            }
        }
    }
}
$Skills = @(Get-RepoSkill)

function Test-ManagedSkillLink {
    param([System.IO.FileSystemInfo]$Item)

    if (-not $Item.LinkType) { return $false }
    foreach ($target in @($Item.Target)) {
        $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Split-Path -Parent $Item.FullName), $target))
        $parent = [System.IO.Path]::GetDirectoryName($full.TrimEnd('\', '/'))
        if ($Buckets -icontains $parent) { return $true }
    }
    $false
}

# 只拆連結本身。Directory.Delete 不遞迴，不會像 Remove-Item -Recurse 那樣在 5.1 上跟進連結刪到 repo 的檔案。
function Remove-SkillLink {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.LinkType) { throw "不是連結，拒絕刪除：$Path" }
    [System.IO.Directory]::Delete($Path)
}

function Get-DestEntry {
    param([string]$Dest)
    @(Get-ChildItem -LiteralPath $Dest -Force -ErrorAction SilentlyContinue)
}

# 與 repo 技能同名、卻不由本 repo 管理的項目。
function Get-Conflict {
    param([string]$Dest)
    foreach ($skill in $Skills) {
        $link = Join-Path $Dest $skill.Name
        $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($item -and -not (Test-ManagedSkillLink -Item $item)) { $link }
    }
}

# 本 repo 建立、但名字已不在 core/、draft/ 的連結（技能封存或改名後的殘影）。
function Get-StaleLink {
    param([string]$Dest)
    foreach ($entry in (Get-DestEntry $Dest)) {
        if ((Test-ManagedSkillLink -Item $entry) -and ($Skills.Name -notcontains $entry.Name)) { $entry }
    }
}

# 防呆：$Dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡。
function Assert-DestOutsideRepo {
    param([string]$Dest)
    $destItem = Get-Item -LiteralPath $Dest -Force -ErrorAction SilentlyContinue
    if ($destItem -and $destItem.LinkType -and "$($destItem.Target)" -like "$repo*") {
        Stop-OpsScript -Title "$Dest 指向本 repo（$($destItem.Target)）" -Fix '移除它再重跑'
    }
}

function Install-Agent {
    param([string]$Name)
    $dest = $Dests[$Name]
    Assert-DestOutsideRepo $dest

    $conflicts = @(Get-Conflict $dest)
    if ($conflicts.Count -gt 0) {
        Write-OpsFail "$Name 無法安裝：以下同名技能不由本 repo 管理，未做任何變更：$($conflicts -join ', ')"
        return
    }

    Write-OpsStep "$Name : $dest"
    try {
        if (-not (Test-Path -LiteralPath $dest)) {
            Invoke-OpsRun -Display "mkdir $dest" -Action { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        }
    } catch {
        Write-OpsFail "$Name 無法建立目錄：$($_.Exception.Message)"
        return
    }
    foreach ($skill in $Skills) {
        $link = Join-Path $dest $skill.Name
        try {
            Invoke-OpsRun -Display "link $link -> $($skill.Source)" -Action {
                if (Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue) { Remove-SkillLink $link }
                New-Item -ItemType Junction -Path $link -Target $skill.Source | Out-Null
            }
            Write-OpsPass "linked [$($skill.Bucket)] $($skill.Name)"
        } catch {
            Write-OpsFail "$($skill.Name)：$($_.Exception.Message)"
        }
    }
    Remove-StaleLink $dest
}

# 技能封存或改名後，舊連結成了殘影：本 repo 建的才清，外來的一律不碰。
function Remove-StaleLink {
    param([string]$Dest)
    foreach ($entry in @(Get-StaleLink $Dest)) {
        try {
            Invoke-OpsRun -Display "unlink $($entry.FullName)" -Action { Remove-SkillLink $entry.FullName }
            Write-OpsPass "pruned stale $($entry.Name)"
        } catch {
            Write-OpsFail "$($entry.Name)：$($_.Exception.Message)"
        }
    }
}

# 本 repo 建立的連結（含斷鏈與已不在 core/、draft/ 的過期連結）。
function Get-OwnedLink {
    param([string]$Dest)
    foreach ($entry in (Get-DestEntry $Dest)) {
        if (Test-ManagedSkillLink -Item $entry) { $entry }
    }
}

function Uninstall-Agent {
    param([string]$Name)
    $dest = $Dests[$Name]
    Assert-DestOutsideRepo $dest

    Write-OpsStep "$Name : $dest"
    foreach ($skipped in @(Get-Conflict $dest)) { Write-OpsWarn "略過（不由本 repo 管理）：$skipped" }
    $links = @(Get-OwnedLink $dest)
    if ($links.Count -eq 0) { Write-OpsSkip "$Name 沒有本 repo 建立的連結"; return }
    foreach ($entry in $links) {
        try {
            Invoke-OpsRun -Display "unlink $($entry.FullName)" -Action { Remove-SkillLink $entry.FullName }
            Write-OpsPass "removed $($entry.Name)"
        } catch {
            Write-OpsFail "$($entry.Name)：$($_.Exception.Message)"
        }
    }
}

# 刪東西前的最後一道門：互動時問一次（預設 No），沒有終端機就必須帶 -Yes；-WhatIf 什麼都不會刪，免問。
function Confirm-Uninstall {
    param([string[]]$Agents)
    $total = 0
    foreach ($a in $Agents) { $total += @(Get-OwnedLink $Dests[$a]).Count }
    if ($total -eq 0 -or $Yes -or $WhatIfPreference) { return }
    if (-not (Test-OpsTty -Stream In)) {
        Stop-OpsScript -Code 2 -Title '移除需要確認' -Fix "沒有終端機時請加 -Yes（先用 -WhatIf 看會移除什麼）"
    }
    if (-not (Confirm-Ops "將移除 $($Agents -join ', ') 的 $total 個本 repo 連結。繼續？")) {
        Stop-OpsScript -Title '已取消' -Fix '沒有移除任何連結'
    }
}

function Invoke-Uninstall {
    $agents = @(Resolve-Agent 'uninstall' '移除')
    Confirm-Uninstall $agents
    foreach ($a in $agents) { Uninstall-Agent $a }
    Complete-OpsRun
}

# 唯讀：把一個代理的技能目錄分成 缺少／斷鏈／同名衝突／過期 四種異常，全無異常才算正常。
function Get-AgentProblem {
    param([string]$Dest)
    $missing = @(); $broken = @(); $conflict = @()
    foreach ($skill in $Skills) {
        $link = Join-Path $Dest $skill.Name
        $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if (-not $item) { $missing += $skill.Name }
        elseif (-not (Test-ManagedSkillLink -Item $item)) { $conflict += $skill.Name }
        # 斷鏈的 Junction 本身 Test-Path 仍為真，所以改看技能必有的 SKILL.md 讀不讀得到
        elseif (-not (Test-Path -LiteralPath (Join-Path $link 'SKILL.md'))) { $broken += $skill.Name }
    }
    $stale = @(Get-StaleLink $Dest | ForEach-Object { $_.Name })
    [pscustomobject]@{ Missing = $missing; Broken = $broken; Conflict = $conflict; Stale = $stale }
}

function Show-AgentStatus {
    param([string]$Name)
    $dest = $Dests[$Name]
    Write-OpsStep "$Name : $dest"
    $p = Get-AgentProblem $dest
    $labels = [ordered]@{
        Missing  = '缺少（跑 install 補上）'
        Broken   = '斷鏈（跑 install 重連）'
        Conflict = '同名但不由本 repo 管理（install 會拒絕，請自行處理）'
        Stale    = '過期連結（技能已封存或改名，跑 install 或 uninstall 清掉）'
    }
    $clean = $true
    foreach ($key in $labels.Keys) {
        $names = @($p.$key)
        if ($names.Count -eq 0) { continue }
        $clean = $false
        Write-OpsFail "$Name $($labels[$key])：$($names -join ', ')"
    }
    if ($clean) { Write-OpsPass "$Name 的 $($Skills.Count) 個技能都已連結" }
}

function Invoke-Status {
    foreach ($a in @(Resolve-Agent 'status' '檢查')) { Show-AgentStatus $a }
    Complete-OpsRun
}

# 子命令表：選單、用法與分派都讀它。Fn 是處理函式；Verb 是選代理時的動詞。
# 新增子命令 = 加一列 + 一個函式 + ValidateSet 補一個值。
$SubCommands = [ordered]@{
    install   = @{ Desc = '把技能連進代理的技能目錄（支援 -WhatIf）'; Fn = 'Invoke-Install'; Verb = '安裝' }
    uninstall = @{ Desc = '移除本 repo 建立的連結，不碰外來技能（支援 -WhatIf、-Yes）'; Fn = 'Invoke-Uninstall'; Verb = '移除' }
    status    = @{ Desc = '唯讀檢查連結狀態；有缺漏、斷鏈、過期或衝突時結束碼 1'; Fn = 'Invoke-Status'; Verb = '檢查' }
}

function Write-Usage { Write-Host ((Get-Help $SelfPath -Full | Out-String).TrimEnd()) }

# 用法錯誤：先印用法，再以結束碼 2 收尾。
function Stop-OpsUsage {
    param([string]$Title, [string[]]$Fix = @())
    Write-Usage
    Stop-OpsScript -Code 2 -Title $Title -Fix $Fix
}

# 互動選代理：輸入編號，空白分隔，可多選；選定後直接處理，不再確認。
# 無效輸入提示後重問；讀到 EOF 取消（結束碼 1）。
function Read-AgentSelection {
    param([string]$Verb)
    Write-Host "選擇要${Verb}的代理（可用空白多選）："
    for ($i = 0; $i -lt $AgentNames.Count; $i++) { Write-Host "  $($i + 1)) $($AgentNames[$i])" }
    while ($true) {
        Write-Host -NoNewline '輸入編號（例如 1 3）：'
        $line = [Console]::In.ReadLine()
        if ($null -eq $line) { Stop-OpsScript -Title '已取消' -Fix '沒有選任何代理，什麼都沒做' }
        $tokens = @($line.Trim() -split '\s+')
        $invalid = @($tokens | Where-Object { $_ -notmatch '^[1-3]$' })
        if ($invalid.Count -gt 0) {
            Write-Host '請輸入一個或多個有效編號，以空白分隔，例如 1 3。'
            continue
        }
        $picked = @($tokens | ForEach-Object { $AgentNames[[int]$_ - 1] } | Select-Object -Unique)
        Write-Host "即將${Verb}：$($picked -join ', ')"
        return $picked
    }
}

# 參數給了代理就驗證後使用；沒給就詢問（需要終端機），不替操作者挑。
function Resolve-Agent {
    param([string]$Name, [string]$Verb)
    $given = @($script:AgentArgs | Where-Object { $_ })
    if ($given.Count -gt 0) {
        foreach ($a in $given) {
            if ($AgentNames -notcontains $a) { Stop-OpsUsage "未知的代理：$a" "可用：$($AgentNames -join '、')" }
        }
        return @($given | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique)
    }
    if (-not (Test-OpsTty -Stream In)) {
        Stop-OpsUsage '沒有指定代理' "例：$ScriptName $Name claude；或在終端機中執行以互動選擇"
    }
    $picked = @(Read-AgentSelection $Verb)
    if ($script:FromMenu) { Write-Host "-> $ScriptName $Name $($picked -join ' ')" }
    $picked
}

function Write-InstallHint {
    param([string[]]$Agents)
    if ($Agents -contains 'claude') { Write-Host 'Claude Code：重開後輸入 /ask-luca 確認。' }
    if ($Agents -contains 'copilot') {
        Write-Host 'Copilot：重開後問「有哪些 skills 可以用？」確認。'
        Write-Host '注意：Copilot 不支援 disable-model-invocation，編排型技能'
        Write-Host '（implement、to-tickets…）在那邊會變成代理可自行呼叫。'
    }
    if ($Agents -contains 'codex') { Write-Host 'Codex：重開後輸入 /skills 查看，並用 $ask-luca 明確呼叫技能。' }
}

function Invoke-Install {
    $agents = @(Resolve-Agent 'install' '安裝')
    foreach ($a in $agents) { Install-Agent $a }
    if ($script:NFail -eq 0) { Write-InstallHint $agents }
    Complete-OpsRun
}

function Invoke-OpsCommand {
    param([string]$Name)
    if (-not $SubCommands.Contains($Name)) { Stop-OpsUsage "未知子命令：$Name" '用 -Help 查看可用的子命令' }
    & $SubCommands[$Name].Fn
}

# 選單：選了動作就進該動作（再選代理）；取消結束碼 1。
function Invoke-OpsMenu {
    $names = @($SubCommands.Keys)
    $w = "$($names.Count)".Length
    $script:FromMenu = $true
    while ($true) {
        for ($i = 0; $i -lt $names.Count; $i++) {
            Write-Host ('  {0}) {1,-10} {2}' -f "$($i + 1)".PadLeft($w), $names[$i], $SubCommands[$names[$i]].Desc)
        }
        Write-Host '選擇編號（q 取消）：' -NoNewline
        $choice = [Console]::In.ReadLine()
        if ($null -eq $choice -or $choice -eq '' -or $choice -eq 'q') { exit 1 }
        if ($choice -match '^[1-9][0-9]*$' -and [int]$choice -le $names.Count) {
            Invoke-OpsCommand $names[[int]$choice - 1]
            return
        }
        Write-Host "無效的選項：$choice"
    }
}

function Invoke-Main {
    if ($Help) { Write-Usage; exit 0 }
    $name = $Command
    # 代理名稱單獨當子命令，等同 install 該代理（PR-INSTALL-05）。
    if ($name -and $AgentNames -contains $name) {
        $script:AgentArgs = @($name) + @($script:AgentArgs)
        $name = 'install'
    }
    if ($name) { Invoke-OpsCommand $name; return }
    if (Test-OpsTty -Stream In) { Invoke-OpsMenu; return }
    Stop-OpsUsage '未指定子命令' '帶上子命令，或在終端機中執行以進入選單'
}

$script:AgentArgs = @()
$script:FromMenu = $false
if ($env:MANAGE_LIB -ne '1') {
    $script:Cmdlet = $PSCmdlet
    $script:AgentArgs = @($Agent)
    Invoke-Main
}
