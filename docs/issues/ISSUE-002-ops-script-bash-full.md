# 把 `/ops-script` 的 bash 骨架補齊成完整共用段

## Done when

- `skills/draft/ops-script/skeleton.sh` 的共用段升為 `ops-lib v2`，新增：
  - `step`：步驟標題。
  - 結果計數 `pass`／`fail`／`warn`／`skip`，結尾印總表；有任何 `fail` 時結束碼為 1。
  - 多選器：輸入「1 3 5-7」切換勾選，`a` 全選、`n` 全不選、Enter 確定；大小寫皆接受；越界編號忽略；一個都沒選就按 Enter 等於取消。
- 以上函式可在 `SKELETON_LIB=1` 下載入，餵 here-string 驗證至少三種輸入：「1 3 5-7」、「A」、空輸入，結果符合上述語意。
- 示範子命令 `hello` 實際用到多選器與結果總表。
- `SKILL.md`（或其參考檔）補上：
  - 共用段維護規則：只改骨架、改了升版號、再同步到每支腳本；同一專案出現兩個版號即表示有一支沒同步。
  - `set -e` 陷阱清單：`read` 讀到輸入結尾、`grep -q` 遇上 pipefail、`-u` 下的空陣列、`local x=$(cmd)` 吞掉失敗。
  - 骨架需要 bash 4.3 以上（若用了 nameref）。
- `bash -n` 與 shellcheck（若有）乾淨；`bash scripts/check.sh` 全綠。

## Context

延續 ISSUE-001 完成後的骨架。共用段逐字複製、不抽共用檔的理由見 `docs/adr/0002-ops-script-shared-helpers-are-copied-verbatim-into-each-script.md`。

## Blocked by

Blocked by: ISSUE-001-ops-script-tracer.md

## Notes

- 多選器語意以本票為準，不要另外參考其他版本。
- 不得出現任何實際專案、服務或外部專案的名稱。
