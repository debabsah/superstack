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
    --receipt) [ $# -ge 2 ] || { echo "superstack-mint: --receipt needs a value" >&2; exit 64; }; name="${2:-}"; shift 2 ;;
    --files)   [ $# -ge 2 ] || { echo "superstack-mint: --files needs a value" >&2; exit 64; }; files="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) echo "superstack-mint: unknown argument $1 (usage: --receipt <name> --files \"<paths>\" -- <command...>)" >&2; exit 64 ;;
  esac
done
[ -n "$name" ] && [ -n "$files" ] && [ $# -gt 0 ] || {
  echo "superstack-mint: --receipt, --files, and a command are all mandatory" >&2; exit 64; }
case "$name" in *[!A-Za-z0-9._-]*|..|.)
  echo "superstack-mint: receipt name '$name' — a receipt name is a name, not a path (letters, digits, dot, hyphen, underscore)" >&2; exit 64;;
esac
# A receipt name must not clobber something that is not a receipt: the
# artifact of an earlier run shares this directory.
# -L before -e: a DANGLING symlink is not "existing", so the not-a-receipt
# check below never fires on one and the write follows the link out of the
# record entirely.
if [ -p "$root/.superstack/receipts/$name" ]; then
  echo "superstack-mint: $root/.superstack/receipts/$name is a named pipe — reading it would block forever; remove it" >&2; exit 64
fi
if [ -L "$root/.superstack/receipts/$name" ]; then
  echo "superstack-mint: $root/.superstack/receipts/$name is a symlink — a receipt is written in the record, never through a link out of it" >&2; exit 64
fi
if [ -e "$root/.superstack/receipts/$name" ] \
   && ! head -n 1 "$root/.superstack/receipts/$name" 2>/dev/null | grep -q '^command: '; then
  echo "superstack-mint: $root/.superstack/receipts/$name exists and is not a receipt — refusing to overwrite it" >&2; exit 64
fi
# A name differing only in case is the SAME FILE on this filesystem, so
# writing it destroys a receipt under a name nobody asked for. Compared
# case-folded rather than as a string, for the same reason the binding
# compares what git sees rather than what the caller typed.
if [ -d "$root/.superstack/receipts" ]; then
  lown="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  for _ex in "$root/.superstack/receipts"/*; do
    [ -e "$_ex" ] || continue
    _b="$(basename "$_ex")"
    [ "$_b" = "$name" ] && continue
    if [ "$(printf '%s' "$_b" | tr '[:upper:]' '[:lower:]')" = "$lown" ]; then
      echo "superstack-mint: receipt name '$name' collides with the existing '$_b' — on this filesystem they are one file, and writing it would destroy that receipt; pick a distinct name" >&2; exit 64
    fi
  done
fi
# THE BINDING MUST BE ONE GIT CAN SEE, which is not the same as one that
# exists. The signature is computed by git, so a path git has no view of —
# ignored, untracked, outside the work tree, or the same name in the wrong
# case on a case-insensitive filesystem — reduces to the signature of
# nothing and recomputes equal at every read: a receipt that never stales
# and vouches forever for a surface it never covered, reached by a typo
# rather than a forgery. A binding of only whitespace is worse still: it
# reads as absent at the gate, silently downgrading that receipt to the
# head-only check. Relative paths mean the CALLER's directory and are
# recorded root-relative, because that is how the gate reads them back;
# globs are recorded as the concrete paths they covered AT MINT TIME, so a
# later deletion shows up as a change instead of quietly leaving the
# pathspec.
rootp="$(cd "$root" 2>/dev/null && pwd -P)"; [ -n "$rootp" ] || rootp="$root"
cwdp="$(pwd -P)"
gitok=0; git -C "$rootp" rev-parse --git-dir >/dev/null 2>&1 && gitok=1
exp=""; blind=""; unsafe=""
for p in $files; do
  case "$p" in /*) a="$p" ;; *) a="$cwdp/$p" ;; esac
  rel=""
  case "$a" in
    "$rootp"/*) rel="${a#"$rootp"/}" ;;
    "$rootp")   rel="." ;;
  esac
  if [ -z "$rel" ]; then blind="${blind:+$blind }$p"; continue; fi
  # The binding is ONE FIELD, re-split on whitespace here and again at the
  # gate, so a covered path carrying a space is torn into fragments that
  # match nothing and the receipt vouches forever. A glob delivers such a
  # path without the caller ever typing a space.
  # ALLOW A SAFE SET, never ban one more character each round. Whitespace
  # tears the field; a glob metacharacter turns the recorded name into a
  # pattern that can bind a file nobody asked for and can match nothing
  # later. Both readers re-split and re-glob this field, so only names that
  # survive both belong in it.
  case "$rel" in *[!A-Za-z0-9._/-]*) unsafe="${unsafe:+$unsafe }$rel"; continue ;; esac
  if [ "$gitok" -eq 1 ]; then
    git -C "$rootp" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 || { blind="${blind:+$blind }$p"; continue; }
    # Where git has been told to stop watching a path (assume-unchanged,
    # skip-worktree), it reports clean however the file changes, so the
    # signature would keep vouching over real edits.
    # [[:lower:]], never [a-z]: this platform's collation puts uppercase
    # inside that range, so [a-z] matched the ordinary H and refused every
    # tracked file.
    case "$(git -C "$rootp" ls-files -v -- "$rel" 2>/dev/null | cut -c1 | sort -u | tr -d '\n')" in
      *[[:lower:]]*|*S*) blind="${blind:+$blind }$p"; continue ;;
    esac
  else
    [ -e "$a" ] || { blind="${blind:+$blind }$p"; continue; }
  fi
  exp="${exp:+$exp }$rel"
done
[ -z "$unsafe" ] || {
  echo "superstack-mint: --files names $unsafe, whose characters the binding cannot carry — the field is re-split and re-expanded by two readers, so a covered path may use only letters, digits, dot, underscore, hyphen and slash. Rename the path, or bind the directory holding it" >&2; exit 64; }
[ -z "$blind" ] || {
  echo "superstack-mint: --files names $blind, which git cannot see — untracked, ignored, outside the work tree, or the same name in the wrong case. A binding git cannot see reduces to the signature of nothing and recomputes equal at every read, so the receipt would vouch forever" >&2; exit 64; }
[ -n "$exp" ] || {
  echo "superstack-mint: --files names no path git can see — the binding is the point" >&2; exit 64; }
files="$exp"

# shellcheck disable=SC2086
covsig() { (cd "$root" && git diff HEAD -- $files 2>/dev/null; git status --porcelain -- $files 2>/dev/null) | cksum | cut -d' ' -f1; }
# The signature must describe the tree the check SAW. Taken only after the
# run, a covered file edited mid-flight is baked in as though the check had
# observed it — the receipt then vouches for a state nothing verified.
sig0="$(covsig)"
rev0="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"
# stdin comes from nowhere: a driver that reads it (xargs and friends) would
# otherwise wait on the caller's terminal forever, with no receipt and no
# word about why.
out="$("$@" 2>&1 </dev/null)"; rc=$?

rev="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"; [ -n "$rev" ] || rev=none
sig="$(covsig)"
# The revision is compared too: a commit landing mid-run leaves the dirty
# state clean at both ends, so the signature pair alone reads as no
# movement while the receipt names a revision the check never saw.
[ "$sig0" = "$sig" ] && [ "$rev0" = "$(git -C "$root" rev-parse --short HEAD 2>/dev/null)" ] || {
  echo "superstack-mint: the tree moved while the check was running (a covered file changed, or a commit landed) — the run did not observe the state this receipt would bind, so nothing is written; settle the tree and re-run" >&2
  exit 70; }

mkdir -p "$root/.superstack/receipts"
rp="$root/.superstack/receipts/$name"
# The command has run since the receipt path was judged, so a run that
# plants a link at its own receipt path would redirect this write out of
# the record or onto a genuine receipt. Judge again, then write to a name
# nothing can have prepared and rename into place: a rename replaces a
# symlink instead of following it.
if [ -p "$rp" ]; then
  echo "superstack-mint: $rp became a named pipe while the check ran — reading it would block forever; nothing is written" >&2; exit 64
fi
if [ -L "$rp" ]; then
  echo "superstack-mint: $rp became a symlink while the check ran — a receipt is written in the record, never through a link out of it; nothing is written" >&2; exit 64
fi
if [ -e "$rp" ] && ! head -n 1 "$rp" 2>/dev/null | grep -q '^command: '; then
  echo "superstack-mint: $rp exists and is not a receipt — refusing to overwrite it" >&2; exit 64
fi
# The staging name sits OUTSIDE receipts/ (a leftover there would be a
# citable receipt name and would be counted as one) and carries more than
# the pid, which the driver knows because this process is its parent.
rptmp="$root/.superstack/.minting.$$.${RANDOM:-0}"
rm -f "$rptmp" 2>/dev/null
# EVERY FIELD IS ONE LINE. The gate reads this file first-match-wins, so a
# newline inside a recorded value would write fields of its own beneath the
# one it belongs to — forging freshness, binding, or exit through the
# trusted writer. Whatever arrives, one line goes out.
oneline() { printf '%s' "$1" | tr '\n\r' '  '; }
{
  printf 'command: %s\n' "$(oneline "$*")"
  printf 'exit: %s\n' "$rc"
  printf 'output-tail: %s\n' "$(printf '%s\n' "$out" | tail -n 3 | tr '\n\r' '  ' | cut -c1-300)"
  printf 'timestamp: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')"
  printf 'revision: %s\n' "$rev"
  printf 'files: %s\n' "$(oneline "$files")"
  printf 'filesig: %s\n' "$sig"
} > "$rptmp" || {
  echo "superstack-mint: could not write the receipt to $rptmp — nothing was recorded" >&2; rm -f "$rptmp" 2>/dev/null; exit 73; }
mv -f "$rptmp" "$rp" || {
  echo "superstack-mint: could not install the receipt at $rp — nothing was recorded" >&2; rm -f "$rptmp" 2>/dev/null; exit 73; }
# A WRITE THAT DID NOT LAND IS NOT A RECEIPT: say so instead of announcing
# evidence that is not there. A full disk reaches this with no adversary.
if [ -L "$rp" ] || [ ! -f "$rp" ] || ! head -n 1 "$rp" 2>/dev/null | grep -q '^command: '; then
  echo "superstack-mint: the receipt did not land at $rp — nothing is recorded there" >&2; exit 73
fi

echo "superstack-mint: wrote $rp (exit $rc)"
exit "$rc"
