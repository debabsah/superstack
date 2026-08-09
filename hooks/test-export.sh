#!/bin/bash
# Self-checks for scripts/superstack-export.sh — temp repos, style of
# test-doctrine.sh. Fixtures are real git repos: the root resolver branches on
# git and a fixture that can only take one branch tests nothing.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../scripts/superstack-export.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$script" ] && ok "script exists" || bad "script exists (missing: $script)"

repo="$tmp/repo"
git init -q -b main "$repo"
mkdir -p "$repo/.superstack/plans" "$repo/.superstack/tasks" "$repo/.superstack/receipts" "$repo/sub"
printf '<!-- plan: p status: CLOSED -->\ngoal: g\n' > "$repo/.superstack/plans/p.md"
printf '<!-- task: t — goal: g — next: n -->\n' > "$repo/.superstack/tasks/t.md"
printf '# doctrine\n## 2026-08-08 — a statute\n' > "$repo/.superstack/doctrine.md"
printf '2026-08-08 · a verified claim · cmd\n' > "$repo/.superstack/claims-log"
printf '%s\n' '- Q1 parked item' > "$repo/.superstack/queue.md"
printf '%s\n' '- a residual' > "$repo/.superstack/residuals.md"
printf '2026-08-08 PASS phrase=done\n' > "$repo/.superstack/gate-log"
printf '2026-08-08 swept: x — findings: none\n' > "$repo/.superstack/outward-pass"
printf 'receipt body\n' > "$repo/.superstack/receipts/r.txt"
printf 'toured\n' > "$repo/.superstack/toured.md"

out="$(cd "$repo" && bash "$script" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "export exits 0 from repo root" || bad "export exits 0 (rc=$rc: $out)"
d="$repo/superstack-export"
for f in plans/p.md tasks/t.md doctrine.md claims-log queue.md residuals.md README.md; do
  [ -f "$d/$f" ] && ok "slice carries $f" || bad "slice carries $f"
done
for f in gate-log outward-pass toured.md receipts; do
  [ ! -e "$d/$f" ] && ok "slice excludes $f" || bad "slice excludes $f"
done
grep -q "excluded by design" "$d/README.md" 2>/dev/null && ok "export README states the exclusions" || bad "export README states the exclusions"

printf 'stale\n' > "$d/stale-leftover.txt"
( cd "$repo/sub" && bash "$script" >/dev/null 2>&1 )
[ -f "$d/doctrine.md" ] && ok "run from a subdir lands at the repo root" || bad "run from a subdir lands at the repo root"
[ ! -e "$d/stale-leftover.txt" ] && ok "re-export replaces the snapshot (stale file gone)" || bad "re-export replaces the snapshot"

bare="$tmp/bare"; git init -q -b main "$bare"
out="$(cd "$bare" && bash "$script" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "no .superstack refuses with nonzero exit" || bad "no .superstack refuses (rc=0)"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
