---
name: code-review
description: 沿三條軸審查自某個定點以來的 diff — Standards（有沒有遵守這個 repo 的規範？）、Spec（有沒有做到票要求的事？）與 Reuse（倉庫裡有沒有現成的？）。當使用者要審查一個分支、一個 PR 或進行中的工作時使用，也對應 "code review"、"review this branch"、「審一下」、「有沒有現成的」、「重複造輪子」等說法。
---

# Code Review

Three-axis review of the diff between `HEAD` and a fixed point.

- **Standards** — does the code conform to this repo's conventions, and pass the waste and bug checks below?
- **Spec** — does it faithfully implement the originating ticket or spec?
- **Reuse** — does the repo already have what the diff wrote from scratch?

Run all three as **parallel sub-agents** so none pollutes another's context, then report side by side. Sub-agents must not invoke `/code-review` themselves — one level of review, no recursion.

## 1. Pin the fixed point

Whatever the user gave: a SHA, a branch, a tag, `main`, `HEAD~5`. If they gave nothing, ask. Reviewing against a merge-base you assumed is reviewing a different diff than they meant.

`git diff <point>...HEAD` — the diff, not the file tree.

## 2. Standards axis

The repo's own documented standards win over everything below. Read `CLAUDE.md` / `AGENTS.md`, any `docs/` conventions, and — more reliable than either — the surrounding code.

The smells below are always checked and always reported as **judgement calls, never violations**:

- **Mysterious name** — the name does not say what it does
- **Duplicated code** — same logic in three places, about to drift. This axis owns duplication *inside* the diff; the diff repeating what the repo already has belongs to Reuse.
- **Feature envy** — a function more interested in another object's data than its own
- **Data clumps** — the same three parameters travelling everywhere together
- **Primitive obsession** — a domain concept carried as a bare string
- **Repeated switches** — the same branch on the same type, scattered
- **Shotgun surgery** — one change forcing edits across many files
- **Divergent change** — one file edited for unrelated reasons
- **Speculative generality** — abstraction for a case that does not exist
- **Message chains** — `a.b().c().d()`
- **Middle man** — a class that only delegates
- **Refused bequest** — a subclass that ignores most of what it inherits

**Waste**, on the same footing — judgement calls, checked every time:

- **Needless await** — waiting on a result nothing downstream needs yet
- **Serial by accident** — independent operations run one after another
- **Overly broad operation** — fetching, locking, or invalidating more than the change needs
- **Hot-path bloat** — work or allocation inside a loop or per-request path that belongs outside it

A documented repo standard overrides any of these. Consistency beats a rule from a book.

**Must fix** — two bugs, outside the judgement-call rule and outside any repo override:

- **TOCTOU** — a check and the act it guards separated by a window in which the world can change
- **Leak** — memory or a resource (handle, listener, timer, subscription) acquired without a release path, or a reference held past its life

A reviewer who sees a leak and stays quiet is broken.

## 3. Spec axis

Read the originating ticket or spec. Check the diff against it:

- Every *Done when* condition, literally — met, or not
- **Scope creep** — shipped things the spec did not ask for
- **Silent gaps** — spec items with no code
- **Reinterpretation** — built something adjacent to what was asked

## 4. Reuse axis

For each function or block the diff introduces, search the repo for something that already does the job. Search by **purpose, not name** — the existing one is rarely called the same thing. Cover the whole repo, conventional homes first (`utils`, `helpers`, `lib`, `shared`), then the dependencies already in the lockfile — an installed package counts as existing code. Adding a dependency is a decision for the reader, never a finding.

Every finding puts both candidates on the table: the diff's location and the existing one's path, so the reader compares them in one glance. Always a judgement call — the existing one may be worse, or on its way out. Choosing is the reader's job; finding the pair is this axis's.

## 5. Report

Three columns side by side, most severe first. Each finding: file and line, one sentence on the defect, and the concrete failure — inputs or state, and what breaks.

Separate **must fix** from **judgement call**. A review where everything is urgent gets ignored wholesale.

Say plainly when an axis found nothing. Manufactured findings to look thorough cost more than they are worth.
