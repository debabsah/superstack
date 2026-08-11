---
name: superstack-ship
description: Use when finishing a task — writing the final report or status, shipping a change, or handing off — to produce a calibrated done-claim and the docs that make the work reproducible by someone else.
---

# superstack-ship

The report is part of the work, not an afterthought. Ship a **calibrated** claim and the docs that let a stranger redo it.

## The report

- **Answer first**, then the support. Lead with the verdict (done / not done / exact / blocked) in the first line; put evidence underneath, never above.
- **Scale the report to the tier.** T1 = the verdict, its `Verified:` line(s), and the tier line — a few lines, not a document. The full shape here is for T2+.
- **Separate verified from assumed, out loud — as the method's ledger** (canonical shapes: the method skill's ledger section; same tokens every report, and the turn-end claims gate greps for them). Never let an `Assumed:` line read like a `Verified:` one.
- **Cite specifics:** paths, counts, `file:line`, the command you ran, the number you saw, before→after deltas.
- **Report what you observed, not what you intended.** If a step was skipped or a test failed, say so with the output.
- **Calibrate "done" with a use-boundary.** Stamp unproven results **PROVISIONAL** ("do not quote these yet") and lift it explicitly only when the check passed. Scope the claim to exactly what the check covered; put the rest in a visible residual list.
- **State the tier and its gates.** One line: `Tier: Tn — gates run: <verify / review lenses / human gate>`. A skipped gate that leaves no trace is invisible exactly when it matters.
- **Never soften a real problem — including your own.** Flag anything the human must decide (⚠️), state it plainly with the evidence, and repeat the flag into every downstream artifact (PR body, log, memory), not just the chat.
- **End with what the reader still owns.** Even a perfect report leaves a short list: every `Assumed:` line, plus any T3 (outward/production) action gated to the human. Say it explicitly — worry-less means a short, honest residual list, not an empty one.
- **Close in the reader's language: where we are, what's next.** After the ledger, two plain-language lines — the state of the work, and the single next move with whose it is. No session-jargon: a label coined mid-work (a codename, a phase number, an internal shorthand) gets one plain-word gloss or stays out of the report. The reader is catching up, not replaying your process — findings go above; the ending is orientation.

## Docs-as-done

A change isn't done until **someone else could redo it from the record it leaves**. In the same change that ships the work, update the record it affects — runbook, config/topology doc, implementation log. **Scope it to impact:** when a change is fully self-evident in code + tests + commit message, that *is* the record — never write prose that restates a diff (point-don't-copy applies to your own work too). Convert relative references to absolute (dates, versions). Keep one canonical source for a fact; have other docs point to it rather than restating.

## Curate the project overlay

If `.superstack/project.md` exists, **fold in what this task confirmed** — durable facts and **gotchas** (`Gotcha: <trap> → Cause → Rule`) — and announce what changed. Log gotchas liberally — over-capture beats missing one. **Compact on trigger, not ritual:** when the overlay is pushing past ~a page or entries are visibly stale, dedup, retire the obsolete, promote the recurring; skip the pass when it isn't needed. **And never compact in place.** The overlay is git-ignored, so it has no history and no prior revision: a bad or interrupted rewrite of the one file holding the acceptance oracle and the standing human rulings is unrecoverable — nothing else keeps a copy. Write the new page beside it, confirm the **anchors survived** (every oracle row, every `ack'd: human` ruling), then replace, keeping the previous version as `.superstack/project.md.bak`. Note the asymmetry the method already relies on: expiry *demotes* entries (non-destructive, correct); compaction *retires* them (destructive) — and compaction is the one operation that can silently move an anchor. Check `.superstack/gate-log` too: each line is a turn the calibration gate had to bounce; a recurring bounce is a gotcha about working habits — log it like any other trap.

**Keep the calibration record — durable writes first, the destructive one last.** These steps have exactly one safe order, and it is not the order they occur to you in:

1. **Append** every `Verified:` line from the final report to `.superstack/claims-log` (`date · claim · command-or-receipt`) — this is what `superstack-debug` falsifies against when a vouched-for behavior later breaks.
2. **Route** undischarged `Assumed:`/`PROVISIONAL` lines to `.superstack/residuals.md` (the session-start hook surfaces the open count until they're discharged).
3. **Fold** what this task confirmed into the overlay.
4. **Only then, retire the task file** (`.superstack/tasks/<slug>.md`) — promote surviving decisions into the project's committed decision records (`docs/decisions/`, if the project keeps them) or the overlay, and durable facts into the overlay or the project's own docs, then delete it. An in-flight pointer that outlives the work is a lie the next session inherits. An ACTIVE plan is not yours to retire: a campaign closes through superstack-execute's closure, which runs steps 1–3 here itself.

The task file is the transaction's commit record: while it exists, an interrupt is recoverable — you re-read it and redo the steps. Delete it first and an interrupt destroys the `Assumed:` list with no trace, the session-start voice reports *nothing open*, and the run reads as a clean finish. A silent false-clean is the worst state this record can reach, and step order is the whole defence.

**Never trim `residuals.md`.** An open residual is an obligation, not a log line — trimming by length discharges the oldest unverified assumptions, which are precisely the ones most likely to have rotted, and silences the only counter that nags about them. If it is pushing a page, that is a finding to report, not a file to shorten. **`claims-log`: archive, never truncate** — move aged lines to `.superstack/claims-log.<year>` (`superstack-status` and `superstack-debug` read the archives too). A deleted `Verified:` is a claim that can never be falsified, and the record of your own bounces is not yours to prune. `gate-log` needs nothing from you: it rotates itself in the hook, because expiry belongs in the deterministic half rather than in a habit.

## Before you call it shipped

Run **superstack-verify** on the central claim. Don't state as fact anything you haven't verified this session.
