#!/usr/bin/env bash
# adapters/copilot-cli/shim.sh — GitHub Copilot CLI adapter (adoption M8, D-75).
# One argument: the event name. Stdin: Copilot's hook payload (PascalCase
# registration selects the snake_case dialect, whose field names match what
# the core hooks read). The core hooks stay host-neutral; every host-specific
# fact lives in this file. Output translation: ambient stdout becomes
# {"additionalContext": ...}; an outward bounce becomes a structured
# permissionDecision deny; a turn-end gate bounce becomes {"decision":"block"}.
# Fail-open everywhere: parsing doubt, missing jq, missing files -> exit 0.
# Suite: hooks/test-adapter-copilot.sh.
set -u
ev="${1:-}"
here="$(cd "$(dirname "$0")" && pwd)"
hooks="$here/../../hooks"
command -v jq >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }
payload="$(cat 2>/dev/null)" || payload=""
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || exit 0

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }
cwd="$(field '.cwd')"; [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"

wrap_ctx() { # stdin raw text -> {"additionalContext": text}; empty stays silent
  txt="$(cat)"
  [ -n "$txt" ] && printf '%s' "$txt" | jq -Rs '{additionalContext: .}'
  return 0
}

case "$ev" in
  SessionStart)
    # .source passes through whole; the injector treats unknown values as a
    # plain start, so Copilot's "new" needs no translation.
    printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/inject-superstack.sh" 2>/dev/null ) | wrap_ctx
    ;;
  UserPromptSubmit)
    # .prompt and .cwd are dialect-compatible: the payload passes through whole.
    printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/front-door.sh" 2>/dev/null ) | wrap_ctx
    ;;
  PreToolUse)
    # .tool_name / .tool_input.command are dialect-compatible. The gate speaks
    # stderr + exit 2; Copilot wants the structured deny (exit stays 0: the
    # JSON is the decision, and a shim crash must not deny by accident).
    err="$(printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/outward-sweep.sh" 2>&1 >/dev/null ) )"; ec=$?
    [ "$ec" = "2" ] && printf '%s' "$err" | jq -Rs '{permissionDecision: "deny", permissionDecisionReason: .}'
    ;;
  Stop)
    tp="$(field '.transcript_path')"
    [ -n "$tp" ] && [ -f "$tp" ] || exit 0
    case "$(field '.stop_hook_active')" in true) act=true;; *) act=false;; esac
    # Distill Copilot's events.jsonl into the transcript grammar the gates
    # read: user lines mark the turn cut, tool lines carry the editing names
    # and Bash commands. Unknown tool names pass through unmapped and fail
    # open; the Bash-command signatures still arm the turn.
    dt="$(mktemp)"; trap 'rm -f "$dt"' EXIT
    jq -c '
      if .type == "user.message" then {type: "user"}
      elif .type == "tool.execution_start" then
        (.data.toolName // "") as $t |
        (.data.arguments.command // "") as $c |
        (.data.arguments.path // .data.arguments.file_path // "") as $p |
        (if $t == "bash" or $t == "shell" or $t == "local_shell" or $t == "powershell" then "Bash"
         elif ($t | test("write|create")) then "Write"
         elif ($t | test("edit|replace|patch")) then "Edit"
         else $t end) as $n |
        {type: "assistant", name: $n, command: $c, file_path: $p}
      else empty end' "$tp" > "$dt" 2>/dev/null || exit 0
    last="$(jq -rs '[ .[] | select(.type == "assistant.message") | .data.content ] | last // empty' "$tp" 2>/dev/null)"
    [ -n "$last" ] || exit 0
    gp="$(jq -n --arg last "$last" --arg tp "$dt" --argjson act "$act" \
      '{last_assistant_message: $last, transcript_path: $tp, stop_hook_active: $act}')"
    err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-claims.sh" 2>&1 >/dev/null ) )"; ec=$?
    if [ "$ec" != "2" ]; then
      err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-experiential.sh" 2>&1 >/dev/null ) )"; ec=$?
    fi
    [ "$ec" = "2" ] && printf '%s' "$err" | jq -Rs '{decision: "block", reason: .}'
    ;;
  *) : ;;   # PreCompact deliberately unregistered: Copilot ignores hook output there (see adapters/README.md)
esac
exit 0
