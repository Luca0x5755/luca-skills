#!/usr/bin/env bash
# 不變量檢查。CLAUDE.md 裡的每一條規則，在這裡都要有對應的檢查。
# 沒有檢查的規則不是規則，是願望。
# [8]、[11] 是 hook 與安裝器測試，住在 scripts/test-tooling.sh — 編號共用，這裡留空號。
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

echo "[9] 每個 core 與 draft 技能都出現在 flow.svg 或 toolbox.svg 其中之一"
for n in $core $draft; do
  grep -qF "/$n" assets/flow.svg 2>/dev/null || grep -qF "/$n" assets/toolbox.svg 2>/dev/null \
    || err "技能 $n 不在任何一張圖上 — 補進 assets/flow.svg 或 assets/toolbox.svg"
done

echo "[10] hook 三方對齊：settings.json ↔ hooks/ 目錄 ↔ HOOKS.md，缺一即紅"
if [ ! -f hooks/HOOKS.md ]; then
  err "hooks/HOOKS.md 不存在 — hook 地圖是規則的一部分"
else
  for h in hooks/*.sh; do
    b=$(basename "$h")
    case "$b" in test-*) continue ;; esac
    grep -qF "hooks/$b" .claude/settings.json || err "$b 在 hooks/ 但沒掛進 .claude/settings.json"
    grep -q "^## $b" hooks/HOOKS.md || err "$b 在 hooks/ 但 HOOKS.md 沒有它的條目（## $b）"
  done
  for b in $(sed -n 's/^## \(.*\.sh\)$/\1/p' hooks/HOOKS.md); do
    [ -f "hooks/$b" ] || err "HOOKS.md 記載 $b，但 hooks/$b 不存在 — 地圖在說謊"
  done
  for b in $(grep -o 'hooks/[a-z-]*\.sh' .claude/settings.json | sed 's|hooks/||' | sort -u); do
    [ -f "hooks/$b" ] || err "settings.json 掛載 $b，但 hooks/$b 不存在 — 掛載在說謊"
  done
fi

echo "[12] setup-skills 的議題檢查模板：檔案在、SKILL.md 或 CHECKS.md 有引用、workflow 以 base.sha 呼叫腳本、測試跑綠"
d=skills/core/setup-skills
for f in issues-check.yml check-issues.sh; do
  [ -f "$d/$f" ] || { err "$d/$f 不存在 — setup-skills Section F 要複製它"; continue; }
  grep -qF "$f" "$d/SKILL.md" "$d/CHECKS.md" 2>/dev/null || err "$d/SKILL.md 與 CHECKS.md 都沒有提到 $f — 模板沒人會裝"
done
grep -q 'check-issues\.sh' "$d/issues-check.yml" 2>/dev/null && grep -q 'base\.sha' "$d/issues-check.yml" 2>/dev/null \
  || err "$d/issues-check.yml 沒有以 base.sha 呼叫 check-issues.sh — 檢查會失明"
bash scripts/test-issues-check.sh >/dev/null 2>&1 || err "scripts/test-issues-check.sh 未過 — 跑 bash scripts/test-issues-check.sh 看細節"

echo "[13] setup-skills 的真相地圖檢查模板：檔案在、SKILL.md 或 CHECKS.md 有引用、workflow 呼叫腳本、測試跑綠"
d=skills/core/setup-skills
for f in truth-map-check.yml check-truth-map.sh; do
  [ -f "$d/$f" ] || { err "$d/$f 不存在 — setup-skills Section G 要複製它"; continue; }
  grep -qF "$f" "$d/SKILL.md" "$d/CHECKS.md" 2>/dev/null || err "$d/SKILL.md 與 CHECKS.md 都沒有提到 $f — 模板沒人會裝"
done
grep -q 'check-truth-map\.sh' "$d/truth-map-check.yml" 2>/dev/null \
  || err "$d/truth-map-check.yml 沒有呼叫 check-truth-map.sh — 檢查會失明"
bash scripts/test-truth-map-check.sh >/dev/null 2>&1 || err "scripts/test-truth-map-check.sh 未過 — 跑 bash scripts/test-truth-map-check.sh 看細節"

echo "[14] setup-skills 的 capability 檔形狀：五部分齊、寫進 domain.md、只有一個家；SKILL.md 精瘦、F／G 細節在 CHECKS.md"
d=skills/core/setup-skills
shape=$d/capability-shape.md
retired='<ID> — retired：<理由>'
if [ ! -f "$shape" ]; then
  err "$shape 不存在 — capability 檔形狀沒有家"
else
  for part in '現況' '服務對象' \
              '## 規格章節' '- `<合訂本路徑>` <標題全文去掉標記>' '`docs/03_architecture_design.md`' '`docs/05_frontend_spec.md`' \
              '## Promises' '<ID> — <行為>' "$retired" '行首的 `- ` 可有可無' \
              '## 驗證' '選用'; do
    grep -qF -- "$part" "$shape" || err "$shape 缺少「$part」— 形狀不完整"
  done
fi
grep -F 'capability-shape.md' "$d/SKILL.md" | grep -F 'docs/agents/domain.md' >/dev/null \
  || err "$d/SKILL.md 沒有在同一行把 capability-shape.md 寫進 docs/agents/domain.md — 形狀沒人會裝"
for f in $(grep -rlF -- "$retired" skills/core skills/draft 2>/dev/null); do
  [ "$f" = "$shape" ] || err "$f 重述了 capability 檔形狀 — 形狀只住 $shape"
done
n=$(wc -l < "$d/SKILL.md")
[ "$n" -le 150 ] || err "$d/SKILL.md 有 $n 行，超過 150 — 細節往 CHECKS.md 拆"
grep -qF '(CHECKS.md)' "$d/SKILL.md" || err "$d/SKILL.md 沒有以相對路徑 (CHECKS.md) 連到檢查細節"
for sec in 'Section F' 'Section G'; do
  grep -q "^## $sec" "$d/CHECKS.md" 2>/dev/null || err "$d/CHECKS.md 沒有「## $sec」標題 — 細節沒搬過去"
  grep -qF "**$sec" "$d/SKILL.md" && err "$d/SKILL.md 仍有「**$sec」細節 — 搬走，不是複製"
done

echo "[15] to-architecture：孤兒規則交給 /setup-skills 的檢查、形狀從 domain.md 讀、清理走獨立 cut-commit"
f=skills/core/to-architecture/SKILL.md
grep -qF 'orphan and goes red' "$f" && err "$f 仍宣稱「orphan and goes red」— 改寫成由 /setup-skills 安裝的檢查擋下"
grep -qF 'blocked by the check /setup-skills installs' "$f" || err "$f 沒有說明標題標記由 /setup-skills 安裝的檢查擋下"
grep -qF 'docs/agents/domain.md' "$f" || err "$f 沒有指向 docs/agents/domain.md 讀 capability 檔形狀"
grep -qF 'cut-commit' "$f" || err "$f 沒有「改到的章節清理走獨立 cut-commit」規則"

echo "[16] frontend-spec：每頁四項、05 無打勾清單、只引用 ID、cut-commit、## Penpot 前置條件、形狀從 domain.md 讀"
f=skills/core/frontend-spec/SKILL.md
b=skills/core/frontend-spec/PAGE-BRIEF.md
# 只看 ## Shape 底下第一個 code fence 裡的頁面項目
items=$(awk '/^## Shape/{s=1} s&&/^```/{n++; if(n==2) exit; next} s&&n==1&&/^- \*\*/' "$f")
[ "$(grep -c '^- \*\*' <<<"$items")" -eq 4 ] || err "$f 的頁面範本不是恰好四項"
paste=$(grep -F "paste the page's" "$b")
for label in 'Story' 'Dominant region' 'Promise IDs' 'Boards'; do
  grep -qF -- "- **$label**" <<<"$items" || err "$f 的頁面範本缺「$label」"
  grep -qF -- "$label" <<<"$paste" || err "$b 的頁面章節貼上行沒有「$label」— 與頁面形狀不一致"
done
grep -qF 'upstream as a promise' "$f" || err "$f 沒有說可測的互動細節回上游登記成承諾"
grep -qF 'drawn on its boards' "$f" || err "$f 沒有說純視覺細節畫在 board 上"
grep -qE '^[[:space:]]*- \[[ xX]\]' "$f" && err "$f 含打勾清單行 — 05 不寫驗收清單"
grep -qF 'acceptance checklist in `05` is blocked by the check /setup-skills installs' "$f" || err "$f 沒有說明 05 的打勾清單由 /setup-skills 安裝的檢查擋下"
grep -qF 'heading missing either side is blocked by the check /setup-skills installs' "$f" || err "$f 沒有說明標題標記由 /setup-skills 安裝的檢查擋下"
grep -qF 'orphan and goes red' "$f" && err "$f 仍宣稱「orphan and goes red」"
grep -qF 'cited by ID' "$f" && grep -qF 'never restate' "$f" || err "$f 沒有「承諾只引用 ID、不重述」規則"
grep -qF 'cut-commit' "$f" && grep -qF 'Only touched pages are cleaned' "$f" || err "$f 沒有「只清改到的頁、走獨立 cut-commit」規則"
grep -qF '## Penpot' "$f" || err "$f 的前置條件沒有檢查 CLAUDE.md 的「## Penpot」標題"
grep -qF 'guard-penpot.sh' "$f" || err "$f 丟了 guard-penpot.sh 前置條件"
grep -qF '## Penpot' "$b" || err "$b 沒有把子代理指向 CLAUDE.md 的「## Penpot」"
grep -qF 'docs/agents/domain.md' "$f" || err "$f 沒有指向 docs/agents/domain.md 讀 capability 檔形狀"

echo "[17] implement 只寫進 capability 檔、形狀從 domain.md 讀；to-spec 意思改了就換新 ID"
for f in skills/core/implement/SKILL.md skills/core/implement-spec/SKILL.md skills/core/run-queue/*.md; do
  grep -qF 'consolidated spec section' "$f" && err "$f 仍有「consolidated spec section」退路 — 行為規則只寫進 capability 檔"
done
f=skills/core/implement/SKILL.md
grep -F 'docs/capabilities/<name>.md' "$f" | grep -qF 'docs/agents/domain.md' \
  || err "$f 落地行為規則那一行沒有指向 docs/agents/domain.md 讀 capability 檔形狀"
f=skills/core/to-spec/SKILL.md
for part in 'keeps its number' 'test assertion would have to change' 'retired：由 <新 ID> 取代' 'never reissued'; do
  grep -qF -- "$part" "$f" || err "$f 缺少「$part」— Promise IDs 沒區分措辭改動與意思改動"
done

echo "[18] bootstrap-truth：第 4 步照 /setup-skills Section G 安裝檢查、不深連結模板、形狀從 domain.md 讀"
d=skills/draft/bootstrap-truth
f=$d/SKILL.md
for s in 'setup-skills/SKILL.md' 'Section G' "parent of this skill's base directory" 'heading missing either side is blocked by the check /setup-skills installs' 'docs/agents/domain.md'; do
  grep -qF -- "$s" "$f" || err "$f 缺少「$s」— 第 4 步要從 base directory 上一層讀 setup-skills/SKILL.md 照 Section G 裝檢查，形狀從 domain.md 讀"
done
grep -rqiE 'two-way orphan check|orphans go red|orphan-goes-red' "$d" && err "$d 仍描述雙向孤兒檢查 — 改寫成由 /setup-skills 安裝的檢查擋下"
grep -rqE 'setup-skills/(check-truth-map\.sh|truth-map-check\.yml|CHECKS\.md|capability-shape\.md)' "$d" && err "$d 深連結進 setup-skills 資料夾的模板 — 讀整份 setup-skills/SKILL.md 照做"

echo "[19] 被追蹤的檔案與分支名不含私有名單詞（名單在 repo 外；沒有名單就略過）"
terms_file=${PRIVATE_TERMS_FILE:-$HOME/.claude/private-terms.txt}
# 名單的讀法與 hooks/guard-private-terms.sh 相同，改一邊就改另一邊。
terms=$( [ -r "$terms_file" ] && tr -d '\r' < "$terms_file" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -vE '^(#|$)' )
if [ -z "$terms" ]; then
  ok "略過：沒有名單 $terms_file"
else
  # 換行分隔的單一樣式即多個樣式；不設 LC_ALL=C，Git Bash 的 grep 搭 -iF 會 abort。
  hits=$(git ls-files -z | xargs -0 grep -liF -e "$terms" -- 2>/dev/null)
  [ -n "$hits" ] && err "這些檔案含私有名單詞 — 改寫成一般化的失效模式：$(printf '%s\n' "$hits" | tr '\n' ' ')"
  git symbolic-ref --short -q HEAD | grep -qiF -e "$terms" && err "分支名含私有名單詞 — 換一個一般化的分支名"
fi

echo "[20] CI 跑 scripts/test-tooling.sh（hook 與安裝器測試住那裡，Stop hook 不跑它們）"
[ -f scripts/test-tooling.sh ] || err "scripts/test-tooling.sh 不存在 — [8]、[11] 會沒人跑"
grep -qE '^[[:space:]]*-[[:space:]]*run:.*scripts/test-tooling\.sh' .github/workflows/check.yml 2>/dev/null \
  || err ".github/workflows/check.yml 沒有呼叫 scripts/test-tooling.sh — hook 與安裝器測試會靜默停跑"

echo
if [ $fail -eq 0 ]; then echo "全部通過。"; else echo "檢查未通過，見上列 ✗。"; fi
exit $fail
