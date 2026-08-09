#!/bin/bash
# The cross-references the seam fixes planted (DECISIONS.md D-52..D-55) must
# stay present: each check greps a fact whose silent removal would reopen a
# closed seam. SEAMS_ROOT overrides the tree under test so the planted-defect
# drill can prove the suite fires; unset means this repo.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="${SEAMS_ROOT:-$here/..}"
pass=0; fail=0

has() { # desc file pattern
  if grep -q "$3" "$root/$2" 2>/dev/null; then pass=$((pass+1)); echo "PASS: $1";
  else fail=$((fail+1)); echo "FAIL: $1 ($2 lacks: $3)"; fi
}
lacks() { # desc file pattern — the fact must be ABSENT
  if grep -q "$3" "$root/$2" 2>/dev/null; then fail=$((fail+1)); echo "FAIL: $1 ($2 still carries: $3)";
  else pass=$((pass+1)); echo "PASS: $1"; fi
}

has  "gateway routes campaigns to the runner"       skills/superstack/SKILL.md        "superstack-execute"
has  "gateway routes campaigns to plans, not tasks" skills/superstack/SKILL.md        ".superstack/plans/"
has  "gateway ledger shows the receipt-cited shape" skills/superstack/SKILL.md        "receipt: receipts/"
has  "scope carries the promote edge"               skills/superstack-scope/SKILL.md  "superstack-execute"
has  "verify admits the receipt exception"          skills/superstack-verify/SKILL.md "receipt"
has  "execute routes undesigned reds to debug"      skills/superstack-execute/SKILL.md "superstack-debug"
has  "ship points campaigns at the runner"          skills/superstack-ship/SKILL.md   "superstack-execute"
lacks "execute dropped the knows-nothing claim"     skills/superstack-execute/SKILL.md "knows nothing of plans"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail seam check(s) FAILED ($pass passed) — a closed seam reopened; see DECISIONS.md D-52..D-55 before touching these facts."; exit 1; fi
