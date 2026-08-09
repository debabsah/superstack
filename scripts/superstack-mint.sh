#!/usr/bin/env bash
# superstack-mint — runtime-owned receipt minting (D-66). Suite:
# hooks/test-mint.sh; the gate pairing is pinned in hooks/test-gate.sh.
#
# The minter RUNS the named check itself and writes the emitted- receipt from
# what it observed, so the receipt's command/exit/output lines are never
# prose from memory. The receipt binds to the surface it covers:
#   revision  — the short head at mint time (none in a git-less workspace)
#   files:    — the covered paths the caller names (mandatory: the binding
#               is the point; a receipt that covers nothing vouches wrongly)
#   filesig:  — cksum of (git diff HEAD + git status --porcelain) over the
#               covered paths. THE SAME RECIPE LIVES IN gate-claims.sh's
#               fast path — change one, change both; the integration rows in
#               test-gate.sh go red if they drift apart.
# The minter's own exit mirrors the check's, so a red check is loud; the
# receipt records the failure honestly either way, and the gate refuses to
# let a failing-check receipt vouch. Paths with spaces are unsupported (the
# files field word-splits, in both writers).
#
# Usage: superstack-mint.sh --receipt <name> --files "<paths>" -- <command...>
set -u
. "$(dirname "$0")/../hooks/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"

name=""; files=""
while [ $# -gt 0 ]; do
  case "$1" in
    --receipt) name="${2:-}"; shift 2 ;;
    --files)   files="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) echo "superstack-mint: unknown argument $1 (usage: --receipt <name> --files \"<paths>\" -- <command...>)" >&2; exit 64 ;;
  esac
done
[ -n "$name" ] && [ -n "$files" ] && [ $# -gt 0 ] || {
  echo "superstack-mint: --receipt, --files, and a command are all mandatory" >&2; exit 64; }

out="$("$@" 2>&1)"; rc=$?

rev="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"; [ -n "$rev" ] || rev=none
# shellcheck disable=SC2086
sig="$( (cd "$root" && git diff HEAD -- $files 2>/dev/null; git status --porcelain -- $files 2>/dev/null) | cksum | cut -d' ' -f1)"

mkdir -p "$root/.superstack/receipts"
rp="$root/.superstack/receipts/$name"
{
  printf 'command: %s\n' "$*"
  printf 'exit: %s\n' "$rc"
  printf 'output-tail: %s\n' "$(printf '%s\n' "$out" | tail -n 3 | tr '\n' ' ' | cut -c1-300)"
  printf 'timestamp: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')"
  printf 'revision: %s\n' "$rev"
  printf 'files: %s\n' "$files"
  printf 'filesig: %s\n' "$sig"
} > "$rp"

echo "superstack-mint: wrote $rp (exit $rc)"
exit "$rc"
