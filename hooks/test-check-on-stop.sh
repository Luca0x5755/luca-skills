#!/usr/bin/env bash
# check-on-stop.sh 的回歸規格。四條路徑，每條在暫存假 repo 裡搭場景：
# 有 payload.cwd 時測實際工作樹，無 cwd 時保留從 hook 位置定位的相容行為。
# 執行：bash hooks/test-check-on-stop.sh（scripts/check.sh 會跑）
set -u
cd "$(dirname "$0")"
HOOK="$PWD/check-on-stop.sh"
task_command=$(jq -r ' .hooks.Stop[0].hooks[0].command ' ../.claude/settings.json)

fail=0

# run_case <名稱> <payload> <表面髒?0/1> <check綠?0/1> <want ALLOW|BLOCK>
run_case() {
  local name="$1" payload="$2" dirty="$3" green="$4" want="$5"
  local tmp; tmp=$(mktemp -d)
  (
    cd "$tmp" || exit 9
    git init -q
    mkdir hooks scripts skills
    cp "$HOOK" hooks/
    if [ "$green" = 1 ]; then
      printf '#!/usr/bin/env bash\nexit 0\n' > scripts/check.sh
    else
      printf '#!/usr/bin/env bash\necho "  ✗ 假違規"\nexit 1\n' > scripts/check.sh
    fi
    echo x > skills/probe.md
    if [ "$dirty" = 0 ]; then
      git add skills scripts hooks
      git -c user.email=t@t -c user.name=t commit -qm fixture
    fi
    printf '%s' "$payload" | bash hooks/check-on-stop.sh >/dev/null 2>&1
  )
  local code=$?
  local got=ALLOW
  [ "$code" = 2 ] && got=BLOCK
  if [ "$got" = "$want" ]; then
    printf '  ✓ %-5s %s\n' "$want" "$name"
  else
    printf '  ✗ want=%s got=%s(exit %s)  %s\n' "$want" "$got" "$code" "$name"
    fail=1
  fi
  rm -rf "$tmp"
}

run_case "stop_hook_active=true 防迴圈：即使髒且紅也放行" '{"stop_hook_active":true}' 1 0 ALLOW
run_case "表面乾淨：check 紅也放行（沒動技能就不歸它管）"  '{}'                        0 0 ALLOW
run_case "表面髒且 check 紅：擋下，不准收工"                '{}'                        1 0 BLOCK
run_case "表面髒但 check 綠：放行"                          '{}'                        1 1 ALLOW

# hook 在主樹，payload 指向紅著的 linked worktree 與其子目錄。
task_tmp=$(mktemp -d)
git init -q "$task_tmp/main"
mkdir -p "$task_tmp/main/hooks" "$task_tmp/main/scripts" "$task_tmp/main/skills"
cp "$HOOK" "$task_tmp/main/hooks/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$task_tmp/main/scripts/check.sh"
printf 'seed\n' > "$task_tmp/main/skills/probe.md"
git -C "$task_tmp/main" add hooks scripts skills
git -C "$task_tmp/main" -c user.email=t@t -c user.name=t commit -qm seed
git -C "$task_tmp/main" worktree add -qb worker "$task_tmp/worker"
printf '#!/usr/bin/env bash\nexit 1\n' > "$task_tmp/worker/scripts/check.sh"
printf 'changed\n' >> "$task_tmp/worker/skills/probe.md"
for task_cwd in "$task_tmp/worker" "$task_tmp/worker/skills"; do
  jq -n --arg d "$task_cwd" '{cwd:$d}' | (
    export CLAUDE_PROJECT_DIR="$task_tmp/main"
    cd "$task_tmp/worker/skills" || exit 9
    bash -c "$task_command"
  ) >/dev/null 2>&1
  code=$?
  if [ "$code" = 2 ]; then echo '  ✓ BLOCK payload cwd 的紅工作樹'; else echo '  ✗ 工作樹 check 未擋'; fail=1; fi
done
rm -rf "$task_tmp"

exit $fail
