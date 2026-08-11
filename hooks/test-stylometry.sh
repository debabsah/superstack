#!/bin/bash
# Shipped prose carries no em/en dashes: the characters read machine-authored,
# and the commit guard already bans them in commit messages. Ceiling ZERO:
# any hit is red. Scope is the stranger-facing surfaces. Exemption, per the
# statute's quoted-product-output clause: fenced code blocks only — the
# README's session-voice example quotes hook output whose grammar carries the
# character. Prose stays unconditional; the fence is the whole boundary.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
for f in README.md CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json adapters/README.md; do
  hits="$(awk '/^ *```/{ib=!ib; next} !ib {printf "%d:%s\n", NR, $0}' "$root/$f" 2>/dev/null | grep $'—\|–' || true)"
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
