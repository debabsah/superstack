#!/bin/bash
# Suite for adapters/kiro-cli — the shim, the agent template, the installer.
# Fixture payloads are the captures in the kiro probe record (dogfood/); a
# fixture that never came from a capture binds nothing. Kiro keeps no
# transcript, so the shim WRITES the turn record the gates walk — these rows
# pin that record's grammar against the exact greps in gate-claims.sh and
# gate-experiential.sh; a drift in either breaks a row here, not silently.
# The stop path is warn-only on this host (D-78): exit 2 surfaces the gate
# message in the session UI and cannot block — rows assert the exit and the
# message, which is the whole deliverable of that path.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
shim="$root/adapters/kiro-cli/shim.sh"
tpl="$root/adapters/kiro-cli/agent.template.json"
inst="$root/adapters/kiro-cli/install.sh"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "PASS: $1"; }
no(){ fail=$((fail+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/tmp" "$T/ws/.superstack"
export KIRO_SESSION_ID="testsess"
rec="$T/tmp/superstack-kiro-testsess.jsonl"

run(){ # $1 event, $2 payload -> rc; stdout in $T/out, stderr in $T/err
  printf '%s' "$2" | TMPDIR="$T/tmp" bash "$shim" "$1" >"$T/out" 2>"$T/err"
}

# ── the template ─────────────────────────────────────────────────────────
[ -f "$tpl" ] && ok "template exists" || no "template exists"
grep -q '"agentSpawn"' "$tpl" 2>/dev/null && grep -q 'inject-superstack.sh' "$tpl" 2>/dev/null \
  && ok "template wires agentSpawn straight to the session voice" \
  || no "template wires agentSpawn straight to the session voice"
for ev in userPromptSubmit preToolUse postToolUse stop; do
  grep -q "shim.sh' $ev" "$tpl" 2>/dev/null \
    && ok "template routes $ev through the shim" \
    || no "template routes $ev through the shim"
done
grep -q '"preCompact"' "$tpl" 2>/dev/null \
  && no "template registers no compaction hook (the host has no such event)" \
  || ok "template registers no compaction hook (the host has no such event)"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$tpl" 2>/dev/null | jq -e . >/dev/null 2>&1 \
  && ok "template substitutes into valid JSON" \
  || no "template substitutes into valid JSON"
grep -q 'superstack adapter' "$tpl" 2>/dev/null \
  && ok "template carries the never-clobber marker" \
  || no "template carries the never-clobber marker"

# ── the installer ────────────────────────────────────────────────────────
mkdir -p "$T/plain/adapters/kiro-cli" "$T/qu'ote/adapters/kiro-cli"
for d in "$T/plain" "$T/qu'ote"; do
  cp "$inst" "$tpl" "$d/adapters/kiro-cli/" 2>/dev/null
done
if KIRO_CONFIG_DIR="$T/kiro1" bash "$T/qu'ote/adapters/kiro-cli/install.sh" >/dev/null 2>"$T/err"; then
  no "installer refuses a path the template quoting cannot carry"
else
  grep -q "refusing" "$T/err" && ok "installer refuses a path the template quoting cannot carry" \
    || no "installer refuses a path the template quoting cannot carry"
fi
if KIRO_CONFIG_DIR="$T/kiro2" bash "$T/plain/adapters/kiro-cli/install.sh" >/dev/null 2>&1; then
  jq -e . "$T/kiro2/agents/superstack.json" >/dev/null 2>&1 \
    && grep -q "$T/plain" "$T/kiro2/agents/superstack.json" \
    && ok "clean install writes valid JSON with the resolved root" \
    || no "clean install writes valid JSON with the resolved root"
else
  no "clean install writes valid JSON with the resolved root"
fi
mkdir -p "$T/kiro3/agents"; printf '%s\n' '{"name":"mine"}' > "$T/kiro3/agents/superstack.json"
if KIRO_CONFIG_DIR="$T/kiro3" bash "$T/plain/adapters/kiro-cli/install.sh" >/dev/null 2>"$T/err"; then
  no "installer never clobbers a foreign superstack.json"
else
  grep -q '"name":"mine"' "$T/kiro3/agents/superstack.json" \
    && ok "installer never clobbers a foreign superstack.json" \
    || no "installer never clobbers a foreign superstack.json"
fi

# ── userPromptSubmit: turn cut + the front door ──────────────────────────
rm -f "$rec"
run userPromptSubmit "{\"hook_event_name\":\"userPromptSubmit\",\"cwd\":\"$T/ws\",\"prompt\":\"create a mario game in a single html document\"}"
grep -q '"type": *"user"' "$rec" 2>/dev/null \
  && ok "prompt event appends the turn-cut marker" \
  || no "prompt event appends the turn-cut marker"
grep -q 'superstack front door' "$T/out" 2>/dev/null \
  && ok "idea-shaped prompt surfaces the shaping offer through the shim" \
  || no "idea-shaped prompt surfaces the shaping offer through the shim"
run userPromptSubmit "{\"hook_event_name\":\"userPromptSubmit\",\"cwd\":\"$T/ws\",\"prompt\":\"fix the failing unit test\"}"
[ ! -s "$T/out" ] \
  && ok "ordinary prompt stays silent" \
  || no "ordinary prompt stays silent"

# ── preToolUse: the publish gate, with the tool-name rename ──────────────
run preToolUse "{\"hook_event_name\":\"preToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"execute_bash\",\"tool_input\":{\"command\":\"git push origin main\"}}"
rc=$?
[ "$rc" = "2" ] && grep -q 'outward gate' "$T/err" \
  && ok "unswept push through execute_bash bounces with the gate message" \
  || no "unswept push through execute_bash bounces with the gate message"
run preToolUse "{\"hook_event_name\":\"preToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"execute_bash\",\"tool_input\":{\"command\":\"git status\"}}"
[ $? = 0 ] && ok "read-only command passes silently" || no "read-only command passes silently"
run preToolUse "{\"hook_event_name\":\"preToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"fs_write\",\"tool_input\":{\"command\":\"git push origin dev\",\"path\":\"$T/ws/a.txt\",\"file_text\":\"x\"}}"
[ $? = 0 ] && ok "file-tool events never reach the publish gate (even carrying a publish verb)" || no "file-tool events never reach the publish gate (even carrying a publish verb)"

# ── postToolUse: the shim-written turn record ────────────────────────────
rm -f "$rec"
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"execute_bash\",\"tool_input\":{\"command\":\"echo probed\"},\"tool_response\":{\"success\":true,\"result\":[{\"exit_status\":\"0\",\"stdout\":\"probed\",\"stderr\":\"\"}]}}"
grep -qE '"name" *: *"Bash"' "$rec" 2>/dev/null && grep -q '"command":"echo probed"' "$rec" 2>/dev/null \
  && ok "shell event lands as a Bash line the claims gate can read" \
  || no "shell event lands as a Bash line the claims gate can read"
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"fs_write\",\"tool_input\":{\"command\":\"create\",\"path\":\"$T/ws/probe.txt\",\"file_text\":\"hello\"},\"tool_response\":{\"success\":true,\"result\":[\"\"]}}"
grep -qE '"name" *: *"Write"' "$rec" 2>/dev/null && grep -q 'probe.txt' "$rec" 2>/dev/null \
  && ok "file create lands as a Write line with its path" \
  || no "file create lands as a Write line with its path"
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"fs_write\",\"tool_input\":{\"command\":\"str_replace\",\"path\":\"$T/ws/probe.txt\"},\"tool_response\":{\"success\":true,\"result\":[\"\"]}}"
grep -qE '"name" *: *"Edit"' "$rec" 2>/dev/null \
  && ok "file edit lands as an Edit line" \
  || no "file edit lands as an Edit line"
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"delegate\",\"tool_input\":{\"task\":\"x\"},\"tool_response\":{\"success\":true,\"result\":[\"\"]}}"
grep -qE '"name" *: *"Task"' "$rec" 2>/dev/null \
  && ok "a delegation lands as a Task line (a subagent report is a claim)" \
  || no "a delegation lands as a Task line (a subagent report is a claim)"
before="$(wc -l < "$rec" 2>/dev/null)"
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"fs_read\",\"tool_input\":{\"path\":\"$T/ws/probe.txt\"},\"tool_response\":{\"success\":true,\"result\":[\"hello\"]}}"
after="$(wc -l < "$rec" 2>/dev/null)"
[ "$before" = "$after" ] \
  && ok "a read-only tool leaves no record line" \
  || no "a read-only tool leaves no record line"

# ── stop: the warn-only turn-end gates ───────────────────────────────────
mkrec(){ rm -f "$rec"; for l in "$@"; do printf '%s\n' "$l" >> "$rec"; done }
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}'
run stop "{\"hook_event_name\":\"stop\",\"cwd\":\"$T/ws\",\"assistant_response\":\"Done.\"}"
rc=$?
[ "$rc" = "2" ] && grep -q 'calibration gate' "$T/err" \
  && ok "bare done on a mutating turn warns with the claims-gate message" \
  || no "bare done on a mutating turn warns with the claims-gate message"
grep -q ' BOUNCE phrase=' "$T/ws/.superstack/gate-log" 2>/dev/null \
  && ok "the bounce lands in the SESSION workspace's record (the cwd carrier holds)" \
  || no "the bounce lands in the SESSION workspace's record (the cwd carrier holds)"
run stop "{\"hook_event_name\":\"stop\",\"cwd\":\"$T/ws\",\"assistant_response\":\"Verified: the rename landed - ran the suite -> saw green\"}"
[ $? = 0 ] && ok "a calibrated claim passes the stop path" || no "a calibrated claim passes the stop path"
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}' '{"type": "user"}'
run stop "{\"hook_event_name\":\"stop\",\"cwd\":\"$T/ws\",\"assistant_response\":\"Done.\"}"
[ $? = 0 ] \
  && ok "an earlier turn's mutation never arms the current turn (the cut holds)" \
  || no "an earlier turn's mutation never arms the current turn (the cut holds)"
mkrec '{"type": "user"}' "{\"type\":\"assistant\",\"name\":\"Write\",\"file_path\":\"$T/ws/index.html\"}"
run stop "{\"hook_event_name\":\"stop\",\"cwd\":\"$T/ws\",\"assistant_response\":\"Verified: styles compile - ran the build -> saw 0 errors\"}"
rc=$?
[ "$rc" = "2" ] && grep -q 'look-step gate' "$T/err" \
  && ok "a face change on logic-only evidence warns with the look-gate message" \
  || no "a face change on logic-only evidence warns with the look-gate message"
grep -q ' LOOK-BOUNCE ' "$T/ws/.superstack/gate-log" 2>/dev/null \
  && ok "the look warn lands in the SESSION workspace's record too (both cwd carriers hold)" \
  || no "the look warn lands in the SESSION workspace's record too (both cwd carriers hold)"
KIRO_SESSION_ID=othersess run stop "{\"hook_event_name\":\"stop\",\"cwd\":\"$T/ws\",\"assistant_response\":\"Done.\"}"
[ $? = 0 ] && ok "a session with no record passes silently" || no "a session with no record passes silently"

# ── hostile and degraded input ───────────────────────────────────────────
run stop "not json at all"
[ $? = 0 ] && ok "malformed payload fails open" || no "malformed payload fails open"
mkdir -p "$T/tmp/superstack-kiro-a"; rm -f "$T/stolen.jsonl" "$T/tmp/superstack-kiro-nosession.jsonl"
KIRO_SESSION_ID='a/../../stolen' run userPromptSubmit "{\"hook_event_name\":\"userPromptSubmit\",\"cwd\":\"$T/ws\",\"prompt\":\"hello\"}"
[ ! -f "$T/stolen.jsonl" ] && grep -q '"type": *"user"' "$T/tmp/superstack-kiro-nosession.jsonl" 2>/dev/null \
  && ok "a hostile session id cannot steer the record path (the write collapses to nosession)" \
  || no "a hostile session id cannot steer the record path (the write collapses to nosession)"
rm -f "$rec"; i=0; while [ $i -lt 405 ]; do printf '%s\n' '{"type": "user"}' >> "$rec"; i=$((i+1)); done
run postToolUse "{\"hook_event_name\":\"postToolUse\",\"cwd\":\"$T/ws\",\"tool_name\":\"execute_bash\",\"tool_input\":{\"command\":\"echo x\"},\"tool_response\":{\"success\":true,\"result\":[{\"exit_status\":\"0\",\"stdout\":\"x\",\"stderr\":\"\"}]}}"
[ "$(wc -l < "$rec" | tr -d ' ')" -le 400 ] \
  && ok "the turn record self-rotates (the writer owns the bound)" \
  || no "the turn record self-rotates (the writer owns the bound)"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
