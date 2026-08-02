#!/usr/bin/env bash
# superstack — the one .superstack/ root rule. SOURCED, never executed directly.
# Suite: hooks/test-root.sh. Rationale and evidence: DECISIONS.md D-6.
#
# THE RULE: an existing .superstack/ at the cwd wins; else the git root's; else
# the cwd. Skill bodies all write relative `.superstack/…` paths, so the cwd is
# where the record gets made; the git root keeps a monorepo subdir session on the
# repo's single record instead of growing a half-record per directory.
#
# Constraints, ordered by how easily each is "improved" back into a bug:
# - NOT a walk-up loop. A stray .superstack/ several levels up would capture an
#   unrelated project — a wrong record read confidently is worse than none.
# - `pwd -P` throughout. `git rev-parse --show-toplevel` reports the PHYSICAL
#   path, so a logical `pwd` makes the two branches disagree on form for one
#   directory (macOS /var -> /private/var). Callers concatenate and compare these.
# - Every branch prints and returns 0, so a caller that cannot source this file
#   falls back to its own inline rule instead of failing closed.
superstack_root() {
  _ssr_d="${1:-.}"
  if [ -d "$_ssr_d/.superstack" ]; then
    (cd "$_ssr_d" 2>/dev/null && pwd -P) && return 0
  fi
  _ssr_r="$(cd "$_ssr_d" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$_ssr_r" ]; then printf '%s\n' "$_ssr_r"; return 0; fi
  (cd "$_ssr_d" 2>/dev/null && pwd -P) || printf '%s\n' "$_ssr_d"
  return 0
}
