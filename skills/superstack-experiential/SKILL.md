---
name: superstack-experiential
description: An artifact with a face — a UI, dashboard, chart, game, rendered document, CLI output a human reads — whenever one is built or changed, before claiming done; and before trusting any new check or harness. Also on "look at it" or "screenshot QA". Skip for pure logic changes proven by existing tests.
---

# superstack-experiential

**First act on every load:** append one line — `skill-load experiential <date> <session-id>` — to `.superstack/receipts/loads.log` (create the dir if missing). Mechanical proof of routing; a face that shipped with no load line is countable.

Green tests prove the layer below. An artifact with a face gets *looked at* — the most consistent failure class on record is work that shipped green, reviewed, and never once seen: invisible UIs, claims verified in a reality never simulated. The trigger is the artifact class, not the task size.

## The look-step

1. **Enter the modality.** Open the page, render the chart, run the CLI and read its output as its user would, click the flow that changed. A screenshot, a live drive, a read-through — whichever the artifact's face is.
2. **Record what you literally saw** as the `saw` half of the ledger line: `Verified: dashboard renders — opened /d/1, saw 12 bars, legible in dark mode`. "Looks good" is not an observation.
3. **Scope to the delta.** What changed visually gets looked at; the whole app does not — unless this is a first ship, which earns the full walk-through.
4. **On a project that ships faces repeatedly, mint the experiential oracle row** (the overlay template has the shape) — a *named* looking step fires; an unnamed one gets skipped under momentum. That is the entire lesson of the failure class.

A Stop hook (`gate-experiential.sh`) now asks for step 2 mechanically when the turn changed a file with a face and the ledger carries no sign of anyone having looked. It is a reminder, not the discipline: it knows a handful of extensions and nothing about whether what you saw was right.

## Checker-must-fail

A check you have never seen fail proves nothing — vacuous asserts, tee-masked exit codes, and stale harnesses all stayed green while broken. Before trusting any **new** check, validator, fixture, or harness:

1. Plant a known-bad input (or revert the fix under test) and watch the check go RED.
2. Restore, watch it go green.
3. Only then does its green count as evidence — and prefer a planted case whose shape the fix did not choose.

## The honest boundary

The look-step catches what tests structurally cannot; it does not supply taste or the caring human's oracle. Multi-day lived use, "does this feel right", and the axes you didn't think to check remain outside — say so in the ledger (`Assumed: usable beyond the happy path — needs your eyes`) instead of letting a clean look-step imply them.
