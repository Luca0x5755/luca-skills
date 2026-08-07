---
name: uat-cases
description: 從規格與使用者故事推導 UAT 案例清單，發出凍結的 TC 編號，維護 docs/uat-cases.md — /browser-evidence 的上游。
disable-model-invocation: true
---

# UAT Cases

Derive an acceptance case list from what was promised — spec, user stories, user scenarios — and keep it in `docs/uat-cases.md`. The list is what `/browser-evidence` executes; this skill owns the other half of that contract: **IDs are frozen once issued, and a retired number is never reissued.** Evidence directories on the `evidence` branch are named by these numbers — a renumbered case silently orphans its past exhibits.

Cases test the promise, not the diff. A feature that was specified and never built should surface here as a failing case, not be absent because no code mentions it.

## 1. Name the sources

The sources are named, not guessed. Take what the user pointed at — spec files, issue numbers, story documents; anything missing, ask for. User scenarios often live in nobody's repo: taking them by dictation is normal, not a fallback.

With no spec at all, derive from conversation — and stamp the list's header with the fact that it has no spec backing, so a later reader knows what these cases rest on.

## 2. Read the ledger

`docs/uat-cases.md` is the ledger of every number ever issued — active and retired both. Read it before deriving anything: existing IDs, existing areas, retired numbers.

No file yet means this is the first issue run; the format below starts it.

## 3. Derive cases

For each behaviour the sources promise, write one case:

- **ID** `TC-<AREA>-NN` — area from the project's domain language (use the `/domain-modeling` glossary when one exists). Reuse an existing area whenever one fits; a new area is issued as deliberately as a new number, because areas freeze too.
- **標題** — one line, the behaviour under test.
- **來源** — the spec section or story this case traces to. When the source changes later, this column is how the affected cases are found.
- **角色** — who performs it. The same flow under two roles is two cases; a `403`-vs-`200` divergence between them is how authorization holes surface.
- **前置條件** — what the operator prepares: accounts, seeded data, feature flags. Naming another case's ID here（「TC-AUTH-01 已跑過」）is the legal way to state a dependency between cases — no separate dependency column.
- **步驟** — ordered, each one an observable action a browser driver can perform and photograph. "驗證登入功能" is a title; "在 #login-email 輸入帳號" is a step.
- **期望結果** — what the human reviewer should see. The verdict is theirs; this column is what they judge against.

**Every promise also gets at least one negative case** — wrong input, a role without permission, a boundary value. Testing is sampling, and the happy path is one sample; a promise left with only its happy path carries a stated reason in the proposal, not silence.

No priority column. A UAT list is run whole.

## 4. Propose, then wait

First sweep the sources item by item: every promise maps to at least one case. Promises left unmapped go into the proposal as a **gap list** — a promise nobody can test is a finding, not a footnote.

Then reconcile derived cases against the ledger and present the delta — 新增 N（含擬發的編號）／內容變 M（保號）／退役 K（附一行理由）— then stop for approval.

This pause is the point of the process: a number not yet issued can still be struck; once written it is frozen forever. Approval here is also what authorizes the write — nothing touches the file before it.

## 5. Write the file

Case content in Traditional Chinese; IDs and area names in English. Per case:

```markdown
## TC-AUTH-01 — 一般會員登入後進入儀表板
- **狀態**：active
- **來源**：spec §3.1／story #42
- **角色**：一般會員
- **前置條件**：測試帳號 member01 已建立
- **步驟**：
  1. 開啟 /login
  2. 在 #login-email 輸入 member01@example.com，輸入密碼
  3. 點擊「登入」
- **期望結果**：導向 /dashboard，右上角顯示會員名稱
```

Changed cases are edited in place under their frozen ID — version history is git's job. Retired cases keep their section, flip **狀態** to `retired`, and add a one-line reason; the section standing in the file is what makes "never reissue" checkable by grep instead of by archaeology.

Then stop. The file is the deliverable; committing it is the user's move via `/git-commit`.

## Where this sits

Downstream of `/to-spec` (cases trace to it) and upstream of `/browser-evidence` (which executes the list and holds the other half of the ID discipline — see its contract for what it needs from each case).
