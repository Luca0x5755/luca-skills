#!/usr/bin/env bash
# Usage: check-issues.sh <base-sha>
# Fails when the branch's net change adds files under docs/issues/ (local issues live and die on one branch).
# Fails closed: a bad base or a git error is exit 2, never a silent pass.

base="${1:-}"
if [ -z "$base" ] || ! git rev-parse --verify -q "$base^{commit}" >/dev/null; then
  echo "issues-check: cannot resolve base commit '$base'. Pass the PR's base sha: check-issues.sh <base-sha>." >&2
  exit 2
fi

added=$(git -c core.quotepath=false diff --diff-filter=A --name-only "$base...HEAD" -- ':(top)docs/issues') || {
  echo "issues-check: git diff against '$base' failed (shallow checkout? unrelated history?). The workflow must check out with fetch-depth: 0." >&2
  exit 2
}

if [ -n "$added" ]; then
  {
    echo "issues-check: this branch adds issue files under docs/issues/ that are still present:"
    while IFS= read -r f; do printf '  %s\n' "$f"; done <<<"$added"
    echo "Local issues are branch-scoped: created and finished on one branch, then deleted."
    echo "Finish each one (its ticket goes in the commit that implements it) and 'git rm' it,"
    echo "or move work that will outlive this branch to the real tracker."
  } >&2
  exit 1
fi
