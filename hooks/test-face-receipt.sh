#!/usr/bin/env bash
# Face-receipt clause of the look-step gate: a turn that mutates a face while
# the sheet holds a [face] topic with status:open, or grounded without its
# receipt line, bounces once at claim time — look language does not satisfy
# it, because the receipt records the USER's reaction, not the model's look.
# Ledger-gated like the rest of the hook (the two Stop hooks never both
# bounce). Grammar under test is defined in superstack-inception's sheet block.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/gate-experiential.sh"
pass=0; fail=0

mkfix() {
  fix="$(mktemp -d)"
  mkdir -p "$fix/.superstack/tasks"
  # segment: one genuine user line, then one mutating tool_use on a face
  {
    printf '{"type": "user", "message": "go"}\n'
    printf '{"type":"assistant","content":[{"type":"tool_use","name":"%s","input":{"file_path":"%s"}}]}\n' "$1" "$2"
  } > "$fix/transcript.jsonl"
}

run() { # $1 last_assistant_message
  printf '{"last_assistant_message": "%s", "transcript_path": "%s/transcript.jsonl", "stop_hook_active": false}' "$1" "$fix" \
    | (cd "$fix" && bash "$hook" 2>"$fix/err"); echo $? > "$fix/rc"
}

check() { # $1 name, $2 want_rc, $3 must_contain ('' = skip), $4 must_not ('' = skip)
  rc="$(cat "$fix/rc")"; err="$(cat "$fix/err")"
  ok=1
  [ "$rc" = "$2" ] || ok=0
  [ -n "$3" ] && { printf '%s' "$err" | grep -q "$3" || ok=0; }
  [ -n "$4" ] && { printf '%s' "$err" | grep -q "$4" && ok=0; }
  if [ "$ok" = 1 ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (rc=$rc want=$2)"; fi
  rm -rf "$fix"
}

# A: open face topic + face mutation + look language -> face bounce
mkfix Write /tmp/x/index.html
printf -- '- T3 [face] look and feel — regret:high cost:baked status:open — unknowns: density — enough-when: reaction ratified\n' > "$fix/.superstack/tasks/idea.md"
run 'Verified: page shipped — opened the page -> saw the nav render'
check "open face topic bounces despite look language" 2 "unreacted face topic" ""

# B: grounded face topic without receipt line -> face bounce
mkfix Write /tmp/x/index.html
printf -- '- T3 [face] look and feel — regret:high cost:baked status:grounded — unknowns: none — enough-when: done\n' > "$fix/.superstack/tasks/idea.md"
run 'Verified: page shipped — opened the page -> saw the nav render'
check "grounded face without receipt bounces" 2 "receipt" ""

# C: grounded face topic WITH receipt line -> pass
mkfix Write /tmp/x/index.html
{ printf -- '- T3 [face] look and feel — regret:high cost:baked status:grounded — unknowns: none — enough-when: done\n'
  printf -- '- T3 receipt: mocks/a.html — reaction: "the denser one"\n'; } > "$fix/.superstack/tasks/idea.md"
run 'Verified: page shipped — opened the page -> saw the nav render'
check "receipted face passes" 0 "" ""

# D: no sheet, face mutation, no look language -> existing look bounce intact
mkfix Write /tmp/x/index.html
run 'Verified: done — ran tests, 40 passed'
check "look-step bounce preserved without sheet" 2 "look-step gate" "unreacted face topic"

# E: open face topic but no ledger -> silent (claims gate owns the turn)
mkfix Write /tmp/x/index.html
printf -- '- T3 [face] look and feel — regret:high cost:baked status:open — unknowns: density — enough-when: reaction\n' > "$fix/.superstack/tasks/idea.md"
run 'All done building the page layout'
check "no ledger stays silent" 0 "" ""

# F: open face topic, no face mutation this turn -> silent
mkfix Write /tmp/x/notes.py
printf -- '- T3 [face] look and feel — regret:high cost:baked status:open — unknowns: density — enough-when: reaction\n' > "$fix/.superstack/tasks/idea.md"
run 'Verified: refactor done — opened the page -> saw it unchanged'
check "no face mutation stays silent" 0 "" ""

# D-79: the face bounce carries the human-facing opener.
mkfix Write /tmp/x/index.html
printf -- '- T3 [face] look and feel — regret:high cost:baked status:open — unknowns: density — enough-when: reaction ratified\n' > "$fix/.superstack/tasks/idea.md"
run 'Verified: page shipped — opened the page -> saw the nav render'
check "face bounce carries the human-facing opener (D-79)" 2 "Nothing is broken" ""

echo
if [ "$fail" -eq 0 ]; then echo "face-receipt: all $pass pass"; exit 0
else echo "face-receipt: $fail FAILED ($pass passed)"; exit 1; fi
