#!/bin/bash
# superstack — the prompt-time front door. UserPromptSubmit hook (D-18;
# design: dogfood/front-door-design/DESIGN.md, premises: PREMISES.md v2).
# When the submitted prompt is IDEA-SHAPED and the workspace holds NO shaping
# state on disk, print ONE line inviting the model to OFFER the shaping flow
# — an invitation, never a scolding. Silent on everything else; never blocks
# (exit 0 on every path, never 2 — a wrongly blocked prompt is the worst
# failure this hook could have).
#
# Precision over recall (P9): a missed fire costs one diary line; a wrong
# fire costs the owner's patience. The pattern list stays narrow and is tuned
# from NOISE lines — one NOISE line tightens a pattern, two on one class
# remove that pattern. Every fire is audited beside its prompt checksum.
# TUNABLE (dogfooding): ideare.
set -u

# The off switch (S4 semantics): `off` silences everything; `claims` keeps
# only the claims Stop gate — the door yields on both.
case "${SUPERSTACK_GATES:-all}" in off|claims) cat >/dev/null 2>&1; exit 0;; esac

payload="$(cat 2>/dev/null)" || exit 0
[ -n "$payload" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

prompt="$(printf '%s' "$payload" | jq -r '.prompt // empty' 2>/dev/null)" || exit 0
[ -n "$prompt" ] || exit 0

# A slash command is explicit routing — never second-guess it.
case "$prompt" in /*) exit 0;; esac

lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"

# Idea shapes, narrow by design. Verb+me/us ("build me a"), let's-build,
# i-have-an-idea, i-want-to-<verb>+article (the bare "i want to make sure"
# must NOT match), and verb+article+artifact-noun ("create a mario game").
# "make the/make sure" stay silent by construction.
ideare="(^|[^a-z])((build|create|make|design|prototype) (me|us) (a|an|some|the)|let'?s build|i have an idea|i want to (build|create|make) (a|an|some)|(build|create|make|design|prototype) (a|an) ([a-z0-9-]+ ){0,2}(app|tool|site|website|dashboard|game|plugin|skill|cli|bot|service|api|library|extension|prototype|mvp)([^a-z]|$))"
printf '%s' "$lc" | grep -qE "$ideare" || exit 0

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
# The one .superstack/ root rule, resolved from the payload's cwd.
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root "$cwd" 2>/dev/null)"; [ -n "$root" ] || root="$cwd"

# Shaping state on disk silences the door: an ACTIVE plan, any in-flight task
# file, or a premises ledger. Overlay MEMORY (project.md, doctrine, logs) does
# NOT count — a remembered workspace still deserves the door for a NEW idea.
for pf in "$root/.superstack/plans"/*.md; do
  [ -f "$pf" ] || continue
  head -1 "$pf" 2>/dev/null | grep -q 'status: ACTIVE' && exit 0
done
for tf in "$root/.superstack/tasks"/*.md; do
  [ -f "$tf" ] && exit 0
done
[ -f "$root/PREMISES.md" ] && exit 0

# Audit (P9). Where an overlay exists the count lives in it; a bare workspace
# counts in tmp (outward-sweep's precedent) — DECLINING an offer must never
# plant state. The flow itself creates .superstack/ only on ACCEPTANCE (P7).
stamp="front-door-offer $(date +%F) $(printf '%s' "$prompt" | cut -c1-80 | cksum | cut -d' ' -f1)"
if [ -d "$root/.superstack" ]; then
  mkdir -p "$root/.superstack/receipts" 2>/dev/null
  printf '%s\n' "$stamp" >> "$root/.superstack/receipts/loads.log" 2>/dev/null
else
  printf '%s\n' "$stamp" >> "${TMPDIR:-/tmp}/superstack-front-door-$(printf '%s' "$root" | cksum | cut -d' ' -f1)" 2>/dev/null
fi

printf '%s\n' "superstack front door: this prompt reads like a new idea and this workspace has no shaping on disk. OFFER the owner the choice now - ONE question via the question tool, options: shape it first (recommended) / build straight away - then honor the answer silently, no argument either way. If shaping is chosen, load superstack-inception and follow its prompt-time door section; if building is chosen, proceed without comment."
exit 0
