#!/usr/bin/env bash
# superstack-outside — the cross-model outside voice. Suite: hooks/test-outside.sh.
# Ruling, and why no tool is ever trusted by name: DECISIONS.md D-57.
#
# Usage: superstack-outside.sh <artifact-file> [question]
#   OUTSIDE_CLI      the reviewer command, named EXPLICITLY by the operator —
#                    never auto-detected: binary names collide (a famous model
#                    name may be a disk utility, and an agent wrapper may
#                    proxy any family, including this one, which fakes the
#                    independence this channel exists for).
#   OUTSIDE_TIMEOUT  seconds before a hung tool is cut off (default 300).
#
# The tool runs from a scratch directory and receives the artifact INLINE in
# its prompt: an agentic CLI gets nothing to read and nothing to touch. Its
# output is a CLAIM — source-verify every finding before it earns a fix list
# (superstack-review's provenance rule).
set -u
artifact="${1:?usage: superstack-outside.sh <artifact-file> [question]}"
question="${2:-Attack this artifact adversarially: wrong premises, missing alternatives, overreach.}"
[ -f "$artifact" ] || { echo "superstack-outside: no such artifact: $artifact" >&2; exit 1; }

if [ -z "${OUTSIDE_CLI:-}" ]; then
  cat >&2 <<'MSG'
superstack-outside: no outside CLI is named. Set OUTSIDE_CLI to a command
whose model family the operator can vouch for. It is never auto-detected:
a name collision (a famous model name that is really a disk utility, an
agent wrapper proxying any family) silently fakes the outside voice.
See DECISIONS.md D-57.
MSG
  exit 1
fi
# OUTSIDE_CLI may carry arguments ("codex exec --sandbox read-only"); the
# existence check applies to its first word, the rest travel as arguments.
# shellcheck disable=SC2086
set -- $OUTSIDE_CLI
command -v "$1" >/dev/null 2>&1 || { echo "superstack-outside: named CLI not found: $1" >&2; exit 1; }

secs="${OUTSIDE_TIMEOUT:-300}"
scratch="$(mktemp -d)"; trap 'rm -rf "$scratch"' EXIT

prompt="You are an outside reviewer from a different model family. First line of your reply: identify yourself — state exactly which model and provider you are. Then review the artifact below. ${question}

--- ARTIFACT ---
$(cat "$artifact")
--- END ARTIFACT ---"

capnote=""
# </dev/null is load-bearing: an agent CLI left with an open stdin reads it
# and hangs (same guard as eval/routing/run.sh).
if command -v timeout >/dev/null 2>&1; then
  raw="$(cd "$scratch" && timeout "$secs" "$@" "$prompt" </dev/null 2>&1)"; rc=$?
else
  capnote=" (no timeout binary on this machine — the call ran uncapped)"
  raw="$(cd "$scratch" && "$@" "$prompt" </dev/null 2>&1)"; rc=$?
fi
[ "$rc" -ne 0 ] && { echo "superstack-outside: the tool failed or timed out (exit $rc)$capnote" >&2; printf '%s\n' "$raw" >&2; exit "$rc"; }

printf '=== OUTSIDE VOICE — unverified claim; source-verify every finding before belief%s ===\n' "$capnote"
printf 'tool: %s · timeout: %ss · self-identification is the first line below and is ALSO a claim\n\n' "$OUTSIDE_CLI" "$secs"
printf '%s\n' "$raw"
exit 0
