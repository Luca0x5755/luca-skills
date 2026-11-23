<#
.SYNOPSIS
運維腳本骨架（PowerShell）：不帶參數且有終端機時進入選單；帶子命令時直接執行。

.DESCRIPTION
帶子命令時可供排程與其他腳本呼叫；缺值又沒有終端機時，以結束碼 2 結束並說明要補哪個參數。

結束碼：0 完成、1 失敗或操作者取消、2 用法錯誤。未知的子命令由參數繫結器擋下（-File 下結束碼為 1）。

.PARAMETER Command
子命令。不給且有終端機時進入選單；不給且沒有終端機時印用法並結束碼 2。
  hello：支援 -WhatIf，只印將執行的指令，什麼都不改。

.PARAMETER Pick
hello 的挑選：-Pick alpha,gamma 依名稱免互動。

.PARAMETER Step
逐步模式：每個步驟前印標題與說明並停下，Enter 執行、a 之後不再停、q 離開。需要終端機。可與 -WhatIf 並用。

.PARAMETER Help
顯示這份說明。

.EXAMPLE
./skeleton.ps1 hello -Pick alpha,gamma
建立 alpha、gamma 兩個目錄，免互動。

.EXAMPLE
./skeleton.ps1 hello -Pick beta -WhatIf
只印將執行的指令，什麼都不改。

.EXAMPLE
./skeleton.ps1 hello -Step
逐步執行：每個步驟前停下，讀完說明再按 Enter。
#>

# 運維腳本骨架。上方說明區塊給操作者（-Help 印它），維護者筆記寫在這裡的註解。
# 與 #> 之間要空一行：緊接的註解會被 Get-Help 併進最後一個 .EXAMPLE。
# 複製後改名，替換 hello 示範，其餘照結構擴充。
#   - 子命令表是下方的 $SubCommands；ValidateSet 必須是字面值，所以要與它同步（測試會比對）。
#   - ops-lib 區段逐字複製、不准手改；要改就改本骨架並升版號，再同步回各腳本。
#   - 測試接縫：環境變數 SKELETON_LIB=1，只定義函式、不跑主流程。複製後把變數名改成 <腳本名>_LIB，三處一起改。
#   - 本檔必須存成 UTF-8 with BOM：沒有 BOM 的非 ASCII 腳本在 Windows PowerShell 5.1 的 ANSI 碼頁上會解析失敗。

# Write-Host 是操作者介面：資料走管線（函式回傳值），畫面走 host。PSAvoidUsingWriteHost 針對的是
# 「該回傳資料卻印出去」，這裡不是，故抑制並註明理由。
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = '操作者介面；資料走管線，畫面走 host')]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [ValidateSet('hello')]
    [string]$Command,

    [string[]]$Pick,

    [switch]$Step,

    [switch]$Help
)

# 拒絕被 dot-source：exit 會關掉操作者的 shell。要載入函式請用測試接縫。
if ($MyInvocation.InvocationName -eq '.' -and $env:SKELETON_LIB -ne '1') {
    Write-Host '✗ 不可 dot-source 這支腳本'
    Write-Host '    請直接執行；要在測試中載入函式，設定 SKELETON_LIB=1'
    return
}

# 嚴格模式只是安全網：重要的失敗一律自己攔下、用 Stop-OpsScript 回報。
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# ---- BEGIN ops-lib v8 ----
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

# Assert-OpsTty [-Fix]：只看 stdin。缺值要詢問的路徑先過這關，沒有終端機就結束碼 2。
# 修法由呼叫端給（點名該補的參數）；不給才用通用句。
function Assert-OpsTty {
    param([string[]]$Fix = @('改用選項或參數傳入所需的值，或在終端機中執行'))
    if (-not (Test-OpsTty -Stream In)) {
        Stop-OpsScript -Code 2 -Title '需要終端機' -Fix $Fix
    }
}

# ---- 結果回報 ----
# 計數與訊息：每個行程從 0 開始。
$script:NPass = 0; $script:NFail = 0; $script:NWarn = 0; $script:NSkip = 0
$script:Issues = New-Object System.Collections.Generic.List[string]
$script:Cmdlet = $null

# 逐步模式：主流程在 -Step 時把 StepMode 設為真；流水號與 a（之後不再停）的狀態都記在這裡。
$script:StepMode = $false; $script:StepNo = 0; $script:StepAuto = $false

# Write-OpsStep Title [說明行...]：說明行選填，只在逐步模式印；逐步模式下標題帶流水號，並在印完後停一次。
# 停點由本函式自寫：Enter 執行這一步、a 執行並不再停（仍照印標題與說明）、q 或輸入結束離開；其他輸入重問，沒有跳過。
# q 先印總表、點名停在哪一步之前，結束碼 1。
function Write-OpsStep {
    param([string]$Title, [Parameter(ValueFromRemainingArguments)][string[]]$Note = @())
    if (-not $script:StepMode) { Write-OpsLine "== $Title"; return }
    $script:StepNo++
    Write-OpsLine "== 步驟 $($script:StepNo)：$Title"
    foreach ($line in $Note) { Write-OpsLine "   $line" }
    if ($script:StepAuto) { return }
    while ($true) {
        Write-Host 'Enter 執行這一步、a 之後不再停、q 離開：' -NoNewline
        $ans = [Console]::In.ReadLine()
        if ($null -eq $ans -or $ans.Trim() -eq 'q') {
            Write-OpsSummary
            Write-OpsLine "停在步驟 $($script:StepNo)：$Title 之前，這一步沒有執行"
            exit 1
        }
        $ans = $ans.Trim()
        if ($ans -eq '') { return }
        if ($ans -eq 'a') { $script:StepAuto = $true; return }
    }
}

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
        Write-Host "$Title（例：1 3 5-7；a 全選、n 全不選、Enter 確定）"
        # 編號在前、標記在後，編號欄寬依項目數；與選單的 `N) 名稱` 對齊。
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $mark = if ($sel[$i]) { 'x' } else { ' ' }
            Write-Host ('  {0}) [{1}] {2}' -f "$($i + 1)".PadLeft($w), $mark, $Items[$i])
        }
        Write-Host '輸入編號：' -NoNewline
        $line = [Console]::In.ReadLine()
        if ($null -eq $line) { return }
        if (-not $line.Trim()) { break }
        Update-OpsSelection $sel $line
    }
    for ($i = 0; $i -lt $Items.Count; $i++) { if ($sel[$i]) { $i + 1 } }
}

# ---- 單選器 ----
# Select-OpsOne -Title -Items：畫面與提示走 host；輸入有效編號即選定，管線輸出該編號（1 起算）。
# Enter、q 或讀到 EOF 什麼都不輸出；越界或看不懂的輸入說明後重問（只讀一個值，忽略它等於沒反應）。
function Select-OpsOne {
    param([Parameter(Mandatory)][string]$Title, [Parameter(Mandatory)][string[]]$Items)
    $w = "$($Items.Count)".Length
    while ($true) {
        Write-Host "$Title（q 取消）"
        for ($i = 0; $i -lt $Items.Count; $i++) {
            Write-Host ('  {0}) {1}' -f "$($i + 1)".PadLeft($w), $Items[$i])
        }
        Write-Host '輸入編號：' -NoNewline
        $line = [Console]::In.ReadLine()
        if ($null -eq $line) { return }
        $line = $line.Trim()
        if ($line -eq '' -or $line -eq 'q') { return }  # -eq 不分大小寫，Q 也算
        if ($line -match '^[0-9]{1,6}$' -and [int]$line -ge 1 -and [int]$line -le $Items.Count) { return [int]$line }
        Write-Host "無效的選項：$line"
    }
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

# Resolve-OpsPickOne -Flag -Raw -Items：Resolve-OpsPick 的單選版，Select-OpsOne 的無人值守路徑；給了不只一個名稱就以結束碼 2 結束。
function Resolve-OpsPickOne {
    param([Parameter(Mandatory)][string]$Flag, [string[]]$Raw, [Parameter(Mandatory)][string[]]$Items)
    $picks = @(Resolve-OpsPick -Flag $Flag -Raw $Raw -Items $Items)
    if ($picks.Count -gt 1) {
        Stop-OpsScript -Code 2 -Title "$Flag 只能選一個：$($Raw -join ',')" -Fix '只給一個名稱，不要用逗號列出多個'
    }
    $picks
}
# ---- END ops-lib ----

$SelfPath = $PSCommandPath
$ScriptName = Split-Path -Leaf $SelfPath

# 子命令表：選單與分派都讀它。Fn 是處理函式；新增子命令 = 加一列 + 一個函式 + ValidateSet 補一個值。
$SubCommands = [ordered]@{
    hello = @{ Desc = '示範：挑選並建立目錄'; Fn = 'Invoke-Hello' }
}

# -Detailed：參數說明與範例都印，但不印每個參數的 Required／Position 等欄位
function Write-Usage { Write-Host ((Get-Help $SelfPath -Detailed | Out-String).TrimEnd()) }

# 用法錯誤：先印用法，再以結束碼 2 收尾。
function Stop-OpsUsage {
    param([string]$Title, [string[]]$Fix = @())
    Write-Usage
    Stop-OpsScript -Code 2 -Title $Title -Fix $Fix
}

function Invoke-OpsCommand {
    param([string]$Name)
    if (-not $SubCommands.Contains($Name)) { Stop-OpsUsage "未知子命令：$Name" '用 -Help 查看可用的子命令' }
    & $SubCommands[$Name].Fn
}

# 需確認欄：Confirm 為真的列印 $ConfirmMark；任一列有時其餘列補同寬空白，全表都沒有就不留欄。
$ConfirmMark = '[需確認] '
$ConfirmPad = ' ' * 9  # 與 $ConfirmMark 同寬：中文一字 2 欄

function Format-OpsMenuDesc {
    param([hashtable]$Row, [string]$Pad)
    # 用索引不用 .Confirm：StrictMode 下沒有這個鍵的列存取屬性會丟錯，索引則回 $null
    if ($Row['Confirm']) { return $ConfirmMark + $Row.Desc }
    $Pad + $Row.Desc
}

# 選單：子命令選單就是一次 Select-OpsOne；選了就先印等價指令再執行，取消結束碼 1。
function Invoke-OpsMenu {
    $names = @($SubCommands.Keys)
    $pad = if (@($SubCommands.Values | Where-Object { $_['Confirm'] }).Count) { $ConfirmPad } else { '' }
    $items = @($names | ForEach-Object { '{0,-10} {1}' -f $_, (Format-OpsMenuDesc $SubCommands[$_] $pad) })
    $idx = @(Select-OpsOne -Title '要做什麼？' -Items $items)
    if ($idx.Count -eq 0) { exit 1 }
    $name = $names[$idx[0] - 1]
    $stepArg = if ($script:StepMode) { ' -Step' } else { '' }
    Write-Host "-> $ScriptName $name$stepArg"
    Invoke-OpsCommand $name
}

# hello 的項目：示範多選器與結果總表，換成腳本真正的選項。
$HelloItems = @('alpha', 'beta', 'gamma')

# -Pick 的繫結結果：函式讀不到腳本的 $PSBoundParameters，主流程啟動時再填。
$script:HasPick = $false
$script:BoundPick = @()

function Invoke-Hello {
    $dir = if ($env:HELLO_DIR) { $env:HELLO_DIR } else { './hello-out' }
    if ($script:HasPick) {
        $picks = @(Resolve-OpsPick -Flag '-Pick' -Raw $script:BoundPick -Items $HelloItems)
    } else {
        Assert-OpsTty -Fix '改用 -Pick 指定名稱（例：-Pick alpha,gamma），或在終端機中執行'
        $picks = @(Select-OpsMulti -Title '要建立哪些目錄？' -Items $HelloItems)
        if ($picks.Count -eq 0) { Stop-OpsScript -Title '已取消' -Fix '沒有選任何項目，什麼都沒做' }
    }
    Write-OpsStep '建立目錄' `
        '在 HELLO_DIR（預設 ./hello-out）下建立所選的目錄' `
        '目錄已存在不會出錯，重跑只是再建一次；停在這裡，已建好的目錄會留著'
    foreach ($idx in $picks) {
        $name = $HelloItems[$idx - 1]
        $target = Join-Path $dir $name
        # 失敗要記帳而不是中止：try/catch 接住，結果交給 Complete-OpsRun 決定結束碼。
        try {
            Invoke-OpsRun -Display "mkdir -p $target" -Action {
                New-Item -ItemType Directory -Force -Path $target | Out-Null
                # New-Item -Force 在父路徑是檔案時靜默不做事、不丟錯，所以事後驗證結果。
                if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw "目錄沒有建立：$target" }
            }
            Write-OpsPass "建立 $name"
        } catch {
            Write-OpsFail "建立 ${name}：$($_.Exception.Message)"
        }
    }
    Complete-OpsRun
}

function Invoke-Main {
    if ($Help) { Write-Usage; exit 0 }
    # -Step 需要終端機：沒有就在動手前結束碼 2，點名拿掉 -Step
    if ($script:StepMode) { Assert-OpsTty -Fix '拿掉 -Step，或在終端機中執行' }
    if ($Command) { Invoke-OpsCommand $Command; return }
    if (Test-OpsTty -Stream In) { Invoke-OpsMenu; return }
    Stop-OpsUsage '未指定子命令' '帶上子命令，或在終端機中執行以進入選單'
}

if ($env:SKELETON_LIB -ne '1') {
    $script:Cmdlet = $PSCmdlet
    $script:BoundPick = $Pick
    $script:HasPick = $PSBoundParameters.ContainsKey('Pick')
    $script:StepMode = [bool]$Step
    Invoke-Main
}
