#!/bin/bash
# Shipped prose carries no em/en dashes: the characters read machine-authored,
# and the commit guard already bans them in commit messages. Ceiling ZERO:
# any hit is red. Scope is the four stranger-facing surfaces. Quoted product
# output would be exempt by statute, but no surface quotes any today, so the
# grep stays unconditional; add an exemption only with the quote that needs it.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
for f in README.md CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  hits="$(grep -n $'—\|–' "$root/$f" 2>/dev/null || true)"
  if [ -z "$hits" ]; then
    pass=$((pass+1)); echo "PASS: $f is dash-free"
  else
    fail=$((fail+1)); echo "FAIL: $f carries em/en dashes:"
    printf '%s\n' "$hits" | head -5 | sed 's/^/  /'
  fi
done
echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass surfaces dash-free, ceiling 0)"; exit 0
else echo "$fail surface(s) FAILED ($pass passed)"; exit 1; fi
