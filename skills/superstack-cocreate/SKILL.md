---
name: superstack-cocreate
description: A wanted text artifact with latent requirements — doc, plan, spec, schema, API shape — where direct questions get "I don't know, show me options" and requirements arrive as reactions. Also when an approach menu can't get a pick, and on "probe rounds". Skip when requirements are statable (interview) and for visual/UI artifacts (design tools own those).
---

# superstack-cocreate

People can't describe what they want, but they recognize it on sight. Probes make recognition cheap — and a reaction is data only if you know exactly what it was reacting to.

The description's deferrals (a spec tool when requirements turn out statable; a design-variant tool for visual artifacts) hold only when such a tool is actually installed — confirm it appears in this session's skill listing before handing off, and say so; absent, these rounds cover the ask.

## The round

1. **Name the single contested assumption this round tests.** One axis per round — probes that differ on several axes at once produce reactions nobody can decode.
2. **Write 2–4 probes: identical voice, format, and length** — one page hard cap, skimmable in about two minutes each — **differing only on that axis** (when format itself *is* the contested axis, format varies and everything else holds). Probes are presented in the conversation: they exist to be reacted to now, not kept — say so up front; only the ratified ledger persists. Example, for "design the webhook API": probe A versions per-tenant, probe B versions globally — same headings, same length, one section different.
3. **Present.** Picking none is information, not friction — name what's outside the menu (inception's rule), and treat "none of these" as the axis answered: say what it just excluded.
4. **Decode aloud, then ratify.** "You rejected B — I read that as <requirement>. Confirm or correct." **Nothing locks unratified**: your reading of a reaction is a model-authored claim, not evidence (R1 applied to preferences — the user's confirmation is the independent check on your decode). A wrong decode caught here costs a sentence; locked, it costs the artifact.
5. **Ledger what ratified — in the task file.** Settled requirements append as numbered, falsifiable premises to `.superstack/tasks/<slug>.md`, using inception's premise-ledger block (its stage 3 — don't mint a new format). Open the file if none exists, first line the pointer (scope's grammar: `<!-- task: <slug> — goal: <the artifact being elicited> — next: next round on <axis> -->`) — multi-round elicitation is exactly the session-boundary risk task files exist for. Ratifications that live only in chat die with the session. Open questions become the next round's axis.

## Convergence and escape

- **Cap at ~3 rounds.** Still foggy → the fog is the finding: fall back to direct interrogation (superstack-inception / superstack-scope), or park via superstack-queue with what the rounds did settle.
- **Probes are discarded at convergence — say so.** Only the ratified ledger and the final artifact survive.
- Converged → **if you entered from inception, return there**: the ratified premises join its ledger and its remaining stages (the lock, the offered cold-read, the priced menu) still run. Standalone → hand the ratified ledger to **superstack-scope**: "done" gets its named external check there, and the real artifact gets built once, against requirements that are now statable.

## Red flags

- Probes drifting in style or length between options — the reaction will be to the style.
- Locking a requirement from a reaction the user never confirmed.
- Polishing a probe — a probe someone is reluctant to throw away has already cost too much.
