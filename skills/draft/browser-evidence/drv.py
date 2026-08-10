"""Shared UAT driver helpers for /browser-evidence.

The canonical copy ships with the skill. Each project keeps its own at
tests/e2e/lib/drv.py, maintained through normal code PRs — selector
sediment and page objects land there too. Per-run case scripts import
this module and are committed with the evidence they produced.

Credentials come from uat-creds.env (kept out of git) or the
environment. A case script never carries a literal credential.
"""

import json
from datetime import datetime, timezone
from pathlib import Path

# Set by the case script, first line, before any capture.
# Mirrors the evidence/ branch name: "<operator>-<YYYY-MM-DD>-<shortSHA>"
RUN = ""
ROOT = Path("docs/uat")

_seq, _net, _logs, _facts, _heals = {}, {}, {}, {}, []
_manuals, _chan = [], {}


def run_dir(tc):
    if not RUN:
        raise RuntimeError("set drv.RUN before capturing anything")
    d = ROOT / RUN / tc
    d.mkdir(parents=True, exist_ok=True)
    return d


def launch(p, headed=True, slow=700):
    # Headed and slowed for the operator's eyes; fixed position so
    # successive runs land on the same spot on screen.
    return p.chromium.launch(headless=not headed, slow_mo=slow,
                             args=["--window-size=1600,1050", "--window-position=40,20"])


def banner(pg, text):
    # Burnt-in caption; the fixed id makes a second call replace, never stack.
    pg.evaluate("""t => {
        let d = document.getElementById('__uat') || document.createElement('div');
        d.id = '__uat';
        d.style.cssText = 'position:fixed;z-index:2147483647;left:0;right:0;top:0;'
            + 'background:#111;color:#0f0;font:600 16px/1.6 monospace;'
            + 'padding:6px 14px;border-bottom:2px solid #0f0';
        d.textContent = t;
        document.body.appendChild(d);
    }""", text)


def watch(pg, tc):
    # Network: state-changing writes only — widen to GET per case when the
    # case is about response-body exposure. Console: errors and warnings only.
    _net.setdefault(tc, [])
    _logs.setdefault(tc, [])
    pg.on("response", lambda r: _net[tc].append({"s": r.status, "m": r.request.method, "u": r.url})
          if r.request.method in ("POST", "PUT", "PATCH", "DELETE") else None)
    pg.on("console", lambda m: _logs[tc].append({"t": m.type, "x": m.text})
          if m.type in ("error", "warning") else None)
    pg.on("pageerror", lambda e: _logs[tc].append({"t": "pageerror", "x": str(e)}))
    pg.on("dialog", lambda d: d.accept())


def step_shot(pg, tcids, slug, full_page=True):
    for tc in tcids:
        _seq[tc] = _seq.get(tc, 0) + 1
        pg.screenshot(path=str(run_dir(tc) / f"{_seq[tc]:02d}-{slug}.png"),
                      full_page=full_page)


def evidence(tcids, slug, data):
    # Non-browser step artifact — same counter as step_shot, so a case can
    # mix browser and api steps without the numbering forking.
    for tc in tcids:
        _seq[tc] = _seq.get(tc, 0) + 1
        if isinstance(data, (dict, list)):
            (run_dir(tc) / f"{_seq[tc]:02d}-{slug}.json").write_text(
                json.dumps(data, ensure_ascii=False, indent=1), "utf-8")
        else:
            (run_dir(tc) / f"{_seq[tc]:02d}-{slug}.txt").write_text(str(data), "utf-8")


def manual(pg, tc, step_no, instruction):
    # Hand one step to the operator in the same headed browser, then resume.
    banner(pg, f"[人工] {instruction}")
    input(f"[{tc} 步驟 {step_no}] {instruction} — 完成後按 Enter：")
    _manuals.append({"tc": tc, "step": step_no, "what": instruction})
    fact(tc, step_no, f"本步驟由操作者人工完成：{instruction}")


def fact(tc, step_no, text):
    _facts.setdefault(tc, {}).setdefault(step_no, []).append(text)


def heal(tc, step_no, old, new):
    # Location only. A change to what the step does or asserts is not a heal.
    _heals.append({"tc": tc, "step": step_no, "old": old, "new": new})
    fact(tc, step_no, f"selector 由 `{old}` 改為 `{new}`（self-heal）")


def flush_case(tc, fields, steps, commit, env, operator, channel="chromium"):
    d = run_dir(tc)
    _chan[tc] = channel
    (d / "network.json").write_text(
        json.dumps(_net.get(tc, []), ensure_ascii=False, indent=1), "utf-8")
    (d / "console.json").write_text(
        json.dumps(_logs.get(tc, []), ensure_ascii=False, indent=1), "utf-8")
    (d / "manifest.json").write_text(json.dumps({
        "tc": tc, "commit": commit, "env": env, "operator": operator,
        "ran_at": datetime.now(timezone.utc).isoformat(), "channel": channel,
    }, ensure_ascii=False, indent=1), "utf-8")

    g = lambda k: fields.get(k, "未提供")
    lines = [f"## {tc} — {g('標題')}",
             f"- **狀態**：{g('狀態')} ／ **負責人**：{g('負責人')} ／ **角色**：{g('角色')}",
             f"- **來源**：{g('來源')}",
             f"- **前置條件**：{g('前置條件')}",
             f"- **期望結果**：{g('期望結果')}", ""]
    shots = sorted(d.glob("[0-9][0-9]-*.png"))
    arts = sorted(p for p in d.glob("[0-9][0-9]-*.*") if p.suffix in (".json", ".txt"))
    for i, step in enumerate(steps, 1):
        lines.append(f"### 步驟 {i} — {step}")
        lines += [f"![]({p.name})" for p in shots if p.name.startswith(f"{i:02d}-")]
        for p in arts:
            if p.name.startswith(f"{i:02d}-"):
                # Reader stays in the .md — payload embedded like a shot,
                # excerpted when long, raw file always linked.
                body = p.read_text("utf-8")
                snip = body if len(body) <= 1500 else body[:1500] + "\n…（節錄）"
                lines += [f"[{p.name}]({p.name})",
                          "```json" if p.suffix == ".json" else "```", snip, "```"]
        lines += [f"- **機器事實**：{f}" for f in _facts.get(tc, {}).get(i, [])]
        lines += ["- **觀察**：", ""]   # the agent's half — filled before the next case
    (d / "REPORT.md").write_text("\n".join(lines), "utf-8")


def flush_run(operator, listed, covered, skips=()):
    lines = [f"# {RUN} — run index",
             f"- 測試者：{operator}",
             f"- 覆蓋：{len(covered)}／{len(listed)}", ""]
    lines += [f"- [{tc}]({tc}/REPORT.md)（{_chan.get(tc, 'chromium')}）" for tc in covered]
    if skips:
        lines += ["", "## 跳過"] + [f"- {s}" for s in skips]
    if _manuals:
        lines += ["", "## 人工接手",
                  "| 案例 | 步驟 | 內容 |",
                  "| --- | --- | --- |"]
        lines += [f"| {m['tc']} | {m['step']} | {m['what']} |" for m in _manuals]
    if _heals:
        lines += ["", "## Self-heal",
                  "| 案例 | 步驟 | 原 selector | 新 selector |",
                  "| --- | --- | --- | --- |"]
        lines += [f"| {h['tc']} | {h['step']} | `{h['old']}` | `{h['new']}` |"
                  for h in _heals]
    (ROOT / RUN / "REPORT.md").write_text("\n".join(lines), "utf-8")
