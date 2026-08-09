---
name: superstack-execute
description: Run a campaign — a build with milestone structure spanning many sessions — from an opened plan through audited milestones to closure, surviving compaction and cold starts. Load whenever the session-start line names an ACTIVE plan (required before build actions), when opening a plan, or on "continue the plan". Skip for work a task file covers.
---

# superstack-execute

<!-- Absorbed from godmode's execute skill (godmode @ adacebb) through the evidence door (DECISIONS.md D-3), adapted to superstack's state layer: the plan file is the sole authority (no STATE.md), receipts feed the claims-log, camp rides superstack-continuity, one-way doors ride the outward gate. Deliberately deferred pieces are listed in D-3, not silently dropped. -->

**First act on every load: emit the load receipt** — append one line (`skill-load execute <date> <session-id>`) to `.superstack/receipts/loads.log`. Mechanical proof the loop was loaded; a session that skipped it is countable.

## Opening a plan (once per campaign)

One ACTIVE plan per project. Write `.superstack/plans/<slug>.md`, first line `<!-- plan: <slug> status: ACTIVE -->`. Header: a `goal:` line — what this campaign is for, one clause, surfaced at every session start and moved only by the owner (superstack-scope's rule, same reason); the verify command and what green literally prints (or the overlay oracle row it uses); the frontier block (below); the 2–3 load-bearing rulings as pointers to statutes/anchors — never restated; this skill's name as the resume protocol. Body: milestones carrying **intent + done-when + true dependency edges** (an edge is real only when verified) — never implementation detail. Admit only the non-derivables: rulings, paid knowledge, done-definitions, true edges. Test for every line: *could a competent stranger with the spec and repo re-derive this?* Delete it.

**The goal card** — in the plan body, authored WITH the owner at open; their corrections to the draft are the point, that is where the jargon dies. The `goal:` one-liner routes; the card is what a person confirms. Every line must be checkable by someone with none of this product's vocabulary: the owner's words verbatim, quoted and dated; **"when this is done you will be able to"** — three to five outcomes the owner can check by looking or clicking; one weighting line (the main thing versus the supporting machinery); **"not the point:"** — the nearest tempting wrong turns; and, for work with a face, which artifact the owner reacts to at check moments. Amendments append with their date; the card is never rewritten in place (D-46).

**The frontier block** (in the plan header — the plan is the sole authority):

```
frontier: <step-id> {camped|in-progress|torn} @ <time> <commit> <model>
verify: <result> @ <date> — re-run <command> before trusting
in-flight: none | <operation — resume probe: <how progress is read>>
counters: wakes N · receipts N · patch-streak N
blocked-on-owner: none | <items>
```

`in-progress` is written by the turn that begins a step; `camped` only by camp. **Absence of `camped` is the torn trigger — crash is the safe default.** `in-flight` is written BEFORE any destructive act and cleared at its kill-point.

## The session loop

1. **Wake.** Run superstack-continuity's resume ritual, then the plan's named verify command — reality beats the plan. Quote the verify output and the frontier line back; nothing authored. Compaction is a wake — same entry, always. Increment the wake counter.
2. **Torn check.** Frontier not `camped`, or compaction recovery: the step is TORN. Reversible step: default DISCARD to the last kill-point — salvage requires a stated reason. Irreversible step: run its read-only resume probe against the per-unit markers; a probe that cannot determine progress stops and escalates to the owner, never proceeds.
3. **Grain.** If the frontier step lacks implementation grain, write it now — the check FIRST, observed RED, then the grain. Ambiguous asks: state the interpretation assumptions (3–5 bullets) before building. Failing-check output is read and quoted before and after any fix — never "fix the failing test" blind.
4. **Delegation, said out loud.** The grain lists the step's delegable questions — each marked delegate or inline; **"delegable: none" is written, never implied.** Invalid inline reasons, by name: context already loaded, faster myself, smaller than it looked. One question per fresh-context subagent; the brief carries the question verbatim, never the expected answer; returns carry quotes, sources, and the exact command — a subagent's report is a claim until checked (the kernel's provenance rule). Launches log one line to `.superstack/receipts/delegations.log`. Delegated implementation follows the same brief rule: the subagent gets the step's grain, done-when, and named check — never the plan file or the session's history. Every dispatch names its model tier: cheap tier for mechanical slices, strong tier for integration judgment and audits. The wake re-run of the named check is never delegated.
5. **Build in increments that end fast-green**, each closing with a receipt recording the repo revision and its touched checks. Between increments: kill-point. A step that rewrites many files runs in its own git worktree, merged only after its check is green; a worktree this session did not create is never deleted. **A red you did not design** — a wake verify contradicting the plan, an increment that will not end green — is superstack-debug's moment: route there before any second try of the same fix class.
6. **Write-ahead as intent.** The record lands BEFORE the mutating act, the completion mark after — a record without its mark IS the torn signal. Rulings, discoveries, evidence pointers, frontier movement: written in the turn they happen; an uncertain belief keeps its hedge. Owner corrections route through superstack-doctrine (write-ahead, verbatim), and substantial owner input ends PATCH mode.
7. **Hold points.** Before any result becomes expensive to inspect — built upon, migrated over, deleted from, published: run FULL verify now and record it. Before any operation that can destroy uncommitted work: an unconditional WIP commit first. One-way doors are never fired by this session — the outward gate enforces the publish verbs; everything else on the list (charge, send, destructive DDL, force-push) is prepared as an exact command and handed to the owner.
8. **Camp** = the handover. Update the frontier block (stamp time/commit/model, status `camped`); with superstack-continuity's session-close rules this IS the handoff. Camp EARLY when context runs long, then keep working.

**PATCH mode** — boundary observable: fits one increment, touches nothing destructive, cites no ruling, deletes no code this session did not write. The loop shrinks to fast-verify green + one receipt + write-ahead + a one-line camp. A patch streak of three forces a full session.

## The goal check

Fires at campaign open and whenever direction visibly changes — the owner challenges course, or anyone edits the goal or its card. Read the card back and ask **"what here no longer matches what you want?"** — never a yes/no, which invites a rubber stamp. Bring the current artifact when the work has a face (the reaction is the confirmation, not the prose) and one honest line of where the effort has gone since the last confirmation, read from the receipts — effort weight is the true direction, and drift is usually a weighting inversion before it is a wrong turn. Ordinary wakes display the `goal:` line and ask nothing. The answer lands in the card, dated, verbatim (write-ahead, D-46).

## Done — receipts, not prose

Done = the check ran + its receipt exists. Receipts under `.superstack/receipts/` are `emitted-` (command, exit code, timestamp, repo revision — written by the verify entry point itself) or `attested-` (procedure, observed value, timestamp, attester model-id) — never freely authored prose, never credential-bearing stdout (exit codes only for env/token/connection commands). **The ledger line cites the receipt** — `Verified: <claim> — receipt: receipts/<file>` — which is what the claims gate reads, so a receipted fact is never re-run just to satisfy a bounce. The done-line carries the check ID, the receipt pointer, and **"not covered:"** naming what the work does not cover. A bare "done" is invalid; done is revocable — currency is the last full-suite green stamp in the frontier block.

**Receipt decay.** A receipt is evidence only while the surface it covers is unchanged. Once the files its check touches have moved past the repo revision it records, it is a claim again and **superstack-verify's run-it-fresh rule applies in full**. This skill owns the rule because this skill introduced receipts (D-10). When in doubt, decay it.

**Check lifecycle:** red before green, always (checker-must-fail, per superstack-experiential). Once a check has certified a done it is ratcheted — tighten freely; relaxing, removing, or retargeting it needs the owner or a statute.

## The milestone audit

Audits tier by stakes (D-45). A **full cold audit** — a fresh-context subagent (general-purpose — it must run checks, so the read-only reviewer agent cannot audit) re-runs the milestone's checks, reads the done-whens cold, inspects the artifact against them — is owed by: a judgment-shaped deliverable no suite guards (an analysis, a report, a design — anything whose defects tests cannot see), a one-way door, and campaign closure. A **code milestone whose named checks and suites ran green this session** closes on a light pass instead: confirm the receipt exists, cites the current revision, and the done-when's own command is what produced it — no fresh subagent. When the tier is arguable, audit; misjudging down is the expensive error. **Auditor-red beats builder-green.** Closure needs its tier's pass or an owner waiver — owner-authored, quoting the owner, naming the skipped done-when. "Closed" means passed-or-waived; otherwise BUILT-UNAUDITED, **and the frontier never passes two unaudited milestones.** Audit verdicts append to the plan; failures mint gotchas.

## The absent owner

`blocked-on-owner` is a list in the frontier block; the frontier may relocate to any milestone whose verified edges avoid every blocked decision. A parked step must be at a kill-point or reverted. PROVISIONAL covers the choice that cannot wait — it binds until the owner returns, then surfaces under decided-on-your-behalf (superstack-autonomy owns the report shape).

## Closure

The ACTIVE slot is freed only by closure or parking, and both require the survives-it line: which checks live on (and where they now run), which receipts stand, and every escaped residual converted to a `.superstack/residuals.md` entry.

**Then run superstack-ship's calibration-record steps against the campaign** — its steps 1–3, in its order. `ship` owns task files and points campaigns back here, so closure here runs the steps itself (D-10).

Only then does the plan's first line flip to `status: CLOSED` and the session-start line go quiet.
