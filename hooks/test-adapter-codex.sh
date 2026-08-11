#!/bin/bash
# Self-checks for the Codex CLI adapter (codex plan M2, D-76). The probed
# contract: Codex sends our native payload dialect, so SessionStart,
# UserPromptSubmit, PreToolUse, and PreCompact wire DIRECTLY to the core
# hooks (the template must pin that, not a shim), and only Stop routes
# through the stop shim, which distills the rollout
# transcript grammar (payload.type user_message / function_call, arguments
# as a JSON STRING with the command under cmd) into what the gates read,
# forwards last_assistant_message from the payload, and passes gate bounces
# through as exit 2 + stderr. Installer: never clobbers a hooks.json it did
# not write. Fail-open everywhere. Fixture payloads mirror
# the codex probe record in dogfood/.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$here/.."
shim="$root/adapters/codex-cli/stop-shim.sh"
template="$root/adapters/codex-cli/hooks.template.json"
inst="$root/adapters/codex-cli/install.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
command -v jq >/dev/null || { echo "jq is required for this suite"; exit 1; }

ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# ---- the template: direct wiring is the design, pinned -------------------
if [ -f "$template" ]; then ok "template exists"; else bad "template exists"; fi
resolved="$tmp/hooks.json"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$template" > "$resolved" 2>/dev/null
if jq . "$resolved" >/dev/null 2>&1; then ok "resolved template is valid JSON"; else bad "resolved template is valid JSON"; fi
for ev in SessionStart UserPromptSubmit PreToolUse Stop PreCompact; do
  if jq -e --arg e "$ev" '.hooks[$e][0].hooks[0].type == "command"' "$resolved" >/dev/null 2>&1; then
    ok "template registers $ev (Codex nesting)"
  else bad "template registers $ev (Codex nesting)"; fi
done
dir_ok=1
for pair in "SessionStart:inject-superstack.sh" "UserPromptSubmit:front-door.sh" "PreToolUse:outward-sweep.sh" "PreCompact:pre-compact.sh"; do
  ev="${pair%%:*}"; h="${pair##*:}"
  jq -r --arg e "$ev" '.hooks[$e][0].hooks[0].command' "$resolved" 2>/dev/null | grep -q "hooks/$h" || dir_ok=0
done
if [ "$dir_ok" = "1" ]; then ok "four spine hooks wire DIRECTLY to the core (no shim)"; else bad "four spine hooks wire DIRECTLY to the core (no shim)"; fi
if jq -r '.hooks.Stop[0].hooks[0].command' "$resolved" 2>/dev/null | grep -q "stop-shim.sh"; then
  ok "Stop routes through the stop shim"
else bad "Stop routes through the stop shim"; fi
if jq -e '.hooks.PreToolUse[0].matcher == "Bash"' "$resolved" >/dev/null 2>&1; then
  ok "PreToolUse carries the Bash matcher"
else bad "PreToolUse carries the Bash matcher"; fi
if [ -x "$shim" ]; then ok "stop shim exists and is executable"; else bad "stop shim exists and is executable"; fi

# ---- direct-wiring sanity: the captured dialect drives the core hooks ----
ws="$tmp/ws-direct"; git init -q -b main "$ws"; mkdir -p "$ws/.superstack"
printf '%s\n' '<!-- pointer: demo — READ ME. Oracle: true -->' > "$ws/.superstack/project.md"
out="$(printf '{"hook_event_name":"SessionStart","session_id":"s1","cwd":"%s","source":"startup"}' "$ws" | ( cd "$ws" && bash "$root/hooks/inject-superstack.sh" 2>/dev/null ))"
if printf '%s' "$out" | grep -q "superstack"; then ok "captured SessionStart payload drives the injector unmodified"; else bad "captured SessionStart payload drives the injector unmodified"; fi
ws="$tmp/ws-push"; git init -q -b main "$ws"
ec=0; printf '{"hook_event_name":"PreToolUse","session_id":"s1","cwd":"%s","tool_name":"Bash","tool_input":{"command":"git push origin main"},"tool_use_id":"c1"}' "$ws" | ( cd "$ws" && bash "$root/hooks/outward-sweep.sh" >/dev/null 2>&1 ) || ec=$?
if [ "$ec" = "2" ]; then ok "captured PreToolUse payload drives the outward gate unmodified"; else bad "captured PreToolUse payload drives the outward gate unmodified (exit $ec)"; fi

# ---- the Stop shim: rollout distillation ---------------------------------
runshim() { ec=0; out="$(printf '%s' "$1" | ( cd "$2" && bash "$shim" 2>&1 >/dev/null ))" || ec=$?; }
mkroll() { # dir: writes events per remaining args: user | exec:<cmd> | patch:<enveloped-file>
  d="$1"; shift; : > "$d/rollout.jsonl"
  for e in "$@"; do
    case "$e" in
      user) printf '%s\n' '{"type":"event_msg","payload":{"type":"user_message","message":"do the thing"}}' >> "$d/rollout.jsonl" ;;
      exec:*) c="${e#exec:}"; jq -cn --arg c "$c" '{type:"response_item",payload:{type:"function_call",name:"exec_command",arguments:({cmd:$c}|tojson)}}' >> "$d/rollout.jsonl" ;;
      patch:*) f="${e#patch:}"; jq -cn --arg p "*** Begin Patch
*** Add File: $f
+<html></html>
*** End Patch" '{type:"response_item",payload:{type:"function_call",name:"apply_patch",arguments:({input:$p}|tojson)}}' >> "$d/rollout.jsonl" ;;
      cpatch:*) f="${e#cpatch:}"; jq -cn --arg p "*** Begin Patch
*** Add File: $f
+hello
*** End Patch
" '{type:"response_item",payload:{type:"custom_tool_call",status:"completed",name:"apply_patch",input:$p}}' >> "$d/rollout.jsonl" ;;
    esac
  done
}
sp() { jq -cn --arg cwd "$1" --arg tp "$1/rollout.jsonl" --argjson act "$2" --arg last "$3" \
  '{hook_event_name:"Stop",session_id:"s1",cwd:$cwd,transcript_path:$tp,stop_hook_active:$act,last_assistant_message:$last}'; }

ws="$tmp/ws-stop-bare"; git init -q -b main "$ws"; mkroll "$ws" user "exec:sed -i .bak s/a/b/ f.txt"
runshim "$(sp "$ws" false 'All the tests pass and everything is done.')" "$ws"
if [ "$ec" = "2" ] && printf '%s' "$out" | grep -q "Verified"; then
  ok "bare claim + shell mutation blocks with the ledger lesson (cmd double-decoded)"
else bad "bare claim + shell mutation blocks with the ledger lesson (exit $ec)"; fi

ws="$tmp/ws-stop-led"; git init -q -b main "$ws"; mkroll "$ws" user "exec:sed -i .bak s/a/b/ f.txt"
runshim "$(sp "$ws" false 'Verified: the suite passes (all checks pass printed). Done.')" "$ws"
if [ "$ec" = "0" ]; then ok "calibrated claim passes"; else bad "calibrated claim passes (exit $ec)"; fi

ws="$tmp/ws-stop-loop"; git init -q -b main "$ws"; mkroll "$ws" user "exec:sed -i .bak s/a/b/ f.txt"
runshim "$(sp "$ws" true 'All the tests pass and everything is done.')" "$ws"
if [ "$ec" = "0" ]; then ok "stop_hook_active loop guard passes"; else bad "stop_hook_active loop guard passes (exit $ec)"; fi

ws="$tmp/ws-stop-cut"; git init -q -b main "$ws"; mkroll "$ws" "exec:sed -i .bak s/a/b/ f.txt" user
runshim "$(sp "$ws" false 'All the tests pass and everything is done.')" "$ws"
if [ "$ec" = "0" ]; then ok "an edit before the last user message does not arm (cut translated)"; else bad "an edit before the last user message does not arm (exit $ec)"; fi

ws="$tmp/ws-stop-face"; git init -q -b main "$ws"; mkroll "$ws" user "patch:index.html"
runshim "$(sp "$ws" false 'Verified: the logic tests pass (suite output read).')" "$ws"
if [ "$ec" = "2" ] && printf '%s' "$out" | grep -q "look"; then
  ok "apply_patch on a face file reaches the look gate (path extracted from the envelope)"
else bad "apply_patch on a face file reaches the look gate (exit $ec, out: $(printf '%s' "$out" | head -c 80))"; fi

# The live rehearsal caught this class: real Codex apply_patch rides
# payload.type custom_tool_call with a RAW-STRING input, not function_call
# with JSON-string arguments. Both rows use the captured shape verbatim.
ws="$tmp/ws-stop-ctc"; git init -q -b main "$ws"; mkroll "$ws" user "cpatch:notes.txt"
runshim "$(sp "$ws" false 'Everything is fixed and fully working now.')" "$ws"
if [ "$ec" = "2" ] && printf '%s' "$out" | grep -q "Verified"; then
  ok "a custom_tool_call apply_patch arms the claims gate"
else bad "a custom_tool_call apply_patch arms the claims gate (exit $ec)"; fi
ws="$tmp/ws-stop-ctc-face"; git init -q -b main "$ws"; mkroll "$ws" user "cpatch:index.html"
runshim "$(sp "$ws" false 'Verified: the logic tests pass (suite output read).')" "$ws"
if [ "$ec" = "2" ] && printf '%s' "$out" | grep -q "look"; then
  ok "a custom_tool_call face file reaches the look gate"
else bad "a custom_tool_call face file reaches the look gate (exit $ec)"; fi

ws="$tmp/ws-stop-nolast"; git init -q -b main "$ws"; mkroll "$ws" user "exec:sed -i .bak s/a/b/ f.txt"
p="$(sp "$ws" false x | jq -c 'del(.last_assistant_message)')"
runshim "$p" "$ws"
if [ "$ec" = "0" ]; then ok "a payload without the final message fails open"; else bad "a payload without the final message fails open (exit $ec)"; fi
runshim 'not json' "$tmp"
if [ "$ec" = "0" ]; then ok "garbage stdin fails open"; else bad "garbage stdin fails open (exit $ec)"; fi

# ---- installer: never clobber a config the user owns ---------------------
badroot="$tmp/we & they"; mkdir -p "$badroot/adapters"
cp -R "$root/adapters/codex-cli" "$badroot/adapters/" 2>/dev/null
ec2=0; CODEX_HOME="$tmp/cx-bad" bash "$badroot/adapters/codex-cli/install.sh" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" != "0" ] && [ ! -f "$tmp/cx-bad/hooks.json" ]; then
  ok "a root path with '&' is refused and nothing is written"
else bad "a root path with '&' is refused and nothing is written (exit $ec2)"; fi
ec2=0; CODEX_HOME="$tmp/cx-good" bash "$inst" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" = "0" ] && jq -e . "$tmp/cx-good/hooks.json" >/dev/null 2>&1 \
   && grep -qF "$(cd "$root" && pwd)/adapters/codex-cli/stop-shim.sh" "$tmp/cx-good/hooks.json"; then
  ok "a clean install writes valid JSON pointing at this clone"
else bad "a clean install writes valid JSON pointing at this clone (exit $ec2)"; fi
ec2=0; CODEX_HOME="$tmp/cx-good" bash "$inst" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" = "0" ]; then ok "reinstall over our own config is allowed (refresh)"; else bad "reinstall over our own config is allowed (exit $ec2)"; fi
mkdir -p "$tmp/cx-theirs"; printf '%s\n' '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo mine"}]}]}}' > "$tmp/cx-theirs/hooks.json"
ec2=0; CODEX_HOME="$tmp/cx-theirs" bash "$inst" >/dev/null 2>&1 || ec2=$?
if [ "$ec2" != "0" ] && grep -q "echo mine" "$tmp/cx-theirs/hooks.json"; then
  ok "a hooks.json the user owns is refused, never clobbered"
else bad "a hooks.json the user owns is refused, never clobbered (exit $ec2)"; fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
