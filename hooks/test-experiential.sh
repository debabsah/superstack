#!/usr/bin/env bash
# Self-checks for gate-experiential.sh — the look-step Stop gate.
#
# The contract under test: when a turn CHANGED AN ARTIFACT WITH A FACE and ends
# on a calibrated claim whose evidence shows no sign of anyone having LOOKED at
# it, bounce once and ask for the look-step (or an honest downgrade).
#
# The load-bearing property is the one a second Stop hook can most easily get
# wrong: THE TWO GATES MUST NEVER BOTH BOUNCE. This one stays silent whenever the
# ledger is absent, which is precisely when gate-claims.sh fires. Checks below
# pin both halves of that.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/gate-experiential.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

check() { # desc expected_exit actual_exit
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "PASS: $1"
  else fail=$((fail+1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}

user='{"type":"user","message":{"role":"user","content":"go"}}'
face='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"/p/app/index.html"}}]}}'
logic='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/p/app/server.py"}}]}}'

mk() { printf '%s\n' "$@" > "$tmp/t.jsonl"; }
run() { # $1 stop_hook_active  $2 last_assistant_message
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":%s,"last_assistant_message":"%s"}' \
    "$tmp/t.jsonl" "$1" "$2" | (cd "$tmp" && bash "$hook") >/dev/null 2>&1
  echo $?
}

bare='Verified: the dashboard is done - ran npm test -> saw 40 passed'
looked='Verified: the dashboard is done - opened /d/1 in the browser -> saw 12 bars'
shot='Verified: done - took a screenshot of the page, all four cards render'
downgrade='Verified: build is green - ran npm test -> saw 40 passed. Assumed: not looked at - needs your eyes on the layout'
noledger='All done. The dashboard is finished.'

# --- the core trigger
mk "$user" "$face"
check "face edited + ledger + no look evidence -> bounce"        2 "$(run false "$bare")"
check "face edited + ledger naming what was seen -> silent"      0 "$(run false "$looked")"
check "face edited + ledger citing a screenshot -> silent"       0 "$(run false "$shot")"
check "face edited + honest not-looked-at downgrade -> silent"   0 "$(run false "$downgrade")"

# --- the two gates must not both fire
check "no ledger at all -> silent (gate-claims.sh owns that turn)" 0 "$(run false "$noledger")"
check "loop guard: stop_hook_active -> silent"                     0 "$(run true "$bare")"

# --- scope
mk "$user" "$logic"
check "logic-only turn -> silent"                                0 "$(run false "$bare")"

# S1 (PREREG.md §3): the gate arms on MUTATING tool_use blocks only. A turn
# that merely READ a face file changed nothing — F1 reproduced a pure
# question-answering turn (a lone Read, no mutation anywhere) bouncing.
readface='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"/p/app/theme.css"}}]}}'
mk "$user" "$readface"
check "zero-mutation turn (lone read-only Read) -> silent"       0 "$(run false "$bare")"
mk "$user" "$readface" "$logic"
check "face Read beside a logic-only edit -> silent"             0 "$(run false "$bare")"
for ext in svg css tsx jsx vue svelte html htm; do
  mk "$user" "$(printf '%s' "$face" | sed "s/index\.html/index.$ext/")"
  check "a .$ext edit counts as a face"                          2 "$(run false "$bare")"
done

# --- S4 (PREREG.md §3): the off switch. `claims` keeps ONLY gate-claims.sh,
# so this gate yields on both `claims` and `off`; unset/unknown stays armed.
rung() { # $1 = SUPERSTACK_GATES value
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"%s"}' \
    "$tmp/t.jsonl" "$bare" | (cd "$tmp" && SUPERSTACK_GATES="$1" bash "$hook") >/dev/null 2>&1
  echo $?
}
mk "$user" "$face"
check "SUPERSTACK_GATES=off silences the look gate"              0 "$(rung off)"
check "SUPERSTACK_GATES=claims silences the look gate"           0 "$(rung claims)"
check "SUPERSTACK_GATES=all keeps the look gate"                 2 "$(rung all)"

# --- fail-open
mk "$user" "$face"
printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false}' "$tmp/t.jsonl" \
  | (cd "$tmp" && bash "$hook") >/dev/null 2>&1
check "no last_assistant_message field -> silent (older Claude Code)" 0 "$?"
printf '{"session_id":"t","transcript_path":"/nope/none.jsonl","stop_hook_active":false,"last_assistant_message":"%s"}' "$bare" \
  | (cd "$tmp" && bash "$hook") >/dev/null 2>&1
check "missing transcript -> silent"                             0 "$?"

# --- the edit must belong to THIS turn
mk "$face" "$user"   # face edit BEFORE the last user message
check "face edited in an earlier turn -> silent"                 0 "$(run false "$bare")"

# --- logging must not corrupt the claims-gate tallies the doctor reads
mkdir -p "$tmp/.superstack"
mk "$user" "$face"
run false "$bare" >/dev/null
grep -q 'LOOK-BOUNCE' "$tmp/.superstack/gate-log" 2>/dev/null
check "look bounces are logged"                                  0 "$?"
grep -qc ' BOUNCE phrase=' "$tmp/.superstack/gate-log" 2>/dev/null
check "a look bounce is NOT counted as a claims bounce"          1 "$?"
grep -q ' PASS phrase=' "$tmp/.superstack/gate-log" 2>/dev/null
check "a look bounce is NOT counted as an armed pass"            1 "$?"

# D-79: line 1 of the look bounce addresses the human reading the session.
mk "$user" "$face"
printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"%s"}' "$tmp/t.jsonl" "$bare" \
  | (cd "$tmp" && bash "$hook") >/dev/null 2>"$tmp/d79-err"
head -n 1 "$tmp/d79-err" | grep -q "Nothing is broken"; check "look bounce line 1 addresses the human (D-79)" 0 "$?"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
