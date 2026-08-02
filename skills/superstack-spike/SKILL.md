---
name: superstack-spike
description: A feasibility question, not a delivery — "can X even do Y", "is this viable", "how expensive would Z be" — where throwaway code is the cheapest probe. Skip when a read-only probe answers, when reasoning settles it (superstack-decide), and for work meant to be kept (superstack-scope).
---

# superstack-spike

A spike buys an **answer**, not code. The code has no legal status; the answer does — a spike without its harvest was just deleted work.

## 1. The contract (one block, before building)

```
question: <falsifiable — what observation settles it>
timebox: <duration>
touches: <scratch only | real data | live service | money>
stop when: answered · timebox spent · <signal it's a dead end>
```

## 2. Build the cheapest thing that answers

Ship discipline is suspended **by declaration, and only when `touches: scratch only`**: no tests, no docs, no review; hardcode freely; T1 on a branch or scratch dir. A probe that reads real data, hits a live service, or spends money keeps its tier and its gates (the tier table in the superstack gateway skill) — **tier is set by blast radius, never by intent; declaring "spike" lowers nothing** (the method's rule: effort never lowers a tier's minimum). The suspension is legal because the contract above exists and step 3 is mandatory.

**Inside an ACTIVE campaign, a spike is off-frontier:** no receipt, no frontier movement; its harvest enters the plan as a write-ahead discovery line, and the campaign's red-before-green discipline resumes untouched.

## 3. The harvest (mandatory)

- **The answer, as a ledger line:** `Verified: <answer> — ran <probe> -> saw <result>` — or `PROVISIONAL: <best reading>` when the timebox ran out unclear (an honest "still unknown, here's what it cost to learn that" is a legal spike result). **Append it to `.superstack/claims-log`** like any shipped claim — an unrecorded `Verified:` can never be falsified.
- **The code's disposition, stated:** `discard` (default) or `rebuild properly`. Spike code never graduates by renaming — keeping it means re-entering through superstack-scope, where it earns tests and review like anything else.
- **What it cost** vs the timebox — appended to the claims-log line itself (`… — cost: <spent>/<boxed>`), so how long spikes here actually take is a readable base rate that tunes the next contract.

## 4. Route the answer somewhere durable

Retires a scope unknown → the task file (none open → the overlay). Changes a premise → the premise ledger (inception's `P<n>` block; entered standalone with no ledger → the overlay, as a dated fact). Spawns real work → superstack-queue (its grammar). A durable project fact → the overlay (`.superstack/project.md`). An answer that lives only in the chat dies with the session.

## Red flag

"The spike works — let me just clean it up and keep it." That's a build wearing a spike's exemption. Stop; re-enter through scope.
