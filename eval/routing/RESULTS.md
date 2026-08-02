# Recorded runs

Read README.md's limitations before citing any number here — single-run
estimates, listing-only simulation, project-authored prompts, exact-match
floor.

## 2026-08-01 — 24/25

- number: **24/25 intended-route matches**
- model: claude-sonnet-5 (`claude -p`, one call per prompt, neutral cwd)
- descriptions measured: commit eac0309 (the post-router-diet listing, 7,986
  chars of 8,000)
- miss: "add caching somewhere, the app feels slow lately" — wanted
  `superstack-scope`, model chose `superstack-inception`. A defensible
  second-best on a solution-shaped fuzzy ask; scope's description is
  kernel-owned (upstream fable-method's) and carries no quoted trigger
  phrases — same row an independent listing-only spot-check called too thin
  to route to. Tracked as the upstream offer in `.superstack/queue.md` Q13's
  family, not fixable by this repo's diet.
- checker-must-fail drill (same day, before this run): a 3-row set with one
  deliberately wrong expected label scored 2/3 with exactly the planted row
  missing — the scorer proves it can report misses. The drill also caught
  two runner defects before the recorded run existed (stdin leak into the
  model prompt; short-name normalization), both fixed first.
