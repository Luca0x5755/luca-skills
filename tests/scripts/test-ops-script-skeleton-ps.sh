#!/usr/bin/env bash
# ops-script PowerShell 骨架的回歸規格。三個接縫：STATIC（檔案本身的 byte／標記／解析／metadata）、
# CLI（powershell -File skeleton.ps1 <args> 的結束碼／輸出／副作用）、LIB（SKELETON_LIB=1 dot-source 後呼叫共用函式）。
# Windows PowerShell 5.1（powershell.exe）與 PowerShell 7（pwsh）各跑一遍；找不到的就明說略過，不算通過。
# 片段與輸出比對一律用 ASCII：5.1 對管線輸出用 OEM 碼頁，中文會走樣，不拿來斷言。
# 例外：選單行檢查覆寫 Write-Host、以 UTF-8 寫檔後再讀，不經管線，才能斷言中文。
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
# disp_width <字串>：顯示寬度近似值 — 多位元組字元算 2 欄（CJK 與全形標點皆為 3 位元組）
disp_width() {
  local c b
  c=$(LC_ALL=C.UTF-8 bash -c 'printf %s "${#1}"' _ "$1")
  b=$(LC_ALL=C bash -c 'printf %s "${#1}"' _ "$1")
  echo $((c + (b - c) / 2))
}
# check_menu_lines <選單輸出>：每行不含旗標、不超過 80 欄；空輸出算失敗
check_menu_lines() {
  # 全形字不放進方括號：C locale 按位元組比對，（ 與 ： 共用前兩個位元組，會互相誤中
  local line flagged="" wide="" bracket="" starts="" prefix desc re='(^|[[:space:]]|（|\(|、|，|；|：|「|/)--?[A-Za-z]'
  # 選單行＝「  N) 名稱<空白>」＋需確認欄（[需確認] 或同寬空白）＋描述
  local row='^( *[0-9]+\) [a-z0-9-]+ +)(\[需確認\] )?(.*)$' br='（|\(|\['
  [ -n "$1" ] || { verdict ng "抓不到選單輸出"; return; }
  while IFS= read -r line; do
    [[ "$line" =~ $re ]] && flagged+="[$line]"
    (($(disp_width "$line") > 80)) && wide+="[$line]"
    [[ "$line" =~ $row ]] || { bracket+="[無法解析：$line]"; continue; }
    prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}" desc="${BASH_REMATCH[3]}"
    [[ "$desc" =~ $br ]] && bracket+="[$line]"
    starts+="$(disp_width "$prefix")"$'\n'
  done <<<"$1"
  expect "選單行不含旗標" "" "$flagged"
  expect "選單行不超過 80 欄" "" "$wide"
  expect "描述欄不含括號" "" "$bracket"
  expect "各列描述起始欄位相同" 1 "$(printf '%s' "$starts" | sort -u | awk 'END { print NR }')"
}

shells=()
for p in powershell.exe pwsh; do
  if command -v "$p" >/dev/null 2>&1; then shells+=("$p"); else echo "!! 略過 $p：找不到這個 PowerShell，該版本沒有驗證，不算通過"; fi
done
if [ ${#shells[@]} -eq 0 ]; then echo "- 兩種 PowerShell 都沒有，整份略過"; exit 0; fi

echo "[STATIC] 檔案本身（與 shell 無關）"
[ -f "$SK" ] && verdict ok "skeleton.ps1 存在" || { verdict ng "skeleton.ps1 不存在"; exit 1; }
expect "前 3 byte 為 EF BB BF" "efbbbf" "$(head -c 3 "$SK" | od -An -tx1 | tr -d ' \n')"
b=$(grep -n '^# ---- BEGIN ops-lib v8 ----' "$SK" | cut -d: -f1)
e=$(grep -n '^# ---- END ops-lib ----' "$SK" | cut -d: -f1)
[ -n "$b" ] && [ -n "$e" ] && [ "$b" -lt "$e" ] && verdict ok "BEGIN v8 在 END 之前" || verdict ng "ops-lib 標記缺漏或順序錯"
for fn in Test-OpsTty Test-OpsColor Stop-OpsScript Confirm-Ops Assert-OpsTty Write-OpsStep \
  Write-OpsPass Write-OpsFail Write-OpsWarn Write-OpsSkip Write-OpsSummary Complete-OpsRun \
  Select-OpsMulti Resolve-OpsPick Select-OpsOne Resolve-OpsPickOne Invoke-OpsRun \
  Set-OpsRunCommand Add-OpsResumeArg Write-OpsResume; do
  l=$(grep -n "^function $fn " "$SK" | cut -d: -f1)
  [ -n "$l" ] && [ -n "$b" ] && [ -n "$e" ] && [ "$l" -gt "$b" ] && [ "$l" -lt "$e" ] \
    && verdict ok "$fn 定義在標記之間" || verdict ng "$fn 沒定義在 ops-lib 標記之間"
done
sk=$(cat "$SK")
# 逐步模式的停點由 ops-lib 自寫：區段內不得出現 Set-PSDebug、Read-Host、-Confirm（Invoke-OpsRun 的 ShouldProcess 屬 -WhatIf）
libtxt=$(sed -n "${b},${e}p" "$SK")
for w in 'Set-PSDebug' 'Read-Host' '-Confirm'; do
  case "$libtxt" in *"$w"*) verdict ng "ops-lib 區段不得出現 $w" ;; *) verdict ok "ops-lib 區段沒有 $w" ;; esac
done
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
contains "單選走 Select-OpsOne" "$doc" "Select-OpsOne"
contains "單選的無人值守走 Resolve-OpsPickOne" "$doc" "Resolve-OpsPickOne"
# 繼續指令（PR-OPS-14）：POWERSHELL.md 單獨斷言，英文詞
psdoc=$(cat "$DIR/POWERSHELL.md")
contains "POWERSHELL.md：每個步驟都必須可重跑" "$psdoc" "re-runnable"
contains "POWERSHELL.md：步驟說明 1-3 行" "$psdoc" "1-3 lines"
contains "POWERSHELL.md：寫明 Add-OpsResumeArg" "$psdoc" "Add-OpsResumeArg"
skipline=$(grep -F 'already done' "$DIR/POWERSHELL.md" | head -1)
contains "POWERSHELL.md：已完成就 Write-OpsSkip" "$skipline" "Write-OpsSkip"
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
  contains "hello 無終端機時點名 -Pick" "$OUT" "-Pick alpha,gamma"
  # -Step 沒有終端機：結束碼 2、點名拿掉 -Step、什麼都不做
  HELLO_DIR="$TMPW\nostep-$ver" cli $nul hello -Pick alpha -Step
  expect "-Step 無終端機回 2" 2 "$RC"
  contains "-Step 無終端機時點名 -Step" "$OUT" "-Step"
  [ ! -e "$tmp/nostep-$ver" ] && verdict ok "-Step 無終端機什麼都不做" || verdict ng "-Step 無終端機不該建立目錄"
  cli $nul -Step; expect "只有 -Step 且無終端機回 2" 2 "$RC"
  # -Help 只給操作者：維護者筆記（ops-lib 同步、測試接縫、BOM）留在 # 註解
  cli $nul -Help
  for w in ops-lib _LIB BOM; do
    case "$OUT" in *"$w"*) verdict ng "-Help 不該出現維護者筆記「$w」" ;; *) verdict ok "-Help 沒有維護者筆記「$w」" ;; esac
  done
  for v in "," "" "1" "Alpha" "alph" "alpha beta" "alpha,x" "alpha,,beta" "alpha," "*"; do
    cli $nul hello -Pick "$v"; expect "-Pick「$v」回 2" 2 "$RC"
  done

  echo "[CLI] hello、-WhatIf 與結果總表"
  d="$TMPW\\p-$ver"
  HELLO_DIR="$d" cli $nul hello -Pick alpha,gamma
  expect "hello -Pick alpha,gamma 回 0" 0 "$RC"
  [ -d "$tmp/p-$ver/alpha" ] && [ -d "$tmp/p-$ver/gamma" ] && [ ! -e "$tmp/p-$ver/beta" ] \
    && verdict ok "恰建立 alpha、gamma" || verdict ng "建立的目錄不符"
  contains "總表 pass 2" "$OUT" "pass 2"
  contains "有 [PASS] 行" "$OUT" "[PASS]"
  dw="$TMPW\\w-$ver"
  HELLO_DIR="$dw" cli $nul hello -Pick beta -WhatIf
  expect "-WhatIf 回 0" 0 "$RC"
  [ ! -e "$tmp/w-$ver" ] && verdict ok "-WhatIf 不做事" || verdict ng "-WhatIf 不該建立目錄"
  contains "-WhatIf 仍印出將執行的指令" "$OUT" "+ "
  HELLO_DIR="$dw" cli $nul hello -Pick beta
  [ -d "$tmp/w-$ver/beta" ] && verdict ok "成對對照：同一個 -Pick beta 真跑會建立 beta" || verdict ng "成對對照：真跑沒建立 beta"
  : >"$tmp/afile"
  HELLO_DIR="$TMPW\\afile\\x" cli $nul hello -Pick alpha
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

  echo "[STATIC] 停點不走 ShouldProcess／Confirm（AST 取 Write-OpsStep 本體）"
  out=$(SKP="$SKW" "$PS" -NoProfile -NonInteractive -Command '$t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseFile($env:SKP,[ref]$t,[ref]$e);$f=$a.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq "Write-OpsStep"},$true); if ($f) { "found"; $x=$f.Extent.Text; foreach ($w in "ShouldProcess","Confirm","Read-Host") { "$w=$($x.Contains($w))" } }' </dev/null | tr -d '\r')
  contains "找到 Write-OpsStep" "$out" "found"
  for w in ShouldProcess Confirm Read-Host; do contains "Write-OpsStep 本體不含 $w" "$out" "$w=False"; done

  hf="$tmp/host-$ver.txt"
  echo "[LIB v8] 逐步模式：Write-OpsStep 的停點"
  # step_run <stdin> <片段>：StepMode 開、終端機為真、無色；畫面以 UTF-8 寫檔。SR_OUT 為畫面，SR_RC 為結束碼
  step_run() {
    hf="$tmp/host-$ver.txt"; rm -f "$hf"
    printf "$1" | NO_COLOR=1 HF="$TMPW/host-$ver.txt" lib "function Write-Host { param(\$Object, [switch]\$NoNewline) \$t = if (\$NoNewline) { \"\$Object\" } else { \"\$Object\`n\" }; [IO.File]::AppendAllText(\$env:HF, \$t, [Text.UTF8Encoding]::new(\$false)) }; function Test-OpsTty { \$true }; \$script:StepMode = \$true; $2" >/dev/null
    SR_RC=$?
    SR_OUT=$(cat "$hf" 2>/dev/null)
  }
  step_run '\n' 'Write-OpsStep FIRST "note one" "note two"'
  expect "Enter 執行這一步、結束碼 0" 0 "$SR_RC"
  contains "標題帶流水號" "$SR_OUT" "== 步驟 1：FIRST"
  contains "印第一行說明" "$SR_OUT" "note one"
  contains "印第二行說明" "$SR_OUT" "note two"
  expect "開跑前不印總覽：第一行就是第一步的標題" "== 步驟 1：FIRST" "$(head -1 <<<"$SR_OUT")"
  step_run '\n\n' 'Write-OpsStep FIRST "n1"; Write-OpsStep SECOND "n2"'
  expect "兩步各停一次、結束碼 0" 0 "$SR_RC"
  contains "第二步流水號 2" "$SR_OUT" "== 步驟 2：SECOND"
  step_run 'a\n' 'Write-OpsStep A "na"; Write-OpsStep B "nb"; Write-OpsStep C "nc"'
  expect "a 之後不再讀輸入（讀了會遇到 EOF 而結束碼 1）" 0 "$SR_RC"
  contains "a 之後仍印標題" "$SR_OUT" "== 步驟 3：C"
  contains "a 之後仍印說明" "$SR_OUT" "nc"
  step_run 'q\n' 'Write-OpsStep A "na"; Write-OpsPass RAN-A'
  expect "q 結束碼 1" 1 "$SR_RC"
  contains "q 先印總表" "$SR_OUT" "總計：pass 0  fail 0  warn 0  skip 0"
  contains "q 點名停在哪一步之前" "$SR_OUT" "停在步驟 1：A 之前"
  case "$SR_OUT" in *RAN-A*) verdict ng "q 之後不該再執行這一步" ;; *) verdict ok "q 之後這一步沒有執行" ;; esac
  step_run '' 'Write-OpsStep A "na"; Write-OpsPass RAN-A'
  expect "輸入結束等同 q：結束碼 1" 1 "$SR_RC"
  contains "輸入結束也點名停在哪一步之前" "$SR_OUT" "停在步驟 1：A 之前"
  step_run 'y\ns\nx\n\n' 'Write-OpsStep A "na"'
  expect "無效輸入（含 y、s）重問後 Enter 結束碼 0" 0 "$SR_RC"
  expect "共問四次（沒有跳過選項）" 4 "$(grep -o 'q 離開' <<<"$SR_OUT" | wc -l | tr -d ' ')"
  out=$(printf 'SENTINEL\n' | NO_COLOR=1 lib 'Write-OpsStep T "note"; Write-OpsPass x; "left=" + [Console]::In.ReadLine()'); rc=$?
  expect "不帶 -Step：結束碼 0" 0 "$rc"
  contains "不帶 -Step：照舊印 == 標題" "$out" "== T"
  contains "不帶 -Step：不讀輸入" "$out" "left=SENTINEL"
  case "$out" in *note*) verdict ng "不帶 -Step 不該印說明行" ;; *) verdict ok "不帶 -Step 不印說明行" ;; esac
  case "$out" in *步驟*) verdict ng "不帶 -Step 標題不該有流水號" ;; *) verdict ok "不帶 -Step 標題沒有流水號" ;; esac

  echo "[LIB v8] 停點與確認、-WhatIf 互相獨立"
  printf 'y\n\ny\n' | NO_COLOR=1 librc 'function Test-OpsTty { $true }; $script:StepMode = $true; Write-OpsStep A; if (Confirm-Ops go) { exit 0 } else { exit 1 }'
  expect "停點輸入 y 不算確認、Enter 後另一次 y 才確認" 0 $?
  printf 'y\n\n\n' | NO_COLOR=1 librc 'function Test-OpsTty { $true }; $script:StepMode = $true; Write-OpsStep A; if (Confirm-Ops go) { exit 0 } else { exit 1 }'
  expect "Enter 不能代替確認的 y" 1 $?
  dwi="$TMPW\\whatif-step-$ver"
  step_run 'a\n' "\$env:HELLO_DIR = '$dwi'; function T { [CmdletBinding(SupportsShouldProcess)] param(); \$script:Cmdlet = \$PSCmdlet; \$script:HasPick = \$true; \$script:BoundPick = 'beta'; Invoke-Hello }; T -WhatIf"
  expect "-Step 加 -WhatIf：結束碼 0" 0 "$SR_RC"
  contains "-Step 加 -WhatIf：停點照走" "$SR_OUT" "== 步驟 1："
  contains "-Step 加 -WhatIf：仍印將執行的指令" "$SR_OUT" "+ mkdir"
  [ ! -e "$tmp/whatif-step-$ver" ] && verdict ok "-Step 加 -WhatIf 不建立目錄" || verdict ng "-Step 加 -WhatIf 不該建立目錄"

  echo "[LIB v8] hello 的步驟帶說明行，用 -Step 跑完"
  dst="$TMPW\\hello-step-$ver"
  step_run 'a\n' "\$env:HELLO_DIR = '$dst'; \$script:HasPick = \$true; \$script:BoundPick = 'alpha,gamma'; Invoke-Hello"
  expect "hello -Step 跑完結束碼 0" 0 "$SR_RC"
  [ -d "$tmp/hello-step-$ver/alpha" ] && [ -d "$tmp/hello-step-$ver/gamma" ] && verdict ok "hello -Step 建立 alpha、gamma" || verdict ng "hello -Step 沒建立目錄"
  case "$(sed -n 2p <<<"$SR_OUT")" in "+ "*|"["*|"") verdict ng "hello 的步驟沒有說明行" ;; *) verdict ok "hello 的步驟標題後有說明行" ;; esac

  echo "[LIB v8] 選單的等價指令帶 -Step"
  step_run '1\n' 'function Invoke-OpsCommand { param($Name) }; Invoke-OpsMenu'
  contains "-Step 選單的等價指令" "$SR_OUT" "-> skeleton.ps1 hello -Step"
  step_run '1\n' '$script:StepMode = $false; function Invoke-OpsCommand { param($Name) }; Invoke-OpsMenu'
  out=$SR_OUT
  contains "不帶 -Step 的等價指令照舊" "$out" "-> skeleton.ps1 hello"
  case "$out" in *"-Step"*) verdict ng "不帶 -Step 的等價指令不該有 -Step" ;; *) verdict ok "不帶 -Step 的等價指令沒有 -Step" ;; esac
  step_run 'q\n' 'Invoke-Main'
  expect "只有 -Step、有終端機：進選單，q 取消回 1" 1 "$SR_RC"
  contains "只有 -Step 進了選單" "$SR_OUT" "要做什麼？"

  echo "[LIB v8] 繼續指令：q／EOF、任何模式的 fail 會印，正常做完不印"
  # host_rc <stdin> <片段>：與 step_run 相同的畫面捕捉，但不開 StepMode。SR_OUT 為畫面，SR_RC 為結束碼
  host_rc() {
    hf="$tmp/host-$ver.txt"; rm -f "$hf"
    printf "$1" | NO_COLOR=1 HF="$TMPW/host-$ver.txt" lib "function Write-Host { param(\$Object, [switch]\$NoNewline) \$t = if (\$NoNewline) { \"\$Object\" } else { \"\$Object\`n\" }; [IO.File]::AppendAllText(\$env:HF, \$t, [Text.UTF8Encoding]::new(\$false)) }; function Test-OpsTty { \$true }; $2" >/dev/null
    SR_RC=$?
    SR_OUT=$(cat "$hf" 2>/dev/null)
  }
  rc_set='Set-OpsRunCommand -Script skeleton.ps1 -Name hello -Bound ([ordered]@{Pick="alpha"; Step=[switch]$true}); '
  step_run 'q\n' "$rc_set"'Write-OpsStep A "na"'
  expect "q：結束碼 1" 1 "$SR_RC"
  contains "q 印繼續指令" "$SR_OUT" "-> skeleton.ps1 hello -Pick alpha -Step"
  expect "q 的繼續指令恰好一行" 1 "$(grep -c -- '-> skeleton.ps1' <<<"$SR_OUT")"
  step_run '' "$rc_set"'Write-OpsStep A "na"'
  contains "輸入結束也印繼續指令" "$SR_OUT" "-> skeleton.ps1 hello -Pick alpha -Step"
  step_run 'q\n' 'Write-OpsStep A "na"'
  expect "沒記過指令的 q 仍結束碼 1" 1 "$SR_RC"
  case "$SR_OUT" in *"->"*) verdict ng "沒記過指令不該印繼續指令" ;; *) verdict ok "沒記過指令不印繼續指令" ;; esac
  host_rc '' "$rc_set"'Write-OpsFail x; Complete-OpsRun'
  expect "不帶 -Step 有 fail：結束碼 1" 1 "$SR_RC"
  contains "不帶 -Step 有 fail 也印繼續指令" "$SR_OUT" "-> skeleton.ps1 hello -Pick alpha -Step"
  host_rc '' 'Write-OpsFail x; Complete-OpsRun'
  expect "沒記過指令有 fail：結束碼 1" 1 "$SR_RC"
  case "$SR_OUT" in *"->"*) verdict ng "沒記過指令有 fail 不該印 ->" ;; *) verdict ok "沒記過指令有 fail 不印 ->" ;; esac
  host_rc '' "$rc_set"'Write-OpsPass a; Complete-OpsRun'
  expect "只有 pass：結束碼 0" 0 "$SR_RC"
  case "$SR_OUT" in *"->"*) verdict ng "正常做完不該印繼續指令" ;; *) verdict ok "正常做完不印繼續指令" ;; esac
  host_rc '' "$rc_set"'Write-OpsWarn w; Write-OpsSkip s; Complete-OpsRun'
  expect "只有 warn／skip：結束碼 0" 0 "$SR_RC"
  case "$SR_OUT" in *"->"*) verdict ng "warn／skip 不該印繼續指令" ;; *) verdict ok "warn／skip 不印繼續指令" ;; esac

  echo "[LIB v8] 繼續指令的寫法"
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Pick=@("alpha","gamma"); Step=[switch]$true; WhatIf=[switch]$true}); Write-OpsResume'; out=$SR_OUT
  expect "陣列以逗號接、switch 只印名稱" "-> s.ps1 hello -Pick alpha,gamma -Step -WhatIf" "$out"
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Step=[switch]$false}); Write-OpsResume'; out=$SR_OUT
  expect "false 的 switch 不印" "-> s.ps1 hello" "$out"
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Pick="a b"}); Write-OpsResume'; out=$SR_OUT
  expect "含空白的值加引號" "-> s.ps1 hello -Pick 'a b'" "$out"
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Pick="alpha"}); Write-OpsResume'; out=$SR_OUT
  case "$out" in *-Yes*) verdict ng "原參數沒有 -Yes 不該自動加" ;; *) verdict ok "原參數沒有 -Yes 就不加" ;; esac
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Yes=[switch]$true; Pick="alpha"}); Write-OpsResume'; out=$SR_OUT
  expect "原參數有 -Yes 就照原樣" "-> s.ps1 hello -Yes -Pick alpha" "$out"
  host_rc '' 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{Step=[switch]$true}); Add-OpsResumeArg -Flag -Pick -Value alpha,gamma; Write-OpsResume'; out=$SR_OUT
  expect "補登的參數接在原參數之後" "-> s.ps1 hello -Step -Pick alpha,gamma" "$out"
  out=$(lib 'Set-OpsRunCommand -Script s.ps1 -Name hello -Bound ([ordered]@{}); $o = @(Write-OpsResume); "n=$($o.Count)"' </dev/null)
  contains "繼續指令不進成功輸出串流" "$out" "n=0"

  echo "[LIB v8] hello 互動挑選後補登 -Pick，照繼續指令重跑不再進多選器"
  dbad="$TMPW\afile\x"
  host_rc '' "\$env:HELLO_DIR = '$dbad'; function Select-OpsMulti { param(\$Title, \$Items) 1; 3 }; Set-OpsRunCommand -Script skeleton.ps1 -Name hello -Bound ([ordered]@{}); Invoke-Hello"
  expect "互動挑選建立失敗回 1" 1 "$SR_RC"
  contains "互動挑選補登 -Pick" "$SR_OUT" "-> skeleton.ps1 hello -Pick alpha,gamma"
  drr="$TMPW\resume-$ver"
  host_rc '' "\$env:HELLO_DIR = '$drr'; \$script:HasPick = \$true; \$script:BoundPick = 'alpha,gamma'; function Select-OpsMulti { throw 'multi' }; Set-OpsRunCommand -Script skeleton.ps1 -Name hello -Bound ([ordered]@{Pick='alpha,gamma'}); Invoke-Hello"
  expect "照繼續指令重跑不進多選器、結束碼 0" 0 "$SR_RC"
  contains "重跑建立兩個目錄" "$SR_OUT" "pass 2"
  host_rc '' "\$env:HELLO_DIR = '$dbad'; \$script:HasPick = \$true; \$script:BoundPick = 'alpha,gamma'; Set-OpsRunCommand -Script skeleton.ps1 -Name hello -Bound ([ordered]@{Pick='alpha,gamma'}); Invoke-Hello"
  expect "本來就帶 -Pick：繼續指令只有一個 -Pick" 1 "$(grep -o -- '-Pick' <<<"$(grep -- '-> ' <<<"$SR_OUT")" | wc -l | tr -d ' ')"

  echo "[CLI v8] 繼續指令走 host 串流、原參數來自腳本層繫結"
  : >"$tmp/afile"
  clihost() {  # clihost <重導> <腳本參數...>：-Command 才能重導 PowerShell 的 host 串流
    local redir=$1; shift
    OUT=$(HELLO_DIR="$TMPW\afile\x" SK="$SKW" "$PS" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& \$env:SK $* $redir" </dev/null 2>&1); RC=$?
    OUT=${OUT//$'\r'/}
  }
  clihost '6>$null' hello -Pick alpha,gamma
  expect "失敗的 hello 回 1" 1 "$RC"
  case "$OUT" in *"->"*) verdict ng "繼續指令漏進成功輸出串流" ;; *) verdict ok "成功輸出串流沒有繼續指令" ;; esac
  clihost '6>&1' hello -Pick alpha,gamma
  expect "繼續指令恰為原參數（不含 Command）" "-> skeleton.ps1 hello -Pick alpha,gamma" "$(grep -- '-> ' <<<"$OUT")"
  clihost '6>&1' hello -Pick alpha,gamma -Verbose
  contains "腳本層的 switch 流進繼續指令" "$OUT" "-> skeleton.ps1 hello -Pick alpha,gamma -Verbose"

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

  echo "[LIB v4] 清單格式：編號在前、標記在後、編號依項目數補齊寬度"
  out=$(printf '1\n\n' | lib '$r = @(Select-OpsMulti -Title T -Items "a","b")')
  contains "未選的列是「  1) [ ] a」" "$out" "  1) [ ] a"
  contains "選中的列是「  1) [x] a」" "$out" "  1) [x] a"
  out=$(printf '\n' | lib '$r = @(Select-OpsMulti -Title T -Items (1..10 | ForEach-Object { "item$_" }))')
  contains "10 項時 9 號補一格空白" "$out" "   9) [ ] item9"
  contains "10 項時 10 號不補" "$out" "  10) [ ] item10"
  out=$(printf 'q\n' | lib '$Script:SubCommands = [ordered]@{}; 1..10 | ForEach-Object { $Script:SubCommands["n$_"] = @{ Desc = "d"; Fn = "x" } }; Invoke-OpsMenu')
  contains "選單 10 列時 9 號補一格空白" "$out" "   9) n9"
  contains "選單 10 列時 10 號不補" "$out" "  10) n10"
  out=$(printf 'q\n' | lib 'Invoke-OpsMenu')
  contains "選單 1 列時編號不補空白" "$out" "  1) hello"

  # 中文經 5.1 管線會走樣：覆寫 Write-Host，把畫面以 UTF-8 寫進檔案再檢查（-NoNewline 的提示不換行）
  hf="$tmp/host-$ver.txt"
  # host_text <stdin 內容> <片段>：跑片段，印出抓到的 host 畫面
  host_text() {
    rm -f "$hf"
    printf "$1" | HF="$TMPW/host-$ver.txt" lib "function Write-Host { param(\$Object, [switch]\$NoNewline) \$t = if (\$NoNewline) { \"\$Object\" } else { \"\$Object\`n\" }; [IO.File]::AppendAllText(\$env:HF, \$t, [Text.UTF8Encoding]::new(\$false)) }; $2" >/dev/null
    cat "$hf" 2>/dev/null
  }

  echo "[LIB v6] Select-OpsOne（輸入有效編號即選定；Enter、q、EOF 取消；無效輸入說明後重問）"
  so() {  # so <輸入>：SO_OUT 為選取結果
    SO_OUT=$(printf '%b' "$1" | lib '"RESULT=" + ((@(Select-OpsOne -Title T -Items "item1","item2","item3")) -join ",")' | sed -n 's/.*RESULT=//p' | tail -1)
  }
  so '2\n'; expect "輸入 2 選中 2" "2" "$SO_OUT"
  so ' 3 \n'; expect "前後空白不影響" "3" "$SO_OUT"
  so '02\n'; expect "前導 0 照十進位算" "2" "$SO_OUT"
  for a in "" q Q; do
    so "$a\n"; expect "輸入「$a」取消：無輸出" "" "$SO_OUT"
  done
  so ''; expect "EOF 取消：無輸出" "" "$SO_OUT"
  so '0\n2\n'; expect "越界之後重問、再選 2" "2" "$SO_OUT"
  so '4\n\n'; expect "超過項目數不選、Enter 取消" "" "$SO_OUT"
  so '1 2\n\n'; expect "一次給兩個編號不算選定" "" "$SO_OUT"
  out=$(printf '1\n' | lib '$r = @(Select-OpsOne -Title TITLEX -Items "a","b"); "COUNT=" + $r.Count')
  expect "標題不污染回傳值：Count 為 1" "1" "$(sed -n 's/.*COUNT=//p' <<<"$out" | tail -1)"
  out=$(host_text '0\nx\n\n' '$r = @(Select-OpsOne -Title "標題" -Items "a","b")')
  contains "標題行帶取消說明" "$out" "標題（q 取消）"
  contains "清單列沒有勾選框" "$out" "  1) a"
  contains "輸入行是「輸入編號：」" "$out" "輸入編號："
  contains "越界時說明" "$out" "無效的選項：0"
  contains "看不懂的輸入說明" "$out" "無效的選項：x"
  expect "重問時重畫標題" 3 "$(grep -o '標題（q 取消）' <<<"$out" | wc -l | tr -d ' ')"
  out=$(printf '\n' | lib '$r = @(Select-OpsOne -Title T -Items (1..10 | ForEach-Object { "item$_" }))')
  contains "10 項時 9 號補一格空白" "$out" "   9) item9"

  echo "[LIB v6] Resolve-OpsPickOne（Resolve-OpsPick 的單選版）"
  rp1() {  # rp1 <值>：RP1_OUT 為回傳的編號
    RP1_OUT=$(RAW="$1" lib '"RESULT=" + ((@(Resolve-OpsPickOne -Flag "-Target" -Raw $env:RAW -Items "alpha","beta","gamma")) -join ",")' </dev/null | sed -n 's/.*RESULT=//p' | tail -1)
  }
  rp1 beta; expect "beta 選中 2" "2" "$RP1_OUT"
  RAW='alpha,gamma' librc 'Resolve-OpsPickOne -Flag "-Target" -Raw $env:RAW -Items "alpha","beta","gamma"' </dev/null; expect "兩個名稱結束碼 2" 2 $?
  rp1 'alpha,gamma'; expect "兩個名稱時無輸出" "" "$RP1_OUT"
  out=$(host_text '' '$env:RAW = "alpha,gamma"; Resolve-OpsPickOne -Flag "-Target" -Raw $env:RAW -Items "alpha","beta","gamma"')
  contains "兩個名稱時說明只能選一個" "$out" "-Target 只能選一個"
  RAW='delta' librc 'Resolve-OpsPickOne -Flag "-Target" -Raw $env:RAW -Items "alpha","beta","gamma"' </dev/null; expect "不認得的名稱結束碼 2" 2 $?

  echo "[LIB v7] Assert-OpsTty 收呼叫端的修法；不給就沿用通用句"
  librc 'Assert-OpsTty -Fix "FIXX"' </dev/null; expect "給修法時仍回 2" 2 $?
  out=$(host_text '' 'Assert-OpsTty -Fix "改用 -Pick alpha"')
  contains "給修法時印出那句修法" "$out" "    改用 -Pick alpha"
  case "$out" in *改用選項或參數*) verdict ng "給了修法不該再印通用句" ;; *) verdict ok "給了修法就不印通用句" ;; esac
  out=$(host_text '' 'Assert-OpsTty')
  contains "不給修法時印通用句" "$out" "改用選項或參數傳入所需的值，或在終端機中執行"
  out=$(host_text '' 'Write-Usage')
  contains "-Help 寫出結束碼" "$out" "結束碼：0 完成、1 失敗或操作者取消、2 用法錯誤"

  echo "[LIB v6] 子命令選單就是一次 Select-OpsOne"
  out=$(host_text 'q\n' 'Invoke-OpsMenu')
  contains "選單有標題行「要做什麼？（q 取消）」" "$out" "要做什麼？（q 取消）"
  contains "選單的輸入行是「輸入編號：」" "$out" "輸入編號："
  case "$out" in *選擇編號*) verdict ng "選單不該再印「選擇編號」" ;; *) verdict ok "選單不再印「選擇編號」" ;; esac
  out=$(host_text '9\nq\n' 'Invoke-OpsMenu')
  contains "選單輸入越界編號說明後重問" "$out" "無效的選項：9"

  echo "[LIB] 選單行只答「做什麼、要不要確認」：無旗標、80 欄內；旗標細節留在 -Help"
  # 中文經 5.1 管線會走樣：覆寫 Write-Host，把選單行以 UTF-8 寫進檔案再檢查
  mf="$tmp/menu-lines-$ver.txt"
  # menu_lines [前置片段]：跑選單（q 取消），印出抓到的選單行；前置片段可替換子命令表
  menu_lines() {
    rm -f "$mf"
    printf 'q\n' | MF="$TMPW/menu-lines-$ver.txt" lib "function Write-Host { param(\$Object, [switch]\$NoNewline) if (-not \$NoNewline) { [IO.File]::AppendAllText(\$env:MF, \"\$Object\`n\", [Text.UTF8Encoding]::new(\$false)) } }; ${1:-}; Invoke-OpsMenu" >/dev/null
    # 只留清單列：標題行不是選單行
    grep -E '^ +[0-9]+\) ' "$mf" 2>/dev/null
  }
  check_menu_lines "$(menu_lines)"
  case "$(menu_lines)" in *"[需確認]"*) verdict ng "hello 不需確認，不該標 [需確認]" ;; *) verdict ok "hello 沒有標 [需確認]" ;; esac
  # 需確認欄：Confirm 欄位決定；有任一列時其餘列補同寬空白，全表都沒有就不留欄
  out=$(menu_lines '$Script:SubCommands = [ordered]@{ alpha = @{ Desc = "x"; Fn = "f" }; beta = @{ Desc = "y"; Fn = "f"; Confirm = $true } }')
  contains "Confirm 列印出 [需確認]" "$out" "  2) beta       [需確認] y"
  contains "其餘列補同寬空白" "$out" "  1) alpha               x"
  expect "全表沒有 Confirm 時不留欄" "  1) alpha      x" "$(menu_lines '$Script:SubCommands = [ordered]@{ alpha = @{ Desc = "x"; Fn = "f" } }')"
  # 比對手寫的說明（ASCII 片段）：Get-Help 語法段會自動產生 [-Pick] [-WhatIf]，只找旗標名會恆真
  cli $nul -Help
  contains "-Help 仍說明 -Pick 的用法" "$OUT" "-Pick alpha,gamma"
  contains "-Help 仍示範 hello 的 -WhatIf" "$OUT" "hello -Pick beta -WhatIf"

  echo "[LIB v3] Resolve-OpsPick（名稱整串精確比對，輸出與 Select-OpsMulti 同形）"
  rp() {  # rp <值>：RP_OUT 為回傳的編號（逗號串接）
    RP_OUT=$(RAW="$1" lib '"RESULT=" + ((@(Resolve-OpsPick -Flag "-Pick" -Raw $env:RAW -Items "alpha","beta","gamma")) -join ",")' </dev/null | sed -n 's/.*RESULT=//p' | tail -1)
  }
  rp 'gamma,alpha'; expect "輸出遞增，不照輸入順序" "1,3" "$RP_OUT"
  rp 'beta,beta'; expect "重複的名稱只出現一次" "2" "$RP_OUT"
  out=$(RAW='alph' lib 'Resolve-OpsPick -Flag "-Pick" -Raw $env:RAW -Items "alpha","beta","gamma"' </dev/null)
  contains "錯誤訊息列出可用的名稱（逗號串接）" "$out" "alpha,beta,gamma"

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
