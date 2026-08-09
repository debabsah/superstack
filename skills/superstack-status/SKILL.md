---
name: superstack-status
description: Use when the user asks for the superstack status, overlay health, the calibration record, or what the method has been tracking in this workspace. Read-only report; changes nothing.
---

# superstack-status

Run the doctor and show its output verbatim:

```
bash "<this skill's base directory>/../../scripts/superstack-status.sh"
```

(The harness announces this skill's base directory when it loads; resolve the path from there.)

It reports, read-only: the overlay pointer and stale-date count, in-flight tasks and their staleness, open residuals, the gate's bounce/pass tallies, the claims record (shipped and falsified, archives included), task sheets and their open topics, any ACTIVE plan with its frontier, the doctrine statute count, open queue items with the oldest open date, value predictions and how many are due, tours recorded, skipped gates still open, outward bounce/pass tallies with the last sweep, and the receipt count. If something it reports needs work — no overlay, undischarged residuals, a stale task, a due prediction — offer the matching move (bootstrap offer, `superstack-verify` to discharge, resume-or-retire the task, `superstack-value` to settle) and wait for the user's go.
