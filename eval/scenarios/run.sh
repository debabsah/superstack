#!/bin/bash
# The behavioral eval lab's runner — a SCORECARD, never a gate. Executes every
# scenario script beside it, sums PASS/MISS per scenario, and prints one
# comparable block per run. Always exits 0: a baseline is allowed to show the
# product missing (that is the data); the oracle suites in hooks/ are what
# gate, and hooks/test-eval-lab.sh pins which scenarios must score full marks.
# RUN_MODEL_ARMS=1 adds the model-arm ceremony rows (real API calls); unset
# keeps the run free and deterministic. Method and metric definitions:
# README.md beside this script.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
echo "scorecard $(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown) $(date +%F)"
tp=0; tm=0
for s in "$here"/s[0-9]-*.sh; do
  [ -f "$s" ] || continue
  out="$(bash "$s" 2>/dev/null)"
  p="$(printf '%s' "$out" | grep -c '^PASS:')"
  m="$(printf '%s' "$out" | grep -c '^MISS:')"
  tp=$((tp+p)); tm=$((tm+m))
  echo "scenario $(basename "$s" .sh): $p pass / $m miss"
  printf '%s\n' "$out" | grep -E '^(MISS|INFO):' | sed 's/^/  /'
done
echo "totals: $tp pass / $tm miss (a miss is data, not a failure — see README.md)"
exit 0
