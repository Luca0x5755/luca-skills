---
name: briefing
description: 把簡報圖（SVG／Mermaid）變成上台用的口頭講稿＋導讀 — 結論先行、節間串場、預期質詢與建議答法，整份寫成 briefing.md 放在圖旁。
disable-model-invocation: true
---

# Briefing

Turn presentation diagrams into what the presenter says on stage: a spoken
script plus a delivery guide — where to point, what to stress, what will be
asked. Scope is SVG and Mermaid, text formats the model reads precisely.
Raster images (PNG screenshots) are out of scope: say so instead of guessing
at pixels.

## 1. Gather

- **Diagrams.** If this session drew them, that memory is the source.
  Otherwise read the SVG/Mermaid source and reconstruct what each diagram
  claims. A label you cannot interpret from source is a question for the
  user, not a guess.
- **Audience.** Four audiences; resolve via AskUserQuestion when unclear.
  The audience sets tone, depth, and who asks what in Q&A:

  | Audience | They will probe |
  | --- | --- |
  | 業務主管／客戶 | cost, schedule, benefit, why-do-this |
  | 技術主管 | consistency of choices, sourcing, what-runs-where |
  | 標案／文件審查 | responsibility, coverage, compliance |
  | 工程師 | contracts, data, interactions, failure modes |

- **Time budget.** Default 1–2 minutes per diagram (口語約 250–400 字).
  When the user names a total duration, allocate it across diagrams and
  label every section with its estimated time.

## 2. Order

With multiple diagrams, propose a narrative order — overview → detail →
schedule is the usual spine — and list it at the top of the output for the
user to overturn. File-name order is an accident, not a narrative.

## 3. Script each diagram

Fixed skeleton, conclusion first:

1. **Bottom line** — one sentence: what this diagram proves or asks for.
2. **Visual guide** — where the eyes go first and in what order
   (「請先看左半部⋯」).
3. **2–3 key points** — expand only what supports the bottom line.
4. **Transition** — one sentence handing off to the next diagram.

Genre exceptions are few: Gantt/milestone charts narrate along the time
axis; sequence diagrams along the message flow. Everything else takes the
skeleton.

**Q&A prep, per diagram.** 2–3 likely questions with suggested answers,
asked from the audience's seat (table above). A question the diagram cannot
answer well is a defect of the diagram, not of the script — flag it as a
suggested diagram fix instead of papering over it.

**Language.** Script in Traditional Chinese, tech nouns stay English
(`Order Service`, `PostgreSQL`); all-English is fine when the audience is
engineers. Tone follows the audience: 會報敬語 for 主管／審查, plain and
direct for engineers.

## 4. Deliver

One `briefing.md` next to the diagrams — never one file per diagram:
transitions live between sections, and splitting severs them.

```
# <簡報名> 簡報講稿
敘事順序：<proposed order — 使用者可推翻>

## 開場（約 30 秒）
今天報什麼、結論是什麼。

## <圖 1 標題>（估 X 分鐘）
講稿：…
導讀：指讀順序與強調點。
預期質詢：2–3 條「問題＋建議答法」。

## <圖 N 標題>（估 X 分鐘）
…

## 總結（約 30 秒）
重點回收、下一步、請示事項。
```

A single diagram gets a single-section file: skip 開場／總結.

Before handing over, check: every diagram covered and the order stated;
every section carries its time estimate and the total matches any requested
duration; every section leads with its bottom line; every Q&A entry matches
the audience; every unanswerable question is flagged as a diagram weakness.
