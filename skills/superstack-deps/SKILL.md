---
name: superstack-deps
description: Dependencies need moving — an EOL or deprecation notice, a security advisory, "upgrade to vX", "how far behind are we". Also on "upgrade dependencies". Skip for new dependencies (superstack-decide), lockfile-only patch bumps, and updating the superstack plugin itself (the plugin manager's job).
---

# superstack-deps

The platform moves under every project. An upgrade is ordinary work with one distinguishing risk: the breaking change you didn't read about — so the method is inventory, batches, and a checkpoint per batch.

## The method

1. **See green first, then inventory — printed.** Run the project's named verify command *before* any bump: a post-bump red you can't attribute is two hours of bisecting a failure that predated you (scope's rule, applied here). Then the inventory: what's depended on, current vs latest, EOL/advisory flags, and which dependencies are load-bearing vs incidental. When the work spans sessions, the inventory lives at the top of the task file (`.superstack/tasks/<slug>.md`) — dated, so the next session diffs against it instead of re-deriving it.
2. **Batch by risk, not alphabet.** Patch-safe bumps travel together; each major travels **alone**, with its breaking-change digest read from the actual changelog — opened, not guessed (R1: the changelog is a file you haven't opened yet).
3. **Each batch ends at a checkpoint:** the project's named verify command green, then a commit — so any batch is a legal stopping point and execution moves verified-state to verified-state (the plan shape). Rollback per batch is the commit revert — which stays true only if batches are pure: **no drive-by refactors inside an upgrade commit.**
4. **A big migration is a campaign.** Framework major, runtime jump, anything spanning sessions: open a plan file and run superstack-execute — this skill is its inventory-and-batching front end, not a substitute for the campaign loop.
5. **A pin is a decision.** What stays behind, stays behind *with its reason recorded* (a superstack-decide record or the overlay's Conventions, with a revisit trigger) — pinned-with-reason ages into a plan; silently stale ages into an incident.

## The ledger

What moved (versions, before → after), what the verify command showed per batch, and what remains behind with its why. `Assumed:` covers the transitive surface honestly — a green suite proves what the suite covers, not the dependency tree's whole behavior.
