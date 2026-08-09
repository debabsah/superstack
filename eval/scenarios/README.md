# The behavioral eval lab

Five deterministic scenario scripts and a runner that print a scorecard for
the promises on this product's own box: work survives compaction and session
death, evidence stops counting when the code under it changes, a bare "done"
does not pass, and the ambient machinery stays cheap. The routing eval next
door (`eval/routing/`) measures whether skills fire; this lab measures
whether the deterministic spine holds.

## The one design law

**The lab measures; the suites gate.** `run.sh` always exits 0, and a MISS in
its scorecard is data, not a build failure — a baseline is allowed to show
the product missing, because that is what a baseline is for. The split is
enforced one directory up: `hooks/test-eval-lab.sh` pins the two
recovery scenarios (s1, s2) at full marks — those are shipped-behavior
invariants, and a MISS there is a regression — while the measurement
scenarios (s3, s4) are smoked but never count-pinned, so their misses can
move release to release without a test edit. Every scenario supports
`LAB_HOOKS=<dir>` to point it at a different hooks tree; the suite's
embedded drill uses that lever to prove the lab can see breakage.

## The scenarios and their metrics

- **s1 compaction-carry** — the chain: PreCompact carries the ACTIVE plan's
  goal and frontier out; the compact-source session start carries them back
  in with the resume ritual armed. Metric: recovery assertions passed.
- **s2 session-death** — a hard kill mid-step: the torn signal, a clean
  camp, the in-flight task's next action, and the undischarged-obligation
  count must all be visible from disk at the next start. Metric: recovery
  assertions passed.
- **s3 evidence-staleness** — the receipt path in both staleness
  directions, including the two documented limits (uncommitted edits under a
  receipt; a fabricated receipt naming the current head). Metric: staleness
  catches over the battery. The documented-limit rows are the baseline the
  staleness milestone exists to move.
- **s4 claim-attacks** — an adversarial corpus of completion phrasings
  (indirect, implied, passive, fabricated) against the claims gate, plus
  honest-report controls that must not bounce. Metrics: attacks caught,
  honest reports untouched. The claim grammar is frozen by ruling, so every
  escape recorded here is tuning data for a future ruling, never a silent
  widening.
- **s5 ceremony** — the ambient voice against its own coded budget, hook
  latency on the every-turn paths, and (behind `RUN_MODEL_ARMS=1`, real API
  calls) the marginal cost of the ambient context on a trivial task, bare
  arm versus with-ambient arm. The third arm is each future revision of the
  product — the reason this lab is re-run after every milestone.

## Running it

```
bash eval/scenarios/run.sh                    # free, deterministic
RUN_MODEL_ARMS=1 bash eval/scenarios/run.sh   # adds two model calls (s5)
```

Recorded baselines live in `RESULTS.md`, each with its commit, date, and
model id where arms ran.

## Limitations — read before citing any number

- **Fixture scenarios, not live sessions.** The lab drives the hooks with
  synthetic payloads the way the harness would; it cannot force a real
  compaction, kill a real session, or observe skill routing. Live-session
  judgment stays with the passive telemetry regime.
- **The attack corpus is authored by the same project** that maintains the
  gate. Escapes it does not think of are not counted. Adversarial additions
  are welcome; the corpus grows by addition, never by quietly deleting a
  miss.
- **Latency numbers are machine-relative.** The scorecard pins only a
  coarse ceiling; compare INFO numbers across runs on the same machine.
- **Model-arm numbers are prompt-side simulations** of ambient cost (the
  same class of limitation as the routing eval's listing-only caveat) and
  carry single-run variance; re-run before quoting.
