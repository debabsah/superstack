#!/bin/bash
# Self-checks for eval/routing/ — the routing-accuracy eval (plan M3). Static
# only: no model calls here. The contract: prompts.tsv holds exactly one
# tab-separated row per installed skill (prompt<TAB>expected), every expected
# name is a real skills/ dir, prompts are distinct and non-empty, run.sh
# parses, and the method file exists. The eval's NUMBER is produced by
# eval/routing/run.sh, never here.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
ev="$root/eval/routing"
pass=0; fail=0

ok() { pass=$((pass+1)); echo "PASS: $1"; }
no() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$ev/README.md" ] && ok "method file exists" || no "method file missing (eval/routing/README.md)"
[ -f "$ev/prompts.tsv" ] && ok "prompt set exists" || no "prompt set missing (eval/routing/prompts.tsv)"
if [ -f "$ev/run.sh" ] && bash -n "$ev/run.sh" 2>/dev/null; then ok "run.sh parses"; else no "run.sh missing or unparseable"; fi

skills=$(ls -d "$root"/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ -f "$ev/prompts.tsv" ]; then
  rows=$(grep -c '	' "$ev/prompts.tsv" 2>/dev/null)
  [ "$rows" = "$skills" ] && ok "one row per skill ($rows)" || no "row count $rows != skill count $skills"

  bad=0
  while IFS='	' read -r p e; do
    [ -n "$p" ] || continue
    [ -d "$root/skills/$e" ] || { bad=$((bad+1)); echo "  unknown expected skill: $e"; }
  done < "$ev/prompts.tsv"
  [ "$bad" -eq 0 ] && ok "every expected name is an installed skill" || no "$bad expected name(s) match no skills/ dir"

  dup=$(cut -f2 "$ev/prompts.tsv" | sort | uniq -d | wc -l | tr -d ' ')
  [ "$dup" -eq 0 ] && ok "expected names are distinct (full coverage)" || no "$dup expected name(s) duplicated"
  dupp=$(cut -f1 "$ev/prompts.tsv" | sort | uniq -d | wc -l | tr -d ' ')
  [ "$dupp" -eq 0 ] && ok "prompts are distinct" || no "$dupp prompt(s) duplicated"
fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
