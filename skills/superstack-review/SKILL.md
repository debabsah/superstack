---
name: superstack-review
description: Use before trusting or shipping an answer, design, plan, analysis, or risky code change — when you are about to commit to it. Also when the user asks for a review, a red-team, a second opinion, or to check work adversarially. For pure code diffs, prefer a dedicated code-review command when the environment has one; this runner covers every other artifact and needs nothing installed.
---

# superstack-review

Don't self-vibe-check. **Manufacture blind adversaries** — fresh context, none of your rationale — and let them attack the actual work. Uses only the built-in Agent/Task tool — no other plugin required. (For a pure code diff, a dedicated code-review command in your environment may be sharper for that narrow case; this runner needs nothing installed and covers every artifact — designs, plans, analyses, schemas, configs, prose.)

## Run it

1. **Run the deterministic checks first** — the acceptance oracle, tests, linters, validators. Don't spend a reviewer on what a tool catches; reviewers are for judgment. Between the two sit **different-kind checks** — types, property/invariant checks, a reference implementation, a dry run on real data — more independent of your blind spots than another model instance; prefer one where it exists.
2. **Size the panel to the risk tier** (the method skill's table): **T2 → one lens**, the dominant risk; **T3 → 2–5 lenses**. **The default first lens is the scope block's load-bearing unknowns** — attack what changes everything if wrong; generic lenses (correctness/logic, security, data/edge-cases, architecture, requirements-fit, ops) fill the rest. Going past the tier minimum needs a named reason — a specific unresolved risk, not thoroughness for its own sake. One concern per lens; no overlap.
3. **Dispatch one `superstack-lens` subagent per lens, all in a single message** (multiple Agent/Task calls in one turn = they run in parallel). `superstack-lens` ships with this plugin (`agents/superstack-lens.md`); its toolset is a harness-enforced allowlist (`Read, Grep, Glob`), so a reviewer **cannot** edit the artifact under review and **cannot** dispatch further subagents. That is a boundary, not a request — the difference matters, because "READ-ONLY" addressed to an agent holding Edit/Write/Bash is only a suggestion. Give each dispatch just its lens and the exact scope (files, diff range, or artifact + the plan/requirements it's judged against); the adversary rules live in the agent.

   **Know what "blind" buys you here.** A dispatched reviewer starts without your reasoning — that is real, and it is what decorrelates it from the momentum errors your context is carrying. It is *not* context-free: it inherits the project's own material, including `CLAUDE.md`, the files, and the repo's history. When that material argues the author's case — a git log that reads as design rationale, a README that blesses the design — point the reviewer at a sanitized copy of the artifact instead, and say in the dispatch which context you withheld.

   If `superstack-lens` is unavailable — an older harness, or this plugin's agents didn't load — **say so out loud**, fall back to a plain general-purpose subagent with the template in [../superstack/references/adversary-prompt.md](../superstack/references/adversary-prompt.md), and treat any reviewer file change in that run as a defect of the run.

   When the operator has named a genuinely different model family (`scripts/superstack-outside.sh`, OUTSIDE_CLI set), add its read as one more lens — same rules as every reviewer: its findings are claims until source-verified (D-57).
4. **Collect, dedup, and *verify each finding against the source* before it earns a place on the fix list** — a plausible-sounding finding that isn't in the actual artifact is dropped. Watch for reviewers converging because they shared context rather than because the defect is real. (This is the method's general **provenance rule**: any agent's report — reviewer, subagent, or you — is a claim until checked against the source; a subagent's "success" on delegated work gets the same treatment.)
5. **Triage** what survives: fix-now / defer-with-a-record / accept-with-a-written-note. **Each fix-now finding mints the categorical check that would have caught its class** (R2: the invariant layer, not the instance) — a test in the project's suite, or an oracle row in the overlay — so that class never needs a reviewer again. Report the verdict answer-first.

## When critique lands on *your own* work

Fold it in and credit it; don't defend. Re-derive from the invariant the critique implies ("no line here may contradict X"), not just the lines it cited. Downgrade your own earlier verdict out loud if the evidence contradicts it.
