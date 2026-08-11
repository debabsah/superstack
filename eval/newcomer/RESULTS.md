# Newcomer instrument baselines

Method and frozen rubrics: README.md beside this file. Scores are judged
against the rubric as frozen before each run; the raw agent reports are
preserved in the workspace record (the run transcripts), and every finding
routes to the queue dated.

## 2026-08-09 — stranger test, run 1 (model: claude-opus, fresh context)

Brief: as quoted in the method file's instrument-1 section — clone only,
README first and alone, tasks 1-6, honesty over politeness.

**Score: 12/12.** R1 2/2 (named both halves in its own words: a plugin
that stops the agent "from forgetting things and from lying about being
finished"); R2 2/2 (all four ideas, unprompted, with the line range); R3
2/2 (steps in order, jq named load-bearing with a stated intent to verify it before proceeding); R4 2/2
(ran the exact loop, reported the final line verbatim, counted 25 suite
endings against the badge); R5 2/2 (concrete first actions: the status
command, then a plain-sentence debug ask to test routing); R6 2/2 (an
eighteen-point friction log, seventeen entries line-anchored — past the
three-or-more bar however the v2 anchor question resolves).

**Reading the score honestly: comprehension is not the bottleneck.** A
capable cold reader reconstructs the whole product from the README. The
instrument's value landed in R6 — the friction log is the largest single
batch of line-anchored README defects any recorded pass in this workspace
has produced (seventeen of its eighteen entries carry anchors), including
one genuine hazard: the README's own self-check line (`|| exit 1` in an interactive
shell) closes the stranger's terminal on the first failing suite — the
exact failure case it exists to surface kills the session before it can be
read. Headline findings, all queued under Q45: the opening sentence's
"part no skill can do alone" riddle; the kernel/runners/modules vocabulary
requiring reader subtraction (a direct writing-rules violation); the
unexplained 24/25 badge reading as a warning; the jq
flat-requirement-vs-honest-callout contradiction; the unverifiable
"capable model at medium-or-higher effort" requirement; the claude-CLI
use-vs-test ambiguity; the install block never saying where the commands
are typed; who-writes-the-ledger and how-receipts-mint never shown; the
tagline's absolutes not surviving contact with the one-bounce and
best-effort disclosures; and the biggest: the README never shows one line
of actual product output — "I finished the README without ever having
seen the record."

Raw reports preserved verbatim: dogfood/newcomer-runs-2026-08-09/.

## 2026-08-09 — novice inception benchmark, run 1 (model: claude-opus, fresh context)

Brief: as quoted in the method file's instrument-2 section — assistant role,
the canonical novice ask, opening only, user never simulated.

**Score: 9/10 (corrected by the cold audit from a first-pass 10/10).**
N1 1/2 — the rubric's 2-band demands NO process narration, and the
user-facing message carries at least three (the blind-second-list
paragraph, "another fifteen or so on my list that I will just handle",
"I will ask how much effort you want me spending"), plus a bracketed tool
note inside the verbatim section; plain wording, but the rubric's test is
absence, and the first pass quietly traded that conjunct for "explained in
plain words" — builder-green by construction, caught by the audit. The
leak is also a PRODUCT finding, not just a scoring one: the skill itself
mandates announcing the rival cast's outcome, so faithful execution
narrates process at a novice — the announce rule and novice-plainness
conflict by design (routed to Q46). N2
2/2 (surfaces far more than three unstated decisions: size, feel, look,
phone, death model, tinkering, the finish line — plus the trademark
implication and the 120Hz timing trap); N3 2/2 (three correctable-for-free
assumptions up front, a starred recommendation with a describe-your-own
option on the question posed, "one word closes this"); N4 2/2 on the
artifact's own text (the visible round holds exactly one question, the
other six previewed as a plan, not asked — judged from the artifact alone;
the first pass leaned on skill-body knowledge a blind score may not use,
struck per the audit; the rubric's undefined "round" unit is a v2 item);
N5 2/2 (the read-back states the unsaid implications before any question:
side-scrolling, keyboard, and the code-drawn-art/IP consequence of
"single file").

**Reading the scores honestly, across both runs (audit-corrected).**
Instrument 1 hit its ceiling at n=1 under a strong model (all six rows
independently re-scored 2 by the auditor); whether that ceiling is the
product's or the model's is an open question for a weaker-model arm.
Instrument 2 did NOT max: N1 discriminated exactly as written and caught a
real design conflict (the skill's announce rules produce process narration
in novice-facing text). The real qualitative yield remains the stranger's
friction log — R6 measured it but under-weights it at two points of
twelve — and the novice opening's weight (581 words before the first
question, faithful to the skill, possibly heavy for a hobbyist's first
contact). Rubric v2 items, dated for FUTURE runs per the amendment law:
a length/first-response-weight row for the novice instrument; a
weaker-model arm for both; the friction log promoted from one rubric row
to the instrument's primary output; define the "round" unit N4 scores;
state whether R6 requires every point anchored or at least three (run 1's
log had one unanchored entry of eighteen). Queued as Q46.
