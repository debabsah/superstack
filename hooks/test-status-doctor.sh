#!/bin/bash
# Self-checks for scripts/superstack-status.sh — the read-only doctor. The
# contract (plan M2; KERNEL.md deviation 12): the doctor reads EVERY state
# file the product maintains — overlay, tasks, residuals, gate-log,
# claims-log, plans/frontier, doctrine, queue, value-log, toured,
# skipped-gates, outward record, receipts — writes nothing, and exits 0
# however little state exists. Count grammars mirror hooks/inject-superstack.sh (R2).
# Temp repos; style of test-outward.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
doctor="$here/../scripts/superstack-status.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

check() { # desc grep_pattern output
  if printf '%s' "$3" | grep -q "$2"; then pass=$((pass+1)); echo "PASS: $1"
  else fail=$((fail+1)); echo "FAIL: $1 (wanted /$2/)"; fi
}

git init -q -b main "$tmp/full"; s="$tmp/full/.superstack"
mkdir -p "$s/tasks" "$s/plans"
printf '%s\n' '<!-- pointer: proj — oracle: make test -->' > "$s/project.md"
printf '<!-- task: t — goal: g — next: n -->\n' > "$s/tasks/t.md"
{ printf '<!-- task: sheeted — goal: g — next: settle T5 -->\n## sheet\n'
  printf -- '- T4 [face] the look — regret:med cost:loose status:grounded — evidence: pick\n'
  printf -- '- T4 receipt: mock.html — reaction: "B"\n'
  printf -- '- T5 run model — regret:med cost:baked status:grounded — evidence: pick\n'
  printf -- '- T5 run model — regret:med cost:baked status:open — unknowns: where output lives — enough-when: pick\n'; } > "$s/tasks/sheeted.md"
printf -- '- Assumed: x — y — z\n' > "$s/residuals.md"
printf '2026-07-30 BOUNCE phrase=done snippet=x\n2026-07-30 PASS phrase=verified snippet=y\n' > "$s/gate-log"
printf '2026-07-30 · suite green · bash hooks/test-x.sh -> all pass\n2026-07-29 · CI green · gh run watch 1 FALSIFIED 2026-07-31 — broke on Linux\n' > "$s/claims-log"
printf -- '<!-- plan: pub status: ACTIVE -->\ngoal: ship it honestly\nfrontier: M2 in-progress @ t abc123 model\n' > "$s/plans/pub.md"
printf '# doctrine\n## 2026-07-30 — rule one\ntext\n## 2026-07-31 — rule two\ntext\n' > "$s/doctrine.md"
printf -- '- Q1 (2026-07-29) open thing - why - revisit: later\n- Q2 (2026-07-30) taken thing [taken 2026-07-31]\n- Q3 (2026-07-31) second open - why - revisit: later\n- Q4 (2026-07-30) built thing [resolved 2026-08-01 - shipped]\n- Q5 (2026-07-31) moved thing [reshaped 2026-08-02 - folded into Q3]\n' > "$s/queue.md"
printf -- '- V1 (2026-07-01) signups up, check by 2026-07-15 - open\n- V2 (2026-07-01) time saved, check by 2026-07-10 [HELD 2026-07-11]\n' > "$s/value-log"
printf -- '- 2026-07-31 the state layer — depth: overview\n' > "$s/toured.md"
printf -- '- G1 skipped push gate [closed 2026-07-31]\n- G2 skipped review gate\n' > "$s/skipped-gates.md"
printf '2026-07-31T20:33 BOUNCE verb=git push cmd=x\n2026-07-31T20:34 PASS-receipt verb=git push cmd=y\n' > "$s/outward-log"
printf '2026-07-31 20:34 swept: delta — findings: none\n' > "$s/outward-pass"
mkdir -p "$s/receipts"
printf 'command: c\nexit: 0\n' > "$s/receipts/emitted-2026-07-31-x"
printf 'skill-load execute 2026-07-31 sid\n' > "$s/receipts/loads.log"

before="$(find "$s" -type f | wc -l | tr -d ' ')"
out="$( cd "$tmp/full" && bash "$doctor" 2>&1 )"; ec=$?
after="$(find "$s" -type f | wc -l | tr -d ' ')"

check "overlay pointer reported"            "oracle: make test" "$out"
check "ACTIVE plan and frontier reported"   "plan: pub ACTIVE.*M2 in-progress" "$out"
check "doctrine statute count reported"     "doctrine: 2" "$out"
check "queue counts only truly-open rows"   "queue: 2 open" "$out"
check "queue names the oldest open date"    "oldest open: 2026-07-29" "$out"
check "claims counted in the ship grammar"  "claims: 1 shipped" "$out"
check "falsified claim counted once, apart" "1 falsified" "$out"
check "value-log open predictions reported" "value: 1 open" "$out"
check "toured record reported"              "toured: 1" "$out"
check "skipped gates open count reported"   "skipped gates: 1 open" "$out"
check "outward tallies reported"            "outward: 1 bounce" "$out"
check "receipts reported"                   "receipts: 2" "$out"
check "sheet counts reported"               "sheet: sheeted — 3 topic(s), 1 open" "$out"
check "duplicate topic id flagged"          "DUPLICATE topic id(s): T5" "$out"
if printf '%s' "$out" | grep -q "DUPLICATE.*T4"; then fail=$((fail+1)); echo "FAIL: receipt line miscounted as duplicate"
else pass=$((pass+1)); echo "PASS: receipt lines never count as duplicates"; fi
if [ "$ec" -eq 0 ]; then pass=$((pass+1)); echo "PASS: exit 0 on full state"
else fail=$((fail+1)); echo "FAIL: exit $ec on full state"; fi
if [ "$before" = "$after" ]; then pass=$((pass+1)); echo "PASS: doctor wrote nothing"
else fail=$((fail+1)); echo "FAIL: file count changed $before -> $after"; fi

# minimal state: overlay only — every other section silent or absent, exit 0
git init -q -b main "$tmp/min"; mkdir -p "$tmp/min/.superstack"
printf '%s\n' '<!-- pointer: p — oracle: o -->' > "$tmp/min/.superstack/project.md"
out="$( cd "$tmp/min" && bash "$doctor" 2>&1 )"; ec=$?
if [ "$ec" -eq 0 ]; then pass=$((pass+1)); echo "PASS: exit 0 on minimal state"
else fail=$((fail+1)); echo "FAIL: exit $ec on minimal state"; fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
