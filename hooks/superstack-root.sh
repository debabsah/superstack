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
  if [ -n "$_ssr_r" ]; then
    # Re-resolve git's answer through pwd -P: Windows git speaks C:/ drive
    # form while the shell speaks /c/ MSYS form, and callers compare these.
    (cd "$_ssr_r" 2>/dev/null && pwd -P) && return 0
    printf '%s\n' "$_ssr_r"; return 0
  fi
  (cd "$_ssr_d" 2>/dev/null && pwd -P) || printf '%s\n' "$_ssr_d"
  return 0
}

# Advisory per-gate run counter (.superstack/gate-runs.<gate>, D-81): the
# recall denominator the capped gate-log cannot carry. ONE FILE PER GATE —
# the two Stop hooks run in parallel on the flagship host, so a shared file
# rewritten whole loses increments to that race every turn end; per-gate
# files leave only the cross-session same-gate race, priced as advisory.
# temp+mv, never corrupts. Every branch returns 0: a counter must not be
# able to fail a gate.
superstack_count_run() { # $1 gate name; $2 optional dir for the root rule
  _scr_r="$(superstack_root "${2:-.}" 2>/dev/null)"
  [ -n "$_scr_r" ] && [ -d "$_scr_r/.superstack" ] || return 0
  _scr_f="$_scr_r/.superstack/gate-runs.$1"
  _scr_n="$(sed -n "s/^$1 //p" "$_scr_f" 2>/dev/null)"
  case "$_scr_n" in ''|*[!0-9]*) _scr_n=0;; esac
  _scr_t="$(mktemp "$_scr_f.XXXXXX" 2>/dev/null)" || return 0
  printf '%s %s\n' "$1" "$((_scr_n + 1))" > "$_scr_t" 2>/dev/null \
    && mv "$_scr_t" "$_scr_f" 2>/dev/null || rm -f "$_scr_t"
  return 0
}
