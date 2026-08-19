---
name: study-repo
description: 讀懂一個下載回來的第三方 repo — 先跑起來，再追一條核心路徑，產出拋棄式的 AI_README.md 學習報告，看完自己刪。
disable-model-invocation: true
---

# Study Repo

Learn a codebase someone else wrote. The output is **throwaway**: `AI_README.md` plus `AI_README-flow.svg` at the repo root. The user reads them and deletes them — scaffolding for one head, not documentation the project will keep.

Comprehension research says the fast route is: run it, find the entry point, follow **one** critical path out. Walking module by module feels productive and teaches little. This skill runs the fast route.

Out of scope: whether the project is worth adopting. That question is answered by GitHub metadata, not by the code.

## Evidence discipline

Four marks, obeyed by every step. They are what separates this report from a confident summary of files nobody opened.

- **Commands carry a verification mark** — `⚠️ 未驗證` when copied out of a build file, `✅ 已驗證（Node 20.11）` when actually executed in step 2.
- **Claims name their source** — `src/server.ts:41`. A claim with no path is a hypothesis and says so.
- **Quantities are counted** — every number (file counts, field totals, line counts) comes from a command run against the repo. A number quoted from the project's own docs imports their staleness into your report.
- **Absence is a finding** — `資訊缺失：無部署設定` states something true about the project.
- **Coverage is declared** — the report ends with the list of files actually read, and every claim traces back to that list.

## 1. Measure

Before opening any source file, size the job: file count, language mix, last commit date, and candidate entry points (`package.json` `main` / `scripts.start`, `__main__.py`, `main()`, `Dockerfile` `CMD`, route definitions).

State the reading budget out loud. A 300-line script gets read whole; a 3000-file monorepo gets its trunk, and section 9 says exactly that.

## 2. Run it first

Extract the Dev and Prod commands from `package.json`, `requirements.txt` / `pyproject.toml`, `Dockerfile`, `docker-compose.yml`, and CI workflows. Mark every one `⚠️ 未驗證`.

Brief the user before asking: one plain line per command — what it does, what it touches — plus the environment prerequisites (runtime version, env vars, system dependencies). A command that executes arbitrary code (`postinstall`, `curl | sh`, `docker build`) gets a warning citing the `path:line` it came from; a harmless one stays at one line. The briefing is report material — it becomes section 2 of the report, not throwaway chat.

Then stop and ask the user whether to execute them. Running a stranger's build scripts is irreversible, so the human decides — and the briefing is what makes their decision informed. Always put the offer to them; a report that skips the question ships half-finished. A yes authorizes install and tests only: deploy and production commands are listed and briefed, never executed, and stay `⚠️ 未驗證`.

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

## 4. Draw the path

One diagram: the step-3 path, written to `AI_README-flow.svg` beside the report and referenced as `![核心路徑](./AI_README-flow.svg)`.

**Load the `/svg-palette` skill via the Skill tool — mandatory** before choosing any color.

Draw what the path actually showed. When module boundaries stayed unclear, write `資訊缺失：模組邊界不明確` and ship no diagram — one honest sentence beats an invented picture.

## 5. Write the report

Read [`REPORT-TEMPLATE.md`](REPORT-TEMPLATE.md) and follow its nine sections in order. The order is the reading order.

Two rules bind the whole document:

- **A section may be empty; its content is never padded.** `此專案無測試` is a finding. A paragraph of generic testing advice is noise.
- **Simple, clear, precise, concise.** State the thing. Transitions（首先、接著、最後）and hedges earn no space.

## 6. Hand over

Report the two paths written, and that clearing them is `rm AI_README.md AI_README-flow.svg`. The user reads and deletes; nothing here is maintained.
