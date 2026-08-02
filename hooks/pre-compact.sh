#!/usr/bin/env bash
# superstack — PreCompact: the ACTIVE plan's goal survives compaction.
# BEST-EFFORT by design; godmode's pre-compact.sh is the pattern (S5,
# dogfood/reduction-trial/PREREG.md §3 — INTENT §10 step 2 mandates this
# before the trial, or the retained arm is crippled at every compaction).
# One mechanical act: print the plan's goal: and frontier: lines to stdout so
# the summarizer carries them — the words verbatim, the bytes sanitized (T2,
# dogfood/publish-prep/THREAT-MODEL.md): control chars stripped and each line
# capped at 600, because a plan file is model-written input and this channel
# feeds compaction instructions. The cap is generous on purpose — the budget
# this protects is the summary's, not the preamble's. Every path exits 0: a
# broken hook must never block compaction. Suite: hooks/test-pre-compact.sh.
cat >/dev/null 2>&1   # payload drained; nothing in it changes the act

. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"
pd="$root/.superstack/plans"
[ -d "$pd" ] || exit 0
sanitize() { printf '%s' "$1" | tr -d '\000-\010\013-\037\177' | cut -c1-600; }
for pf in "$pd"/*.md; do
  [ -f "$pf" ] || continue
  head -1 "$pf" 2>/dev/null | grep -q 'status: ACTIVE' || continue
  slug="$(head -1 "$pf" | sed -n 's/.*plan: \([a-z0-9-]*\).*/\1/p')"
  goal="$(sanitize "$(grep -m1 '^goal:' "$pf" 2>/dev/null)")"
  fr="$(sanitize "$(grep -m1 '^frontier:' "$pf" 2>/dev/null)")"
  printf 'superstack pre-compact: plan %s is ACTIVE — carry these lines into the summary verbatim, and verify the frontier stamp at wake:\n' "${slug:-unnamed}"
  [ -n "$goal" ] && printf '%s\n' "$goal"
  [ -n "$fr" ] && printf '%s\n' "$fr"
  break
done
exit 0
