# Changelog

## 2.0.0 (2026-08-09)

Evidence that maintains itself, closures that need their artifacts, a
publish tier that waits for you, and the whole product told as four
ideas: your goal, your state, your rules, your evidence.

The behavior change that earns the major number: the destructive tier
of the publish gate (`terraform`/`kubectl apply`, `docker push`, and
the package-registry publishes) no longer passes on an identical retry
alone. It waits for a one-line grant file you write, consumed on use
and logged. Everyday pushes and PR verbs keep the one-bounce charter
unchanged. The grant records your authorization; it is not access
control.

- **Receipts expire by themselves**: `scripts/superstack-mint.sh` runs
  the named check itself and writes the receipt from what it observed:
  command, exit, output tail, revision, covered files, and a
  working-state signature, so receipt content is never prose from
  memory. The claims gate stales a files-bound receipt the moment a
  covered file changes, committed or not, leaves it current across
  unrelated commits, and refuses a receipt that records a failing run.
  Hand-written receipts without a files binding keep the previous
  head-matching behavior exactly.
- **Closures need artifacts**: a claim that a campaign or milestone is
  closed passes only through a cited receipt that exists, is fresh, and
  records a passing run. Ledger wording alone bounces, with its own
  audit row and a message that teaches the minting command.
- **The publish gate closes its verified bypass**: a flag between the
  binary and the verb (`git -C <clone> push`, `gh -R <repo> pr merge`)
  no longer slips past the pattern; every read-only sibling with the
  same shape is pinned silent in the suite.
- **The doctor reports silent darkness**: a missing `jq` (which
  silently disarms the publish gate and the prompt door), a plan file
  the continuity carriers cannot parse (a present-but-dark campaign), a
  workspace with real work but no hook line ever landed, and an off
  switch set in the environment. Each is reported with its consequence,
  and healthy records pinned silent.
- **The eval lab ships in `eval/scenarios/`**: five deterministic
  scenario suites (compaction carry, session death, evidence
  staleness, claim attacks with honest-report controls, and ceremony
  cost) with recorded baselines in `RESULTS.md`. Recovery scenarios
  are pinned invariants; measurement scenarios record their misses as
  numbered data. Known limit, stated plainly: the model-arm input-token
  and cost columns are provisional until the usage parse reads the
  cache fields; the output-token and duration columns are trustworthy.
- **A domain glossary with its defenses coded**: `.superstack/domain.md`
  holds terms, never specs; entries without your `[ack: date]` stamp
  are proposals and never surface at session start, expired entries
  drop, and the ambient line carries a count and a pointer, never term
  content.
- **Smaller sharpenings**: the debug skill opens with its front gate
  (the red comes first; a theory before the red is not debugging);
  review panels append a yield row so a configuration that keeps
  finding nothing accumulates the case to shrink it; inception sheet
  topics record who minted them (`from:` owner, model, rival, or
  reaction); a waiver is recorded as `WAIVED:` with the owner's words
  and is never upgraded into `Verified:` by a later report; the
  session voice's unknown-state fallbacks now name the defect and the
  cure instead of shrugging.
- **The story rework**: the README tells the whole product through the
  four ideas above, with the survival scenarios linked beside the
  routing eval so the claims stay checkable.

## 1.1.0 (2026-08-08)

Campaign-shaped work now routes end to end, a receipt can carry the
evidence a done-claim needs, and the corrections you give once follow
you into every project.

- **Campaign routing**: describe a many-session build at the front door
  and it routes to the campaign runner and its plan files; the scoping
  skill can promote a task into a campaign mid-flight; a check that goes
  red inside a campaign routes to the debugging skill; and a campaign
  that closes writes its verified claims into the project's claims
  record. Asking the idea door for changes to a running codebase now
  lands in scoping instead of idea-shaping.
- **Receipts as evidence**: end a turn by citing a receipt file and the
  done-claim gate reads the receipt instead of parsing your prose. The
  gate checks exactly two things: the cited file exists under
  `.superstack/receipts/`, and its content names the current short
  commit; everything deeper stays the verify skill's job. The gate's
  quiet judgment calls (suppressed phrasings, mixed honest reports,
  missing or stale citations) now leave dated rows in the gate log, and
  a workspace with no git commit yet passes with a row saying exactly
  that.
- **Personal rule book**: save a correction about how you like to work
  once, at the user level, and it surfaces at session start in every
  project the plugin runs in, beside that project's own rules; the
  project's rule wins where they collide.
- **State export**: `scripts/superstack-export.sh` bundles a project's
  `.superstack/` state so a second machine or a fresh clone can pick the
  work up where it stands.
- **Outside reviewer channel**: name a second-model command of your
  choosing in one environment variable and reviews add its reading as
  one more voice; it runs from a scratch directory, is asked to identify
  itself first, and its findings arrive marked unverified until checked
  against the source. Unconfigured, nothing runs.
- **Status doctor**: the read-only status report counts shipped claims
  in the grammar the shipping skill actually writes, and the backlog
  lines name the oldest still-open item, so a quiet queue shows its age.
- **Suites**: new checks pin the campaign-routing facts above, run the
  plugin manifest validator with its warnings treated as failures, and
  lint every skill body and hook comment for narrative drift; CI
  installs the `claude` CLI so all 23 suites run on the bare runners on
  every push.

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
