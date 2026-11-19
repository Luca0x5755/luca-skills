# Seed document template

The reader is the user, editing the seed before a restart; the restart's interview then walks it entry by entry. Every entry keeps its original text and adds marks beside it, never inside it.

```markdown
# 設計回收：<branch>

<one line: start commit, branch tip, date of salvage>
<document locations used — recorded in docs/agents/ or inferred, and how>
<skipped paths with the reason>

## 偏離摘要
<the drift point in one sentence: which spec or decision, which commit, what friction it started from>
| 層 | 翻案數 |
| --- | --- |
| 故事 / 概念 / 規則 / UI / 資料模型 / 架構・API / 流程 | <n> |

## 意圖
### <story, scenario, term or rule name>
> <original text, verbatim>

- 穩定度：穩定 ｜ 改過 <n> 次（<commit> → <commit> → …），最後版本見上
- 做法字眼：無 ｜ <each solution token found: route, screen, column, endpoint, library>
- 來源：初始需求（<first spec or story that held it>） ｜ 新增需求（<spec>） ｜ 已建成品的摩擦（<spec and commit>） ｜ main 既有，分支改寫（<first commit>）
- 層別：<layer> ｜ 層別未定（<why>）
- 待決：<the open question this entry poses for the restart>

## 放棄的做法
### <decision, one per reversal or abandoned implementation choice>
- 走過的路：<what was decided>
- 為什麼放棄：<stated reason, quoted where possible>
- 提交：<commits>
- 層：UI ｜ 資料模型 ｜ 架構・API

## 偏離時間線
| 日期 | 提交 | 層 | 原本 → 改成 | 理由 |
| --- | --- | --- | --- | --- |
<every reversal, oldest first; the drift point's row carries ◆>
```

## Tag rules

- **穩定度** counts edits to this entry's own text, not to decisions that merely cite it — a count anyone can recompute from `git log -p`. Which edits were reversals is the timeline's job.
- **做法字眼** lists tokens, not judgements. A story naming a route or a column is flagged even when the token looks harmless; the user decides what stays. Test and verification references (`驗證：…`) are traceability, not solution words.
- **來源** is 初始需求 when the entry, or its need, already exists in the branch's first spec or story; 新增需求 when a later spec opens a new need; 已建成品的摩擦 when the introducing spec's Why starts from what was already built; main 既有，分支改寫 for an entry that existed on `main` before the branch.
- **理由** in the timeline and under 放棄的做法 is a quote with its source, or `未記`.
- **層別未定** is the honest tag for a passage mixing intent and solution — a promise that bundles a field, a toggle and a rule. Keep it whole; the user splits it.
- **待決** asks; it never answers. "Is this still the need, without the account page?" — not a rewritten story.
