# Seed document template

The reader is the user, editing the seed before a restart; the restart's interview then walks it chapter by chapter. The body follows `/to-spec`'s sections so the edited seed feeds `/grill-with-docs` → `/to-spec` without reshaping. Only the Why paragraphs are drafted; everything else is original text with marks beside it, never inside it.

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

## <user goal, in the user's words>

### Why
草擬：<sentence> [<source: spec, story or commit>] <sentence> [<source>] …

> <each original passage the draft drew on, verbatim, with its source>

### 範圍
<original text, verbatim, with source> ｜ 未記，請你補

### 承諾
舊:<ID> — <original promise text, verbatim>
⚠ <solution tokens in it: route, screen, column, endpoint, library> (line omitted when none)
<stability> ｜ <origin> ｜ <layer>

### 成功指標
<original text, verbatim, with source> ｜ 未記，請你補

### 範圍外
<original text, verbatim, with source> ｜ 未記，請你補

### 待解問題
- <one question per entry above that the restart must settle>

## 名詞與規則
### <glossary term, or business rule no promise holds>
> <definition and _Avoid_ line, or the rule's text, verbatim, with source>
<stability> ｜ <origin> ｜ <layer>

### 待解問題
- <…>

## 分支改寫的 main 承諾
### 舊:<ID>
- 改前：<main's text, verbatim>
- 改後：<branch's final text, verbatim>
- 目的：<quote with source> ｜ 未記
- 提交：<commits>

## 附錄 A：放棄的做法
### <decision, one per reversal or abandoned implementation choice>
- 走過的路：<what was decided>
- 為什麼放棄：<quote with source> ｜ 未記
- 提交：<commits>
- 層：UI ｜ 資料模型 ｜ 架構・API

## 附錄 B：偏離時間線
| 日期 | 提交 | 層 | 原本 → 改成 | 理由 |
| --- | --- | --- | --- | --- |
<every reversal and every tweak to the built product, oldest first; the drift point's row carries ◆; a tweak's row says 微調 and carries its stated purpose>
```

## Mark rules

- **Draft** — only the Why is drafted, by user goal, merging needs the branch scattered across several specs' Why. Every sentence ends on its source; a sentence with no source is left out. The originals it drew on sit beneath it, so the user can check every sentence against its evidence.
- **Stability** is `穩定` or `改過 <n> 次（<commit> → <commit> → …）`. It counts edits to this entry's own text, not to decisions that merely cite it — a count anyone can recompute from `git log -p`. Which edits were reversals is the timeline's job.
- **⚠** lists tokens, not judgements. A promise naming a route or a column is flagged even when the token looks harmless; the user decides what stays. Test and verification references (`驗證：…`) are traceability, not solution words.
- **Origin** is `初始需求（<first spec or story that held it>）` when the entry, or its need, already exists in the branch's first spec or story; `新增需求（<spec>）` when a later spec opens a new need.
- **Layer** is the reversal layer; `層別未定（<why>）` is the honest tag for a passage mixing intent and solution — a promise bundling a field, a toggle and a rule. Keep it whole; the user splits it.
- **Reasons and purposes** are a quote with its source, or `未記`.
- **待解問題** asks; it never answers. "Is this still the need, without the account page?" — not a rewritten promise.
