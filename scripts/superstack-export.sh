#!/usr/bin/env bash
# superstack-export — copy the shareable slice of .superstack into a committed
# folder (superstack-export/) at the repo root. Suite: hooks/test-export.sh.
# Ruling and slice contents: DECISIONS.md D-48.
#
# ALLOWLIST, never everything: plans/ tasks/ doctrine.md claims-log queue.md
# residuals.md. Behavioral logs (gate-log, outward logs, receipts/) and
# anything unlisted stay local — adding to the slice is a ruling, not a
# convenience edit here.
#
# Read-back is by eye or by copying files into a fresh .superstack/ — there is
# no import step on purpose; the export is plain text.
set -u
. "$(dirname "$0")/../hooks/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"
S="$root/.superstack"
[ -d "$S" ] || { echo "superstack-export: no .superstack under $root — nothing to export" >&2; exit 1; }

dest="$root/superstack-export"
rm -rf "$dest"
mkdir -p "$dest"

copied=0
for d in plans tasks; do
  [ -d "$S/$d" ] || continue
  for f in "$S/$d"/*.md; do
    [ -f "$f" ] || continue
    mkdir -p "$dest/$d"
    cp "$f" "$dest/$d/" && copied=$((copied+1))
  done
done
for f in doctrine.md claims-log queue.md residuals.md; do
  [ -f "$S/$f" ] && cp "$S/$f" "$dest/$f" && copied=$((copied+1))
done

rev="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo no-commits)"
{
  echo "# superstack export — the shareable slice of this project's record"
  echo
  echo "exported: $(date '+%Y-%m-%d %H:%M') at revision $rev"
  echo "contains (whichever existed): plans/ tasks/ doctrine.md claims-log queue.md residuals.md"
  echo "excluded by design: gate-log, outward logs, receipts/ — behavioral, stays local (D-48)"
  echo "read-back: plain text; copy files into a fresh .superstack/ to adopt them"
} > "$dest/README.md"

echo "superstack-export: $copied file(s) -> $dest"
exit 0
