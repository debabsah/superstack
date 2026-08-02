---
name: superstack-teach
description: The human wants to understand — "walk me through this", "explain at my level", "teach me" — or a handover where the maintainer is the human. Skip for one-line answers and stranger-facing docs (a documentation task, not teaching).
---

# superstack-teach

A verified claim is not an understood system. Every other record in this method flows toward the model or the file; this one flows toward the human — the goal is *their* durable mental model, not another document.

The stranger-facing-docs deferral routes to a doc-generation tool only when one really exists here — look for it in the skill listing and say what you found; with none installed, superstack-ship's docs-as-done owns the document while this skill owns the human's understanding.

## The session

1. **Calibrate first.** Open `.superstack/toured.md` if it exists and start where the last tour ended — then one question about what they already know or use (not a quiz, a placement). Pitch the register there, and hold it: every term of art gets one plain-word gloss or stays out (jargon that outruns the owner is this method's most user-visible recorded failure).
2. **Walk the actual artifact, not an abstraction.** Open the real files; trace **one real flow end to end** — the request, the click, the query — before any architecture talk. When the claim is about *behavior* — what the code does when run — **enter the modality: run the flow and show its output** (superstack-experiential's rule); narrating from memory of what you wrote is the provenance rule failing against your yesterday-self. Name the load-bearing walls and *why* they're load-bearing; decision records (`docs/decisions/`, if the project keeps them) are the why-source — cite them rather than reconstructing rationale from memory.
3. **Check-backs, not lectures.** After each chunk, one question that only has an answer if the chunk landed — "what would break if we deleted X?" beats "does that make sense?" (which always gets yes). A wrong answer means re-teach *differently*, not louder — the register was wrong, not the listener.
4. **Name the honest boundary.** What this walkthrough deliberately skipped, and where it lives — a tour that implies completeness teaches a false map.

## The record

Append one line to `.superstack/toured.md` (step 1 is its reader):

```
- <date> <topic> — depth: <overview|working|deep>
```

So the next teaching session starts where this one ended instead of at zero. Expiry toward doubt applies: a tour ~90 days old is a *stale* map — offer a refresh, don't assume retention.

## Boundary

Docs-as-done (superstack-ship) writes for a stranger with no context; teach writes for *this* human's current model of the system. Producing a doc as a side effect is fine; producing *only* a doc means teaching didn't happen.
