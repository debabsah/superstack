---
name: superstack-debug
description: Use when behavior contradicts expectation — a bug, an unexplained error, a failing test, output that looks wrong, a fix that didn't hold — or when you're about to retry the same category of fix a second time, or work keeps failing or stalling. Also when the user says "debug this", "why is this happening", or "still broken". Skip when the cause is already proven.
---

# superstack-debug

A bug is a wrong **belief**, not just a wrong line. Fix your model of the system first; the code change then falls out. Never debug by mutation — "change something, rerun, hope" burns evidence and moves the bug around. **The front gate:** the red comes first — a debug run opens by running the reproducing command this session, or by saying plainly it cannot reproduce yet and instrumenting for capture; a theory offered before the red is on screen is not debugging.

## The procedure

1. **Reproduce first.** Get the minimal command that shows it red, and run it. A failure you can't trigger on demand can't be verified fixed — and if you can't reproduce it, *that is the finding*: report it and instrument (logging, a capture) instead of shipping a speculative patch.
2. **State the contradiction in one sentence.** "X should produce Y because Z; it produces W." If you can't fill in Z, you don't understand the intended behavior yet — go read the source of truth first (R1).
3. **Run a hypothesis ledger, cheapest-first.** List 2–5 candidate causes. Each gets a designed probe with a **predicted outcome written down before running it** — a probe whose outcome you can't predict is a coin flip, not an experiment. One variable per probe. Strike out falsified rows in writing; that's what prevents circling back to a cause you already killed.
4. **Bisect the delta when a working/broken pair exists** — version, commit, input, environment, config. Differential evidence beats staring at code.
5. **Three strikes → up a level.** The same category of fix failing twice means the shared assumption underneath is wrong (R2). Stop patching; re-read the contradiction; widen the frame.
6. **Fix the invariant, not the instance.** Root cause found → grep every caller and sibling path; the fix goes where all paths route through, or the siblings stay broken.
7. **Verify red → green on the exact reproduction from step 1** — red before the fix, green after, at the layer of the claim (→ superstack-verify). A fix you never watched fail isn't proven to be *the* fix.
8. **Root-cause the escape.** Always the second question: why did the existing checks miss this? Mint the runnable rule — the test/assert/check that would have caught it — and log the gotcha (`trap → cause → rule`) to `.superstack/project.md`. If a task file is open in `.superstack/tasks/`, record the decision trail there. And if the broken behavior was vouched for earlier, find that claim in `.superstack/claims-log` — **and in `.superstack/claims-log.<year>`, where `superstack-ship` archives older ones; a claim you can't find is not a claim that was never made** — then mark it `FALSIFIED <date> — <what actually broke>`: a falsified `Verified:` is a calibration miss, and *how the check missed it* is the gotcha.

## Red flags — you are debugging by mutation

- "Let me just try…" with no predicted outcome.
- Editing code before reproducing the failure.
- Two changes in one probe (you won't know which mattered).
- A fix explained with "somehow" or "must have been".
- Deleting or weakening the failing test to get green.
- Attempt three of the same fix.
