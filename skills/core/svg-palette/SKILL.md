---
name: svg-palette
description: SVG 繪圖的色盤與用色規則 — 預設靛青深淺＋橘強調，可用使用者指定色票（公司 CI 色）覆蓋。當要繪製任何 SVG 圖、挑「配色」「色票」「圖表顏色」，或使用者提供品牌色要套進圖裡時使用。
---

# SVG Palette

Color roles and rules for every SVG diagram. Palettes are defined as **roles**, not
loose swatches — any palette (including a user-supplied one) maps into the same
role slots, so swapping palettes never changes the drawing logic.

## Roles

| Role | Purpose | Default (Indigo) |
| --- | --- | --- |
| `primary-1` (darkest) | Reading spine (see Light-first) | `#28406B` |
| `primary-2` | Reading spine, second shade | `#4A648F` |
| `primary-3` | Darkest pale tier fill (`ink` text) | `#7E93B4` |
| `primary-4` | Pale tier fills, card borders | `#B9C6D9` |
| `primary-5` (lightest) | Background washes, bands, pale tier fills | `#E3EAF3` |
| `accent` | The one thing to emphasize (see accent rule) | `#E07B39` |
| `ink` | Text on light ground | `#1F2933` |
| `muted` | Secondary text, arrows, borders | `#5B6B78` |
| `line` | Gridlines, dividers | `#D9E0E6` |
| `bg` | Canvas ground | `#FFFFFF` |

## Rules

- **Light-first.** The default surface for every shape is a white card: `bg`
  fill, `line` or `primary-4` border (≥2px), `ink` title, `muted` sub-line.
  Solid `primary-1`/`primary-2` blocks are the **reading spine** — rail
  labels, header rows, at most one main node — small and few; full-width dark
  bars and full-height dark sidebars are what this rule exists to prevent.
  Clarity comes from whitespace and thin rules; legibility comes from type
  size and `ink` text, so the light grammar projects as well as the dark one.
- **One accent per diagram, thin carriers only.** The accent marks the single
  point the audience must see, carried by an edge strip, an underline, colored
  text, or a small badge — a large accent-filled block shouts instead of
  pointing. Two accents means no accent: demote one to a primary tier.
- **Depth over hue.** Distinguish categories with primary shades first —
  under light-first that means pale tiers `primary-5..3` with `ink` text.
  Reach for extra hues only when shades genuinely cannot separate the categories
  (see Fallback below).
- **Text is ink on light, white on dark.** On `primary-1`/`primary-2` fills use
  `#FFFFFF` text; on `primary-3` and lighter use `ink`. Never gray text:
  projector-measured, gray text at 60% brightness is barely legible and
  anything lighter vanishes on a bad projector.
- **No red/green semantics in solid fills.** Shapes never encode status as
  red/green (user decision, also colorblind-hostile). The one sanctioned
  exception is semantic badges (below), where the printed word carries the
  meaning.
- **Ground is white.** `bg` stays `#FFFFFF` for anything that may land on a
  slide — screenshots must paste clean into PowerPoint.

## As-Is/To-Be encoding

Three states, fixed:

- **added / changed** → `accent` on thin carriers: accent border + accent
  title text on a white card (never a solid accent fill)
- **removed / deprecated** → `primary-5` fill with `muted` dashed border
- **unchanged** → the light-first default (white card / pale tier)

When a diagram needs the four-state gap disposition (新增／演進／保留／汰換),
the three-state encoding cannot express it — use the gap-disposition badge
vocabulary below.

## Semantic badges

A badge is a small pill stamped on a block: **pale fill + dark text of the
same hue, with the word always printed on it**. The text carries the meaning;
the hue only speeds scanning — which is why badges are the one place
red/green-family hues are allowed. A vocabulary is fixed per diagram: every
badge on the diagram comes from one vocabulary, and the legend lists all of
its terms.

**Gap disposition** (目標架構圖 — what happens to each building block):

| Term | Fill | Text |
| --- | --- | --- |
| 新增 | `#DCE8F5` | `#1B4A7A` |
| 演進 | `#FAEEDA` | `#7A4A00` |
| 保留 | `#DDEFE4` | `#1E5537` |
| 汰換 | `#FAE0DC` | `#8C2A1F` |

**Sourcing** (取得方式 — how each layer is obtained): 自建／商用／混合.
Neutral styling — white fill, `primary-1` text, and on white/pale ground a
`line` border so the pill keeps its edge. No semantic hues: the terms carry
no good/bad axis, so color would only add noise.

New vocabularies reuse this mechanism (pale fill, dark same-hue text, word
always printed) rather than adding new color rules.

## Override: user-supplied palette

When the user names brand/CI colors, map them into the roles and use them
**instead of** the default — the default is only a fallback for silence.

1. Take the user's main color as the hue; generate `primary-1..5` as a
   dark-to-light ramp of that hue (keep lightness steps roughly even).
2. Take their secondary/highlight color as `accent`; if they gave only one
   color, pick a warm tone that contrasts with the ramp and say so.
3. Neutrals (`ink`/`muted`/`line`/`bg`) stay as defined here unless the user
   overrides them too.
4. Echo the mapped role table back to the user before drawing.

## Alternate themes

Use only when the user asks for that mood by name or description:

| Theme | primary-1..5 | accent |
| --- | --- | --- |
| 企業藍灰 (corporate) | `#1F4E79` `#456A8C` `#5B7C99` `#94A7B7` `#D3DDE4` | `#C9A227` |
| 深墨螢光 (tech/dark-slide) | `#2B3440` `#4A5866` `#77879A` `#A6B2BF` `#DCE2E8` | `#00B4D8` |

## Fallback: many unrankable categories

When a diagram needs 4+ categorical colors that shades cannot separate (e.g.
swimlane owners with no hierarchy), use Okabe-Ito order — colorblind-safe:
`#0072B2` `#E69F00` `#009E73` `#D55E00` `#56B4E9`. This mode has no accent:
`#E07B39` reads as a sixth category next to the Okabe-Ito oranges, so
emphasize with weight or outline instead.
