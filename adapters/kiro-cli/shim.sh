#!/usr/bin/env bash
# adapters/kiro-cli/shim.sh — Kiro CLI adapter (kiro plan M2, D-77/D-78).
# One argument: the event. Stdin: Kiro's JSON payload (hook_event_name, cwd,
# prompt / tool_name + tool_input / assistant_response). Kiro keeps no
# transcript, so this shim WRITES the turn record the gates walk: one
# turn-cut marker per prompt, one line per mutating tool event, keyed by
# KIRO_SESSION_ID under TMPDIR. Kiro's tool vocabulary (execute_bash,
# fs_write, delegate) is mapped here; the core hooks stay host-neutral.
# Blocking reality (the kiro probe record in dogfood/): preToolUse denies
# via exit 2 + stderr; the stop event cannot block on this host, so a
# turn-end gate bounce surfaces as a visible warning in the session UI and
# the turn stands (D-78: warn-only, labeled on the matrix).
# Fail-open everywhere: parsing doubt, missing jq, missing files -> exit 0.
# Suite: hooks/test-adapter-kiro.sh.
set -u
ev="${1:-}"
here="$(cd "$(dirname "$0")" && pwd)"
hooks="$here/../../hooks"
command -v jq >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }
payload="$(cat 2>/dev/null)" || payload=""
printf '%s' "$payload" | jq -e . >/dev/null 2>&1 || exit 0

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }
cwd="$(field '.cwd')"; [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
# The session id names a file; a value carrying a separator could steer the
# write outside TMPDIR, so anything but a plain name collapses to one.
sid="${KIRO_SESSION_ID:-nosession}"
case "$sid" in *[!A-Za-z0-9._-]*|"") sid=nosession;; esac
rec="${TMPDIR:-/tmp}/superstack-kiro-$sid.jsonl"

append_rec() { # the writer owns the bound, same rule as every gate log
  printf '%s\n' "$1" >> "$rec" 2>/dev/null || return 0
  if [ "$(wc -l < "$rec" 2>/dev/null || echo 0)" -gt 400 ]; then
    t="$(mktemp "$rec.XXXXXX" 2>/dev/null)" && tail -n 400 "$rec" > "$t" 2>/dev/null && mv "$t" "$rec" || rm -f "$t"
  fi
}

case "$ev" in
  userPromptSubmit)
    append_rec '{"type": "user"}'
    # .prompt and .cwd are dialect-compatible: the payload passes through
    # whole, and raw stdout injects into the model's context on this host.
    printf '%s' "$payload" | ( cd "$cwd" && bash "$hooks/front-door.sh" 2>/dev/null )
    ;;
  preToolUse)
    tn="$(field '.tool_name')"
    case "$tn" in execute_bash|shell|local_shell) ;; *) exit 0 ;; esac
    gp="$(printf '%s' "$payload" | jq -c '.tool_name = "Bash"' 2>/dev/null)"
    [ -n "$gp" ] || exit 0
    err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/outward-sweep.sh" 2>&1 >/dev/null ) )"; ec=$?
    if [ "$ec" = "2" ]; then printf '%s\n' "$err" >&2; exit 2; fi
    ;;
  postToolUse)
    tn="$(field '.tool_name')"
    case "$tn" in
      execute_bash|shell|local_shell)
        line="$(printf '%s' "$payload" | jq -c '{type: "assistant", name: "Bash", command: (.tool_input.command // "")}' 2>/dev/null)" ;;
      fs_write)
        line="$(printf '%s' "$payload" | jq -c '{type: "assistant", name: (if (.tool_input.command // "") == "create" then "Write" else "Edit" end), file_path: (.tool_input.path // "")}' 2>/dev/null)" ;;
      delegate)
        line='{"type": "assistant", "name": "Task"}' ;;
      *) exit 0 ;;
    esac
    [ -n "$line" ] && append_rec "$line"
    ;;
  stop)
    last="$(field '.assistant_response')"
    [ -n "$last" ] || exit 0
    [ -f "$rec" ] || exit 0
    gp="$(jq -n --arg last "$last" --arg tp "$rec" \
      '{last_assistant_message: $last, transcript_path: $tp, stop_hook_active: false}')"
    err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-claims.sh" 2>&1 >/dev/null ) )"; ec=$?
    if [ "$ec" != "2" ]; then
      err="$(printf '%s' "$gp" | ( cd "$cwd" && bash "$hooks/gate-experiential.sh" 2>&1 >/dev/null ) )"; ec=$?
    fi
    if [ "$ec" = "2" ]; then printf '%s\n' "$err" >&2; exit 2; fi
    ;;
  *) : ;;
esac
exit 0
