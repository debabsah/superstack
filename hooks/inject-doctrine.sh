#!/bin/bash
# superstack SessionStart hook — surface standing project doctrine as one
# capped ambient line. Statutes live in .superstack/doctrine.md as '## ' headers
# (written by the superstack-doctrine skill). Silent when there are none.
# Hardening mirrors inject-project-pointer.sh: control chars stripped, hard cap.
set -u
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"
f="$root/.superstack/doctrine.md"
[ -f "$f" ] || exit 0
n="$(grep -c '^## ' "$f" 2>/dev/null)" || exit 0
[ "${n:-0}" -gt 0 ] || exit 0
newest="$(grep '^## ' "$f" | tail -1 | sed 's/^## *//' | tr -d '[:cntrl:]' | cut -c1-120)"
printf 'superstack doctrine: %s standing statute(s); newest: %s — statutes bind until the owner lifts them; read .superstack/doctrine.md before acting in their scope.\n' "$n" "$newest" | cut -c1-400
exit 0
