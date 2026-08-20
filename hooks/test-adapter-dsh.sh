#!/bin/bash
# Suite for adapters/dsh — the shim, the hooks template, the profile installer.
# Fixture payloads are the captures in the dsh probe record (dogfood/); a
# fixture that never came from a capture binds nothing (the edit-tool row is
# source-derived, named so, and the rehearsal upgrades it). The host hands
# hooks Claude Code-dialect payloads through its bridge, so the shim's jobs
# are narrow: the turn record the gates walk, the final message read from the
# host's own session log at stop time, the lowercase tool names, and the
# stop-loop bound the host does not provide (its stop flag is a constant
# false) — the shim emulates the flag with a marker consumed on the next stop.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
shim="$root/adapters/dsh/shim.sh"
tpl="$root/adapters/dsh/hooks.template.json"
inst="$root/adapters/dsh/install.sh"
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "PASS: $1"; }
no(){ fail=$((fail+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/tmp" "$T/ws/.superstack"
sid="session-test01"
rec="$T/tmp/superstack-dsh-$sid.jsonl"
marker="$T/tmp/superstack-dsh-$sid.bounced"
dtp="$T/ws/dshsession.jsonl"

run(){ # $1 event, $2 payload -> rc; stdout in $T/out, stderr in $T/err
  printf '%s' "$2" | TMPDIR="$T/tmp" bash "$shim" "$1" >"$T/out" 2>"$T/err"
}
mkdsh(){ # writes a dsh-format session log whose final assistant text is $1
  printf '%s\n' '{"type":"user/message","seq":10,"time":1,"data":{"turn":1,"message":{"role":"user","content":[{"type":"text","text":"do the thing"}]}}}' > "$dtp"
  printf '{"type":"assistant/message","seq":187,"time":2,"data":{"turn":1,"step":2,"message":{"role":"assistant","content":[{"type":"reasoning","text":"never surface this"},{"type":"text","text":"%s"}]}}}\n' "$1" >> "$dtp"
  printf '%s\n' '{"type":"step/end","seq":188,"time":3,"data":{"turn":1,"step":2}}' >> "$dtp"
}
stoppay(){ printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","hook_event_name":"Stop","stop_hook_active":false}' "$sid" "$dtp" "$T/ws"; }

# ── the template ─────────────────────────────────────────────────────────
[ -f "$tpl" ] && ok "template exists" || no "template exists"
for ev in SessionStart UserPromptSubmit PreToolUse PostToolUse Stop; do
  grep -q "shim.sh' $ev" "$tpl" 2>/dev/null \
    && ok "template routes $ev through the shim" \
    || no "template routes $ev through the shim"
done
grep -q '"PreCompact"' "$tpl" 2>/dev/null \
  && no "template registers no compaction hook (the host has no such event)" \
  || ok "template registers no compaction hook (the host has no such event)"
grep -q '"matcher": *"bash|pwsh"' "$tpl" 2>/dev/null \
  && ok "publish-gate matcher speaks the host's lowercase tool names" \
  || no "publish-gate matcher speaks the host's lowercase tool names"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$tpl" 2>/dev/null | jq -e . >/dev/null 2>&1 \
  && ok "template substitutes into valid JSON" \
  || no "template substitutes into valid JSON"
grep -q 'superstack adapter' "$tpl" 2>/dev/null \
  && ok "template carries the never-clobber marker" \
  || no "template carries the never-clobber marker"

# ── the installer (file writes only; the plugin-add step is skippable) ───
mkdir -p "$T/plain/adapters/dsh" "$T/qu'ote/adapters/dsh"
for d in "$T/plain" "$T/qu'ote"; do
  cp "$inst" "$tpl" "$d/adapters/dsh/" 2>/dev/null
done
if DSH_HOME="$T/dsh1" SUPERSTACK_DSH_NO_INSTALL=1 bash "$T/qu'ote/adapters/dsh/install.sh" >/dev/null 2>"$T/err"; then
  no "installer refuses a path the template quoting cannot carry"
else
  grep -q "refusing" "$T/err" && ok "installer refuses a path the template quoting cannot carry" \
    || no "installer refuses a path the template quoting cannot carry"
fi
if DSH_HOME="$T/dsh2" SUPERSTACK_DSH_NO_INSTALL=1 bash "$T/plain/adapters/dsh/install.sh" >"$T/instout" 2>&1; then
  p="$T/dsh2/profiles/superstack"
  jq -e '.dsh.profile.bundles | length >= 1' "$p/package.json" >/dev/null 2>&1 \
    && ok "clean install writes a profile manifest with its bundle stack" \
    || no "clean install writes a profile manifest with its bundle stack"
  grep -q 'superstack adapter' "$p/cordis.patch.yml" 2>/dev/null \
    && grep -q 'dsh-hooks-claude-code' "$p/cordis.patch.yml" 2>/dev/null \
    && ok "profile patch mounts the hooks bridge and carries the marker" \
    || no "profile patch mounts the hooks bridge and carries the marker"
  grep -q 'compression: none' "$p/cordis.patch.yml" 2>/dev/null \
    && grep -q 'sessions-superstack' "$p/cordis.patch.yml" 2>/dev/null \
    && ok "profile patch gives sessions a readable root of their own" \
    || no "profile patch gives sessions a readable root of their own"
  jq -e . "$p/superstack-hooks.json" >/dev/null 2>&1 && grep -q "$T/plain" "$p/superstack-hooks.json" \
    && ok "hooks file is valid JSON with the resolved root" \
    || no "hooks file is valid JSON with the resolved root"
  grep -q 'nodeLinker: hoisted' "$p/pnpm-workspace.yaml" 2>/dev/null \
    && ok "profile carries its own workspace boundary (pnpm walks no further)" \
    || no "profile carries its own workspace boundary (pnpm walks no further)"
  grep -q '^\[\]' "$p/cordis.yml" 2>/dev/null \
    && ok "profile carries the empty composition root the boot expects" \
    || no "profile carries the empty composition root the boot expects"
  grep -q 'dsh-hook-protocol' "$T/instout" 2>/dev/null \
    && ok "installer names the protocol package in its finishing step" \
    || no "installer names the protocol package in its finishing step"
else
  no "clean install writes a profile manifest with its bundle stack"
  no "profile patch mounts the hooks bridge and carries the marker"
  no "profile patch gives sessions a readable root of their own"
  no "hooks file is valid JSON with the resolved root"
  no "installer names the protocol package in its finishing step"
fi
mkdir -p "$T/dsh3/profiles/superstack"; printf 'mine\n' > "$T/dsh3/profiles/superstack/cordis.patch.yml"
if DSH_HOME="$T/dsh3" SUPERSTACK_DSH_NO_INSTALL=1 bash "$T/plain/adapters/dsh/install.sh" >/dev/null 2>"$T/err"; then
  no "installer never clobbers a foreign superstack profile"
else
  grep -q 'mine' "$T/dsh3/profiles/superstack/cordis.patch.yml" \
    && ok "installer never clobbers a foreign superstack profile" \
    || no "installer never clobbers a foreign superstack profile"
fi

# ── SessionStart: the briefing rides the JSON envelope, the only stdout
# form this host's bridge injects (plain stdout is dropped; rehearsal-found).
# The fixture plants an overlay so the voice has a line on ANY machine — an
# empty record plus a machine-local personal rule book once made this row
# green here and red on all three CI runners.
printf '%s\n' '<!-- pointer: p — oracle: make test -->' > "$T/ws/.superstack/project.md"
run SessionStart "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}"
jq -e '.hookSpecificOutput | .hookEventName == "SessionStart" and (.additionalContext | contains("superstack"))' "$T/out" >/dev/null 2>&1 \
  && ok "session start emits the briefing inside the injection envelope" \
  || no "session start emits the briefing inside the injection envelope"

# ── UserPromptSubmit: turn cut + the front door (captured shape) ─────────
rm -f "$rec"
run UserPromptSubmit "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"create a mario game in a single html document\"}"
grep -q '"type": *"user"' "$rec" 2>/dev/null \
  && ok "prompt event appends the turn-cut marker" \
  || no "prompt event appends the turn-cut marker"
jq -e '.hookSpecificOutput | .hookEventName == "UserPromptSubmit" and (.additionalContext | contains("superstack front door"))' "$T/out" >/dev/null 2>&1 \
  && ok "the shaping offer rides the injection envelope (plain stdout is dropped on this host)" \
  || no "the shaping offer rides the injection envelope (plain stdout is dropped on this host)"
run UserPromptSubmit "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"fix the failing unit test\"}"
[ ! -s "$T/out" ] \
  && ok "ordinary prompt stays silent" \
  || no "ordinary prompt stays silent"

# ── PreToolUse: the publish gate on the host's lowercase bash ────────────
run PreToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"bash\",\"tool_input\":{\"command\":\"git push origin main\",\"description\":\"push\"},\"tool_use_id\":\"nFcXVf0psOxG8q5dQpcLA8s5bxUccj3M\"}"
rc=$?
[ "$rc" = "2" ] && grep -q 'outward gate' "$T/err" \
  && ok "unswept push through bash bounces with the gate message" \
  || no "unswept push through bash bounces with the gate message"
run PreToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"bash\",\"tool_input\":{\"command\":\"git status\",\"description\":\"status\"},\"tool_use_id\":\"t2\"}"
[ $? = 0 ] && ok "read-only command passes silently" || no "read-only command passes silently"
run PreToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"write\",\"tool_input\":{\"file_path\":\"$T/ws/a.txt\",\"content\":\"git push origin dev\"},\"tool_use_id\":\"t3\"}"
[ $? = 0 ] && ok "file-tool events never reach the publish gate (even carrying a publish verb)" || no "file-tool events never reach the publish gate (even carrying a publish verb)"

# ── PostToolUse: the shim-written turn record (write shape captured) ─────
rm -f "$rec"
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"bash\",\"tool_input\":{\"command\":\"echo probed\",\"description\":\"d\"},\"tool_use_id\":\"t4\",\"tool_response\":\"probed\"}"
grep -qE '"name" *: *"Bash"' "$rec" 2>/dev/null && grep -q '"command":"echo probed"' "$rec" 2>/dev/null \
  && ok "shell event lands as a Bash line the claims gate can read" \
  || no "shell event lands as a Bash line the claims gate can read"
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"write\",\"tool_input\":{\"file_path\":\"$T/ws/probe.txt\",\"content\":\"hello\"},\"tool_use_id\":\"t5\",\"tool_response\":\"ok\"}"
grep -qE '"name" *: *"Write"' "$rec" 2>/dev/null && grep -q 'probe.txt' "$rec" 2>/dev/null \
  && ok "file create lands as a Write line with its path" \
  || no "file create lands as a Write line with its path"
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"edit\",\"tool_input\":{\"file_path\":\"$T/ws/probe.txt\"},\"tool_use_id\":\"t6\",\"tool_response\":\"ok\"}"
grep -qE '"name" *: *"Edit"' "$rec" 2>/dev/null \
  && ok "file edit lands as an Edit line (source-derived; rehearsal upgrades it)" \
  || no "file edit lands as an Edit line (source-derived; rehearsal upgrades it)"
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"subagent\",\"tool_input\":{\"task\":\"x\"},\"tool_use_id\":\"t7\",\"tool_response\":\"ok\"}"
grep -qE '"name" *: *"Task"' "$rec" 2>/dev/null \
  && ok "a delegation lands as a Task line (a subagent report is a claim)" \
  || no "a delegation lands as a Task line (a subagent report is a claim)"
before="$(wc -l < "$rec" 2>/dev/null)"
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"read\",\"tool_input\":{\"file_path\":\"$T/ws/probe.txt\"},\"tool_use_id\":\"t8\",\"tool_response\":\"hello\"}"
after="$(wc -l < "$rec" 2>/dev/null)"
[ "$before" = "$after" ] \
  && ok "a read-only tool leaves no record line" \
  || no "a read-only tool leaves no record line"

# ── Stop: full-strength gates; the final message comes from the host log ─
mkrec(){ rm -f "$rec"; for l in "$@"; do printf '%s\n' "$l" >> "$rec"; done }
rm -f "$marker"
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}'
mkdsh "Done."
run Stop "$(stoppay)"
rc=$?
[ "$rc" = "2" ] && grep -q 'calibration gate' "$T/err" \
  && ok "bare done on a mutating turn bounces with the claims-gate message" \
  || no "bare done on a mutating turn bounces with the claims-gate message"
grep -q ' BOUNCE phrase=' "$T/ws/.superstack/gate-log" 2>/dev/null \
  && ok "the bounce lands in the SESSION workspace's record (the cwd carrier holds)" \
  || no "the bounce lands in the SESSION workspace's record (the cwd carrier holds)"
[ -f "$marker" ] \
  && ok "the bounce writes the loop-bound marker (the host's stop flag is a constant)" \
  || no "the bounce writes the loop-bound marker (the host's stop flag is a constant)"
run Stop "$(stoppay)"
[ $? = 0 ] && [ ! -f "$marker" ] \
  && ok "the next stop passes via the emulated flag and consumes the marker" \
  || no "the next stop passes via the emulated flag and consumes the marker"
mkdsh "Verified: the rename landed - ran the suite -> saw green"
run Stop "$(stoppay)"
[ $? = 0 ] && ok "a calibrated claim passes the stop path" || no "a calibrated claim passes the stop path"
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}' '{"type": "user"}'
mkdsh "Done."
run Stop "$(stoppay)"
[ $? = 0 ] \
  && ok "an earlier turn's mutation never arms the current turn (the cut holds)" \
  || no "an earlier turn's mutation never arms the current turn (the cut holds)"
rm -f "$marker"
mkrec '{"type": "user"}' "{\"type\":\"assistant\",\"name\":\"Write\",\"file_path\":\"$T/ws/index.html\"}"
mkdsh "Verified: styles compile - ran the build -> saw 0 errors"
run Stop "$(stoppay)"
rc=$?
[ "$rc" = "2" ] && grep -q 'look-step gate' "$T/err" \
  && ok "a face change on logic-only evidence bounces with the look-gate message" \
  || no "a face change on logic-only evidence bounces with the look-gate message"
grep -q ' LOOK-BOUNCE ' "$T/ws/.superstack/gate-log" 2>/dev/null \
  && ok "the look bounce lands in the SESSION workspace's record too" \
  || no "the look bounce lands in the SESSION workspace's record too"
rm -f "$marker"
sid=othersess rec="$T/tmp/superstack-dsh-othersess.jsonl" run Stop "{\"session_id\":\"othersess\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
[ $? = 0 ] && ok "a session with no record passes silently" || no "a session with no record passes silently"
sid="session-test01"; rec="$T/tmp/superstack-dsh-$sid.jsonl"

# ── hostile and degraded input ───────────────────────────────────────────
run Stop "not json at all"
[ $? = 0 ] && ok "malformed payload fails open" || no "malformed payload fails open"
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}'
printf '\x28\xb5\x2f\xfd zstd-binary-garbage' > "$dtp"
run Stop "$(stoppay)"
[ $? = 0 ] \
  && ok "an unreadable (compressed) host log fails open, never bounces blind" \
  || no "an unreadable (compressed) host log fails open, never bounces blind"
mkrec '{"type": "user"}' '{"type":"assistant","name":"Bash","command":"sed -i s/a/b/ notes.txt"}'
printf '%s\n' '{"type":"assistant/message","seq":50,"time":1,"data":{"turn":1,"step":1,"message":{"role":"assistant","content":[{"type":"text","text":"Done."}]}}}' > "$dtp"
printf '%s\n' '{"type":"user/message","seq":60,"time":2,"data":{"turn":2,"message":{"role":"user","content":[{"type":"text","text":"next thing"}]}}}' >> "$dtp"
rm -f "$marker"
run Stop "$(stoppay)"
[ $? = 0 ] \
  && ok "a prior turn's message behind a newer prompt is never judged (the flush race stays open, not wrongly bounced)" \
  || no "a prior turn's message behind a newer prompt is never judged (the flush race stays open, not wrongly bounced)"
rm -f "$T/stolen.jsonl" "$T/tmp/superstack-dsh-nosession.jsonl"
run UserPromptSubmit "{\"session_id\":\"a/../../stolen\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"hello\"}"
[ ! -f "$T/stolen.jsonl" ] && grep -q '"type": *"user"' "$T/tmp/superstack-dsh-nosession.jsonl" 2>/dev/null \
  && ok "a hostile session id cannot steer the record path (the write collapses to nosession)" \
  || no "a hostile session id cannot steer the record path (the write collapses to nosession)"
rm -f "$rec"; i=0; while [ $i -lt 405 ]; do printf '%s\n' '{"type": "user"}' >> "$rec"; i=$((i+1)); done
run PostToolUse "{\"session_id\":\"$sid\",\"transcript_path\":\"$dtp\",\"cwd\":\"$T/ws\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"bash\",\"tool_input\":{\"command\":\"echo x\",\"description\":\"d\"},\"tool_use_id\":\"t9\",\"tool_response\":\"x\"}"
[ "$(wc -l < "$rec" | tr -d ' ')" -le 400 ] \
  && ok "the turn record self-rotates (the writer owns the bound)" \
  || no "the turn record self-rotates (the writer owns the bound)"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
