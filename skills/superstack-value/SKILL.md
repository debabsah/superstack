---
name: superstack-value
description: An outcome claim shipping — "this should increase signups", "this saves the team time" — recorded as a dated, falsifiable prediction; settled when the SessionStart line says due. Skip for work with no outcome claim.
---

# superstack-value

"Worth building" is a claim. It ships every day unlabeled, undated, and never falsified — the last claim class without a ledger. This module gives it one, exactly as `claims-log` gives one to "done".

## Recording (at ship, and from inception)

When the work's justification is an expected outcome, append one bullet to `.superstack/value-log`:

```
- V<n> (<date>) expected: <observable change> — check by <YYYY-MM-DD> — from: <task/premise>
```

- **The expectation is an observable, not a vibe** — a number, a behavior, an event that either happens or doesn't. "Users will like it" is not checkable; "the weekly report takes <10 min" is.
- **The horizon is honest** — check-by is when the observable could realistically have moved, not next week by default.
- Inception's demand premises become predictions when the build ships — the premise ledger already wrote the observable; date it and log it.
- One line per shipped outcome-claim; work with no outcome claim gets no entry (do not manufacture predictions to look instrumented).

## Settling (when the SessionStart line says due)

For each due entry: check the observable — the real number, the real behavior, asking the user when the evidence is theirs — and append the verdict to the line:

```
[HELD <date> — <evidence>]   or   [MISSED <date> — <what actually happened>]
```

- **A MISSED is calibration data, not a failure.** Settle it honestly and move on; the log's value is the base rate.
- **A run of MISSED on a theme is a gotcha about product sense** — log it to the overlay (`Gotcha: predictions about <theme> keep missing → …`) so the next inception's demand battery pushes harder there.
- Never delete or rewrite entries; the log is append-only like every calibration record. When evidence can't be had, settle as `[MISSED <date> — unmeasurable as written]` — that too is a lesson: the next prediction gets a measurable observable.

The human owns what "held" means when the observable is ambiguous — ask, don't adjudicate.
