#!/usr/bin/env bash
# ops-script PowerShell 骨架的回歸規格。三個接縫：STATIC（檔案本身的 byte／標記／解析／metadata）、
# CLI（powershell -File skeleton.ps1 <args> 的結束碼／輸出／副作用）、LIB（SKELETON_LIB=1 dot-source 後呼叫共用函式）。
# Windows PowerShell 5.1（powershell.exe）與 PowerShell 7（pwsh）各跑一遍；找不到的就明說略過，不算通過。
# 片段與輸出比對一律用 ASCII：5.1 對管線輸出用 OEM 碼頁，中文會走樣，不拿來斷言。
# 執行：bash tests/scripts/test-ops-script-skeleton-ps.sh（tests/test-tooling.sh 會跑）
set -u
set -o pipefail
cd "$(dirname "$0")/../.."
SK="$PWD/skills/draft/ops-script/skeleton.ps1"
DIR="$PWD/skills/draft/ops-script"
# 傳給 Windows 版 PowerShell 的路徑要是 Windows 格式
if command -v cygpath >/dev/null 2>&1; then SKW=$(cygpath -w "$SK"); else SKW=$SK; fi

fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if command -v cygpath >/dev/null 2>&1; then TMPW=$(cygpath -w "$tmp"); else TMPW=$tmp; fi

verdict() {
  if [ "$1" = ok ]; then printf '  ✓ %s\n' "$2"; else printf '  ✗ %s\n' "$2"; fail=1; fi
}
expect() {  # expect <name> <want> <got>
  if [ "$2" = "$3" ]; then verdict ok "$1"; else verdict ng "$1（想要「$2」，實得「$3」）"; fi
}
contains() {  # contains <name> <haystack> <needle>
  case "$2" in *"$3"*) verdict ok "$1" ;; *) verdict ng "$1（找不到「$3」）" ;; esac
}

shells=()
for p in powershell.exe pwsh; do
  if command -v "$p" >/dev/null 2>&1; then shells+=("$p"); else echo "!! 略過 $p：找不到這個 PowerShell，該版本沒有驗證，不算通過"; fi
done
if [ ${#shells[@]} -eq 0 ]; then echo "- 兩種 PowerShell 都沒有，整份略過"; exit 0; fi

echo "[STATIC] 檔案本身（與 shell 無關）"
[ -f "$SK" ] && verdict ok "skeleton.ps1 存在" || { verdict ng "skeleton.ps1 不存在"; exit 1; }
expect "前 3 byte 為 EF BB BF" "efbbbf" "$(head -c 3 "$SK" | od -An -tx1 | tr -d ' \n')"
b=$(grep -n '^# ---- BEGIN ops-lib v2 ----' "$SK" | cut -d: -f1)
e=$(grep -n '^# ---- END ops-lib ----' "$SK" | cut -d: -f1)
[ -n "$b" ] && [ -n "$e" ] && [ "$b" -lt "$e" ] && verdict ok "BEGIN v2 在 END 之前" || verdict ng "ops-lib 標記缺漏或順序錯"
for fn in Test-OpsTty Test-OpsColor Stop-OpsScript Confirm-Ops Assert-OpsTty Write-OpsStep \
  Write-OpsPass Write-OpsFail Write-OpsWarn Write-OpsSkip Write-OpsSummary Complete-OpsRun \
  Select-OpsMulti Invoke-OpsRun; do
  l=$(grep -n "^function $fn " "$SK" | cut -d: -f1)
  [ -n "$l" ] && [ -n "$b" ] && [ -n "$e" ] && [ "$l" -gt "$b" ] && [ "$l" -lt "$e" ] \
    && verdict ok "$fn 定義在標記之間" || verdict ng "$fn 沒定義在 ops-lib 標記之間"
done
sk=$(cat "$SK")
contains "ErrorActionPreference 設為 Stop" "$sk" "\$ErrorActionPreference = 'Stop'"
contains "外部程式檢查 LASTEXITCODE" "$sk" 'LASTEXITCODE'
contains "CmdletBinding 帶 SupportsShouldProcess" "$sk" '[CmdletBinding(SupportsShouldProcess)]'
contains "用 IsInputRedirected 偵測無終端機" "$sk" '[Console]::IsInputRedirected'
case "$sk" in *"Read-Host"*) verdict ng "不得用 Read-Host" ;; *) verdict ok "未用 Read-Host" ;; esac

echo "[DOC] 規則寫進文件"
doc=$(cat "$DIR/SKILL.md" "$DIR"/*.md 2>/dev/null)
contains "BOM 必要" "$doc" "BOM"
contains "同時支援 5.1 與 7" "$doc" "5.1"
contains "確認自寫、預設 No" "$doc" "[y/N]"
contains "-WhatIf 走 SupportsShouldProcess" "$doc" "SupportsShouldProcess"
contains "Write-Host 允許與抑制理由" "$doc" "SuppressMessage"
contains "PSScriptAnalyzer" "$doc" "PSAvoidUsingWriteHost"
contains "LASTEXITCODE 檢查" "$doc" "LASTEXITCODE"
contains "IsInputRedirected" "$doc" "IsInputRedirected"
contains "預設 No 的理由" "$doc" "default No"
contains "內建確認按 Enter 即執行" "$doc" "Enter"
contains "同時支援 PowerShell 7" "$doc" "PowerShell 7"
contains "SKILL.md 指向 POWERSHELL.md" "$(cat "$DIR/SKILL.md")" "(POWERSHELL.md)"
[ "$(wc -l <"$DIR/SKILL.md")" -le 150 ] && verdict ok "SKILL.md 不超過 150 行" || verdict ng "SKILL.md 超過 150 行"

for PS in "${shells[@]}"; do
  echo
  echo "===== $PS ====="
  ver=$("$PS" -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.Major' </dev/null | tr -d '\r')
  echo "  （主版本 $ver）"
  # run <stdin 檔> <args...>：CLI 接縫，stdout+stderr 合併進 $OUT，結束碼進 $RC
  cli() {
    local in=$1; shift
    OUT=$("$PS" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$SKW" "$@" <"$in" 2>&1); RC=$?
    OUT=${OUT//$'\r'/}
  }
  # lib <片段>：LIB 接縫；片段走環境變數（ASCII），stdin 由呼叫端管線餵入
  lib() {
    SKELETON_LIB=1 SK="$SKW" SNIP="$1" "$PS" -NoProfile -NonInteractive -ExecutionPolicy Bypass \
      -Command '. $env:SK; Invoke-Expression $env:SNIP' 2>&1 | tr -d '\r'
  }
  librc() { lib "$1" >/dev/null; }
  nul=/dev/null

  echo "[STATIC] 解析與 metadata"
  out=$(SKP="$SKW" "$PS" -NoProfile -NonInteractive -Command '$t=$null;$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($env:SKP,[ref]$t,[ref]$e); "errors=$($e.Count)"' </dev/null | tr -d '\r')
  expect "語法解析器零錯誤" "errors=0" "$out"
  out=$(SKP="$SKW" "$PS" -NoProfile -NonInteractive -Command '$h=Get-Help $env:SKP; "syn=[$($h.Synopsis)]"; "ex=$(@($h.examples.example).Count)"; "desc=$(@($h.description).Count)"' </dev/null | tr -d '\r')
  case "$out" in *"syn=[]"*) verdict ng "Get-Help 讀不到 Synopsis" ;; *syn=*) verdict ok "Get-Help 讀得到 Synopsis" ;; *) verdict ng "Get-Help 失敗" ;; esac
  case "$out" in *"ex=0"*) verdict ng "Get-Help 沒有 Example" ;; *) verdict ok "Get-Help 有 Example" ;; esac
  case "$out" in *"desc=0"*) verdict ng "Get-Help 沒有 Description" ;; *) verdict ok "Get-Help 有 Description" ;; esac
  out=$(SKP="$SKW" "$PS" -NoProfile -NonInteractive -Command '$c=Get-Command $env:SKP; ($c.Parameters["Command"].Attributes.Where({$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues -join ","); "sp=$($c.ScriptBlock.Attributes.SupportsShouldProcess)"; "wi=$($c.Parameters.ContainsKey("WhatIf"))"' </dev/null | tr -d '\r')
  contains "ValidateSet 限定子命令為 hello" "$out" "hello"
  contains "有 -WhatIf 參數" "$out" "wi=True"

  echo "[CLI] 用法與結束碼"
  cli $nul; expect "無子命令且 stdin 重導回 2" 2 "$RC"
  cli $nul -Help; expect "-Help 回 0" 0 "$RC"
  contains "-Help 印出說明" "$OUT" "hello"
  cli $nul bogus; [ "$RC" -ne 0 ] && verdict ok "未知子命令非 0（binder 擋下，退出碼 $RC）" || verdict ng "未知子命令不該回 0"
  cli $nul hello; expect "hello 無 -Pick 且無終端機回 2" 2 "$RC"
  for v in "," "" "9" "0" "1,x" "*"; do
    cli $nul hello -Pick "$v"; expect "-Pick「$v」回 2" 2 "$RC"
  done

  echo "[CLI] hello、-WhatIf 與結果總表"
  d="$TMPW\\p-$ver"
  HELLO_DIR="$d" cli $nul hello -Pick 1,3
  expect "hello -Pick 1,3 回 0" 0 "$RC"
  [ -d "$tmp/p-$ver/alpha" ] && [ -d "$tmp/p-$ver/gamma" ] && [ ! -e "$tmp/p-$ver/beta" ] \
    && verdict ok "恰建立 alpha、gamma" || verdict ng "建立的目錄不符"
  contains "總表 pass 2" "$OUT" "pass 2"
  contains "有 [PASS] 行" "$OUT" "[PASS]"
  dw="$TMPW\\w-$ver"
  HELLO_DIR="$dw" cli $nul hello -Pick 2 -WhatIf
  expect "-WhatIf 回 0" 0 "$RC"
  [ ! -e "$tmp/w-$ver" ] && verdict ok "-WhatIf 不做事" || verdict ng "-WhatIf 不該建立目錄"
  contains "-WhatIf 仍印出將執行的指令" "$OUT" "+ "
  HELLO_DIR="$dw" cli $nul hello -Pick 2
  [ -d "$tmp/w-$ver/beta" ] && verdict ok "成對對照：同一個 -Pick 2 真跑會建立 beta" || verdict ng "成對對照：真跑沒建立 beta"
  : >"$tmp/afile"
  HELLO_DIR="$TMPW\\afile\\x" cli $nul hello -Pick 1
  expect "建立失敗回 1" 1 "$RC"
  contains "失敗行 [FAIL]" "$OUT" "[FAIL]"

  echo "[CLI] 測試接縫 SKELETON_LIB 嚴格比對 \"1\""
  SKELETON_LIB=1 cli $nul; expect "LIB=1 直接執行回 0" 0 "$RC"
  expect "LIB=1 直接執行不跑 main（無輸出）" "" "$OUT"
  for v in 0 true 1x; do
    SKELETON_LIB="$v" cli $nul; expect "LIB=「$v」照常跑 main（無子命令回 2）" 2 "$RC"
  done

  echo "[LIB] dot-source 護欄"
  out=$(SK="$SKW" "$PS" -NoProfile -NonInteractive -Command '. $env:SK; "after=$(Get-Command Confirm-Ops -ErrorAction SilentlyContinue | Measure-Object | % Count)"' </dev/null 2>&1 | tr -d '\r')
  contains "未設接縫的 dot-source 被擋（函式沒載入）" "$out" "after=0"
  out=$(lib '"defined=$((Get-Command Confirm-Ops).Name)"' </dev/null)
  expect "LIB=1 載入函式且不跑 main" "defined=Confirm-Ops" "$out"

  echo "[LIB] Stop-OpsScript"
  out=$(lib 'Stop-OpsScript -Code 1 -Title "TITLE" -Fix "FIX1","FIX2"' </dev/null)
  librc 'Stop-OpsScript -Code 1 -Title "T"' </dev/null; expect "結束碼 1" 1 $?
  librc 'Stop-OpsScript -Code 2 -Title "T"' </dev/null; expect "結束碼 2" 2 $?
  contains "標題行" "$out" "✗ TITLE"
  contains "修法縮排四格" "$out" "    FIX1"
  contains "第二行修法" "$out" "    FIX2"

  echo "[LIB] Confirm-Ops"
  for a in y Y yes YES; do
    printf '%s\n' "$a" | librc 'if (Confirm-Ops "go") { exit 0 } else { exit 1 }'; expect "輸入 $a 為真" 0 $?
  done
  for a in n "" maybe; do
    printf '%s\n' "$a" | librc 'if (Confirm-Ops "go") { exit 0 } else { exit 1 }'; expect "輸入「$a」為假（預設 No）" 1 $?
  done
  librc 'if (Confirm-Ops "go") { exit 0 } else { exit 1 }' </dev/null; expect "EOF 為假" 1 $?
  out=$(echo n | lib 'Confirm-Ops "go" | Out-Null'); contains "提示含 [y/N]" "$out" "[y/N]"

  echo "[LIB] Assert-OpsTty 與 Test-OpsColor"
  librc 'Assert-OpsTty' </dev/null; expect "stdin 非終端機回 2" 2 $?
  col() {  # col <NO_COLOR> <TERM> <tty 回傳值>
    NO_COLOR="$1" TERM="$2" lib "function Test-OpsTty { \$$3 }; \"color=\$(Test-OpsColor)\"" </dev/null
  }
  expect "條件全成立時開色" "color=True" "$(col '' xterm true)"
  expect "NO_COLOR 非空關閉" "color=False" "$(col 1 xterm true)"
  expect "TERM=dumb 關閉" "color=False" "$(col '' dumb true)"
  expect "stdout 非終端機關閉" "color=False" "$(col '' xterm false)"

  echo "[LIB] step 與結果計數"
  out=$(lib 'Write-OpsStep PREP' </dev/null); contains "step 印 == 標題" "$out" "== PREP"
  out=$(lib 'Write-OpsPass A; Write-OpsFail B; Write-OpsWarn C; Write-OpsSkip D; Write-OpsSummary' </dev/null)
  contains "pass 行" "$out" "[PASS] A"
  contains "fail 行" "$out" "[FAIL] B"
  contains "warn 行" "$out" "[WARN] C"
  contains "skip 行" "$out" "[SKIP] D"
  contains "總表計數" "$out" "pass 1  fail 1  warn 1  skip 1"
  out=$(lib 'Write-OpsSummary' </dev/null); contains "起始計數皆為 0" "$out" "pass 0  fail 0  warn 0  skip 0"
  out=$(lib 'Write-OpsPass a; Write-OpsFail BROKEN; Write-OpsWarn note; Write-OpsSummary' </dev/null)
  expect "總表重列 fail（原行加重列共兩次）" 2 "$(grep -c 'BROKEN' <<<"$out")"
  librc 'Write-OpsPass a; Complete-OpsRun' </dev/null; expect "無 fail 時 Complete 回 0" 0 $?
  librc 'Write-OpsPass a; Write-OpsWarn b; Write-OpsSkip c; Complete-OpsRun' </dev/null; expect "warn／skip 不影響 Complete 回 0" 0 $?
  librc 'Write-OpsFail b; Complete-OpsRun' </dev/null; expect "有 fail 時 Complete 回 1" 1 $?
  librc 'Complete-OpsRun' </dev/null; expect "零筆結果 Complete 回 0" 0 $?

  echo "[LIB] Select-OpsMulti（結果走管線、畫面走 host）"
  ms() {  # ms <輸入> [項目數]：MS_OUT 為選取結果（逗號串接）
    local n=${2:-7} items="" i
    for ((i = 1; i <= n; i++)); do items="$items,'item$i'"; done
    local snip='"RESULT=" + ((@(Select-OpsMulti -Title T -Items ITEMS)) -join ",")'
    snip=${snip/ITEMS/${items#,}}
    MS_OUT=$(printf '%b' "$1" | lib "$snip" | sed -n 's/.*RESULT=//p' | tail -1)
  }
  ms '1 3 5-7\n\n'; expect "「1 3 5-7」選中 1,3,5,6,7" "1,3,5,6,7" "$MS_OUT"
  ms 'A\n\n'; expect "「A」全選" "1,2,3,4,5,6,7" "$MS_OUT"
  ms 'a\n\n'; expect "「a」全選" "1,2,3,4,5,6,7" "$MS_OUT"
  ms 'a\nn\n2\n\n'; expect "a 之後 n 全不選、再選 2" "2" "$MS_OUT"
  ms 'N\n3\n\n'; expect "大寫 N 全不選、再選 3" "3" "$MS_OUT"
  ms 'a\n2 4\n\n'; expect "a 之後再輸入編號是切換" "1,3,5,6,7" "$MS_OUT"
  ms '1\n1\n2\n\n'; expect "同編號切換兩次回到未選" "2" "$MS_OUT"
  ms '0 8 99 2\n\n'; expect "越界編號忽略、其餘照算" "2" "$MS_OUT"
  ms '5-9\n\n'; expect "範圍中越界的部分忽略" "5,6,7" "$MS_OUT"
  ms '1-999999\n\n' 3; expect "範圍 1-999999 只切換 1..3" "1,2,3" "$MS_OUT"
  ms '7-5\n\n'; expect "倒序範圍 7-5 等同 5-7" "5,6,7" "$MS_OUT"
  ms '\n'; expect "空輸入取消：無輸出" "" "$MS_OUT"
  ms '1\nn\n\n'; expect "全取消勾選後 Enter 等於取消" "" "$MS_OUT"
  ms ''; expect "EOF 取消：無輸出" "" "$MS_OUT"
  mkdir -p "$tmp/globdir" && : >"$tmp/globdir/2" && : >"$tmp/globdir/a"
  out=$(cd "$tmp/globdir" && printf '*\n\n' | lib '"RESULT=" + ((@(Select-OpsMulti -Title T -Items "a","b","c")) -join ",")' | sed -n 's/.*RESULT=//p' | tail -1)
  expect "輸入 * 不會被展開成檔名" "" "$out"
  out=$(printf '1\n\n' | lib '$r = @(Select-OpsMulti -Title TITLEX -Items "a","b"); "n=$($r.Count)"')
  contains "畫面（標題）出現在 host" "$out" "TITLEX"
  out=$(printf '1\n\n' | lib '$r = @(Select-OpsMulti -Title TITLEX -Items "a","b"); "COUNT=" + $r.Count')
  expect "標題不污染回傳值：選一項時 Count 為 1" "1" "$(sed -n 's/.*COUNT=//p' <<<"$out" | tail -1)"

  echo "[LIB] Invoke-OpsRun 與 LASTEXITCODE"
  out=$(lib 'Invoke-OpsRun -Display "echo hi" -Action { Write-Host ran }; "done"' </dev/null)
  contains "執行 Action" "$out" "ran"
  contains "先印 + 指令" "$out" "+ echo hi"
  out=$(lib '$Script:Cmdlet = $null; try { Invoke-OpsRun -Display x -Action { & (Get-Process -Id $PID).Path -NoProfile -Command "exit 3" }; "noerr" } catch { "caught" }' </dev/null)
  contains "外部程式非 0 結束碼會丟例外" "$out" "caught"
  out=$(lib 'try { Invoke-OpsRun -Display x -Action { & (Get-Process -Id $PID).Path -NoProfile -Command "exit 0" }; "ok" } catch { "caught" }' </dev/null)
  contains "外部程式 0 不丟例外" "$out" "ok"
  out=$(lib 'try { Invoke-OpsRun -Display x -Action { cmd /c "exit 5" | Out-Null; "ignored" } ; "ok" } catch { "caught" }' </dev/null)
  contains "前一個外部程式的舊值不外洩（Action 內自行處理）" "$out" "caught"

  out=$(lib 'try { Write-Error "boom"; "after" } catch { "stopped" }' </dev/null)
  contains "ErrorActionPreference=Stop 生效（非終止錯誤被攔成例外）" "$out" "stopped"

  echo "[LIB] 一表三用：子命令表、選單、分派"
  out=$(SKP="$SKW" SKELETON_LIB=1 SK="$SKW" SNIP='$v=(Get-Command $env:SK).Parameters["Command"].Attributes.Where({$_.TypeId.Name -eq "ValidateSetAttribute"}).ValidValues -join ","; $t=($Script:SubCommands.Keys -join ","); "same=$($v -eq $t)"; foreach($k in $Script:SubCommands.Keys){ "fn=$([bool](Get-Command $Script:SubCommands[$k].Fn -ErrorAction SilentlyContinue))" }' \
    "$PS" -NoProfile -NonInteractive -Command '. $env:SK; Invoke-Expression $env:SNIP' </dev/null 2>&1 | tr -d '\r')
  contains "ValidateSet 與子命令表一致" "$out" "same=True"
  case "$out" in *"fn=False"*) verdict ng "有子命令沒有對應函式" ;; *) verdict ok "每個子命令都有對應函式" ;; esac
  dm="$TMPW\\menu-$ver"
  out=$(printf '1\n1\n\n' | HELLO_DIR="$dm" lib 'function Test-OpsTty { $true }; Invoke-OpsMenu')
  contains "選單執行前印出等價指令" "$out" "-> skeleton.ps1 hello"
  [ -d "$tmp/menu-$ver/alpha" ] && verdict ok "選單路徑建立被選的 alpha" || verdict ng "選單路徑沒建立 alpha"
  for a in q ""; do
    printf '%s\n' "$a" | librc 'function Test-OpsTty { $true }; Invoke-OpsMenu'; expect "選單輸入「$a」取消回 1" 1 $?
  done
  librc 'Invoke-OpsMenu' </dev/null; expect "選單 EOF 取消回 1" 1 $?
  printf '\n' | HELLO_DIR="$TMPW\\menu-cancel-$ver" librc 'function Test-OpsTty { $true }; Invoke-OpsCommand hello'
  expect "hello 選單取消回 1" 1 $?
  [ ! -e "$tmp/menu-cancel-$ver" ] && verdict ok "選單取消不建立" || verdict ng "選單取消卻建立了目錄"
done

echo
if [ $fail -eq 0 ]; then echo "ops-script PowerShell 骨架測試全部通過（已跑：${shells[*]}）。"; else echo "ops-script PowerShell 骨架測試未通過。"; fi
exit $fail
