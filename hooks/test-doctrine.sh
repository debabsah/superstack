#!/bin/bash
# Self-checks for inject-doctrine.sh — temp repos, style of test-gate.sh.
# CLAUDE_CONFIG_DIR is pinned to a fixture for every check: the hook reads the
# personal rule book from there, and a real one on the running machine must
# never leak into these fixtures.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/inject-doctrine.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

check() { # desc expected_grep(or empty for silence)
  desc="$1"; want="$2"
  out="$(cd "$tmp/repo" && CLAUDE_CONFIG_DIR="$tmp/cfg" bash "$hook" 2>/dev/null)"
  if [ -z "$want" ]; then
    [ -z "$out" ] && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; }
  else
    printf '%s' "$out" | grep -q "$want" && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; }
  fi
}

git init -q -b main "$tmp/repo"
mkdir -p "$tmp/cfg"
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
out="$(cd "$tmp/repo" && CLAUDE_CONFIG_DIR="$tmp/cfg" bash "$hook" 2>/dev/null)"
[ "${#out}" -le 400 ] && { pass=$((pass+1)); echo "PASS: output hard-capped at 400 chars"; } || { fail=$((fail+1)); echo "FAIL: cap (len ${#out})"; }

# The personal rule book (D-49): a doctrine file under CLAUDE_CONFIG_DIR binds
# in every workspace and surfaces beside the project's line.
printf '# doctrine\n## 2026-08-08 — chat carries no internal codes\ntext\n' > "$tmp/cfg/superstack-doctrine.md"
check "personal statute surfaces beside the project line" "personal, every workspace"
check "personal newest title surfaces" "chat carries no internal codes"
out="$(cd "$tmp/repo" && CLAUDE_CONFIG_DIR="$tmp/cfg" bash "$hook" 2>/dev/null)"
[ "$(printf '%s\n' "$out" | grep -c 'superstack doctrine')" -eq 2 ] && { pass=$((pass+1)); echo "PASS: both lines print when both files carry statutes"; } || { fail=$((fail+1)); echo "FAIL: expected two doctrine lines (got: $out)"; }
rm -rf "$tmp/repo/.superstack"
check "personal line appears with no project doctrine at all" "personal, every workspace"
out="$(cd "$tmp/repo" && CLAUDE_CONFIG_DIR="$tmp/cfg" bash "$hook" 2>/dev/null)"
printf '%s' "$out" | grep -q "statutes bind until the owner lifts them" && { fail=$((fail+1)); echo "FAIL: project trailer printed without a project file"; } || { pass=$((pass+1)); echo "PASS: no project line without a project file"; }
printf '## 2026-08-08 — %s\n' "$long" >> "$tmp/cfg/superstack-doctrine.md"
out="$(cd "$tmp/repo" && CLAUDE_CONFIG_DIR="$tmp/cfg" bash "$hook" 2>/dev/null)"
# ${#line} follows the shell's locale exactly as the hook's cut does; awk here
# counts bytes on macOS and reads a 400-char line with em dashes as over-cap.
maxlen=0
while IFS= read -r line; do [ "${#line}" -gt "$maxlen" ] && maxlen="${#line}"; done <<EOF
$out
EOF
[ "$maxlen" -le 400 ] && { pass=$((pass+1)); echo "PASS: personal line hard-capped at 400 chars"; } || { fail=$((fail+1)); echo "FAIL: personal cap (len $maxlen)"; }
printf '# doctrine\n\nno statutes here\n' > "$tmp/cfg/superstack-doctrine.md"
check "personal file with zero statutes is silent" ""

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
