---
name: superstack-verify
description: Use when about to claim work is complete, fixed, passing, correct, or done — before committing, opening a PR, or moving to the next task. Also when a result looks good and you're tempted to move on, or a green signal came back suspiciously clean. If the environment ships a dedicated end-to-end verify skill for exercising code changes, prefer it for driving the change; this runner owns claim calibration (the evidence ledger) and non-code artifacts.
---

# superstack-verify

"It ran" is not verification. **Evidence before claims, always.** Verify at the layer of the *claim*, not the layer below it.

Before deferring to a dedicated end-to-end verify skill, confirm one is actually installed — check the skill listing, don't assume; with none present, this runner owns the whole check.

## The gate

Before any success/completion claim or expression of satisfaction:

1. **Identify** the command or observation that would *prove* this specific claim.
2. **Run it fresh, in full** (not a remembered earlier run; not a partial check). One exception: a still-current receipt — superstack-execute's receipt-decay law owns when one counts, and decayed means fresh.
3. **Read** the whole output — exit code, counts, the actual values.
4. **Verify at the layer of the claim.** Exit 0 / "deploy healthy" / "containers up" only proves the layer *below* the claim. If the claim is "the output is correct," look at the output. If it's "the page renders," look at the page. If it's "the definitions load," import them in the built artifact and count them.
5. **Only then** state the claim — as ledger lines: `Verified: <claim> — ran <command> -> saw <result>`, with anything unchecked under `Assumed:` or `PROVISIONAL`. If it fails, state the actual status with the output.

## Sharpen it

- **Know what pass looks like before you run it:** pull the oracle from `.superstack/project.md` — the command *and* what green literally prints. Exit 0 with `3 skipped` is not the pass you meant.
- **The counting environment is binding:** the oracle row's *Counts where* decides where green counts. Local green on a CI-counted claim stays `PROVISIONAL` until the environment of record agrees — quote it (e.g. `gh pr checks`).
- **Discharge residuals — durable write first, delete second:** when this evidence settles an entry in `.superstack/residuals.md`, **append its resolution to `.superstack/claims-log`** (as a `Verified:` line if that's what it became), *then* delete the line from `residuals.md`, then announce it. The order is load-bearing, not stylistic: interrupt it the other way round and you lose the residual *and* never record the claim — and that lost `Verified:` is exactly what `superstack-debug` needs to falsify against when the behaviour later breaks. A residual is discharged only once its resolution is durable somewhere else. The counters treat any remaining `Assumed:`/`PROVISIONAL` line as open.
- **Categorical over enumerated:** assert a property over *all* items of a class, so the check inspects cases you didn't think to list. When it over-fires, diagnose *scope vs. substance* before loosening it.
- **Oracle over the whole population:** when reconstructing hidden logic, diff your candidate against a readable known-good output over *every* row, not a sample; state plainly which parts are transcribed vs. inferred.
- **No known-good output? Manufacture the oracle with a metamorphic relation:** state how the output *must change* when the input changes in a known way (add a row → the count rises by one; permute input order → the result is unchanged), then check that property. It turns hidden truth into a runnable check.
- **A number derived from data is a claim about the data:** before quoting a count, rate, or aggregate as fact, run one independent sanity check — reconcile against a known total, re-derive one row or sample by hand, or check an order-of-magnitude bound — and record the query that produced the number beside it. A figure that fails its sanity check ships as `PROVISIONAL` or not at all.
- **Experiential claims get experienced:** when the claim is that an artifact renders, reads, or is usable — a page, dashboard, chart, document — the proving observation is *entering its modality*: open it, screenshot it, click the flow, and record what you literally saw as the `saw` half of the ledger line. Green tests and zero-must-fix reviews prove the layer below, and the looking step only fires reliably when it is *named* — so on a project that ships such artifacts repeatedly, mint an experiential oracle row rather than trusting the habit.
- **Sample the tails:** first item, last item, weirdest item — not just the middle.
- **Use evidence you didn't generate:** re-open the file you wrote, re-run, screenshot and read it, diff before/after, count what you claimed to count.
- **Treat good news as suspect:** a pass that came too easily is unverified until you can say *why* it's real. Distinguish "the build succeeded" (rehearsal) from "the thing loaded and ran" (reality).
- **Re-check against the original request** and any standing rules from scoping.

## Red flags — you have NOT verified

"should", "probably", "seems to", "Great/Perfect/Done!" before running anything, trusting a subagent's "success" without checking its diff, relying on a partial check, a fallback you just wrote that swallows a failure (`except: pass`, empty-on-error, a guessed default — announce it or delete it), "just this once." Any of these → run the command, read the output, *then* claim.

The plugin's Stop-hook gate bounces done-claims that carry no ledger marker and no receipt line it can check — it checks the format; the truth is this skill's job.
