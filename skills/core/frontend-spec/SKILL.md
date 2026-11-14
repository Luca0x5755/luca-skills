---
name: frontend-spec
description: 為有 UI 的規格定前端真相：路由表、四態頁面與 style tokens 寫進前端合訂本（docs/05_frontend_spec.md，章節標能力），mockup 由子代理逐頁畫在專案的 Penpot 設計稿正本上。/to-spec 之後、/to-tickets 之前跑，可選。
disable-model-invocation: true
---

# Frontend Spec

Turn a spec's UI surface into frontend truth plus Penpot mockups. Runs after `/to-spec` (and `/to-architecture` if it ran), before `/to-tickets` — a ticket that cites the board `Dashboard · Empty · Mobile` is verifiable; "make a nice dashboard" is not.

**Optional step.** No UI in the spec → skip entirely.

**Not `/prototype`.** Prototype answers "does this interaction work" with throwaway code that gets deleted. This skill produces truth: the frontend volume's page sections and the boards tickets build against. Never let a prototype graduate into a mockup — redraw the answer here.

## Two homes for truth

- **`docs/05_frontend_spec.md`** — the consolidated frontend volume, edited on the feature branch and merged in the same PR as the code, so `main` never describes UI it doesn't have. It holds the routes table, the page sections, and a style-tokens section (chosen archetype, colors, type, density — set once as Penpot tokens, shared by every board; extend it, never fork per-feature tokens or restyle per page). Specs stay consolidated — never split pages into per-capability spec files. Touch only the sections this spec changes.
- **The design master** — the project's one Penpot file, and the source of truth for layout. It has no branches, so it may lead `main`. A board counts only when a `05` page section lists it by name; `05` is the roster. The `.penpot` snapshot in the repo may lag the master, and updating it is the user's call.

**Cross-mapping is mechanical.** Every page section this skill writes or touches in `05` names its capabilities (`### 排場頁（能力：排場）`); the owning `docs/capabilities/<name>.md` lists them back. A section naming no capability is an orphan and goes red.

No truth layer yet? An inherited legacy project goes through `/bootstrap-truth` first; a young project just starts its `05` and first capability file here.

**Precondition.** The project's `CLAUDE.md` declares its Penpot file and carries a section of Penpot operating rules. Either one missing → stop and ask the user to create the file, connect the plugin, and declare both. Opening a design file is theirs to do. The project also has `.claude/hooks/guard-penpot.sh` registered in `.claude/settings.json` — it blocks the Penpot calls that search the whole file and freeze the tab; missing or unregistered → stop and ask the user to run `/setup-skills`.

## Shape

In `docs/05_frontend_spec.md`:

```markdown
## Routes
| Page | Path | Auth | 能力 | One-line purpose |
| --- | --- | --- | --- | --- |

## Pages
### <page>（能力：<capability>）
- **Story**: as <role>, I want <action>, so that <goal>.
- **Dominant region**: the one question this page answers, and its one
  primary action.
- **Boards**: `<page> · <State> · <Desktop|Mobile>` for each of Loading /
  Empty / Error / Success — eight names, listed in full. A page missing a
  board is not done.
```

The board name is the string tickets cite, so it follows this format exactly. Light and dark are a token theme, one board serving both.

## Workflow

Drawing one page takes on the order of a hundred Penpot calls plus image exports. All of it stays inside subagents: **the main thread calls no `penpot` tool and exports no image.** Its job is the documents, the dispatching, and the roster.

1. **Draft `05`.** Show the section drafts to the user, then write them once approved. A project whose `05` has no style-tokens section yet chooses its archetype here, with the user. Done when every page in the spec has its row in the routes table, its section and its eight board names, and the style-tokens section exists.
2. **Shared foundation.** When step 1 wrote or changed the style-tokens section, or the pages need a component not yet in the design master, dispatch one subagent to set up those tokens and components before any page. Skip when the spec adds neither. Done when its report lists each token set and component as `done`.
3. **First page — the gate.** Dispatch one subagent for the first page. When it reports, stop and ask the user to review that page's boards in Penpot. The first page sets how tokens, density and the four states are expressed, so the remaining pages wait for the user's approval. Changes asked for → dispatch the correction, then ask again. Done when the user approves the page.
4. **Remaining pages.** One subagent per page, dispatched after the previous one has reported. Done when every page has a report with `stopped: none`.
5. **Reconcile the roster.** Check every board name in the `05` sections this run touched against the subagent reports. Done when each is reported `done`, or is named as undone in the final report.

### Dispatching

Fill [`PAGE-BRIEF.md`](PAGE-BRIEF.md) and pass it as the subagent's prompt.

- **Fresh, never a fork.** A fork inherits this conversation and brings its weight along.
- **One at a time.** Penpot has a single plugin connection, in one foreground browser tab.
- **One use each.** A correction or a resumption goes to a new subagent, briefed with the change list or the boards still missing.
- **Stopped means the user acts.** A report with `stopped: tab suspended` or `stopped: plugin unreachable` is a request for the user to bring the Penpot tab to the foreground. After they confirm, dispatch a new subagent for the boards that page still lacks. Any other `stopped` reason goes to the user as reported, and the run waits for their call.
- **Subagents must not invoke this skill.**

## Rules

- **Pixels live in the design master.** `05`'s page sections carry briefs and the board roster. Never hand-write HTML/CSS as a stand-in for a mockup.
- **Write the post-merge truth.** Routes and pages state what is true once this PR merges — no "we will", no history of what the page used to be.
- **All four states, every page.** Silent failure is not a design. An Empty state nobody drew becomes an Error state nobody handled.
- **Boards are updated in place.** A page that changes keeps its boards and their names; it is never redrawn beside the old ones.
- **No standards sections.** Coding conventions, browser support, API-client choices belong to the target repo's CLAUDE.md — not here.
- **Do not invent flows.** A page or interaction not settled in the spec goes back to `/grill-with-docs`, or through a `/prototype` detour if it needs a runnable answer.

## Finish

**Commit — mandatory, commit only.** Follow the `/git-commit` rules for the files this skill wrote; read `git-commit/SKILL.md` first, in the parent of this skill's base directory. Nothing written → no commit.

Report the files edited, then the boards by page: drawn, changed, and undone with the reason. Say which pages the user has reviewed — only the first was gated — and ask them to review the rest in Penpot. The design master already holds the boards; the snapshot was left alone.

Then report the next step as **one hop tagged with its trigger**: `/to-tickets` (multi-session) or `/implement` (one session).

## Rationalization table

| Excuse | Reality |
| --- | --- |
| "The prototype already looks right, I'll reuse its code as the mockup" | Prototype code carries every shortcut it was born with. Keep the answer, redraw the design. |
| "Success state is obvious, I'll skip Empty/Error boards" | The undrawn states are where users actually live. Eight boards or the page is not specced. |
| "I'll restyle this one page, it's special" | One shared token set in `05`'s style-tokens section. A special page today is an inconsistent app in a month. |
| "Faster to edit the docs on main directly" | Then main describes UI that doesn't exist. The branch is the staging area for `05`; the PR is the atomic unit of truth. |
| "It's one small fix, I'll make the Penpot call from here" | One fix is a run of calls and exports that never leave this context. Dispatch it. |
| "Two pages at once would be faster" | One plugin connection, and no run has shown two subagents can share it. One at a time. |
| "The subagent is already warm, I'll send it the next page" | It is also already full. A new page gets a new subagent. |
