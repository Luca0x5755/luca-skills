#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks git commands the repo's skills forbid.
# Contract: exit 2 = block the tool call; stderr goes back to the model as the reason.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() { printf '%s\n' "$1" >&2; exit 2; }

# Rules match only at command position (line start or after && || ; | $( ),
# so prose *mentioning* a forbidden command — PR bodies, commit messages,
# markdown backticks — does not trip them.
P='(^|&&|\|\||[;|]|\$\()[[:space:]]*'

if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+add[[:space:]]+([^;|&]*[[:space:]])?(-A|--all)([[:space:]]|;|\)|$)" \
   || printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+add[[:space:]]+\.([[:space:]]|;|\)|$)"; then
  deny "Blocked: bulk 'git add'. The staging area is a boundary the user draws — never stage everything on their behalf. Stage specific files the user asked for, or report what is unstaged and ask."
fi

if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+push[^;|&]*[[:space:]](-f|--force)"; then
  deny "Blocked: force push. A rejected push means the remote has history you have not seen. Report the situation; forcing is the user's call, typed by the user."
fi

# 'git reset --hard': only the exact form 'git reset --hard HEAD' passes — it
# drops uncommitted changes without moving the branch pointer (the /refactor
# retreat). Any other target (bare, HEAD~1, a sha) rewrites history → blocked.
if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+reset[^;|&]*--hard"; then
  if printf '%s\n' "$cmd" | tr ';&|' '\n' | sed -E 's/^[[:space:]]*(\$\()?[[:space:]]*//' \
     | grep -E "^git[[:space:]]+reset([[:space:]]|$)" | grep -e '--hard' \
     | grep -qvE "^git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+HEAD[[:space:]]*$"; then
    deny "Blocked: 'git reset --hard' with any target other than exactly HEAD discards commits irreversibly. Allowed form: 'git reset --hard HEAD' (drops uncommitted changes only, e.g. the /refactor retreat). Moving the branch pointer is the user's call."
  fi
fi

if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+commit[^;|&]*[[:space:]](--no-verify|-n)([[:space:]]|;|\)|$)"; then
  deny "Blocked: commit with hooks bypassed. A failing hook is a signal to fix, not to mute. Investigate the failure; bypassing is the user's call."
fi

exit 0
