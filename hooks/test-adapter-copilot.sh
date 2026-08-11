#!/bin/bash
# Self-checks for the Copilot CLI adapter (adoption M8, D-75). The contract:
# adapters/copilot-cli/shim.sh receives a Copilot-CLI hook payload on stdin
# (PascalCase event registration, snake_case fields — the dialect the probe
# captured live) and drives the untouched core hooks, translating outputs:
# ambient stdout becomes {"additionalContext": ...}, an outward bounce becomes
# {"permissionDecision":"deny", ...}, a turn-end gate bounce becomes
# {"decision":"block", ...}. The Stop path distills Copilot's events.jsonl
# into the transcript grammar the gates read. Fail-open everywhere: garbage
# in, exit 0, no block. Fixture payloads mirror dogfood/host-probe fields.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$here/.."
shim="$root/adapters/copilot-cli/shim.sh"
template="$root/adapters/copilot-cli/hooks.template.json"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
command -v jq >/dev/null || { echo "jq is required for this suite"; exit 1; }

ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# ---- the template config -------------------------------------------------
if [ -f "$template" ]; then ok "template exists"; else bad "template exists"; fi
resolved="$tmp/hooks.json"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$template" > "$resolved" 2>/dev/null
if jq . "$resolved" >/dev/null 2>&1; then ok "resolved template is valid JSON"; else bad "resolved template is valid JSON"; fi
if [ "$(jq -r '.version' "$resolved" 2>/dev/null)" = "1" ]; then ok "template carries version 1"; else bad "template carries version 1"; fi
for ev in SessionStart UserPromptSubmit PreToolUse Stop; do
  if jq -e --arg e "$ev" '.hooks[$e][0].type == "command"' "$resolved" >/dev/null 2>&1; then
    ok "template registers $ev as a command hook"
  else bad "template registers $ev as a command hook"; fi
done
# PreCompact is deliberately NOT registered: Copilot processes no hook output
# there, so a registration would be a dead spawn per compaction and a parity
# claim the matrix denies. This row pins the decision.
if jq -e '.hooks | has("PreCompact") | not' "$resolved" >/dev/null 2>&1; then
  ok "PreCompact is deliberately absent"
else bad "PreCompact is deliberately absent"; fi
# PascalCase registration is load-bearing: it selects the snake_case payload
# dialect the shim and the core hooks read. A camelCase key would silently
# switch every field name.
if jq -e '.hooks | keys | map(select(. == "sessionStart" or . == "preToolUse" or . == "stop")) | length == 0' "$resolved" >/dev/null 2>&1; then
  ok "no camelCase event keys (dialect guard)"
else bad "no camelCase event keys (dialect guard)"; fi
if grep -q "shim.sh" "$resolved" 2>/dev/null; then ok "template routes events through the shim"; else bad "template routes events through the shim"; fi
if [ -x "$shim" ]; then ok "shim exists and is executable"; else bad "shim exists and is executable"; fi

runshim() { # event payload cwd -> stdout (exit code in $ec)
  ec=0
  out="$(printf '%s' "$2" | ( cd "$3" && bash "$shim" "$1" 2>/dev/null ))" || ec=$?
}

# ---- SessionStart: ambient lines become additionalContext ----------------
ws="$tmp/ws-session"; git init -q -b main "$ws"; mkdir -p "$ws/.superstack"
printf '%s\n' '<!-- pointer: demo — READ ME. Oracle: true -->' > "$ws/.superstack/project.md"
p='{"hook_event_name":"SessionStart","session_id":"s1","cwd":"'"$ws"'","source":"new","initial_prompt":"hi"}'
runshim SessionStart "$p" "$ws"
if printf '%s' "$out" | jq -e '.additionalContext | contains("superstack")' >/dev/null 2>&1; then
  ok "SessionStart wraps the ambient voice in additionalContext JSON"
else bad "SessionStart wraps the ambient voice in additionalContext JSON (got: $(printf '%s' "$out" | head -c 120))"; fi
if [ "$ec" = "0" ]; then ok "SessionStart exits 0"; else bad "SessionStart exits 0 (exit $ec)"; fi

# ---- UserPromptSubmit: the front door rides additionalContext ------------
ws="$tmp/ws-door"; mkdir -p "$ws"
p='{"hook_event_name":"UserPromptSubmit","session_id":"s1","cwd":"'"$ws"'","prompt":"create a mario game in a single html document"}'
runshim UserPromptSubmit "$p" "$ws"
if printf '%s' "$out" | jq -e '.additionalContext | contains("superstack")' >/dev/null 2>&1; then
  ok "idea prompt in an unshaped workspace surfaces the front door"
else bad "idea prompt in an unshaped workspace surfaces the front door (got: $(printf '%s' "$out" | head -c 120))"; fi
p='{"hook_event_name":"UserPromptSubmit","session_id":"s1","cwd":"'"$ws"'","prompt":"fix the typo in README"}'
runshim UserPromptSubmit "$p" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "plain prompt stays silent"; else bad "plain prompt stays silent (out: $(printf '%s' "$out" | head -c 80), exit $ec)"; fi

# ---- PreToolUse: the outward gate becomes a structured deny --------------
ws="$tmp/ws-push"; git init -q -b main "$ws"
p='{"hook_event_name":"PreToolUse","session_id":"s1","cwd":"'"$ws"'","tool_name":"Bash","tool_input":{"command":"git push origin main","description":"push","mode":"sync"}}'
runshim PreToolUse "$p" "$ws"
if printf '%s' "$out" | jq -e '.permissionDecision == "deny"' >/dev/null 2>&1; then
  ok "unswept publish verb is denied"
else bad "unswept publish verb is denied (got: $(printf '%s' "$out" | head -c 120))"; fi
if printf '%s' "$out" | jq -e '.permissionDecisionReason | length > 0' >/dev/null 2>&1; then
  ok "the deny carries the gate's reason"
else bad "the deny carries the gate's reason"; fi
ws="$tmp/ws-ls"; git init -q -b main "$ws"
p='{"hook_event_name":"PreToolUse","session_id":"s1","cwd":"'"$ws"'","tool_name":"Bash","tool_input":{"command":"ls -la","description":"list","mode":"sync"}}'
runshim PreToolUse "$p" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "read-only command passes silently"; else bad "read-only command passes silently (out: $(printf '%s' "$out" | head -c 80), exit $ec)"; fi

# ---- Stop: distilled transcript arms the claims gate ---------------------
mkev() { # dir final_message [edit_position: before-cut|after-cut|none]
  d="$1"; mkdir -p "$d"
  {
    printf '%s\n' '{"type":"session.start","data":{}}'
    [ "$3" = "before-cut" ] && printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c0","toolName":"bash","arguments":{"command":"sed -i .bak s/a/b/ file.txt","description":"edit","mode":"sync"},"turnId":"0"}}'
    printf '%s\n' '{"type":"user.message","data":{"content":"Fix the bug"}}'
    [ "$3" = "after-cut" ] && printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c1","toolName":"bash","arguments":{"command":"sed -i .bak s/a/b/ file.txt","description":"edit","mode":"sync"},"turnId":"1"}}'
    printf '%s' '{"type":"assistant.message","data":{"messageId":"m1","content":"'
    printf '%s' "$2"
    printf '%s\n' '","toolRequests":[]}}'
  } > "$d/events.jsonl"
}
sp() { printf '{"hook_event_name":"Stop","session_id":"s1","cwd":"%s","transcript_path":"%s/events.jsonl","stop_reason":"end_turn","stop_hook_active":%s}' "$1" "$1" "$2"; }

ws="$tmp/ws-stop-bare"; mkev "$ws" "All the tests pass and everything is done." "after-cut"; git init -q -b main "$ws"
runshim Stop "$(sp "$ws" false)" "$ws"
if printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  ok "bare done-claim on a mutating turn is blocked"
else bad "bare done-claim on a mutating turn is blocked (got: $(printf '%s' "$out" | head -c 120))"; fi
if printf '%s' "$out" | jq -e '.reason | contains("Verified")' >/dev/null 2>&1; then
  ok "the block teaches the ledger"
else bad "the block teaches the ledger"; fi

ws="$tmp/ws-stop-led"; mkev "$ws" "Verified: the suite passes (all checks pass printed). Done." "after-cut"; git init -q -b main "$ws"
runshim Stop "$(sp "$ws" false)" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "calibrated claim passes"; else bad "calibrated claim passes (out: $(printf '%s' "$out" | head -c 100))"; fi

ws="$tmp/ws-stop-loop"; mkev "$ws" "All the tests pass and everything is done." "after-cut"; git init -q -b main "$ws"
runshim Stop "$(sp "$ws" true)" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "stop_hook_active loop guard passes"; else bad "stop_hook_active loop guard passes"; fi

ws="$tmp/ws-stop-read"; mkev "$ws" "All the tests pass and everything is done." "none"; git init -q -b main "$ws"
runshim Stop "$(sp "$ws" false)" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "read-only turn never blocks"; else bad "read-only turn never blocks (out: $(printf '%s' "$out" | head -c 100))"; fi

ws="$tmp/ws-stop-cut"; mkev "$ws" "All the tests pass and everything is done." "before-cut"; git init -q -b main "$ws"
runshim Stop "$(sp "$ws" false)" "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "an edit before the last user message does not arm (cut translated)"; else bad "an edit before the last user message does not arm (cut translated)"; fi

# ---- Stop: native edit tools arm, carry the face, and every shell name ---
ws="$tmp/ws-stop-edit"; mkdir -p "$ws"; git init -q -b main "$ws"
{
  printf '%s\n' '{"type":"user.message","data":{"content":"change it"}}'
  printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c1","toolName":"str_replace","arguments":{"path":"config.txt","old_str":"a","new_str":"b"},"turnId":"1"}}'
  printf '%s\n' '{"type":"assistant.message","data":{"messageId":"m1","content":"Everything is done and working.","toolRequests":[]}}'
} > "$ws/events.jsonl"
runshim Stop "$(sp "$ws" false)" "$ws"
if printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  ok "a native edit tool (str_replace) arms the claims gate"
else bad "a native edit tool (str_replace) arms the claims gate (got: $(printf '%s' "$out" | head -c 100))"; fi

ws="$tmp/ws-stop-face"; mkdir -p "$ws"; git init -q -b main "$ws"
{
  printf '%s\n' '{"type":"user.message","data":{"content":"build the page"}}'
  printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c1","toolName":"create","arguments":{"path":"index.html","file_text":"<html></html>"},"turnId":"1"}}'
  printf '%s\n' '{"type":"assistant.message","data":{"messageId":"m1","content":"Verified: the logic tests pass (suite output read).","toolRequests":[]}}'
} > "$ws/events.jsonl"
runshim Stop "$(sp "$ws" false)" "$ws"
if printf '%s' "$out" | jq -e '.decision == "block" and (.reason | contains("look"))' >/dev/null 2>&1; then
  ok "a face file edited natively reaches the look gate (path carried)"
else bad "a face file edited natively reaches the look gate (got: $(printf '%s' "$out" | head -c 100))"; fi

ws="$tmp/ws-stop-lshell"; mkdir -p "$ws"; git init -q -b main "$ws"
{
  printf '%s\n' '{"type":"user.message","data":{"content":"fix it"}}'
  printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c1","toolName":"local_shell","arguments":{"command":"sed -i .bak s/a/b/ f.txt","description":"edit","mode":"sync"},"turnId":"1"}}'
  printf '%s\n' '{"type":"assistant.message","data":{"messageId":"m1","content":"Everything is done and working.","toolRequests":[]}}'
} > "$ws/events.jsonl"
runshim Stop "$(sp "$ws" false)" "$ws"
if printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  ok "the local_shell tool name arms like bash"
else bad "the local_shell tool name arms like bash (got: $(printf '%s' "$out" | head -c 100))"; fi

ws="$tmp/ws-stop-pshell"; mkdir -p "$ws"; git init -q -b main "$ws"
{
  printf '%s\n' '{"type":"user.message","data":{"content":"fix it"}}'
  printf '%s\n' '{"type":"tool.execution_start","data":{"toolCallId":"c1","toolName":"powershell","arguments":{"command":"sed -i .bak s/a/b/ f.txt","description":"edit","mode":"sync"},"turnId":"1"}}'
  printf '%s\n' '{"type":"assistant.message","data":{"messageId":"m1","content":"Everything is done and working.","toolRequests":[]}}'
} > "$ws/events.jsonl"
runshim Stop "$(sp "$ws" false)" "$ws"
if printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  ok "the powershell tool name arms like bash"
else bad "the powershell tool name arms like bash (got: $(printf '%s' "$out" | head -c 100))"; fi

# ---- install.sh: a path sed would corrupt is refused, never half-written -
badroot="$tmp/we & they"
mkdir -p "$badroot/adapters"
cp -R "$root/adapters/copilot-cli" "$badroot/adapters/" 2>/dev/null
ec2=0; COPILOT_CONFIG_DIR="$tmp/cfg-bad" bash "$badroot/adapters/copilot-cli/install.sh" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" != "0" ] && [ ! -f "$tmp/cfg-bad/hooks/superstack.json" ]; then
  ok "a root path with '&' is refused and nothing is written"
else bad "a root path with '&' is refused and nothing is written (exit $ec2)"; fi
ec2=0; COPILOT_CONFIG_DIR="$tmp/cfg-good" bash "$root/adapters/copilot-cli/install.sh" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" = "0" ] && jq -e . "$tmp/cfg-good/hooks/superstack.json" >/dev/null 2>&1 \
   && grep -qF "$(cd "$root" && pwd)/adapters/copilot-cli/shim.sh" "$tmp/cfg-good/hooks/superstack.json"; then
  ok "a clean install writes valid JSON pointing at this clone"
else bad "a clean install writes valid JSON pointing at this clone (exit $ec2)"; fi

# ---- PreCompact and garbage: never break the host ------------------------
ws="$tmp/ws-pc"; mkdir -p "$ws"
runshim PreCompact '{"hook_event_name":"PreCompact","cwd":"'"$ws"'","transcript_path":"/nonexistent","trigger":"auto"}' "$ws"
if [ "$ec" = "0" ]; then ok "PreCompact exits 0"; else bad "PreCompact exits 0 (exit $ec)"; fi
runshim Stop 'not json at all' "$ws"
if [ -z "$out" ] && [ "$ec" = "0" ]; then ok "garbage stdin fails open"; else bad "garbage stdin fails open"; fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
