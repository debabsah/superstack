---
name: superstack-autonomy
description: Unattended work — "go ahead while I'm away", "run overnight", "proceed autonomously", a mandate for hours of solo work — and the return report after. Skip for ordinary interactive turns.
---

# superstack-autonomy

Autonomy is contract-shaped: the human's absence changes what you owe, not what you may skip. Restraint tracks authorization, not timidity.

## Before starting: the contract

1. **Restate the mandate as enumerated terms** — what you will do, what you will not, where you will stop — before any work. A bare "approved" or "go ahead" gets unpacked aloud: list everything it just locked, invite a flag.
2. **The inward/outward line holds.** Local commits are free under the mandate; anything outward — push, publish, PR, deploy, send — stays with the human unless the mandate names it explicitly (the outward gate enforces the publish verbs mechanically; this contract covers the rest).
3. Hedges are gates: "for now", "probably", "I think" in the mandate mark decisions to bring back, not permissions to assume.

## During: the ledger replaces the human

- **A skipped human gate becomes a ledger entry, never a silent skip.** Append to `.superstack/skipped-gates.md`:
  `- G<n> (<date>) <what was skipped> — close: <exact instruction for the human>`
  Mark closed by appending `[closed <date>]` to the line — the SessionStart line counts open entries until then.
- **Commit per verified step** (checks before each commit), so any death point is resumable.
- **Branch first.** Unattended work never starts on the default branch unless the mandate names it; a worktree isolates multi-file rewrites, and the merge back rides the return report.
- **Wait honestly.** Declare idleness instead of manufacturing work; pre-commit the wake condition when watching something external; on wake, re-verify the green you were waiting for rather than trusting it ("1m34s seems fast for two database containers" is the right instinct).

## After: the account

The handoff report is STATUS-labeled and **leads with misses**: what is not done, what was deliberately skipped (with its G-number), what you guessed (flagged as guesses), and what the stretch cost — model/token spend is a disclosed budget decision, not a footnote. `DONE_WITH_CONCERNS` is a legal and often correct verdict. Then the ordinary calibrated ledger: Verified / Assumed / PROVISIONAL.
