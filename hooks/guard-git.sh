#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks git commands the repo's skills forbid.
# Contract: exit 2 = block the tool call; stderr goes back to the model as the reason.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() { printf '%s\n' "$1" >&2; exit 2; }

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+add[[:space:]]+([^;|&]*[[:space:]])?(-A|--all)([[:space:]]|;|$)' \
   || printf '%s' "$cmd" | grep -qE 'git[[:space:]]+add[[:space:]]+\.([[:space:]]|;|$)'; then
  deny "Blocked: bulk 'git add'. The staging area is a boundary the user draws — never stage everything on their behalf. Stage specific files the user asked for, or report what is unstaged and ask."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[^;|&]*[[:space:]](-f|--force)'; then
  deny "Blocked: force push. A rejected push means the remote has history you have not seen. Report the situation; forcing is the user's call, typed by the user."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+reset[^;|&]*--hard'; then
  deny "Blocked: 'git reset --hard' discards work irreversibly. Say what you want to undo and why; the user decides. For inspecting a state, use 'git stash' or a new branch instead."
fi

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit[^;|&]*[[:space:]](--no-verify|-n)([[:space:]]|;|$)'; then
  deny "Blocked: commit with hooks bypassed. A failing hook is a signal to fix, not to mute. Investigate the failure; bypassing is the user's call."
fi

exit 0
