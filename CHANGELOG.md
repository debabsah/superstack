# Changelog

## 0.9.0 (2026-08-03)

- **Honest enforcement language**: the manifests no longer say
  "deterministic gates that enforce them". Firing is deterministic (hooks
  run on the harness event whether or not a skill loads); enforcement is
  heuristic, logged, and one-bounce overridable, and both manifests now
  carry that disclosure. The README's "what's guaranteed" line sharpened
  to "guaranteed to fire".
- **Slimmer manifests**: the plugin description drops the module roster
  and hardcoded counts for a short pain-first form; the marketplace entry
  keeps a fuller paragraph. No public surface lists a skill count that can
  go stale.
- **Delegation mechanics in the campaign runner**: delegated
  implementation gets a small brief (the step's grain, done-when, and
  named check; never the plan file or the session's history); every
  dispatch names its model tier; a step that rewrites many files runs in
  its own git worktree, and a worktree the session did not create is
  never deleted. Unattended work branches first unless the mandate names
  the default branch.

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
