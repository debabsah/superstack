#!/bin/bash
# Self-checks for eval/scenarios/ — the behavioral eval lab (plan superstack-v2
# M0; ruling D-65). The lab is a SCORECARD, not a gate: its runner always exits
# 0 and reports PASS/MISS counts; this suite is what gates. Contract pinned
# here: the lab's files exist and parse; the runner produces a scorecard line
# per scenario; the two recovery scenarios (compaction carry, session death)
# are shipped-behavior invariants and must score full marks on the real tree;
# and the lab can SEE breakage — the embedded drill points a recovery scenario
# at a stubbed hooks dir and demands misses appear. Staleness and attack
# scenario counts are measurements, never pinned here.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
lab="$root/eval/scenarios"
pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS: $1"; }
no() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$lab/README.md" ] && ok "method file exists" || no "method file missing (eval/scenarios/README.md)"
if [ -f "$lab/run.sh" ] && bash -n "$lab/run.sh" 2>/dev/null; then ok "runner parses"; else no "runner missing or unparseable"; fi
n=0
for s in "$lab"/s[0-9]-*.sh; do
  [ -f "$s" ] || continue
  if bash -n "$s" 2>/dev/null; then n=$((n+1)); else no "scenario unparseable: $(basename "$s")"; fi
done
[ "$n" -ge 5 ] && ok "$n scenario scripts present and parseable" || no "expected >= 5 scenario scripts, found $n"

# The recovery invariants: full marks on the real tree. A MISS in either is a
# product regression this suite must catch, not a measurement to record.
for s in s1-compaction-carry s2-session-death; do
  out="$(bash "$lab/$s.sh" 2>/dev/null)"
  if printf '%s' "$out" | grep -q '^MISS:'; then no "$s must score full marks on the real tree ($(printf '%s' "$out" | grep -c '^MISS:') miss(es))"
  else ok "$s scores full marks on the real tree"; fi
done

# Smoke: the measurement scenarios run and report at least one assertion each.
for s in s3-evidence-staleness s4-claim-attacks s5-ceremony; do
  out="$(bash "$lab/$s.sh" 2>/dev/null)"
  if printf '%s' "$out" | grep -qE '^(PASS|MISS|INFO):'; then ok "$s runs and reports"
  else no "$s produced no assertions"; fi
done

# The embedded drill: the lab must be able to see breakage. A stub hooks dir
# whose pre-compact prints nothing must turn the carry scenario red.
stub="$(mktemp -d)"; trap 'rm -rf "$stub"' EXIT
printf '#!/bin/bash\nexit 0\n' > "$stub/pre-compact.sh"
out="$(LAB_HOOKS="$stub" bash "$lab/s1-compaction-carry.sh" 2>/dev/null)"
if printf '%s' "$out" | grep -q '^MISS:'; then ok "drill: a stubbed hooks dir turns the carry scenario red"
else no "drill: the lab cannot see a broken hook (no MISS under the stub)"; fi

# The runner end to end: one scorecard block per scenario, exit 0.
out="$(bash "$lab/run.sh" 2>/dev/null)"; rc=$?
[ "$rc" -eq 0 ] && ok "runner exits 0 (a scorecard, not a gate)" || no "runner exited $rc"
blocks="$(printf '%s' "$out" | grep -c '^scenario ')"
[ "$blocks" -ge 5 ] && ok "scorecard covers $blocks scenarios" || no "scorecard covers only $blocks scenarios"
printf '%s' "$out" | grep -q '^scorecard ' && ok "scorecard header names commit and date" || no "scorecard header missing"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
