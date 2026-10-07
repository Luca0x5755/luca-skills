# Parallel queue execution

Reference for `run-queue` parallel mode. The coordinator owns the integration branch; workers own separate checkouts. At most two implementer workers run concurrently; seam reviewers and integration consume available agent slots too. Reserve capacity for review and integrate serially. Workers never invoke `run-queue` or `implement-spec`.

## Prepare and admit

1. Pin the current integration tip and create one branch/worktree per admitted ticket from that tip. Use absolute paths outside the integration checkout; verify each worktree's root and branch before any write.
2. Read the ticket and its touched surfaces before admission. Potentially overlapping files, registries, migrations, shared truth documents, ports, databases, fixture directories or generated outputs require an exclusive reservation or actual isolation. If uncertain, schedule serially. Independent blocking edges alone are insufficient.
3. Bootstrap dependencies and ignored local inputs using the project's existing procedure. Credentials stay in the environment or outside the repo. Never copy secrets into tracked files. Check fixture/test counts so required tests cannot silently skip. If resources cannot be reproduced or isolated, run that ticket serially in the integration checkout only after other writers stop.
4. Verify installed hooks resolve from the project root and inspect the worker's real cwd/index. Existing `.claude` Bash hooks do not establish protection in every harness: determine the actual active hook mechanism. No effective mandatory guardrails means parallel admission fails; keep the guards enabled and use the supported environment.
5. Give the worker context pointers to the approved spec, its ticket, truth documents, proposed seams and assigned checkout. Claim its ID before dispatch. Workers may inspect the integration tip but cannot modify that branch or other checkouts.

## Candidate integration gate

A worker reports its committed branch, ticket diff, test evidence, round count and review disclosures. Local green is a candidate, not queue completion.

Only one integration gate runs at a time:

1. Record the latest integration tip and create a temporary candidate-integration branch/worktree from it. Merge the worker branch there. The coordinator owns that candidate checkout while the worker is stopped; a repairer may own it only after explicit handover.
2. Resolve straightforward mechanical merge conflicts there; an ambiguous behavior/contract choice stays unresolved and is reported under the existing bounded failure rules. Run every required suite, typecheck, lint and the ticket's literal Done when checks on the **combined** tree. Preserve spec files and truth-layer changes.
3. A failing merge or combined check uses the ticket's remaining retry budget. Repair only in the candidate checkout, preserve observed outputs, and run focused regression plus required integration checks. Do not repeatedly launch broad review; the worker's ticket review has already run. A fresh independent review is warranted only by a new concern or user request.
4. Before promotion, compare integration HEAD to the recorded tip. If it moved, rebuild/revalidate the candidate against the new tip; stale green is not proof. The single coordinator should prevent this, but external updates must be detected.
5. Green: coordinator fast-forwards integration to the validated candidate, records integrated commit IDs in session memory, releases the claim/reservations and recomputes readiness from its tree. Red: preserve candidate branch/evidence, write STALLED on integration, and park dependents. No failed candidate enters integration.

Candidate merges can add merge commits. The requirement is a fast-forward **promotion of the validated combined tree**, not pretending every worker branch will remain a fast-forward after concurrent work lands.

## Systemic stop and cleanup

On denied permissions or a persistent hook block, stop new dispatch and promotion immediately. Signal all workers, wait for their safe stop, and preserve committed candidate branches. Report active work that could not stop; do not modify or remove its checkout. The coordinator does not reset other checkouts.

Remove only worktrees created by this run that are stopped, clean and whose evidence no longer depends on untracked files. Verify their absolute paths and ownership; use normal `git worktree remove`, never force removal. Keep incomplete candidate branches and dirty checkouts with pointers in the report. Clean fully integrated temporary branches only after verifying their tips are reachable from integration.

After an interruption, rebuild claims/reservations by inspecting actual worktrees, branches and commits. The integration tree remains the source for ticket completion; no second persistent progress file is introduced.
