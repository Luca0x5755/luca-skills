#!/usr/bin/env bash
# 把 skills/core 與 skills/draft 的技能連進 ~/.claude/skills。
# draft 也連 —— 桶的分界是「對外發佈與否」，不是「本機能不能用」。
# 沒辦法在本機叫起來的 draft，等於沒辦法被試用，等於永遠畢不了業。
# archive 不連。
# 連結後改這個 repo 的檔案會立刻生效，不需重裝。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$HOME/.claude/skills"

mkdir -p "$dest"

# 防呆：$dest 本身若指回這個 repo，會把連結寫進 repo 自己的樹裡
if [ -L "$dest" ]; then
  target="$(readlink -f "$dest")"
  case "$target" in
    "$repo"*) echo "$dest 指向本 repo（$target）。移除它再重跑。" >&2; exit 1 ;;
  esac
fi

for bucket in core draft; do
  dir="$repo/skills/$bucket"
  [ -d "$dir" ] || continue
  for skill in "$dir"/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    rm -rf "$dest/$name"
    ln -s "${skill%/}" "$dest/$name"
    echo "linked [$bucket] $name"
  done
done

echo
echo "完成。重開 Claude Code 後輸入 /ask-luca 確認。"
