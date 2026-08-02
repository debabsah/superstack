---
name: superstack-decide
description: A mid-work technical fork — "which way should we go", a design/architecture/tooling choice about to lock — or the user ruling on how the thing is built (conduct rulings are superstack-doctrine's). Also on "record this decision". Skip for statute-governed choices, forks needing building (superstack-spike), and trivially reversible picks (a log line).
---

# superstack-decide

**First act on every load:** append one line — `skill-load decide <date> <session-id>` — to `.superstack/receipts/loads.log` (create the dir if missing). Mechanical proof of routing; a fork that locked with no load line is countable.

A decision is real only when its rejected alternative and revisit trigger survive it. Chat history is not a record; six weeks later, "why did we choose X?" deserves a file, not an archaeology dig.

## The fork

1. **Frame it in one line** — what locks if we proceed, and how expensive reversal is (the reversibility class decides how much thinking this earns — R7).
2. **Price 2–4 options.** Each carries its downstream cost in one clause; one is marked recommended with the rejected cost stated (R6's shape: one question, a recommendation, the rejected cost). A menu never boxes the conclusion in — name what's outside it.
3. **Who decides:** reversible and in scope → decide now and record why. A one-way door, a genuine ambiguity, or anything touching an anchor → the human (R6). When the human's ruling is about *conduct* ("never do X again"), it's a statute — route to superstack-doctrine; a *design* choice lands here. One event can mint both.

## The record

- **House style wins.** If the repo already keeps decision records — `docs/adr/`, `ADR-*.md`, any existing convention — use *their* path and format; this shape fills silence, never fights a convention.
- **The first record in a silent repo is offered, never silent.** Creating `docs/decisions/` mints a new committed convention in someone's repo — say so and ask ("this locks an approach; want it recorded in docs/decisions/?"), create the directory on yes. If the owner declines, decisions live in the overlay's Conventions instead — durable on this machine only, and say that limit out loud.

On yes, create `docs/decisions/NNNN-<slug>.md` (zero-padded, first record `0001`; next = ls the directory):

```
# NNNN — <choice, imperative>
date: <YYYY-MM-DD> · decided by: <human|model — context>
context: <2–3 lines: the fork and what forced it>
options: <A — cost> / <B — cost> / …
chose: <X> because <Z>
revisit if: <the observation that reopens this>
supersedes: <NNNN — omit unless replacing one>
```

Same grammar as the task file's decision log (`chose X over Y because Z; revisit if W`) — this is that line's durable, committed form. Append-only: supersede, never edit (doctrine's rule, same reason) — and when a record is superseded, append one line to the OLD file, `superseded-by: NNNN`. An append, not an edit: the dead end carries a sign pointing at the live decision.

- **Committed on purpose:** the overlay is per-machine and destructively compacted; a decision record must survive machines, teammates, and compaction.
- **Promotion seam:** when superstack-ship retires a task file, decision-log lines that outlived the task promote here (ship's step 4 names this target).
- **Not every choice earns a file:** the test is the future question — if nobody will ask "why", the task-file line was enough. Records that can't name their revisit trigger are wishes, not decisions.
