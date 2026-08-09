# Driver recipe

The Playwright mechanics behind [`browser-evidence`](SKILL.md): what the generated script does, and the two pitfalls that have already produced a wrong answer.

Each run generates both files from scratch — a `drv.py` holding the helpers below, and a script per run that imports it. A `drv.py` left over from last time is a liability, not a head start: the helpers are stable, the selectors they wrap are not.

## Run root — every written path hangs off it

```python
RUN = "2026-08-09-4b17006"   # <date>-<short SHA of the commit under test>
```

Set it once, at the top, from the build being captured. Every file the driver writes lands under `RUN/<TC-ID>/`. A helper that builds its path from the case ID alone writes into whatever run came before — silently, and the exhibit it corrupts is the one already committed.

## Launch — headed on purpose

```python
def launch(p, headed=True, slow=700):
    return p.chromium.launch(headless=not headed, slow_mo=slow,
                             args=["--window-size=1600,1050", "--window-position=40,20"])
```

Every flag serves the human, not the machine. `headless=False` so the operator sees it run; `slow_mo` so eyes can follow; a fixed window position so successive runs land in the same place on screen.

Mobile layouts get a phone viewport instead (`480×950`) — the exhibit has to show what the user's device shows.

## Login — real form, session reused

Fill the real login form once, then persist and replay:

```python
ctx.storage_state(path="brand_state.json")   # later runs: browser.new_context(storage_state=...)
```

Prefer stable ids (`#login-email`). Where the app gives none, index visible inputs positionally — and expect that to break when the form changes, because it will.

## Banner — the burnt-in caption

A fixed bar at the top of the page, stating the case and step:

```python
d.id = '__uat'
d.style.cssText = ('position:fixed;z-index:2147483647;left:0;right:0;top:0;'
                   'background:#111;color:#0f0;font:600 16px/1.6 monospace;'
                   'padding:6px 14px;border-bottom:2px solid #0f0')
d.textContent = t
```

`2147483647` is the 32-bit ceiling, so it sits above any modal. The fixed id makes a second call replace the text instead of stacking bars. Black-on-green monospace reads as obviously *not* the application under test.

Call it before each step, then let the page settle so it makes the shot.

> **Pitfall — the banner is page text.** Searching the DOM for a phrase can match the caption instead of the application, which once turned a passing case into a reported defect. Query the HTML for field names (`cost`, `unit_price`) rather than rendered words.

## Screenshots — numbered per case

```python
def step_shot(pg, tcids, slug):
    for tc in tcids:
        _seq[tc] = _seq.get(tc, 0) + 1
        pg.screenshot(path=f"{RUN}/{tc}/{_seq[tc]:02d}-{slug}.png", full_page=True)
```

One image can serve several cases — the same screen is often step 1 of one case and the precondition of another — so the counter is per case, keeping each sequence aligned with its own step numbers.

`full_page=True` is a choice, not a default: it catches what scrolled out of view, and on a long list page it costs megabytes. Use the viewport when the step's proof is on screen.

> **Pitfall — the counter is module state.** It resets with the process, so splitting one case across two scripts restarts its numbering at `01`. Keep a case inside one run.

## Dialogs

Native `confirm()` blocks a Playwright run until something answers it:

```python
pg.on("dialog", lambda d: d.accept())
```

## Network — the layer the screenshot cannot show

Two identical-looking clicks can differ only in status code. Record state-changing requests as they happen:

```python
pg.on("response", lambda r: net.append({"s": r.status, "m": r.request.method, "u": r.url})
      if r.request.method in ("POST", "PUT", "PATCH", "DELETE") else None)
```

Writes only. Static assets, polling and analytics would bury the three lines that matter. A `403`/`200` difference across two roles is how an authorization bypass surfaces — and it is unrecoverable after the fact, since a rerun may no longer reproduce the state.

Widen to `GET` when the case is specifically about data exposure in a response body.

Write the collected list to `<RUN>/<TC-ID>/network.json`.

## Console — the layer the page hides

A JS error can leave the frame looking perfectly normal — the handler died, the shot shows the form still standing. Collect what the page said to itself:

```python
pg.on("console", lambda m: logs.append({"t": m.type, "x": m.text})
      if m.type in ("error", "warning") else None)
pg.on("pageerror", lambda e: logs.append({"t": "pageerror", "x": str(e)}))
```

Errors and warnings only — `log`/`debug` chatter would bury them, same reasoning as the network filter. Write to `<RUN>/<TC-ID>/console.json`. Like the network log, it is unrecoverable after the fact.

## API without UI

Forged signatures, internal tokens, cross-origin endpoints:

```python
api = p.request.new_context()
```

`APIRequestContext` is outside the browser's CORS rules, so it reaches endpoints the page cannot.
