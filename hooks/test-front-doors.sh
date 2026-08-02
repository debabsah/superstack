#!/bin/bash
# Front-door completeness: every module skill is named in every enumerated surface.
# The 0.5.0 release proved this rots when left to memory (marketplace.json shipped
# saying "nine modules" while eighteen existed; caught a release later by reviewers,
# not by any check). This makes the roster mechanical. Kernel runner dirs are exempt:
# they are covered by prose ("the kernel: ... runners"), and the gateway's own
# front-door clause is pinned by KERNEL.md's invariant check, not here.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
pass=0; fail=0
kernel="superstack-scope superstack-debug superstack-review superstack-verify superstack-ship superstack-status"
for d in "$root"/skills/superstack-*/; do
  name="$(basename "$d")"
  case " $kernel " in *" $name "*) continue ;; esac
  for surface in README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    if grep -q "$name" "$root/$surface"; then pass=$((pass+1))
    else fail=$((fail+1)); echo "FAIL: $name missing from $surface"; fi
  done
done
echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
