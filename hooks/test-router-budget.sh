#!/bin/bash
# Router-listing budget (plan M1, ruled mandatory by DECISIONS.md D-21): the
# harness reserves 1% of a 200K context for the skill listing = 8000 chars, and
# over-budget skills collapse to name-only rows, freshly installed packs first.
# Row formula from the harness binary: len("superstack:"+dir) + 4 +
# min(len(description), 1536), rows newline-joined. Every skill must also HAVE
# a description — an empty one passes the budget by gutting routing.
# Tightening the budget is fine; raising it above 8000 needs the owner.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
total=0; rows=0

for d in "$root"/skills/*/; do
  s="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue
  desc="$(awk '
    /^---$/ { fm++; next }
    fm==1 && /^description:/ { sub(/^description:[ ]*/,""); buf=$0; on=1; next }
    fm==1 && on && /^[a-zA-Z_-]+:/ { on=0 }
    fm==1 && on { buf=buf" "$0 }
    fm==2 { exit }
    END { print buf }' "$d/SKILL.md" | tr -s ' ')"
  dlen=${#desc}
  if [ "$dlen" -eq 0 ]; then fail=$((fail+1)); echo "FAIL: $s has no description"; continue; fi
  [ "$dlen" -gt 1536 ] && dlen=1536
  name="superstack:$s"
  total=$((total + ${#name} + 4 + dlen))
  rows=$((rows+1))
done
total=$((total + rows - 1))

if [ "$rows" -ge 25 ]; then pass=$((pass+1)); echo "PASS: $rows skill rows found"
else fail=$((fail+1)); echo "FAIL: only $rows skill rows found (expected >= 25)"; fi

if [ "$total" -le 8000 ]; then pass=$((pass+1)); echo "PASS: listing $total chars <= 8000 budget"
else fail=$((fail+1)); echo "FAIL: listing $total chars exceeds the 8000-char budget by $((total-8000))"; fi

echo "router-budget: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
