#!/usr/bin/env bash
# 把 skills/core 與 skills/draft 的技能連進代理的個人技能目錄。
# draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
# 沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。
# archive 不連。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。
#
#   bash scripts/install.sh            # Claude Code（預設）
#   bash scripts/install.sh copilot    # GitHub Copilot
#   bash scripts/install.sh all        # 兩邊都裝
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-claude}"

# Git Bash / MSYS 的 ln -s 會退化成「複製目錄」而不是建連結，
# 複製品不會跟著 repo 更新 —— 靜默地裝出一份會過期的技能。
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "偵測到 Git Bash / MSYS：這裡的 ln -s 會複製而非連結。" >&2
    echo "改用 PowerShell：.\\scripts\\install.ps1 $target" >&2
    exit 1 ;;
esac

case "$target" in
  claude)  agents="claude" ;;
  copilot) agents="copilot" ;;
  all)     agents="claude copilot" ;;
  *)       echo "用法：install.sh [claude|copilot|all]" >&2; exit 2 ;;
esac

# 代理各自的個人技能目錄。Copilot 另外也讀 ~/.agents/skills，
# 但兩個都連會讓同一個技能被載入兩次，所以只挑一個。
dest_for() {
  case "$1" in
    claude)  echo "$HOME/.claude/skills" ;;
    copilot) echo "$HOME/.copilot/skills" ;;
  esac
}

for agent in $agents; do
  dest="$(dest_for "$agent")"
  mkdir -p "$dest"

  # 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡
  if [ -L "$dest" ]; then
    resolved="$(readlink -f "$dest")"
    case "$resolved" in
      "$repo"*) echo "$dest 指向本 repo（$resolved）。移除它再重跑。" >&2; exit 1 ;;
    esac
  fi

  echo "→ $agent : $dest"
  for bucket in core draft; do
    dir="$repo/skills/$bucket"
    [ -d "$dir" ] || continue
    for skill in "$dir"/*/; do
      [ -d "$skill" ] || continue
      name="$(basename "$skill")"
      rm -rf "$dest/$name"
      ln -s "${skill%/}" "$dest/$name"
      echo "  linked [$bucket] $name"
    done
  done
  echo
done

case " $agents " in
  *" claude "*) echo "Claude Code：重開後輸入 /ask-luca 確認。" ;;
esac
case " $agents " in
  *" copilot "*)
    echo "Copilot：重開後問「有哪些 skills 可以用？」確認。"
    echo "注意：Copilot 不支援 disable-model-invocation，編排型技能"
    echo "（implement、to-tickets…）在那邊會變成代理可自行呼叫。"
    ;;
esac
