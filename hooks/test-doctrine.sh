#!/bin/bash
# Self-checks for inject-doctrine.sh — temp repos, style of test-gate.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/inject-doctrine.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

check() { # desc expected_grep(or empty for silence)
  desc="$1"; want="$2"
  out="$(cd "$tmp/repo" && bash "$hook" 2>/dev/null)"
  if [ -z "$want" ]; then
    [ -z "$out" ] && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; }
  else
    printf '%s' "$out" | grep -q "$want" && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; }
  fi
}

git init -q -b main "$tmp/repo"
check "no .superstack dir is silent" ""
mkdir -p "$tmp/repo/.superstack"
check "no doctrine file is silent" ""
printf '# doctrine\n\npreamble, no statutes\n' > "$tmp/repo/.superstack/doctrine.md"
check "doctrine with zero statutes is silent" ""
printf '## 2026-07-20 — menus summarize a mapped space\ntext\n## 2026-07-28 — no module without its trigger\ntext\n' >> "$tmp/repo/.superstack/doctrine.md"
check "two statutes reported with count" "2 standing statute(s)"
check "newest statute title surfaces" "no module without its trigger"
printf '## 2026-07-29 — \x01\x02evil\ttitle with controls\n' >> "$tmp/repo/.superstack/doctrine.md"
check "control characters stripped from title" "eviltitle with controls"
long="$(printf 'x%.0s' $(seq 1 300))"
printf '## 2026-07-30 — %s\n' "$long" >> "$tmp/repo/.superstack/doctrine.md"
out="$(cd "$tmp/repo" && bash "$hook" 2>/dev/null)"
[ "${#out}" -le 400 ] && { pass=$((pass+1)); echo "PASS: output hard-capped at 400 chars"; } || { fail=$((fail+1)); echo "FAIL: cap (len ${#out})"; }

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
