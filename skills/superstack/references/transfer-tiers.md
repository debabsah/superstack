# What transfers, and what this plugin can't supply

From the forensic study this plugin distills. Read it to calibrate expectations: a method skill installs *discipline*, but the observed quality of the source came from **discipline + scaffolding + operator + judgment**, in decreasing order of transferability.

## Tier 1 — Portable discipline (this plugin carries it)
Name the external check before building; cheapest-probe-first grounding + the oracle-over-population; categorical tests and verify-at-the-claim; work-the-invariant + grep-every-caller; decision records with rejected alternatives; answer-first + verified-vs-assumed reporting and calibrated done-claims; one-question interviewing; incident → runnable rule → prove-it; the `Root cause / Remedy / Lesson` shape. These are prompt-able and live in the skills here.

## Tier 2 — The environment must supply this (a skill can't fake it)
Protected/prod-`main` PR-flow; a **permission gate that actually blocks** irreversible/credential actions; secrets management; **review passes that actually run**; a real acceptance oracle to diff against; a faithful CI-parity execution loop. In the study, a large share of the *safety* and *doc-freshness* came from these — not from the model's in-the-moment restraint. Where your environment provides them, this method + a capable model get you most of the way. Where it doesn't, the model must self-enforce (weaker) — so invoke the runners deliberately rather than trusting the reflex to fire.

## Tier 3 — Judgment (hardest to transfer)
*Which* unknown is load-bearing; *which* rule to try next when a diff won't close; *when* to reframe an ask upward; whether a green is suspect *this time*. A capable model (the target here: a frontier Claude model) supplies much of this; a weaker one needs the Tier-2 scaffolding to compensate. In the source sessions a sharp operator also supplied part of the judgment at key moments.

## What the harness guarantees — and what stays yours
The plugin can enforce **calibration** (the Stop-hook gate bounces done-claims that carry no `Verified:`/`Assumed:`/`PROVISIONAL` marker), **memory** (the overlay carries this project's oracles and traps across sessions), and **firing** (SessionStart and Stop are deterministic; skills trigger by relevance). It cannot enforce the *truth* of any single claim — no text check can — and it does not supply the Tier-2 environment guarantees above. The user's residual job, even when everything works: read the `Assumed:` list, and own the T3 (outward/production) actions gated to them. Worry-less means that residual list is short and honest — never that it is empty.

## The honest caveat
The plugin encodes the transferable part — the discipline — not the source model's raw intelligence or judgment; it does not turn one model into another. Treat its gates as force-multipliers on a capable model: keep verifying at the layer of the claim rather than assuming the method carries you the whole way.
