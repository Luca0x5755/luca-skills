# Research report template

The reader is the user, scanning: the answer, its confidence and where it could flip, in the first screen. The ledger serves a downstream agent and sits last as an appendix.

Readability: open every section with one orienting sentence — where the reader is, before any detail. Then short sentences, one point per sentence, plain words. When readability collides with terseness, readability wins.

```markdown
# <research question>

<one line: scope, purpose, level, comparison dimensions if declared>

## 結論
<the answer in one or two sentences — for a list: the inclusion criteria, the row count and how fresh the data is.
Confidence: 高 / 中 / 低 with a one-line reason.
Name any claim the answer leans on that only passed Refutation.>

| <sub-question> | <dimension> | <dimension> |
| --- | --- | --- |

### <sub-question>: <its conclusion as one sentence>
<only what the table cannot hold — conflicts, the conditions it holds under, anti-patterns>

## 清單
| <fields> | 來源 | 裁判 | 狀態 | 資料日期 |
| --- | --- | --- | --- | --- |

## 缺口
- <what could not be found, and why>

## 翻盤條件
| 子題 | 翻盤發現 | 查法 |
| --- | --- | --- |

## 附錄：主張帳本
| ID | 主張 | 來源 | 裁判 | 狀態 |
| --- | --- | --- | --- | --- |
| <A1> | <claim> | <URL with passage, or how to re-obtain the data> | Executable / Source / Refutation / Unverified | 成立 / 被推翻 / 未驗證 |

Refutation 由同一模型系列執行，獨立性有限。
```

## The comparison table

Present exactly when step 1 declared comparison dimensions: one row per sub-question, one column per dimension, every cell filled. A cell no evidence reached reads `查無`, and the gaps say why.

## Sub-question sections

A `###` heading states that sub-question's conclusion as a sentence, never its topic. The heading carries only `成立` claims; a claim that only passed Refutation brings its qualifier into the heading (部分成立, 依目標而定, 單一案例). `未驗證` claims stay out of headings.

The body holds what the table cannot. A sub-question with nothing beyond its table row gets no section. Without a table, every sub-question gets a section. A single-question report has none.

## IDs and citations

Ledger IDs are the sub-question letter plus a sequence number (`A1`, `B3`); a single-question report numbers plainly (`1`, `2`) and drops the `子題` column from the flip table. Body claims cite IDs in brackets — `[A1]`. Source names stay in the ledger; a body names a source only when disagreement between sources is itself the finding.

## Lists

`## 清單` appears only for a list. Each row carries its own source, grade, status and date, so the ledger holds only claims outside the list; a refuted row stays, marked 被推翻. A cell nobody could source reads `查無`.

## When evidence cannot answer

Write `現有證據無法回答` and name the single verifiable action that would settle it. "Needs further research" is an adjective, not an action. Confidence stays in three words because a percentage would claim precision the evidence lacks.

Absence is a finding: "found no reliable source on X" belongs in the gaps. Refuted claims stay in the ledger, since knowing what failed is part of the result.
