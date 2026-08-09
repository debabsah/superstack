#!/bin/bash
# superstack SessionStart hook — surface standing doctrine as capped ambient
# lines. Two sources, one line each, silent when empty: the project's statutes
# (.superstack/doctrine.md) and the owner's personal rule book
# (${CLAUDE_CONFIG_DIR:-~/.claude}/superstack-doctrine.md), which binds in
# EVERY workspace; inside a project, the project's own statute outranks a
# personal one. Statutes are '## ' headers (written by superstack-doctrine).
# Hardening mirrors inject-project-pointer.sh: control chars stripped, hard cap
# per line.
set -u
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"

emit() { # file label trailer — one capped line, or nothing
  ef="$1"; elabel="$2"; etrailer="$3"
  [ -f "$ef" ] || return 0
  en="$(grep -c '^## ' "$ef" 2>/dev/null)" || return 0
  [ "${en:-0}" -gt 0 ] || return 0
  enewest="$(grep '^## ' "$ef" | tail -1 | sed 's/^## *//' | tr -d '[:cntrl:]' | cut -c1-120)"
  printf '%s: %s standing statute(s); newest: %s — %s\n' "$elabel" "$en" "$enewest" "$etrailer" | cut -c1-400
}

emit "$root/.superstack/doctrine.md" \
  "superstack doctrine" \
  "statutes bind until the owner lifts them; read .superstack/doctrine.md before acting in their scope."
pf="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/superstack-doctrine.md"
emit "$pf" \
  "superstack doctrine (personal, every workspace)" \
  "the owner's own rules, binding in this workspace too; the project statute wins where they collide; read $pf before acting in their scope."
exit 0
