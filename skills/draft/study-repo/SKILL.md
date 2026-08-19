---
name: study-repo
description: 讀懂一個下載回來的第三方 repo — 先跑起來，追一條核心路徑，再親手走一遍主要功能，產出拋棄式的 AI_README.md 學習報告，看完自己刪。
disable-model-invocation: true
---

# Study Repo

Learn a codebase someone else wrote. The output is **throwaway**: `AI_README.md`, `AI_README-flow.svg`, and `AI_README-shots/` at the repo root. The user reads them and deletes them — scaffolding for one head, not documentation the project will keep.

Comprehension research says the fast route is: run it, find the entry point, follow **one** critical path out — then trigger that path once with your own hands. Walking module by module feels productive and teaches little. This skill runs the fast route.

Out of scope: whether the project is worth adopting. That question is answered by GitHub metadata, not by the code.

## Evidence discipline

Five marks, obeyed by every step. They are what separates this report from a confident summary of files nobody opened.

- **Commands carry a verification mark** — `⚠️ 未驗證` when copied out of a build file, `✅ 已驗證（Node 20.11）` when actually executed in step 2.
- **Claims name their source** — `src/server.ts:41`. A claim with no path is a hypothesis and says so.
- **Quantities are counted** — every number (file counts, field totals, line counts) comes from a command run against the repo. A number quoted from the project's own docs imports their staleness into your report.
- **Absence is a finding** — `資訊缺失：無部署設定` states something true about the project.
- **Coverage is declared** — the report ends with the list of files actually read, and every claim traces back to that list.

## 1. Measure

Before opening any source file, size the job: file count, language mix, last commit date, and candidate entry points (`package.json` `main` / `scripts.start`, `__main__.py`, `main()`, `Dockerfile` `CMD`, route definitions).

State the reading budget out loud. A 300-line script gets read whole; a 3000-file monorepo gets its trunk, and section 10 says exactly that.

## 2. Run it first

Extract the Dev and Prod commands from `package.json`, `requirements.txt` / `pyproject.toml`, `Dockerfile`, `docker-compose.yml`, and CI workflows. Mark every one `⚠️ 未驗證`.

Brief the user before asking: one plain line per command — what it does, what it touches — plus the environment prerequisites (runtime version, env vars, system dependencies). A command that executes arbitrary code (`postinstall`, `curl | sh`, `docker build`) gets a warning citing the `path:line` it came from; a harmless one stays at one line. The briefing is report material — it becomes section 2 of the report, not throwaway chat.

Then stop and ask the user whether to execute them. Running a stranger's build scripts is irreversible, so the human decides — and the briefing is what makes their decision informed. Always put the offer to them; a report that skips the question ships half-finished. One question, one yes: it authorizes install, tests, and the step-4 walkthrough (dev-server start included). Deploy and production commands are listed and briefed, never executed, and stay `⚠️ 未驗證`.

**Yes** — start the install in the background and read code while it builds. A cold install of a large project outlasts the entire reading pass; waiting on it doubles the run for nothing.

Then run the test suite the project's own CI runs, and characterize the failures — platform-specific, environment-specific, or real. A failure pattern (all path handling, all on one OS) states more about a project than any prose about its quality.

Record what actually broke — wrong runtime version, an env var missing from `.env.example`, an undeclared system dependency, a suite that only passes under WSL — and upgrade the marks. These lines are the most valuable in the report: they are precisely what the project's own README does not tell you.

**No** — the marks stay `⚠️`.

## 3. Follow one path

Start at the entry point. Follow the single path that best represents the project's core purpose, boundary to boundary, noting every file it passes through.

**One path.** A second path turns the report back into a module inventory — the artifact that reads as thorough and teaches nothing.

Harvest three things along the way, all of which the code assumes and the reader lacks:

- **Data shapes** — the main types, schemas, state objects. Understanding the data collapses most of the remaining code.
- **Vocabulary** — the project's invented terms. Someone who does not know a project's words cannot read its code.
- **Tests as spec** — where they live, how to run them, and the one test that states the core behaviour most plainly.

## 4. Walk the path

Turn the step-3 path into a walkthrough the user performs by hand: trigger the project's main function once, boundary to boundary. Install stays out — that was step 2's business, and rehearsing it teaches nothing.

Write each step as a human operation — "open `http://localhost:3000`, type X, submit" — and annotate it with the code it fires (`src/server.ts:41`). The steps and the step-5 diagram cover the same stations, one to one: read the path, then walk it.

The form follows the project:

- **Server** — start the dev server, perform the UI operations that drive the path.
- **CLI** — run the one command that best states the core purpose.
- **Library** — write a scratch script (~10 lines) calling the core API. It goes into the report as a fenced block the user copies and runs; verify it from the scratchpad, then delete it.

Then perform the walkthrough yourself, once. For a web UI, write a throwaway Playwright script in the scratchpad — headed browser, one screenshot per step — and discard the script after the run. The script is this skill's own, start to finish: `/browser-evidence` and its exhibit pipeline stay out — its output is permanent evidence for others, this output is throwaway scaffolding for one head. Screenshots land in `AI_README-shots/` at the repo root; CLI and library steps capture their actual terminal output instead. A **No** in step 2 skips the performance — the section is still written, every step `⚠️ 未驗證`.

Shut the dev server down when done. The run leaves no background process and no scratch files outside `AI_README-shots/`.

## 5. Draw the path

One diagram: the step-3 path, written to `AI_README-flow.svg` beside the report and referenced as `![核心路徑](./AI_README-flow.svg)`.

**Load the `/svg-palette` skill via the Skill tool — mandatory** before choosing any color.

Draw what the path actually showed. When module boundaries stayed unclear, write `資訊缺失：模組邊界不明確` and ship no diagram — one honest sentence beats an invented picture.

## 6. Write the report

Read [`REPORT-TEMPLATE.md`](REPORT-TEMPLATE.md) and follow its ten sections in order. The order is the reading order.

Two rules bind the whole document:

- **A section may be empty; its content is never padded.** `此專案無測試` is a finding. A paragraph of generic testing advice is noise.
- **Simple, clear, precise, concise.** State the thing. Transitions（首先、接著、最後）and hedges earn no space.

## 7. Hand over

Report the paths written, and that clearing them is `rm -rf AI_README.md AI_README-flow.svg AI_README-shots/`. The user reads, walks the path once, and deletes; nothing here is maintained.
