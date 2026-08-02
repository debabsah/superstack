# Routing-accuracy eval

One number: of 25 plainly-phrased user prompts — one per installed skill —
how many does a fresh model route to the intended skill, given exactly what
the harness router sees (the name + description listing, nothing else)?

## Why this metric

superstack ships 25 skills and states on every public surface that modules
are routed to "on a best-effort basis." This eval prices that best effort.
It directly measures the surface the router diet (DECISIONS.md D-21) edited,
so a description change that hurts routing shows up here as a lower number.

## Method

- `prompts.tsv`: one tab-separated row per skill — `prompt<TAB>expected`.
  Authoring rule: each prompt states the skill's firing moment the way a
  user would type it, and does not quote the description's distinctive
  phrases (generic speech like "I have an idea" is allowed — users say it).
  Full-roster coverage and well-formedness are pinned by
  `hooks/test-eval-routing.sh`; the prompt set is versioned with the
  descriptions it tests, so a routing claim always names its commit.
- `run.sh`: builds the listing live from `skills/*/SKILL.md` frontmatter
  (same rows the harness composes), then makes one `claude -p` call per
  prompt from a neutral temp directory (so no workspace hooks leak into the
  call). The model is asked for a single skill name; the scorer normalizes
  gently (first token, punctuation stripped, a bare short name gets the
  `superstack-` prefix) and then requires an exact match; anything else —
  wrong skill, "none", empty, a sentence — is a miss. Misses are printed
  with the prompt, never hidden.
- Output: `N/25 intended-route matches (model, commit, date)`.

## Running it

```
bash eval/routing/run.sh            # ~25 short model calls
EVAL_MODEL=claude-opus-5 bash eval/routing/run.sh
```

## Limitations — read before citing the number

- **Single-run variance.** Model outputs vary between runs; a one-run number
  is an estimate, not a constant. Re-run before quoting it anywhere new, and
  quote it with its model id and commit.
- **Listing-only simulation.** The real harness router sees conversation
  context this eval does not; a hit here can still miss live, and vice
  versa. Live-session feel (the FELT.md diary) remains the owner's judge.
- **Authored by the same project.** The prompt set was written by the team
  that wrote the descriptions. The non-quoting rule limits leakage; it does
  not eliminate authorship bias. Adversarial prompt contributions are the
  fix, and are welcome.
- **Scoring is exact-match.** A defensible second-best route counts as a
  miss. The number therefore understates "useful routing" and should be
  read as a floor, not a ceiling.

Recorded runs live in `RESULTS.md`.
