# The code stance — calibrated code

The method's reflexes calibrate *claims*; this stance calibrates the *code itself*. It exists to kill one gravity — the most universal bad habit in software: **graceful degradation that hides breakage**. A swallowed exception, an empty-on-error return, a guessed default — each is an uncalibrated claim written in code. Graceful degradation without an announcement is lying in code.

1. **No silent failure paths.** Every fallback announces itself — a log line, stderr, a named default — or doesn't exist. `except: pass` and return-empty-on-error are claims of success nobody made.
2. **Fail-open vs fail-closed is chosen by blast radius, and the comment says so.** Advisory, observability, and best-effort paths fail open (a missed extra beats a false block). Money, auth, migrations, and deletion fail closed. One comment names the choice: `# fail-open: advisory; a missed check beats a trapped session`.
3. **Code leaves evidence.** Scripts and jobs print what they did, with numbers — rows migrated, files touched, checks passed/failed. Silent success is unverifiable success; it forces the next session to re-derive what happened.
4. **Loud at the boundary, confident inside.** Validate and reject at trust boundaries (user input, network, files, subprocess output). Inside, assert invariants instead of defensively handling impossible states — the defensive branch for the impossible is unreachable, untested, and where bugs hide.
5. **Comments state constraints, not narration.** Ceilings, invariants, deliberate asymmetries, why-nots. Delete anything that explains what the next line does.
6. **House style beats this stance.** The stance fills silence in a codebase; it never fights an existing convention. Per-project overrides live in the overlay's *Conventions & guardrails* section.

## Boundary with minimalism modes

A minimalism mode (e.g. ponytail) governs **how much code exists**; this stance governs **how code fails and what evidence it leaves**. They compose: the laziest solution that works still announces its failures. When they seem to conflict, rules 1, 2, and 4 are never traded for brevity — a shorter diff that hides a failure is a second bug, not a saving.
