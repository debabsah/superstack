#!/bin/bash
# Self-checks for front-door.sh — the prompt-time door (D-18; design at
# dogfood/front-door-design/DESIGN.md, premises in PREMISES.md).
# The contract: an IDEA-SHAPED prompt in a workspace with NO shaping state
# gets exactly one injected offer line; everything else gets silence; the
# hook never blocks (exit 0 on every path) and never plants state in a bare
# workspace. Precision over recall (P9): the "does not fire" rows are the
# load-bearing half. Temp dirs; style of test-outward.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/front-door.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

payload() { jq -n --arg p "$1" --arg d "$2" '{session_id:"t", prompt:$p, cwd:$d, hook_event_name:"UserPromptSubmit"}'; }

check() { # desc want_exit want_offer(y/n) prompt dir [env]
  desc="$1"; wex="$2"; woff="$3"; p="$4"; d="$5"; ev="${6:-all}"
  out="$(printf '%s' "$(payload "$p" "$d")" | SUPERSTACK_GATES="$ev" bash "$hook" 2>/dev/null)"; got=$?
  offer=n; printf '%s' "$out" | grep -q "front door" && offer=y
  if [ "$got" -eq "$wex" ] && [ "$offer" = "$woff" ]; then pass=$((pass+1)); echo "PASS: $desc"
  else fail=$((fail+1)); echo "FAIL: $desc (exit $got, offer=$offer; wanted exit $wex, offer=$woff)"; fi
}

# -- bare workspace: the door's home ground ---------------------------------
mkdir -p "$tmp/bare"; git init -q -b main "$tmp/bare"

# -- D-74 M5: a workspace that muted inception gets no offer ----------------
mkdir -p "$tmp/mutedws/.superstack"; git init -q -b main "$tmp/mutedws"
printf 'superstack-inception\n' > "$tmp/mutedws/.superstack/muted"
check "muted inception silences the door"            0 n "create a mario game in a single html document" "$tmp/mutedws"
check "session-1 shaped prompt gets the offer"      0 y "Build me a small local web dashboard that reads the git history of my projects" "$tmp/bare"
check "README's own example gets the offer"          0 y "create a mario game in a single html document" "$tmp/bare"
check "i-have-an-idea gets the offer"                0 y "I have an idea for a plugin that tracks my reading list" "$tmp/bare"
check "i-want-to-build gets the offer"               0 y "I want to build a tiny site for my recipes" "$tmp/bare"
[ ! -d "$tmp/bare/.superstack" ] && { pass=$((pass+1)); echo "PASS: an offer never plants state in a bare workspace"; } \
  || { fail=$((fail+1)); echo "FAIL: offer created .superstack in a bare workspace"; }

# -- precision: ordinary work must stay silent ------------------------------
check "bug-fix prompt is silent"                     0 n "fix the failing test in parser.py" "$tmp/bare"
check "make-sure phrasing is silent"                 0 n "make sure the tests pass and fix whatever fails" "$tmp/bare"
check "i-want-to-make-sure is silent"                0 n "I want to make sure this works before we ship" "$tmp/bare"
check "make-the phrasing is silent"                  0 n "make the error message clearer" "$tmp/bare"
check "slash command is silent (explicit routing)"   0 n "/superstack:superstack shape this idea" "$tmp/bare"

# -- shaping state on disk silences the door --------------------------------
mkdir -p "$tmp/shaped/.superstack/tasks"; git init -q -b main "$tmp/shaped"
printf '%s\n' '<!-- task: t - next: continue -->' > "$tmp/shaped/.superstack/tasks/t.md"
check "a task file silences the door"                0 n "build me a dashboard for my sales data" "$tmp/shaped"
mkdir -p "$tmp/planned/.superstack/plans"; git init -q -b main "$tmp/planned"
printf '%s\n' '<!-- plan: p status: ACTIVE -->' > "$tmp/planned/.superstack/plans/p.md"
check "an ACTIVE plan silences the door"             0 n "build me a dashboard for my sales data" "$tmp/planned"
printf '%s\n' '<!-- plan: p status: CLOSED -->' > "$tmp/planned/.superstack/plans/p.md"
check "a CLOSED plan alone does not silence it"      0 y "build me a dashboard for my sales data" "$tmp/planned"
mkdir -p "$tmp/prem"; git init -q -b main "$tmp/prem"; printf 'x\n' > "$tmp/prem/PREMISES.md"
check "a premises ledger silences the door"          0 n "build me a dashboard for my sales data" "$tmp/prem"

# -- audit: fires are counted where state exists ----------------------------
mkdir -p "$tmp/overlay/.superstack"; git init -q -b main "$tmp/overlay"
printf '%s\n' '<!-- pointer: p -->' > "$tmp/overlay/.superstack/project.md"
check "overlay memory alone does not silence a NEW idea" 0 y "design a new cli for my notes" "$tmp/overlay"
grep -q '^front-door-offer ' "$tmp/overlay/.superstack/receipts/loads.log" 2>/dev/null \
  && { pass=$((pass+1)); echo "PASS: the fire is audited in loads.log"; } \
  || { fail=$((fail+1)); echo "FAIL: no audit line in loads.log"; }

# -- the knob and fail-open -------------------------------------------------
check "SUPERSTACK_GATES=off silences the door"       0 n "build me a dashboard please" "$tmp/bare" off
check "SUPERSTACK_GATES=claims silences the door"    0 n "build me a dashboard please" "$tmp/bare" claims
printf 'not json' | bash "$hook" >/dev/null 2>&1
[ $? -eq 0 ] && { pass=$((pass+1)); echo "PASS: malformed payload fails open"; } \
  || { fail=$((fail+1)); echo "FAIL: malformed payload did not exit 0"; }
printf '' | bash "$hook" >/dev/null 2>&1
[ $? -eq 0 ] && { pass=$((pass+1)); echo "PASS: empty payload fails open"; } \
  || { fail=$((fail+1)); echo "FAIL: empty payload did not exit 0"; }

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
