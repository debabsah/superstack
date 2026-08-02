# Changelog

## 0.8.0 (2026-08-01)

The first public-facing cut, built as a milestone campaign: every milestone
closed through a cold fresh-context audit (auditor-red beats builder-green),
and the audits that went red on their first round forced fixes that had to
pass a second cold round before anything shipped.

- **Positioning**: every public surface (README, both manifest descriptions)
  leads with the memory-and-law identity: where your goals, corrections,
  and evidence live across every session, with deterministic gates that
  enforce them. No surface promises that skill modules fire on their own;
  hooks fire deterministically, modules are the routed-to specialist bench.
  Guarded by `hooks/test-positioning.sh`.
- **Router diet**: the 25-skill listing cut from 10,688 to 7,986 characters
  against the harness's 8,000-character budget, so a fresh install routes
  instead of being silently stripped to name-only rows. Kernel-owned
  descriptions untouched; redundant name-echo trigger phrases dropped.
  Guarded by `hooks/test-router-budget.sh`.
- **Hardening**: the PreCompact carrier sanitizes what it carries (control
  bytes stripped, 600-char cap); the status doctor reports every state file
  the product maintains, receipts included; a session-start backstop writes
  the `.superstack/` ignore rule when an overlay sits untracked and
  unignored; skills that defer to outside tools now check the tool is
  installed and name their built-in fallback.
- **Eval**: a routing-accuracy eval ships in `eval/routing/`: method,
  25-prompt set, runner, and a recorded run: 24/25 intended-route matches
  (claude-sonnet-5; limitations stated in the method, misses printed).
- **Docs**: the gates documented as one-bounce by design with the override
  always available and logged, the `jq` fail-open consequence stated, and
  the zero-network / zero-residue claims written as checkable facts.

Versions before 0.8.0 predate this changelog; their record is the
development repository's history and `DECISIONS.md`.
