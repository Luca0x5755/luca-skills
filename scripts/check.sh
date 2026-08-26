#!/usr/bin/env bash
# 不變量檢查。CLAUDE.md 裡的每一條規則，在這裡都要有對應的檢查。
# 沒有檢查的規則不是規則，是願望。
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "  ✗ $*"; fail=1; }
ok()  { echo "  ✓ $*"; }

list_dirs() { [ -d "$1" ] && find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort || true; }

core=$(list_dirs skills/core)
draft=$(list_dirs skills/draft)
archive=$(list_dirs skills/archive)

echo "[1] 每個技能資料夾都有 SKILL.md，且 name 與資料夾名一致"
for bucket in core draft archive; do
  for n in $(list_dirs "skills/$bucket"); do
    f="skills/$bucket/$n/SKILL.md"
    [ -f "$f" ] || { err "$bucket/$n 沒有 SKILL.md"; continue; }
    name=$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '\r')
    desc=$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1 | tr -d '\r')
    [ "$name" = "$n" ] || err "$f: name=\"$name\" 與資料夾名 \"$n\" 不符"
    [ -n "$desc" ] || err "$f: 缺 description"
  done
done
[ $fail -eq 0 ] && ok "共 $(echo "$core" | grep -c . ) 個 core 技能"

echo "[2] core 技能全部在 README.md 有連結"
for n in $core; do
  grep -qF "(./skills/core/$n/SKILL.md)" README.md || err "README.md 缺少 $n 的連結"
done

echo "[3] draft 技能全部在 README.md 有連結（試用中小節）；archive 不得出現"
for n in $draft; do
  grep -qF "(./skills/draft/$n/SKILL.md)" README.md || err "README.md 缺少試用技能 $n 的連結"
done
for n in $archive; do
  grep -qF "skills/archive/$n" README.md && err "README.md 不該提到已封存技能 $n"
done

echo "[4] plugin.json 的 skills 陣列 == core 集合"
declared=$(sed -n 's|.*"\./skills/core/\([^"]*\)".*|\1|p' .claude-plugin/plugin.json | sort)
if [ "$declared" != "$core" ]; then
  err "plugin.json 與 skills/core 不一致"
  diff <(echo "$core") <(echo "$declared") | sed 's/^/      /'
fi

echo "[5] plugin.json 與 package.json 的 version 相等"
pv=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' package.json | head -1)
gv=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .claude-plugin/plugin.json | head -1)
[ "$pv" = "$gv" ] || err "version 不同步：package.json=$pv, plugin.json=$gv"

echo "[6] 路由器 ask-luca 提到每一個 core 技能"
for n in $core; do
  [ "$n" = "ask-luca" ] && continue
  grep -qF "/$n" skills/core/ask-luca/SKILL.md || err "ask-luca 沒有提到 /$n — 路由器在說謊"
done

echo "[7] description 用繁體中文（core 與 draft；archive 不受約束）"
for bucket in core draft; do
  for n in $(list_dirs "skills/$bucket"); do
    f="skills/$bucket/$n/SKILL.md"
    [ -f "$f" ] || continue
    desc=$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1 | tr -d '\r')
    # 沒有任何 CJK 字元的 description 就是英文寫的
    echo "$desc" | grep -qP '[\x{4e00}-\x{9fff}]' || err "$f: description 不是中文 —「$desc」"
  done
done

echo "[8] hooks/ 每支 hook 都有對應測試且跑綠；hook 寫 log 用 >>，不用 tee"
for h in hooks/*.sh; do
  b=$(basename "$h")
  case "$b" in test-*) continue ;; esac
  t="hooks/test-$b"
  if [ ! -f "$t" ]; then err "$b 沒有對應測試 $t — 沒有檢查的 hook 會靜默腐爛"; continue; fi
  bash "$t" >/dev/null 2>&1 || err "$t 未過 — 跑 bash $t 看細節"
done
grep -lE '\btee\b' hooks/*.sh >/dev/null 2>&1 && err "hook 用 tee 寫 log 會把訊息漏進 stdout — 改用 >>：$(grep -lE '\btee\b' hooks/*.sh | tr '\n' ' ')"

echo "[9] 每個 core 與 draft 技能都出現在 flow.svg 或 toolbox.svg 其中之一"
for n in $core $draft; do
  grep -qF "/$n" assets/flow.svg 2>/dev/null || grep -qF "/$n" assets/toolbox.svg 2>/dev/null \
    || err "技能 $n 不在任何一張圖上 — 補進 assets/flow.svg 或 assets/toolbox.svg"
done

echo
if [ $fail -eq 0 ]; then echo "全部通過。"; else echo "檢查未通過，見上列 ✗。"; fi
exit $fail
