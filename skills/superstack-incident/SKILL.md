---
name: superstack-incident
description: A live incident — production down or degraded, users affected, data at risk, a deploy gone wrong — however phrased ("why is this broken" included); mitigation outranks diagnosis while harm is ongoing. Skip for dev-time bugs with nothing live behind them (superstack-debug).
---

# superstack-incident

Mid-incident, priorities invert: **mitigate first, diagnose later** — and the timeline you don't keep now cannot be reconstructed honestly afterward. Every normal gate stays visible; the human gate stands (its one narrow exception is in step 4).

## The response

1. **Mitigate.** Rollback, feature-flag off, failover, rate-limit — the cheapest action that stops user harm, preferring reversible mitigations. A rollback is a tourniquet, not an admission. Expect the outward gate on mitigations that publish — `kubectl apply`, `terraform apply`, `git push` (the gate's actual list, not a class: `kubectl rollout undo` and most rollback verbs pass ungated). For `git push` it bounces once; retry the identical command (the documented once-ungated path — superstack-outward logs the override automatically). The applies and registry publishes sit in the destructive tier, where a retry alone never passes: write the owner's one-shot grant — one line, `grant: kubectl apply`, into `.superstack/outward-grant` — or have the owner write it, then retry; the gate consumes the grant and logs the use. Either way, note the skipped sweep in the timeline and run **superstack-outward** at stability, scoped to what shipped.
2. **Open the incident file in the same breath:** `.superstack/tasks/00-incident-<slug>.md` — and `mkdir -p .superstack/tasks` silently if it doesn't exist; the overlay's offer-and-interview waits for stability, an outage is not the moment. The `00-` prefix sorts the file first, so the session-start task list reaches it before ordinary tasks. First lines:

   ```
   <!-- task: 00-incident-<slug> — goal: stop <the user harm> — next: mitigate -->
   impact: <who/what is affected, since when>
   severity: <your on-call process's scale if one exists; else plain words — "all checkouts failing">
   started: <HH:MM> · mitigated: <HH:MM or open>
   ```

   **If an ACTIVE plan is mid-step** — check `.superstack/plans/` directly, one ls — camp its frontier with execute's own line: `frontier: <step-id> camped @ <time> <commit> <model>`. Skipping that is a *chosen* loss: an unstamped frontier reads as torn and the next session discards to the last kill-point — if you choose it, say so in the timeline, which is durable.
3. **Timeline as you go.** Timestamped one-liners in the incident file — `HH:MM — observed / did / decided` — written in the turn they happen, not recalled later. **Capture evidence before it rotates:** logs, metrics, screenshots, NOW; they are the postmortem's raw material.
4. **Gates relax auditably, never silently — and the human gate stands.** In most incidents the human is present (they reported it): one-way doors still route to them, stated as exact commands. Self-relaxation is only for an unreachable human with harm ongoing — and each skipped *human* gate gets the full entry, autonomy's grammar verbatim, appended to `.superstack/skipped-gates.md` at the moment of the skip:

   ```
   - G<n> (<date>) <what was skipped> — close: <exact instruction for the human>
   ```

   Mechanical bounces are not human gates: the step-1 outward override lives in the timeline and outward's own log, never as a G-entry.
5. **Comms in plain language.** One forwardable status line for the human: impact, mitigation state, next update time. No unverified cause claims — "cause unknown, mitigated" is calibrated and legal; a guessed cause in a status line is a wrong claim at its loudest.

## After stability: the postmortem

Hand off to **superstack-debug** for root cause — the timeline is its evidence, its procedure runs from the reproduce. The postmortem is debug's "root-cause the escape" written for a reader:

- Timeline (from the file, verbatim), impact, root cause, **why existing checks missed it**.
- Prevention items → superstack-queue entries with revisit triggers; the minted runnable rule → the suite or an overlay oracle row; the working-habit trap → a gotcha.
- **A mitigation that sticks is a decision.** "The write-through cache stays off" is an architecture choice made under the worst deliberation conditions in the method — route it through superstack-decide before the incident file retires; a timeline one-liner is not its record.
- If the broken behavior was vouched for earlier, mark the claim `FALSIFIED` in the claims-log (debug's step 8 — the incident is calibration data).

**Close:** the incident file retires like any task file — ship's ordering rule, durable writes first; prevention items must land somewhere durable before the file dies. Blameless is the tone: the record indicts checks and systems, not people.

## The boundary

This is the solo-with-a-model shape. Severity ladders, paging, incident-commander roles, and status pages belong to your real on-call process, which **wins wherever they conflict**. What this skill owns is the discipline the model itself contributes: mitigate-first ordering, the live timeline, auditable gate relaxation, and the postmortem's route back into checks.
