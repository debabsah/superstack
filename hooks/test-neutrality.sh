#!/usr/bin/env bash
# CROSS-HARNESS NEUTRALITY CHECK. Skill prose names the moment (session
# start, turn end, compaction), never a host's own event or tool name; a
# host name in a skill body is a portability bug, and this scan is what
# keeps a new one from landing. Rationale: DECISIONS.md D-75.
#
# Scope boundaries (D-75): frontmatter is exempt (descriptions are router
# surfaces; edits there need their own measurement before shipping), and
# hooks/ plus hooks.json are never scanned: they ARE the Claude Code
# adapter. Path and file-name conventions (CLAUDE.md, ~/.claude, the host
# CLI in smith) are adapter coupling points for the capability matrix, not
# prose bugs; keep them out of TOKENS.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
CEILING="${NEUTRALITY_CEILING:-0}"

TOKENS='(SessionStart|UserPromptSubmit|PreToolUse|PostToolUse|SubagentStop|PreCompact|Stop[- ][Hh]ook|AskUserQuestion|TodoWrite|Claude Code)'

# One awk pass per file drops the frontmatter block while keeping original
# line numbers. `neutrality-exempt` on a line is the only escape hatch,
# per-line, never per-file.
found="$(
  for f in "$root"/skills/*/SKILL.md "$root"/skills/*/references/*.md; do
    [ -f "$f" ] || continue
    awk -v f="${f#"$root"/}" '
      NR==1 && /^---[[:space:]]*$/ { fm=1; next }
      fm==1 { if (/^---[[:space:]]*$/) fm=0; next }
      { printf "%s:%d:%s\n", f, NR, $0 }
    ' "$f"
  done | grep -E "$TOKENS" | grep -v 'neutrality-exempt'
)"
hits="$(printf '%s' "$found" | grep -c .)"
[ -n "$found" ] && printf '%s\n' "$found" | cut -c1-110 | sed 's/^/  /'

echo
if [ "$hits" -le "$CEILING" ]; then
  echo "all checks pass ($hits host-specific reference(s), ceiling $CEILING)"
  exit 0
else
  echo "$hits host-specific reference(s) over a ceiling of $CEILING — name the moment (session start, turn end, compaction), never the host's event or tool; hosts live in hooks/ and the adapter layer."
  exit 1
fi
