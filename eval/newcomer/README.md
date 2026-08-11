# The newcomer instruments — method and frozen rubrics

Two repeatable instruments that turn the adoption experience into numbers
with a method beside them. The law of both: the rubric is frozen BEFORE the
run, every run records the model id and date in RESULTS.md, and findings
route to the workspace queue as dated rows, never into silent fixes. These
are measurements, not gates: low scores are data.

## Instrument 1 — the scored stranger test

A fresh-context agent plays a complete stranger holding only a clone of
this repository. It is ordered to read README.md first and alone, then:

1. Say what the product is, in its own words, before reading anything else.
2. List the install steps in order, including every prerequisite.
3. Answer: what organizes this product — what are its central ideas?
4. Run the README's own self-check line from the clone root and report what
   it printed.
5. Describe the first thing it would do with the product in a real project.
6. Log every point of confusion, each with the README line it happened at.

### Scoring rubric (frozen; two points per row, /12)

### R1 — category and purpose
2 = names both what it is (a coding-agent plugin) and what it is for (work
surviving sessions, dones carrying proof) in its own words; 1 = one of the
two; 0 = neither or a misreading.

### R2 — the organizing ideas
2 = names the four ideas (goal, state, rules, evidence) or all four in its
own words; 1 = two or three; 0 = one or none.

### R3 — install path
2 = steps in order AND names jq as load-bearing; 1 = steps without the
prerequisite (or vice versa); 0 = cannot reconstruct the path.

### R4 — self-check run
2 = runs the loop, reports the real outcome; 1 = runs it but misreads the
outcome; 0 = does not run it.

### R5 — first real use
2 = describes a concrete plausible first session (an entry point it could
actually type or say); 1 = vague but directionally right; 0 = lost. This
row listens for whether the product's entry points are findable — the
typed-entry finding from the market-evidence pass.

### R6 — friction specificity
2 = three or more confusion points each anchored to a line; 1 = fewer or
unanchored; 0 = none logged (a stranger with zero confusion is a rubric
failure, not a perfect product).

## Instrument 2 — the novice inception benchmark

A fresh-context agent plays the ASSISTANT. The user is a hobbyist who typed
exactly: "create a mario game in a single html document". The agent holds
the idea-shaping skill body as its instructions and writes out the OPENING
of the engagement only — the triviality check, the topic cast, and its
first message(s) to the user up to and including the first question round.
The user's answers are never simulated.

### Scoring rubric (frozen; two points per row, /10)

### N1 — plain language
2 = the opening reads for a hobbyist, no method jargon leaks (no internal
vocabulary, no process narration); 1 = mostly plain with leaks; 0 = jargon.

### N2 — the unknown-unknowns surfaced
2 = surfaces three or more decisions the ask never stated (scope/length,
where it runs, saving progress, look and feel, controls); 1 = one or two;
0 = builds or asks nothing beyond the literal ask.

### N3 — defaults carried
2 = every question arrives with a workable default the novice can accept
in one word; 1 = some; 0 = open-ended interrogation.

### N4 — bounded rounds
2 = at most four questions in the round, independent of each other;
1 = five to six or dependent; 0 = a wall of questions.

### N5 — the read-back
2 = states the ask's unsaid implications back before questioning (what a
single-file game implies); 1 = partial; 0 = none.

## Repeating a run

Dispatch a fresh-context agent with the corresponding brief (the exact
briefs used for the baseline are quoted in RESULTS.md), score against the
rubric above WITHOUT amending it mid-run, append the dated entry. If the
rubric itself proves wrong, amend it dated for FUTURE runs; a rubric is
never edited to fit a run already made.
