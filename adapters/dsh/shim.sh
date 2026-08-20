#!/usr/bin/env bash
# adapters/dsh/shim.sh — DeepSeek Harness adapter.
# One argument: the event. Stdin: the host bridge's Claude Code-dialect
# payload (session_id, transcript_path, cwd, plus per-event fields). The
# bridge already speaks our dialect for the door and the publish gate; the
# shim owns the three gaps: the turn record the gates walk (PostToolUse
# lines, lowercase tool names mapped), the final assistant message read
# from the host's own session log at stop time (the stop payload does not
# carry it), and the stop-loop bound — the host's stop_hook_active is a
# constant false with no upstream loop guard, so a marker written on a
# bounce and consumed on the next stop emulates the flag. Blocking
# reality (dogfood/dsh-probe-2026-08-20.md): PreToolUse and Stop both
# deny via exit 2 + stderr, proven live. Fail-open everywhere: parsing
# doubt, missing jq, missing files -> exit 0.
# Suite: hooks/test-adapter-dsh.sh.
set -u
ev="${1:-}"
here="$(cd "$(dirname "$0")" && pwd)"
hooks="$here/../../hooks"
command -v jq >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }
payload="$(cat 2>/dev/null)" || payload=""
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || exit 0

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }
cwd="$(field '.cwd')"; [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
# The session id names files; a value carrying a separator could steer the
# writes outside TMPDIR, so anything but a plain name collapses to one.
sid="$(field '.session_id')"
case "$sid" in *[!A-Za-z0-9._-]*|"") sid=nosession;; esac
rec="${TMPDIR:-/tmp}/superstack-dsh-$sid.jsonl"
marker="${TMPDIR:-/tmp}/superstack-dsh-$sid.bounced"

append_rec() { # the writer owns the bound, same rule as every gate log
  printf '%s\n' "$1" >> "$rec" 2>/dev/null || return 0
  if [ "$(wc -l < "$rec" 2>/dev/null || echo 0)" -gt 400 ]; then
    t="$(mktemp "$rec.XXXXXX" 2>/dev/null)" && tail -n 400 "$rec" > "$t" 2>/dev/null && mv "$t" "$rec" || rm -f "$t"
  fi
}

# Context injects on this host ONLY through the JSON envelope; plain hook
# stdout is dropped by the bridge (rehearsal-found), so both context
# producers get wrapped here. hookEventName must name the firing event or
# the bridge discards the envelope's fields.
envelope() { # $1 event, $2 text
  jq -n --arg ev "$1" --arg c "$2" \
    '{hookSpecificOutput: {hookEventName: $ev, additionalContext: $c}}' 2>/dev/null
}

case "$ev" in
  SessionStart)
    out="$(printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/inject-superstack.sh" 2>/dev/null ) )"
    [ -n "$out" ] && envelope SessionStart "$out"
    ;;
  UserPromptSubmit)
    append_rec '{"type": "user"}'
    # .prompt and .cwd are dialect-compatible: the payload passes through whole.
    out="$(printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/front-door.sh" 2>/dev/null ) )"
    [ -n "$out" ] && envelope UserPromptSubmit "$out"
    ;;
  PreToolUse)
    tn="$(field '.tool_name')"
    case "$tn" in bash|pwsh) ;; *) exit 0 ;; esac
    gp="$(printf '%s' "$payload" | jq -c '.tool_name = "Bash"' 2>/dev/null)"
    [ -n "$gp" ] || exit 0
    err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/outward-sweep.sh" 2>&1 >/dev/null ) )"; ec=$?
    if [ "$ec" = "2" ]; then printf '%s\n' "$err" >&2; exit 2; fi
    ;;
  PostToolUse)
    tn="$(field '.tool_name')"
    case "$tn" in
      bash|pwsh)
        line="$(printf '%s' "$payload" | jq -c '{type: "assistant", name: "Bash", command: (.tool_input.command // "")}' 2>/dev/null)" ;;
      write)
        line="$(printf '%s' "$payload" | jq -c '{type: "assistant", name: "Write", file_path: (.tool_input.file_path // "")}' 2>/dev/null)" ;;
      edit)
        line="$(printf '%s' "$payload" | jq -c '{type: "assistant", name: "Edit", file_path: (.tool_input.file_path // "")}' 2>/dev/null)" ;;
      subagent)
        line='{"type": "assistant", "name": "Task"}' ;;
      *) exit 0 ;;
    esac
    [ -n "$line" ] && append_rec "$line"
    ;;
  Stop)
    [ -f "$rec" ] || exit 0
    tp="$(field '.transcript_path')"
    [ -n "$tp" ] && [ -f "$tp" ] || exit 0
    # The final message lives in the host's own log, which flushes on a
    # delay — the stop hook can beat the flush (seen live), so poll
    # briefly. The message must postdate the last user-role event or a
    # PRIOR turn's reply would be judged against THIS turn's record;
    # stale or unreadable (compressed, foreign) logs leave the stop open,
    # never a blind bounce.
    last=""; _try=0
    while [ "$_try" -lt 5 ]; do
      last="$(tail -n 400 "$tp" 2>/dev/null | jq -rs '
        ([.[]? | select(.type == "user/message")] | if length > 0 then .[length-1].seq else -1 end) as $u
        | [.[]? | select(.type == "assistant/message" and .seq > $u)]
        | if length > 0 then .[length-1].data.message.content // [] | map(select(.type == "text") | .text) | join("\n") else "" end' 2>/dev/null)"
      [ -n "$last" ] && break
      _try=$((_try+1)); sleep 0.25 2>/dev/null || break
    done
    [ -n "$last" ] || exit 0
    if [ -f "$marker" ]; then rm -f "$marker" 2>/dev/null; sha=true; else sha=false; fi
    gp="$(jq -n --arg last "$last" --arg tp "$rec" --argjson sha "$sha" \
      '{last_assistant_message: $last, transcript_path: $tp, stop_hook_active: $sha}')"
    err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-claims.sh" 2>&1 >/dev/null ) )"; ec=$?
    if [ "$ec" != "2" ]; then
      err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-experiential.sh" 2>&1 >/dev/null ) )"; ec=$?
    fi
    if [ "$ec" = "2" ]; then : > "$marker" 2>/dev/null; printf '%s\n' "$err" >&2; exit 2; fi
    ;;
  *) : ;;
esac
exit 0
