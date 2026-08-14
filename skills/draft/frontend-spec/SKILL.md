---
name: frontend-spec
description: 為有 UI 的規格定前端真相：路由表與四態頁面寫進 capability 文件、style tokens 進 docs/design-system.md、.pen mockup 常駐 docs/mockup/ — 都在 feature branch 上改，與程式碼同 PR 合併。/to-spec 之後、/to-tickets 之前跑，可選。
disable-model-invocation: true
---

# Frontend Spec

Turn a spec's UI surface into frontend truth plus Pencil mockups. Runs after `/to-spec` (and `/to-architecture` if it ran), before `/to-tickets` — tickets that can cite `dashboard.pen`'s Empty frame are verifiable; "make a nice dashboard" is not.

**Optional step.** No UI in the spec → skip entirely.

**Not `/prototype`.** Prototype answers "does this interaction work" with throwaway code that gets deleted. This skill produces truth: the capability document's UI sections and `.pen` files that tickets build against. Never let a prototype graduate into a mockup — redraw the answer here.

## Truth layer, branch as staging

Edits land in the **truth layer**, on the feature branch, merging in the same PR as the code — `main` never describes UI it doesn't have:

- `docs/design-system.md` — style tokens: chosen archetype, colors, type, density. Set once via Pencil variables, shared by every screen. Extend this file; never fork per-feature tokens or restyle per page.
- `docs/specs/<capability>.md` — the Routes and Pages sections of the capability this spec touches. Touch only what this spec changes.
- `docs/mockup/<page>.pen` — durable layout truth: updated when the page changes, never redrawn from scratch per feature.

No truth layer yet (`docs/specs/` absent)? A doc-heavy legacy project goes through `/consolidate-docs` first; a young project just starts its first capability file here.

## Shape

In `docs/specs/<capability>.md`:

```markdown
## Routes
| Page | Path | Auth | One-line purpose |
| --- | --- | --- | --- |

## Pages
### <page> → `docs/mockup/<page>.pen`
- **Story**: as <role>, I want <action>, so that <goal>.
- **Dominant region**: the one question this page answers, and its one
  primary action.
- **States**: Loading / Empty / Error / Success — each is a frame in the
  .pen file. A page missing a state frame is not done.
```

## Pencil workflow — per .pen file, in order

`.pen` files are encrypted: only `pencil` MCP tools may touch them — never Read/Grep/Edit.

1. `get_app_state` (all four include flags) — no schema, no other Pencil calls.
2. `get_guidelines` — pick the guide matching the product type and the archetype `docs/design-system.md` records (choose one there first if the file is new); tokens live as shared Pencil variables.
3. Design — one screen per file, filename from the route table. Reusable components live in `components.pen`; other screens reference them, never redraw.
4. `get_screenshot` — look at the screenshot before calling a screen done. Desktop and mobile frames both; hierarchy must survive every breakpoint.

## Rules

- **The .pen file is the source of truth for layout.** The capability document carries briefs and acceptance state lists; pixels live in Pencil. Never hand-write HTML/CSS as a stand-in for a mockup.
- **Write the post-merge truth.** Routes and pages state what is true once this PR merges — no "we will", no history of what the page used to be.
- **All four states, every page.** Silent failure is not a design. An Empty state nobody drew becomes an Error state nobody handled.
- **No standards sections.** Coding conventions, browser support, API-client choices belong to the target repo's CLAUDE.md — not here.
- **Do not invent flows.** A page or interaction not settled in the spec goes back to `/grill-with-docs`, or through a `/prototype` detour if it needs a runnable answer.
- **Show the draft before writing.** Document sections first, then mockups; let the user redirect before pixels get expensive.

## Finish

Report the files edited and the `.pen` files produced, each verified by screenshot. Say the next step: `/to-tickets` — tickets cite pages and state frames by name; the truth-layer edits and mockups ride the feature branch and merge with the code.

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "The prototype already looks right, I'll reuse its code as the mockup" | Prototype code carries every shortcut it was born with. Keep the answer, redraw the design. |
| "Success state is obvious, I'll skip Empty/Error frames" | The undrawn states are where users actually live. Four frames or the page is not specced. |
| "I'll restyle this one page, it's special" | One shared token set in `docs/design-system.md`. A special page today is an inconsistent app in a month. |
| "Faster to edit the docs on main directly" | Then main describes UI that doesn't exist. The branch is the staging area; the PR is the atomic unit of truth. |
| "Screenshot looks fine in my head, no need to render it" | Layouts overlap in ways schemas don't show. Look at the screenshot before you call it done. |
