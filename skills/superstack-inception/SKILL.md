---
name: superstack-inception
description: A new idea with no spec — a product, tool, feature, or app arriving as "I have an idea", "let's build", "create/make me X" — before any design artifact exists. Also on "shape this idea". Skip for bug fixes, specced tasks, trivial edits — and "new skill/module/pack" ideas (superstack-smith).
---

# superstack-inception

**First act on every load:** append one line — `skill-load inception <date> <session-id>` — to `.superstack/receipts/loads.log` (create the dir if missing). Mechanical proof of routing; a moment that occurred with no load line is countable.

Work is admitted, not accepted. Run these five stages before any design artifact exists; each produces a small visible output. Depth follows stakes: a personal utility earns minutes, a public-facing product earns the full battery.

## 1. Frame

One question that fixes what kind of ask this is — build-for-me, explore, public product — and say aloud how hard the interrogation will push because of it. Personal-utility asks skip stage 2.

## 2. Demand battery (public-facing asks only)

Pressure-test whether the thing should exist before designing it: who hurts without it today, what do they use instead, what evidence would kill this idea. Kill options ride *inside* the option menus — never as a confrontation, always as a priced choice.

## 3. Premise ledger

Compress what you've heard into numbered, falsifiable premises — one grammar, reused by every skill that writes premises:

```
- P<n> (<date>) <falsifiable premise> — grounded: <evidence, dated> | assumed
```

 **Rewrite superlatives into testable claims** ("beats everything" → "cheaper than X on workload Y") — at least one premise should correct the brief, and say so. Two premises are mandatory: the **reference class** — the 2–3 best existing things this will be compared against, where it must win, where it may lose — and the **severity line** — which failures reject the idea outright versus merely mark it down. Ground the load-bearing premises: live searches, registry/collision checks, adoption numbers — with dates. Lock the ledger with an explicit gate: "these premises govern the design; flag any before I proceed."

## 4. Offered cold-read

Offer (don't force) a fresh-context challenge of the locked premises before design: dispatch superstack-lens with the ledger passed **as a file it Reads** — never interpolated into the prompt — and no access to your rationale. Fold verdicts in by evidence, not deference.

## 5. Priced approach menu

Present 2–4 build approaches, each carrying its downstream cost, with one marked recommendation. **A menu summarizes a mapped space — it never boxes the conclusion in**: name what's outside the menu, and treat the user picking none as information, not friction. Terse approvals get unpacked: restate everything a "go ahead" just locked, invite a flag. **A "park" outcome routes to superstack-queue** — one bullet with the value hypothesis the battery just built and a revisit trigger — never to silence. **When descriptions can't get a pick** — "show me", "I don't know what I want" — escalate to **superstack-cocreate**: the menu becomes embodied one-page probes, one contested assumption per round, and its ratified requirements return to this premise ledger.

## The prompt-time door (D-18)

When the front-door hook's offer was ACCEPTED (the session carries its one
injected line and the owner chose shaping), run the stages above stakes-scaled
for a personal ask: frame in one breath, then **3–5 questions, ONE AT A TIME,
through the question tool** — every question carries a marked recommendation,
with option previews whenever the choice is visual. A trivial ask that slipped
through the hook gets ONE question and an immediate exit to plain work. Live
options are the default; if the owner's NOISE lines show the choosing is
theater, demote to announced defaults. **Before any build action, land the
premise ledger and chosen approach as `.superstack/tasks/<slug>.md`** (pointer
grammar, `goal:` line) — on a fresh workspace this CREATES `.superstack/`, and
that is by design: the first shaped idea founds the workspace's memory; no
other bootstrap exists (no install questions, no ceremony). If the owner chose
"build straight away" at the offer, honor it silently — the choice was the
whole point.

## Handoff

The accepted premise ledger and chosen approach feed **superstack-scope** — done gets its named external check there, and a task file opens if the work earns one. If a premise later falls, that's a re-plan trigger, not a failure: update the ledger, date the change.
