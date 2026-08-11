#!/usr/bin/env bash
# adapters/codex-cli/stop-shim.sh — the Codex adapter's ONLY shim (codex plan
# M2, D-76). Codex sends the native payload dialect, final message included,
# so four spine hooks wire directly; this shim exists because the arming walk
# reads the transcript and Codex's rollout grammar differs: user turns are
# payload.type "user_message", tool calls are "function_call" with a JSON
# STRING arguments field (command under cmd; apply_patch files inside a patch
# envelope). Distill, forward, and pass gate bounces through as exit 2 +
# stderr, which Codex honors natively. Fail-open: any doubt, exit 0.
# Suite: hooks/test-adapter-codex.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hooks="$here/../../hooks"
command -v jq >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }
payload="$(cat 2>/dev/null)" || payload=""
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || exit 0

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }
cwd="$(field '.cwd')"; [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
last="$(field '.last_assistant_message')"
[ -n "$last" ] || exit 0
tp="$(field '.transcript_path')"
[ -n "$tp" ] && [ -f "$tp" ] || exit 0
case "$(field '.stop_hook_active')" in true) act=true;; *) act=false;; esac

dt="$(mktemp)"; trap 'rm -f "$dt"' EXIT
jq -c '
  (.payload // {}) as $p |
  if $p.type == "user_message" then {type: "user"}
  elif $p.type == "custom_tool_call" then
    # Real apply_patch rides this type with a RAW-STRING input (live
    # rehearsal capture); envelope markers name the touched files.
    ($p.name // "") as $t |
    ($p.input // "" | tostring) as $blob |
    ([$blob | match("\\*\\*\\* (Add|Update|Delete) File: ([^\\r\\n]+)"; "g")]) as $ms |
    if ($ms | length) > 0 then
      $ms[] | {type: "assistant",
               name: (if .captures[0].string == "Add" then "Write" else "Edit" end),
               command: "", file_path: (.captures[1].string)}
    else
      {type: "assistant",
       name: (if ($t | test("write|create|patch|edit|replace")) then "Edit" else $t end),
       command: "", file_path: ""}
    end
  elif $p.type == "function_call" then
    ($p.name // "") as $t |
    (try ($p.arguments | fromjson) catch {}) as $a |
    if ($t == "exec_command" or $t == "shell" or $t == "shell_command" or $t == "local_shell") then
      {type: "assistant", name: "Bash", command: ($a.cmd // $a.command // ""), file_path: ""}
    else
      ([$a | .. | strings] | join("\n")) as $blob |
      ([$blob | match("\\*\\*\\* (Add|Update|Delete) File: ([^\\r\\n]+)"; "g")]) as $ms |
      if ($ms | length) > 0 then
        $ms[] | {type: "assistant",
                 name: (if .captures[0].string == "Add" then "Write" else "Edit" end),
                 command: "", file_path: (.captures[1].string)}
      else
        {type: "assistant",
         name: (if ($t | test("write|create")) then "Write"
                elif ($t | test("edit|replace|patch")) then "Edit"
                else $t end),
         command: "", file_path: ($a.path // $a.file_path // "")}
      end
    end
  else empty end' "$tp" > "$dt" 2>/dev/null || exit 0

gp="$(jq -n --arg last "$last" --arg tp "$dt" --argjson act "$act" \
  '{last_assistant_message: $last, transcript_path: $tp, stop_hook_active: $act}')"
err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-claims.sh" 2>&1 >/dev/null ) )"; ec=$?
if [ "$ec" != "2" ]; then
  err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-experiential.sh" 2>&1 >/dev/null ) )"; ec=$?
fi
if [ "$ec" = "2" ]; then printf '%s\n' "$err" >&2; exit 2; fi
exit 0
