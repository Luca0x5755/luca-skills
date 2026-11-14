# Page brief

The prompt for one drawing subagent. Fill every `<…>` and send the whole block. For the shared-foundation dispatch, put the tokens and components to set up where the boards go and drop the state names.

```text
Draw one page of mockups in the project's Penpot design file. You own this
page only. Do not invoke the `frontend-spec` skill.

Page: <page name>
Job: <new page | change: <the change list> | resume: only the boards listed below>
Boards:
  <page> · Loading · Desktop
  <page> · Loading · Mobile
  <… all eight, or only the missing ones on a resume>

Page section from docs/05_frontend_spec.md:
<paste the page's Story, Dominant region and Boards lines>

Style tokens: read the style-tokens section of docs/05_frontend_spec.md.

Before the first Penpot call
1. Read the Penpot operating rules section in the project's CLAUDE.md. It
   names the design file, the token sets, and the traps already paid for.
   Its rules win over anything here.
2. Call `high_level_overview` once.
3. List the boards already on this page by name. A board that exists is
   updated in place and keeps its name.

While drawing
- Reuse the file's components and tokens.
- Name each board exactly as listed above. Light and dark are a token theme:
  one board serves both.
- Return ids and names from `execute_code`, leaving shape trees in Penpot.
- Find shapes on the current page only: `penpot.currentPage.getShapeById(id)`,
  or `penpot.currentPage.findShapes({ name | nameLike | type })`, adding
  `.filter(pred)` when a predicate is needed. Leave `penpotUtils.findShape*`
  out entirely, with or without a root: it walks every page of the file and
  freezes the tab on a large one.
- Keep each `execute_code` call to a small batch: every created shape costs
  30–40 ms on a full page. Change main components only where the page needs
  it, since each change re-syncs the whole file. Undo blocks only merge
  history and save no time.
- Export each board when you believe it is finished: set
  `penpot.selection = [penpot.currentPage.getShapeById(id)]` in
  `execute_code`, then call `export_shape` with `shapeId: "selection"` — a
  shape id there triggers the same whole-file search. Look at the image and
  fix overlap, clipping and broken hierarchy. An image of some other shape
  means the selection changed in between: select again and re-export.
  Re-export only a board you changed.
- On "tab suspended", or when the plugin cannot be reached, stop at once and
  report. The first occurrence ends your run: only the user can bring the
  tab back, and a retry spends context for nothing.

Report — exactly this, as your final message:
page: <page name>
boards:
  <board name> | <id> | <done or missing>
  …
deviations: <where the result departs from this brief, or none>
stopped: <none | tab suspended | plugin unreachable | other: reason>
```
