# Project overlay template — `.superstack/project.md`

Copy this shape into `<workspace>/.superstack/project.md` (git-ignored). It is the method's durable memory *for one project*: keep it **thin and pointer-first** (point to the project's own canonical docs for facts they own; never snapshot volatile values), and let it **evolve** — auto-add confirmed durable facts and gotchas, announce changes, and compact when it sprawls past a page (`superstack-ship` checks).

**The first line MUST be a one-line HTML-comment pointer** (the session-start hook injects it as ambient context):

```
<!-- pointer: <project> — oracle: <how "correct" is checked here>. Canonical docs: <where truth lives>. Full profile: .superstack/project.md -->
```

Then only the sections you actually have (drop the rest):

```
# <Project> — superstack project overlay
> ⚠️ Snapshot of an evolving project; the docs pointed to here are canonical — verify against them. Git-ignored, per-machine, auto-curated.

## Canonical docs (point, don't copy)   — where the real truth lives (CLAUDE.md, etc.)
## Acceptance oracle(s)                  — the single highest-value fact: one row per claim type
##   | Claim type | Command / observation | What pass literally prints | Counts where | Last confirmed (by) |
##   (build, behavior slice, data correctness, regression, deploy health — only rows this project has;
##    "counts where" = local / CI / staging — local green counts only where parity is proven;
##    "(by)" = human ack vs model-inferred — model-inferred rows are assumptions until a human ack)
## Conventions & guardrails              — project-specific method notes; code-stance overrides live here (point to CLAUDE.md for what it owns)
## Gotchas (open — log every trap)       — `<trap> → Cause → Rule` (+ optional date); free-form types; log liberally
## Record shapes                         — how this project logs decisions / incidents
## Working assumptions (unverified)       — inferred-but-unchecked; promote up when confirmed
```

Rules of thumb:
- **The admission test:** an entry earns its place only if it would be false or useless in a random other project *and* can't be cheaply re-derived by exploring. Generic wisdom is the method's job; derivable facts (code maps, API shapes) rot faster than they pay rent.
- If a fact is already in the project's `CLAUDE.md` or another canonical doc, **point to it — don't copy it.** On conflict, the canonical doc wins — fix the overlay, never fork the fact.
- A **gotcha** = a surprise/trap you hit and diagnosed that has a learnable rule — log it the moment you confirm it (full logging policy: the method skill's overlay protocol).
- **Standing human rulings are project-level anchors.** Record them in *Conventions* with a human-ack stamp; they bind until the human lifts them — changing one is an escalation (R6), not an update.
- An oracle row records **what pass literally prints**, not just the command — exit 0 with `3 skipped` is not the pass you meant. Note runtime when it changes strategy (`~20min` beside a slow suite) — cheapest-probe-first needs to know.
- **An artifact with a face gets an experiential row.** When the claim type is "it renders / reads / is usable" (a UI, dashboard, chart, docs page), the row's command is a *looking step* — `open <url> / screenshot / click <flow>` — and "what pass literally prints" is what you literally see (`12 bars, legible in dark mode`). Tests prove the layer below; a named looking step fires, an unnamed one gets skipped under momentum.
- Stamp oracle rows and gotchas with a **last-confirmed date**; ~90 days unconfirmed → demote to *Working assumptions* until re-checked. Expire toward doubt; confident rot is worse than a gap.
- The turn-end claims gate writes `.superstack/gate-log` beside this file; recurring bounces are a gotcha about working habits — log them like any other trap.
- **In-flight tasks** live beside this file too: one `.superstack/tasks/<slug>.md` per multi-session task, first line `<!-- task: <slug> — goal: <what this is for> — next: <action> -->` (the session-start hook surfaces it every session). Opened by superstack-scope; a decision record appended at each re-decide; retired by superstack-ship — promote the durables, delete the file.
- **`.superstack/residuals.md` has a grammar, because two counters parse it.** One `- ` bullet per open obligation:
  `- <date> (<version>) Assumed: <what couldn't be checked> — why — discharge: <what would settle it>`
  (or `PROVISIONAL:` in place of `Assumed:`). The session-start hook and `superstack-status` count **bullet lines carrying a token** — so the file's header may name the tokens freely, and prose that merely *mentions* one is not an obligation. Write an open residual as a bullet or it will not be counted.
- Keep it to roughly a page. When it sprawls, that's the signal to compact (dedup, retire stale, point instead of inline).
