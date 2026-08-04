#!/usr/bin/env bash
# README badges state a version and a suite count. Every value here is
# recomputed from the tree: the manifests are the only source for the version,
# the hooks directory is the only source for the suite count. A badge number
# that cannot be recomputed from the tree does not belong on the README.
# Rationale: DECISIONS.md D-43.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
readme="$root/README.md"
plugin="$root/.claude-plugin/plugin.json"
market="$root/.claude-plugin/marketplace.json"

command -v jq >/dev/null || { echo "jq is required for this suite"; exit 1; }

fails=0; checks=0
fail() { echo "  FAIL: $1"; fails=$((fails+1)); }

v_plugin="$(jq -r .version "$plugin")"
v_market="$(jq -r '.plugins[0].version' "$market")"

checks=$((checks+1))
[ "$v_plugin" = "$v_market" ] || fail "manifest versions disagree: plugin.json $v_plugin vs marketplace.json $v_market"

n=0
for f in "$root"/hooks/test-*.sh; do [ -f "$f" ] && n=$((n+1)); done

b_version="$(sed -n 's/.*img\.shields\.io\/badge\/version-\([0-9][0-9.]*\)-.*/\1/p' "$readme" | head -1)"
b_suites="$(sed -n 's/.*img\.shields\.io\/badge\/tests-\([0-9][0-9]*\)%20suites.*/\1/p' "$readme" | head -1)"

checks=$((checks+1))
[ "$b_version" = "$v_plugin" ] || fail "version badge says '${b_version:-none}', the manifests say $v_plugin"
checks=$((checks+1))
grep -qF "alt=\"Version $v_plugin\"" "$readme" || fail "version badge alt text does not say $v_plugin"
checks=$((checks+1))
[ "$b_suites" = "$n" ] || fail "tests badge says '${b_suites:-none}' suites, hooks/ holds $n"
checks=$((checks+1))
grep -qF "alt=\"Tests: $n suites\"" "$readme" || fail "tests badge alt text does not say $n suites"

echo
if [ "$fails" -eq 0 ]; then
  echo "all checks pass ($checks)"
  exit 0
else
  echo "$fails of $checks badge check(s) failed: recompute the badge from the tree (manifest version, live suite count) instead of hand-editing the number."
  exit 1
fi
