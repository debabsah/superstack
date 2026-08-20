# Changelog

## 2.3.0 (2026-08-20)

superstack now runs on DeepSeek Harness: a fourth host adapter carries
the always-on layer there with every gate at full strength, the whole
skill bench loads natively, and the gate logs grew an audit grammar
with a run counter the status report reads back.

- **DeepSeek Harness adapter** (`adapters/dsh/`): one install script
  writes a superstack profile for the host and installs the hook bridge
  it needs; boot with `npx -y @deepseek-ai/dsh --profile superstack`,
  and uninstall by deleting the profile directory (and the readable
  session logs under `~/.dsh/sessions-superstack`, if you want those
  gone too). The shaping offer,
  the publish gate, and both turn-end gates run at full strength: the
  done-claim and look gates read the turn's final message from the
  host's own session log, poll briefly because that log flushes on a
  delay, and bound their own bounce loop because the host's stop flag
  never goes true. The session-start briefing can trail the first turn
  there, and there is no compaction carrier (the goal returns at your
  next session start); the capability matrix records what each cell
  actually ran, and the one unobserved corner, the briefing surfacing
  by the second turn, is named there rather than claimed. All 25 skills
  load natively from the same folder the Codex
  install line links, and the install section carries a personal note
  from the maintainer's testing with a small local model.
- **Gate audit rows**: every gate-log and outward-log row now names the
  gate that wrote it, claims rows carry a duration where the shell can
  measure one honestly, and per-gate run counters give the capped logs
  a denominator the status report reads back. A growing counter also
  counts as proof the hooks fire, and destructive-tier publish bounces
  now count in the outward tally.
- **The mandate fence**: an unattended-work go-ahead expires with its
  session. The session-start line says so wherever open skipped gates
  surface, and the resume-owning skills carry the rule with a
  compaction carve-out, so an overnight run is never interrupted
  mid-session.

## 2.2.1 (2026-08-12)

The turn-end gate messages now open with a line for the human reading
the session, because hosts render a blocking stop hook under an error
banner and a gate catch could read as a crash to a newcomer.

- **A human-facing first line on every turn-end bounce**: the claims
  gate's message and both of the look gate's messages now open with
  "Nothing is broken: superstack flagged this reply because <reason>;
  the model has been asked to fix it and continue. The instructions
  below are for the model." The wording says flagged rather than held,
  so the line stays honest on hosts where the gates warn and the turn
  stands. Three new suite rows pin the line in place, each observed
  red before the fix landed.

## 2.2.0 (2026-08-11)

superstack now runs on Kiro CLI: a third host adapter carries the
always-on layer there, and the README's first-hour rough edges found by
a cold-reader test are fixed.

- **Kiro CLI adapter** (`adapters/kiro-cli/`): one install script writes
  a superstack agent, because hooks ride the agent config on that host;
  use it per session or set it as your default with one command. You get
  the session-start briefing, the shaping offer, and the publish gate at
  full strength. The two turn-end gates warn there instead of bouncing:
  Kiro's stop event cannot block by design, so the gate's message prints
  in your session and the turn stands. Kiro keeps no session transcript,
  so the adapter writes the turn record the gates read, and every cell
  in the capability matrix comes from a live rehearsed run, the
  interactive look-gate warning included.
- **README friction fixes from a cold-reader test**: the self-check line
  no longer closes an interactive shell on the first failing suite (it
  stops and names the failure); the requirements say plainly that `jq`
  feeds the publish gate and the prompt door and that the `claude` CLI
  is only for the test suites; the install commands say where they are
  typed; the routing badge's 24 of 25 is explained where the eval is
  linked; and the page finally shows real product output, a captured
  session-start read-back.
- **Suites 30 to 31**: the Kiro adapter suite lands at 33 rows with
  every load-bearing translation mutant-drilled, including rows the
  release's own closure audit demanded for a path-traversal guard and
  both working-directory carriers. The stylometry check learns the
  statute's quoted-output exemption: fenced code blocks may quote hook
  output verbatim, and prose stays at ceiling zero.

## 2.1.0 (2026-08-10)

superstack now runs beyond Claude Code: two host adapters carry the
always-on layer to GitHub Copilot CLI and OpenAI Codex CLI, and on
Codex the full skill bench loads too.

- **Host adapters**: `adapters/copilot-cli/` and `adapters/codex-cli/`
  each install with one script, and the README teaches both installs
  beside the Claude Code install. A per-host capability matrix
  (`adapters/README.md`) states exactly what runs on each host, and a
  cell says yes only after the behavior was observed in a live session
  there; the limits sit beside the yes cells, plainly: no compaction
  carrier on Copilot, skill routing unmeasured on Codex.
- **A cross-harness neutrality check** fails the build if skill prose
  names any host's internal events or tools, keeping the core portable
  by construction.
- **Per-module muting**: list module names in `.superstack/muted` and
  each listed module's session-start line goes quiet while sessions are
  asked not to route there; the status report shows the muted set. The
  method kernel, the campaign runner, and the resume ritual cannot be
  muted.
- **The goal is checked, not just shown**: when the recorded stopping
  point sits still across sessions while the commits keep moving, the
  session-start voice says the goal line may be stale ground truth.
- **Evidence from outside tools**: name a browser in a one-line provider
  row in `.superstack/providers` and superstack runs the tool itself,
  writing the receipt from what it observed; browser proving works end
  to end on Chrome headless. Fifteen adversarial audit rounds hardened
  the row grammar and the receipt writer before this shipped.
- **Suites 25 to 30**, the adapter suites and a commit-hygiene guard
  among them. Attack rows whose weapons Windows cannot forge (symlinks,
  read-only directory bits) now skip visibly there instead of failing
  falsely; the macOS and Linux runners keep every row.

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
