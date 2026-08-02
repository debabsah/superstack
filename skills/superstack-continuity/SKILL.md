---
name: superstack-continuity
description: Resuming or handing off — after a crash, session limit, compaction, or model handoff; picking up a HANDOFF or state file; closing a session with work in flight; the SessionStart continuity line. Also on "resume safely" or "write the handoff". Skip for a fresh session with nothing inherited.
---

# superstack-continuity

Sessions die — limits, crashes, compaction, handoffs. Continuity is engineering, not memory: the conversation is scratch; files are the project.

## Resuming: verify before continuing

Never continue from what you remember or what a handoff asserts. First, ground truth:

1. `git status` + `git log` — what actually landed, versus what the last session's record claims landed.
2. The suite (or the project's oracle rows) — the state you inherit is the state that passes now, not the state that was reported.
3. **Inherited state is a claim, not evidence.** A HANDOFF, a task file's `next:` pointer, another session's report, your own memory of "where we were" — audit each against disk before acting on it. Handoffs have asserted hooks that never existed; distrust is the posture that caught it.
4. If a subagent or background task died mid-work, classify what it completed (its commits, its files) before re-dispatching.

## Closing: leave the work resumable

When a session ends with work in flight, the last act is the record, addressed to its actual reader:

- **For your future self / the next model session:** the task file's `next:` pointer updated to the true next action; decisions since last update appended; anything half-done named as half-done.
- **For a different tool or model:** a self-contained pack — constraints, commands, "done looks like" per step — assuming none of your context survives.
- **For the human:** a STATUS-labeled report that leads with what is NOT done.

Pin pause points in commits, not prose ("pausing here" in a commit message beats a paragraph the next session never reads).

## When a plan is active

If `.superstack/plans/` holds an ACTIVE plan, superstack-execute specializes this skill: session close means camping the plan's frontier block (that stamp IS the handoff), and resuming means the torn check — a frontier not stamped `camped` is treated as a crash, and the verify-before-resume ritual runs harder, not softer.

## Mid-work anchors

Long turns write their own lifeline as they go: commit per verified step, decision records appended at re-decide, lessons appended to the overlay when confirmed — so an unexpected death loses minutes, not the session. Multi-tab or cross-machine coordination happens only through durable files, never through assumptions about what the other session did.
