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

## 2026-08-08 — the caching-row fix, measured with repetition (D-56)

- change under test: inception's description gained the Skip redirect
  "changes to a running codebase (superstack-scope)", funded by two in-place
  trims; scope untouched (former-kernel, and any anchor echoing the missed
  prompt would break the non-quoting rule above). Listing at commit 81a18f7,
  7,946 chars of 8,000.
- model: claude-sonnet-5 (`claude -p`, one call per prompt, neutral cwd)
- checker-must-fail drill re-run first: 2/3 with exactly the planted row
  missing.
- target row ("add caching somewhere, the app feels slow lately" →
  superstack-scope): **4 hits in 5 runs** (drill, full pass, three
  repetitions). The 2026-08-01 baseline recorded it as its sole miss.
- full 25-row pass on the new listing: 23/25 on its single run — but the
  repetition work below is the real finding about that number.
- newly exposed by repetition, NOT caused by this change: the front-door row
  ("I don't know which of your tools fits, but I want to overhaul this
  payment module carefully" → superstack) scored **1 hit in 4 clean runs**,
  drifting to superstack-scope. This row's competition (gateway vs scope) is
  untouched by the inception edit; the 2026-08-01 baseline simply caught its
  lucky run. Corollary: single-run totals here carry at least one row of
  luck in either direction; compare rows across repetitions, not totals
  across dates. Parked as its own item (queue Q30).
