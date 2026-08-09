---
name: superstack-inception
description: A new idea with no spec — a product, tool, feature, or app arriving as "I have an idea", "let's build", "create/make me X". Also on "shape this idea". Skip for bug fixes, specced tasks, changes to a running codebase (superstack-scope) — and "new skill/module/pack" ideas (superstack-smith).
---

# superstack-inception

**First act on every load:** append one line — `skill-load inception <date> <session-id>` — to `.superstack/receipts/loads.log` (create the dir if missing). Mechanical proof of routing; a moment that occurred with no load line is countable.

Shaping is a consult, not an interrogation: the user sees the finish line from minute one, every question has a one-word exit, and a better mode is never gated on confessing confusion. Work is admitted, not accepted.

## 1. The valve

Three tests, all low → say the one-line verdict aloud and build: regret if a guess is wrong; how many user-facing or irreversible decisions the build makes; whether the output has a face. Any face earns at least one artifact reaction, however small the build. A wrong verdict said aloud costs a correction; a silent one costs the build.

## 2. Read-back

Restate the idea sharper than the user said it, plus 2–3 implied-but-unsaid assumptions ("a catalog implies browsing and search; I'm assuming personal use"). The user reacts and corrects for free before anything is asked.

## 3. Cast the sheet

Generate topics from three sources: "the day this exists, what will it be judged on, and by whom?"; "what will this user hate discovering after the build that they don't know to ask about now?"; and a ghost pass — simulate the target user's first contact with the finished thing, happy path AND first failure; stall points become topics. Public-facing asks add the demand topics: who hurts without this today, what they use instead, what evidence kills the idea.

**The coverage contract.** Seven lenses, each of which must yield topics or an explicit "n/a because …": user and value · interaction and information · trust and permissions · lifecycle and operations · failure and recovery · constraints and integration · validation and success. Expert hats stay internal — no hat names, no jargon in chat.

**The rival cast.** For a nontrivial idea, dispatch superstack-lens with ONLY the raw ask (as a file it Reads, none of your cast or rationale): it drafts its own sheet cold; merge every non-duplicate topic before question one. Announce its outcome either way — "rival cast added N topics" or "rival cast skipped: <the valve verdict>" — an unspoken skip is the miss the record counts.

**Write-ahead, at flush granularity.** The sheet lands in `.superstack/tasks/<slug>.md` at cast time, and the file is touched at exactly FOUR moments: creation (the full sheet, pointer line first); the instant a face receipt lands (the look gate reads it); before any risky action or at a long pause; and once at the close, batching every status flip. Between flushes, answers live in the conversation — a crash re-asks at most the answers since the last flush, a trade taken deliberately over per-answer file churn. One line per topic ID, ever: a revision edits the line in place, never appends a second; the close verifies no ID repeats (the status doctor flags duplicates). Template:

```
<!-- task: <slug> — goal: <what this is for> — next: <current open topic as of the last flush> -->
## sheet
- T<n> [face] <topic> — regret:<high|med|low> cost:<baked|loose> status:<open|grounded|assumed> — unknowns: <a; b> — enough-when: <what closes it> — evidence: <user words | reaction | comparable | expert rationale>
- T<n> receipt: <artifact path> — reaction: "<the user's words>"
```

`[face]` marks topics whose output is experienced (UI, page, chart, document, CLI output). A face topic's `status` may not leave `open` without its receipt line — the look gate checks this mechanically. Show the user a 3–7 topic first tranche in plain language (one stake sentence and cost-to-change each); the full merged sheet stays durable. The tranche announcement says the walk's plan out loud: the order, and where each [face] pick lands and why it is not a question ("the look arrives as two rendered pages once real data exists to render them on"). An unspoken deferral reads as an omission.

## 4. The decision brief

Every nontrivial topic opens with six lines before its question:

```
Decision: <plain words>            Why now: <what gets expensive if deferred>
Expert read: <what a practitioner notices that a novice will not>
Recommendation: ★ <default> — because <one concrete reason>
Real alternative: <materially different option> — when <condition>
Enough when: <the reaction or evidence that closes this topic>
```

## 5. The walk

Highest regret first, fuel gauge between topics ("3 of 6 settled; the big one left is the look"). Questions travel in batches of up to four through the question tool when their topics are independent — no answer among them can change another's question; lens-distant topics usually qualify. A batch is one move, and counts once toward the accept-streak unless an answer carries specifics. Solo, always: a high-regret topic whose answer can reshape the sheet, a follow-up minted by a reaction, and every face round. Per-topic medium: **tellable** → one jobs-to-be-done question about the user's lived situation, ★ default attached, "yours" always works; **latent** → one probe round (superstack-cocreate's round, one axis); **face** → the face law below; **expert-only** → settle it, and report the rationale, the rejected alternative, and what would reverse it, as a premise the cold-read attacks. Prefer world-authored comparables as the first probe where real neighbors exist ("here are three existing catalogs — point at the closest"): they reduce invention, they do not immunize your selection or reading of them. No real neighbor → two contrastive exemplars labeled synthetic, never a silent skip.

Reactions mint topics — one split per reaction, announced. The accept-streak is global across consecutive replies, resets on any specific preference or correction, never on session restart; "A, because X" is engaged, bare "sure/fine/ok" is not. A hedge, a reversal, or three unengaged accepts marks the topic `assumed` — and the TWO highest-regret assumed topics earn contrastive re-rounds. A high-regret topic stays open while its `unknowns` remain, whatever the sheet's motion; the backstop — two consecutive moves without net shrink, engaged splits exempt — converts only low- and medium-regret remainders to flagged defaults and forces the close.

## 6. The face law

A `[face]` topic settles ONLY by the user reacting to something embodied — never by a prose menu describing looks, never by a model-applied default, never by model-initiated deferral — before the approach menu locks. The round opens with a priced fidelity offer, ★ scaled to the topic's regret: an ASCII sketch in-chat (cheap; carries layout, density, and hierarchy — cannot carry tone, color, or typography, and the offer says so), a skeletal page on placeholder data, or a full render in the native consumption medium (an HTML page for web UI, a terminal transcript for a CLI, a paginated page for a document, realistic data for a chart, a storyboard for a game). The user's pick sets the spend. First round at any tier is a gestalt pair: two whole variants, materially different, one marked ★ so "recommended" settles in one word; "neither" is legal and folds the objection into the next pair. After a gestalt pick, decompose: "you chose A — I read these three reasons; confirm or correct." Only ratified axes ground; the rest stay open or assumed. Write the receipt line naming the tier reacted to (`evidence: reaction @ <tier>`), then flip status. A below-full-tier pick keeps the first-render revisit line mandatory — reality still votes at the first real render. Skipping embodiment entirely is legal only in the user's own words, recorded `assumed` with the revisit line; it is never the model's call.

## 7. The close

The closing flush lands first: every status flip batched into the sheet, no topic ID repeated. Then read back in the user's words: grounded vs assumed marked honestly, every default reversible in a sentence. The cold-read runs by default here — superstack-lens over the sheet and premises, the ledger passed as a file — declining it is the owner's call, skipping it silently is not. Then the gut-check ("anything on this page you'd hate?"), and a pending line for reality's vote: `- T<n> revisit: first runnable render` — the ratified look is re-shown at the first real render after build starts. Lock the premise ledger (grammar below, reference class and severity still mandatory), present the priced approach menu (2–4 approaches, downstream cost, one ★, name what's outside the menu), and hand to superstack-scope. A park outcome routes to superstack-queue with the value hypothesis and a revisit trigger.

```
- P<n> (<date>) <falsifiable premise> — grounded: <evidence, dated> | assumed
```

Rewrite superlatives into testable claims; at least one premise should correct the brief, and say so. Two premises are mandatory: the **reference class** (the 2–3 best existing things this will be judged against, where it must win, where it may lose) and the **severity line** (which failures reject the idea outright). Lock with: "these premises govern the design; flag any before I proceed."

## The seam

Inception owns the cast, the order, the progress, the closure, and the handoff. superstack-cocreate is the probe engine called for one open topic at a time; it never owns the finish line. Standalone cocreate is only for an already-named decision arriving outside a shaping session.

## The prompt-time door (D-18)

When the front-door hook's offer was ACCEPTED, this same mechanism runs scaled down: read-back in one breath, a small sheet, questions through the question tool in independent batches per the walk's batching rule — each carrying its ★ recommendation, with option previews whenever the choice is visual. A trivial ask that slipped through gets ONE question and an immediate exit to plain work. Before any build action, the sheet and premises land as `.superstack/tasks/<slug>.md` (pointer grammar, `goal:` line) — on a fresh workspace this CREATES `.superstack/`; the first shaped idea founds the workspace's memory. If the owner chose "build straight away" at the offer, honor it silently.
