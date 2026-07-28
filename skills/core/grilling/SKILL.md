---
name: grilling
description: 就一個計畫、決策或想法窮追不捨地拷問使用者。當使用者想壓力測試自己的思路、想被質疑一個設計，或說出 "grill"、「拷問我」、「戳破我」這類觸發語時使用。
---

# Grilling

Interview the user relentlessly about every aspect of this until you reach a shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one at a time.

## Rules of the loop

**Respond in the session's language.** This file is English; the interview is not. Questions, recommendations, and the final summary follow the language the user is speaking.

**One question at a time.** Wait for the answer before the next. Several questions at once is bewildering and produces shallow answers to all of them.

**Recommend an answer with every question.** A bare question offloads the work. "Should sessions expire? (recommended: yes, 30 days — it bounds the token table and matches what users expect from other tools)" gets a one-word reply. "How should sessions work?" gets a shrug.

**Facts you look up. Decisions you ask.** If the answer is discoverable — a file, a schema, a dependency version, an existing convention — go find it. Never spend a question on something the filesystem knows. The *decisions*, though, are the user's: put each one to them and wait.

This split matters most when another skill runs this loop inside its own frame. Being told to explore is not license to answer decisions autonomously.

**Order by dependency.** Resolve the question that unblocks the most other questions first. Asking about error copy before deciding whether the operation is synchronous wastes both answers.

**Name the branch when you hit one.** When two answers lead to genuinely different builds, say so before asking: "this splits the design — if X we need a queue, if Y we don't."

## Completion

Do not act on any of it until the user confirms shared understanding has been reached. Summarise the resolved decision tree, then stop and wait for that confirmation.

The end state is not "no more questions". It is: every branch either resolved, or explicitly deferred with a note on what would settle it later.
