---
name: superstack-scope
description: Use at the start of a non-trivial task, or when the goal is fuzzy, the request is solution-shaped, or you cannot yet state in one sentence what "correct" will be checked against. Skip for trivial edits.
---

# superstack-scope

Bound the task before building. Produce a short **scope block** and stop for the human only if a fork genuinely changes what you'd build.

**T1 fast path:** reversible and local → write the one-line check (step 1) and go. The full block below is for T2+ or fuzzy scope.

**First, read `.superstack/project.md` if it exists** — it holds this project's acceptance oracle, conventions, and known **gotchas**; scope on top of it (don't re-derive what's there, and don't re-step on a logged landmine). If it's missing, offer to create it (see the method skill's overlay protocol). Then:

1. **Define done as a named external CHECK.** In one sentence: what artifact exists at the end, and *what will "correct" be compared against*? Prefer a concrete oracle (a known-good output, a reference system, a test, a count). If no oracle can exist, name the weakest acceptable substitute (a specific human's sign-off) — and say so. **If you can't write the check, you don't understand the task yet.** In an unfamiliar or long-untouched codebase, **run that check before changing anything** — you can't attribute a failure to your change if you never saw pre-change green.
2. **Split known from assumed.** Two short columns: *Known (evidence)* vs *Assumed (inference)*. Anything in the second column that would change the solution if wrong is a candidate unknown.
3. **Name the 1–3 load-bearing unknowns** — the facts that, if wrong, change the whole shape — and the *cheapest probe* to retire each. Gate on them: don't build past an unretired load-bearing unknown.
4. **Fence it.** A short explicit "out of scope (recorded so nobody wonders)" list.
5. **Right-size.** Note which decisions are cheap to reverse (defer them) vs the one or two that are expensive/unpatchable (spend the thinking there). Assign the task its **risk tier** (T1 reversible-local / T2 hard-to-reverse / T3 outward-production — the method skill's table); the tier fixes the minimum gate before any "done" claim.
6. **Ask only outcome-changing questions.** If a fork changes what you'd build, ask **one** question, with a recommendation and the rejected cost. Otherwise pick the sensible default, state it in one line, and proceed. Ask to change outcomes, not to feel safe.

**If the work will outlive this session, or is T3:** open `.superstack/tasks/<slug>.md` — first line `<!-- task: <slug> — goal: <what this is for, one clause> — next: <action> -->`, then the scope block, an **Anchors** line (the oracle, the fence, human rulings — re-stated at every re-decide; moving one is an escalation to the human, not a re-plan), a decision log (`chose X over Y because Z; revisit if W`), and deferral buckets. Keep the pointer's `next:` current as you work (the SessionStart hook surfaces it every session); append a decision record at every re-decide moment. **`goal:` comes before `next:` and does not move** — the next action changes constantly, the reason the work exists does not, and a cold session that is told only where it is will optimize the route while losing the destination. Changing a `goal:` is an escalation to the human, like moving an anchor. `superstack-ship` retires the file. (Single-session work at any tier needs only the scope block — the file exists for what must survive a session boundary or a T3 audit.)

**Plan to the shape** (method skill → *The plan shape*): the next 1–2 steps concrete with their checkpoints; everything past the next verification point stays a coarse bucket. A step without a check attached is a hope, not a step.

Output the scope block, then continue. Re-open it if a later result invalidates an assumption.
