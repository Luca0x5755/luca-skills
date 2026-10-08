#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks git commands the repo's skills forbid.
# Contract: exit 2 = block the tool call; stderr goes back to the model as the reason.

input=$(cat 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
# The commit-shape checks below ask git about the repo the command runs in.
hcwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$hcwd" ] && cd "$hcwd" 2>/dev/null

deny() { printf '%s\n' "$1" >&2; exit 2; }

# 發布例外只看實際 index；標題本身不能放行一般 main 提交。
release_bump() {
  [ -r "$msgfile" ] || return 1
  local subject target stats added removed path oldline newline pattern count=0
  subject=$(head -1 "$msgfile" | tr -d '\r')
  printf '%s\n' "$subject" | grep -qE '^Bump version to [0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$' || return 1
  target=${subject#Bump version to }
  # 路徑參數、amend、-a 等會改變被提交的集合，不能走 index-only 例外。
  printf '%s\n' "$cmd" | grep -qE "^git[[:space:]]+commit[[:space:]]+(-F[[:space:]]+|--file=)[\"']?[^\"' ;|&]+[\"']?[[:space:]]*$" || return 1
  stats=$(git diff --cached --numstat 2>/dev/null) || return 1
  [ -n "$stats" ] || return 1
  # 新增、刪除、改名與權限變更不是版本更新。
  [ -z "$(git diff --cached --summary 2>/dev/null)" ] || return 1
  while IFS=$'\t' read -r added removed path; do
    [ "$added" = 1 ] && [ "$removed" = 1 ] || return 1
    case "$path" in
      package.json|*/package.json|.claude-plugin/plugin.json)
        pattern='^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"VERSION"[[:space:]]*,?[[:space:]]*$' ;;
      pyproject.toml|*/pyproject.toml|Cargo.toml|*/Cargo.toml)
        pattern="^[[:space:]]*version[[:space:]]*=[[:space:]]*[\"']VERSION[\"'][[:space:]]*$" ;;
      *.csproj)
        pattern='^[[:space:]]*<Version>VERSION</Version>[[:space:]]*$' ;;
      *) return 1 ;;
    esac
    oldline=$(git diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path" | sed -n '/^---/d; s/^-//p' | tr -d '\r')
    newline=$(git diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path" | sed -n '/^+++/d; s/^+//p' | tr -d '\r')
    printf '%s\n' "$oldline" | grep -qE "${pattern/VERSION/[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?}" || return 1
    printf '%s\n' "$newline" | grep -qE "${pattern/VERSION/[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?}" || return 1
    # 完整版本必須等於標題，避免 0.3.0 誤放行 0.3.01。
    [ "$(printf '%s\n' "$newline" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?')" = "$target" ] || return 1
    count=$((count + 1))
  done <<< "$stats"
  [ "$count" -gt 0 ]
}

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

# Commit shape: the three /git-commit rules a machine can check. Prose asks the
# model to read that skill before committing; this fires whether it did or not.
# Cheapest first: the command string, then one git call, then a file read.
if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+commit([[:space:]]|;|\)|$)"; then
  # Short-flag cluster ending in m (-m, -am, -qm, -m"x", -mfoo) or --message. The
  # cluster may not start with F/C/c/t: those take an attached argument (-Fmsg.txt)
  # whose letters are not flags. --trailer is a message flag by another name.
  if printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+commit[^;|&]*[[:space:]](-[^-[:space:]FCct]*m|--message|--trailer)"; then
    deny "Blocked: inline commit message ('-m' / '--message' / '--trailer'). /git-commit passes the message as a file: write it with the Write tool, then 'git commit -F <path>'. An inline message gets mangled by whichever shell you guessed wrong, silently."
  fi
  # 先讀取訊息檔，供發布版本例外與 trailer 檢查共用。
  msgfile=$(printf '%s\n' "$cmd" | tr ';&|' '\n' | sed -E 's/^[[:space:]]*(\$\()?[[:space:]]*//' \
    | grep -E "^git[[:space:]]+commit([[:space:]]|$)" | head -1 \
    | grep -oE "(-F|--file)[[:space:]=]*[\"']?[^\"' ;|&]+" | head -1 | sed -E "s/^(-F|--file)[[:space:]=]*[\"']?//")
  # A command that creates its branch before committing ('git switch -c … && git commit')
  # is the skill's own pattern; only a commit landing on main/master as-is is blocked.
  if ! printf '%s\n' "$cmd" | grep -qE "${P}git[[:space:]]+(switch[^;|&]*[[:space:]](-c|--create)|checkout[^;|&]*[[:space:]]-[bB])([[:space:]]|$)"; then
    branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
    case "$branch" in
      main|master) release_bump || deny "Blocked: commit on '$branch'. Create a work branch first. The /git-release exception requires 'Bump version to <version>', a plain 'git commit -F <file>', and an index changing only version lines in package.json, .claude-plugin/plugin.json, pyproject.toml, Cargo.toml or *.csproj. Other version formats require extending the guard, not bypassing it." ;;
    esac
  fi
  # Trailers sit at line start (optionally behind a marker like the harness's 🤖);
  # a body bullet that merely mentions them starts with '- ' and passes.
  # LC_ALL=C: under a UTF-8 locale Git Bash's grep fails to match [^-] against the emoji.
  if [ -n "$msgfile" ] && [ -r "$msgfile" ] \
     && LC_ALL=C grep -qiE '^(Co-Authored-By|Claude-Session):|^[^-]*Generated with' "$msgfile" 2>/dev/null; then
    deny "Blocked: commit message carries a trailer (Co-Authored-By / Claude-Session / Generated with). /git-commit messages end at the last bullet — delete the trailer lines from the file and commit again."
  fi
fi

# Merging a PR lands code on a shared branch and can trigger deploys — the one
# button in the whole flow that nobody can un-press. 'gh pr merge' is the front
# door; a PUT to the REST merge endpoint is the same act through the back one.
if printf '%s\n' "$cmd" | grep -qE "${P}gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|;|\)|$)"; then
  deny "Blocked: merging a PR. Opening the PR is the agent's job; pressing merge is the user's, typed by the user. Report the PR URL and its check status, then stop."
fi

if printf '%s\n' "$cmd" | grep -qE "${P}gh[[:space:]]+api[^;|&]*/merge([[:space:]]|'|\"|;|\)|$)"; then
  deny "Blocked: merging a PR through the REST API. Going around 'gh pr merge' does not change what it is — the merge button belongs to the user. Report the PR URL and stop."
fi

exit 0
