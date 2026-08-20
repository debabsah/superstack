#!/bin/bash
# Shipped surfaces carry no competitor names and no study provenance:
# a change ships on its own merits, provenance stays in the private
# record (statute in .superstack/doctrine.md). Owner upstreams
# (fable-method, godmode) are exempt. Scans the Variant-A ship set; this
# file is excluded so the pattern list can live here.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
terms='superpowers|gsd-core|caveman|mattpocock|gstack|cross-family|teardown|blind report|GPT'
fail=0
# DeepSeek Harness is speakable as a supported host (statute, owner-ruled);
# what never ships is adoption-provenance framing around its name. The
# statute binds wider than this grep; escapes grow the pattern.
# Loose stems would flag the host-support surfaces themselves ("adapter"
# contains "adapt"), so only finished provenance verb forms count.
prov='(adopted|adoption|adopting|adapted from|borrow|inspir|stole|steal|studied|learned from|ported from|based on)[^.]{0,80}(deepseek|dsh harness)|(deepseek|dsh harness)[^.]{0,80}(adopted|adoption|adopting|adapted from|borrow|inspir|stole|steal|studied|learned from|ported from|based on)'
hits="$(cd "$root" && grep -rniIE "$terms" \
  .claude-plugin .github adapters agents assets eval hooks scripts skills \
  CHANGELOG.md README.md LICENSE 2>/dev/null \
  | grep -v 'hooks/test-teardown-privacy.sh')"
if [ -n "$hits" ]; then
  fail=1
  echo "FAIL: teardown/competitor language on a shipped surface:"
  printf '%s\n' "$hits"
fi
# Provenance framing is banned on shipped surfaces and in every repo's
# commit messages; the bare host name is not (host-support rows say it).
provhits="$(cd "$root" && grep -rniIE "$prov" \
  .claude-plugin .github adapters agents assets eval hooks scripts skills \
  CHANGELOG.md README.md LICENSE 2>/dev/null \
  | grep -v 'hooks/test-teardown-privacy.sh')"
if [ -n "$provhits" ]; then
  fail=1
  echo "FAIL: adoption-provenance framing on a shipped surface:"
  printf '%s\n' "$provhits"
fi
loghits="$(cd "$root" && git log --format=%B 2>/dev/null | grep -niE "$prov" | head -20)"
if [ -n "$loghits" ]; then
  fail=1
  echo "FAIL: adoption-provenance framing in commit-message history:"
  printf '%s\n' "$loghits"
fi
echo
if [ "$fail" -eq 0 ]; then echo "teardown-privacy: clean"; exit 0
else echo "teardown-privacy: FAILED"; exit 1; fi
