#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

echo 'end of input cancels selection'
if HOME="$test_home" bash "$repo/scripts/install.sh" </dev/null >/dev/null 2>&1; then
  echo 'install.sh accepted end of input' >&2
  exit 1
fi

echo 'interactive selection installs only Codex without confirmation'
printf '3\n' | HOME="$test_home" bash "$repo/scripts/install.sh" >"$test_home/output.txt"
[ -L "$test_home/.agents/skills/ask-luca" ] || {
  echo 'interactive Codex installation failed' >&2
  exit 1
}
[ ! -e "$test_home/.claude/skills" ] && [ ! -e "$test_home/.copilot/skills" ] || {
  echo 'interactive Codex selection installed an unselected agent' >&2
  exit 1
}
if grep -q '確認繼續' "$test_home/output.txt"; then
  echo 'interactive selection still requested confirmation' >&2
  exit 1
fi
rm -rf "$test_home/.agents"

echo 'space-separated selection installs each selected agent once'
printf '  3  1\t3  \n' | HOME="$test_home" bash "$repo/scripts/install.sh" >"$test_home/output.txt"
[ -L "$test_home/.agents/skills/ask-luca" ] && [ -L "$test_home/.claude/skills/ask-luca" ] || {
  echo 'multi-selection did not install both selected agents' >&2
  exit 1
}
[ ! -e "$test_home/.copilot/skills" ] || {
  echo 'multi-selection installed an unselected agent' >&2
  exit 1
}
[ "$(grep -c '^→ codex :' "$test_home/output.txt")" -eq 1 ] || {
  echo 'duplicate selection installed Codex more than once' >&2
  exit 1
}
grep -q '即將安裝：codex, claude$' "$test_home/output.txt"
grep -q '^  1\. claude$' "$test_home/output.txt"
grep -q '^  2\. copilot$' "$test_home/output.txt"
grep -q '^  3\. codex$' "$test_home/output.txt"
rm -rf "$test_home/.agents" "$test_home/.claude"

echo 'invalid selections retry without installing partially selected agents'
printf '\n   \n1,3\n0\n4\n-1\n1 x\n13\n999999999999999999999999999999\n2\n' |
  HOME="$test_home" bash "$repo/scripts/install.sh" >"$test_home/output.txt"
[ "$(grep -c '請輸入一個或多個有效編號' "$test_home/output.txt")" -eq 9 ] || {
  echo 'invalid selections were not all retried' >&2
  exit 1
}
[ -L "$test_home/.copilot/skills/ask-luca" ] || {
  echo 'valid selection after errors did not install Copilot' >&2
  exit 1
}
[ ! -e "$test_home/.claude/skills" ] && [ ! -e "$test_home/.agents/skills" ] || {
  echo 'invalid selection partially installed agents' >&2
  exit 1
}
rm -rf "$test_home/.copilot"

echo 'end of input after an error cancels without installation'
if printf '1,3\n' | HOME="$test_home" bash "$repo/scripts/install.sh" >"$test_home/output.txt" 2>&1; then
  echo 'install.sh accepted end of input after an error' >&2
  exit 1
fi
grep -q '已取消安裝。' "$test_home/output.txt"
[ ! -e "$test_home/.agents/skills" ] && [ ! -e "$test_home/.claude/skills" ]

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

echo 'a collision does not block another selected agent'
if printf '3 1\n' | HOME="$test_home" bash "$repo/scripts/install.sh" >/dev/null 2>&1; then
  echo 'multi-agent installation reported success despite a collision' >&2
  exit 1
fi
[ -L "$test_home/.claude/skills/ask-luca" ] || {
  echo 'collision blocked the independent Claude installation' >&2
  exit 1
}
[ -f "$foreign_skill/sentinel.txt" ] && [ ! -e "$test_home/.agents/skills/tdd" ]
