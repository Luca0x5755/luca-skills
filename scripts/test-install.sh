#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

echo 'missing target is rejected'
if HOME="$test_home" bash "$repo/scripts/install.sh" >/dev/null 2>&1; then
  echo 'install.sh accepted a missing target' >&2
  exit 1
fi

echo 'all is rejected'
if HOME="$test_home" bash "$repo/scripts/install.sh" all >/dev/null 2>&1; then
  echo 'install.sh accepted the removed all target' >&2
  exit 1
fi

echo 'Codex installs into its own directory'
HOME="$test_home" bash "$repo/scripts/install.sh" codex >/dev/null
[ -L "$test_home/.agents/skills/ask-luca" ] || {
  echo 'install.sh did not create the Codex skill link' >&2
  exit 1
}
[ ! -e "$test_home/.claude/skills" ] || {
  echo 'install.sh unexpectedly installed Claude skills' >&2
  exit 1
}

rm -rf "$test_home/.agents"
foreign_skill="$test_home/.agents/skills/ask-luca"
mkdir -p "$foreign_skill"
printf 'keep me' >"$foreign_skill/sentinel.txt"

echo 'foreign same-name skill is preserved'
if HOME="$test_home" bash "$repo/scripts/install.sh" codex >/dev/null 2>&1; then
  echo 'install.sh overwrote a foreign skill' >&2
  exit 1
fi
[ -f "$foreign_skill/sentinel.txt" ] || {
  echo 'foreign skill was modified' >&2
  exit 1
}
[ ! -e "$test_home/.agents/skills/tdd" ] || {
  echo 'agent was partially installed after a collision' >&2
  exit 1
}
