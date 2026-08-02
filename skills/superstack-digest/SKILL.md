---
name: superstack-digest
description: A period report for a reader outside the session — a weekly update, client status, "what did we get done this month". Skip for end-of-task reports (superstack-ship), retros when a retro tool ships, and recalling past sessions for yourself (a memory tool).
---

# superstack-digest

The digest is the calibration record paying rent outward. It is assembled from records, never from memory — the conversation is scratch; files are the project (superstack-continuity's rule, applied to reporting).

The description's deferrals (a retro tool for retrospectives; a memory/session-history tool for self-recall) bind only if the named tool is really present — check the session's skill listing first and announce the hand-off; when nothing is there, assemble from records right here.

## Assemble

1. **Gather the period's facts from the record:** `git log` across the repos in scope, the claims-log's `Verified:` lines, value-log settlements (`HELD`/`MISSED`), queue movements, open residuals and skipped-gates. Your recall of the period is a hypothesis; the logs are the evidence (R1 on your own memory). **If the record is thin** — early days, files not yet grown — say so: build from `git log` alone and ledger the gap (`Assumed: the period wasn't fully logged — built from git history only`).
2. **Numbers in a digest are data claims.** Sanity-check each before quoting — counts from commands, reconciled against a known total where one exists. A `PROVISIONAL` number never ships to an external reader: round it into honest words or leave it out.

## Write for the named reader

3. **Their language, not the method's.** Shipped work in outcome words, not commit words ("the report now runs in under a minute", not "refactored the aggregation pipeline"). No session jargon, no tier or ledger tokens **in the artifact** — the draft the client reads goes tokenless. **The chat turn that offers the draft is a normal report and carries its ledger** (`Verified:` what you assembled and from which logs, `Assumed:` what the record couldn't show) — the claims gate reads your turn, not the attachment, and the grammar leaves the artifact, never the method. The honesty travels into the artifact anyway: "on track" is a claim; write it only when the record supports it, and never soften a real problem (R5 holds even in business register — *especially* there).
4. **The reader's sections:** done · in progress with expected next · **blocked / asks** (what you need from *them*, explicit — a digest that hides its asks is decorative) · risks worth their attention.
5. **End the same way every time:** where things stand, what happens next and whose move it is.

## The boundary

**Draft, don't send.** Write the draft to a file named for the period (`<period>-digest.md`, or where the human asks) — outward-facing, so sending is the human's act (the inward/outward line). Offer it with anything you'd flag before it travels — a number you couldn't verify, a claim you'd want them to gut-check — stated above the fold, not discovered by the client.
