# Changelog

## 1.0.0 (2026-08-03)

The idea-shaping interior is rebuilt around a visible, durable decision
sheet, and the platform claim is now proven on every push.

- **Shaping**: a triviality valve (regret, decision count, whether the
  output has a face); a read-back that states the idea's unsaid
  implications for free correction; topics cast under seven coverage
  lenses with a cold rival cast merged before question one and its
  outcome announced either way; a six-line expert decision brief before
  every nontrivial question (the decision, why now, what an expert
  notices, a starred recommendation with its reason, the real
  alternative, what closes the topic); regret-ordered walking where a
  high-regret topic stays open while its unknowns remain; batched
  question rounds (up to four independent questions per round); hedges
  and streaks of bare accepts mark a topic assumed rather than settled,
  and the two highest-regret assumed topics earn embodied re-rounds.
- **The face law**: anything with a face settles only by reacting to an
  embodied artifact, at a fidelity tier the user picks with its cost
  stated (an ASCII sketch, a skeletal page, or a full render in the
  native medium); receipts name the tier; picks below full fidelity are
  re-confirmed at the first real render; skipping embodiment requires
  the user's own words. The look gate now enforces the receipt: building
  on a face while a face topic sits unreacted bounces at claim time.
  Guarded red-first by hooks/test-face-receipt.sh.
- **Sheet durability**: the sheet is written at cast time, pointer line
  first, and touched at four defined moments only; one line per topic
  id, with the status doctor reporting every sheet and flagging
  duplicate ids.
- **cocreate**: owns rendered look probes (its visual refusal is gone);
  invoked under a sheet it settles one topic and returns; standalone it
  still covers an already-named artifact.
- **Platforms**: CI runs every suite on macOS, Linux, and Windows (under
  Git Bash) per push, with line endings pinned and a jq guard so
  fail-open hooks cannot fake a green. Two real portability defects
  fixed on the way: the root resolver now returns one path form on
  Windows, and the router-budget count is locale-pinned to characters.

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
