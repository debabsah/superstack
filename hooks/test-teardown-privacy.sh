#!/bin/bash
# Shipped surfaces carry no competitor names and no study provenance:
# a change ships on its own merits, provenance stays in the private
# record (statute in .superstack/doctrine.md). Owner upstreams
# (fable-method, godmode) are exempt. Scans the Variant-A ship set; this
# file is excluded so the pattern list can live here.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
terms='superpowers|gstack|cross-family|teardown|blind report|GPT'
fail=0
hits="$(cd "$root" && grep -rniIE "$terms" \
  .claude-plugin .github agents assets eval hooks scripts skills \
  CHANGELOG.md README.md LICENSE 2>/dev/null \
  | grep -v 'hooks/test-teardown-privacy.sh')"
if [ -n "$hits" ]; then
  fail=1
  echo "FAIL: teardown/competitor language on a shipped surface:"
  printf '%s\n' "$hits"
fi
echo
if [ "$fail" -eq 0 ]; then echo "teardown-privacy: clean"; exit 0
else echo "teardown-privacy: FAILED"; exit 1; fi
