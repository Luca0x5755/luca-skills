#!/usr/bin/env bash
# Stop hook: while the invariant surface has uncommitted changes, check.sh must be
# green before the agent may finish. Contract: exit 2 = keep working; stderr = why.

input=$(cat)

# Loop protection: if a previous Stop-hook block is already being handled, let go.
printf '%s' "$input" | jq -e '.stop_hook_active == true' >/dev/null 2>&1 && exit 0

hcwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$hcwd" ]; then
  if ! cd "$hcwd" 2>/dev/null; then
    echo "Blocked: cannot inspect payload cwd. Restore the working directory before finishing." >&2
    exit 2
  fi
  task_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  cd "$task_root" || exit 0
else
  cd "$(dirname "$0")/.." || exit 0
fi

# Only act when the files the invariants govern have changed.
git status --porcelain -- skills .claude-plugin README.md package.json 2>/dev/null | grep -q . || exit 0

if ! out=$(bash scripts/check.sh 2>&1); then
  {
    echo "scripts/check.sh is red with uncommitted skill changes. Fix the violations before finishing:"
    printf '%s\n' "$out" | tail -30
  } >&2
  exit 2
fi

exit 0
