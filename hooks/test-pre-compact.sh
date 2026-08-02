#!/bin/bash
# Self-checks for pre-compact.sh — the PreCompact goal/frontier carrier (S5,
# dogfood/reduction-trial/PREREG.md §3). The contract: when an ACTIVE plan
# exists, its VERBATIM goal: and frontier: lines reach stdout before
# compaction can eat them, and every path exits 0 (best-effort by design —
# godmode's pre-compact.sh is the pattern). Temp repos; style of test-outward.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/pre-compact.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

run() { printf '{"trigger":"auto"}' | ( cd "$1" && bash "$hook" 2>/dev/null ); }
runec() { printf '{"trigger":"auto"}' | ( cd "$1" && bash "$hook" ) >/dev/null 2>&1; echo $?; }

check() { # desc grep_fixed_pattern(or !pattern for absence) output
  desc="$1"; pat="$2"; out="$3"
  case "$pat" in
    '!'*) printf '%s' "$out" | grep -qF -- "${pat#!}" && { fail=$((fail+1)); echo "FAIL: $desc"; } || { pass=$((pass+1)); echo "PASS: $desc"; } ;;
    *)    printf '%s' "$out" | grep -qF -- "$pat" && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; } ;;
  esac
}
ck_exit() { # desc want got
  if [ "$3" = "$2" ]; then pass=$((pass+1)); echo "PASS: $1"
  else fail=$((fail+1)); echo "FAIL: $1 (exit $3, wanted $2)"; fi
}

git init -q -b main "$tmp/repo"; mkdir -p "$tmp/repo/.superstack/plans"
# The goal is deliberately LONGER than the SessionStart line's 120-char goal
# cap: this hook must print it verbatim, not the preamble's truncation.
goal='goal: give the catalog a portal a stranger can navigate unaided even when the sidebar is folded and the search index is still cold'
fr='frontier: step-3 in-progress @ 2026-07-28 abc1234 opus-5'
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\n%s\n%s\n' "$goal" "$fr" > "$tmp/repo/.superstack/plans/portal-m8.md"

out="$(run "$tmp/repo")"
check "ACTIVE plan: verbatim goal line reaches stdout"     "$goal" "$out"
check "ACTIVE plan: verbatim frontier line reaches stdout" "$fr" "$out"
check "the plan is named"                                  "portal-m8" "$out"
ck_exit "exit 0 with an ACTIVE plan" 0 "$(runec "$tmp/repo")"

# a pre-0.7 plan with no goal line still carries its frontier
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\n%s\n' "$fr" > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run "$tmp/repo")"
check "goal-less plan still carries the frontier" "$fr" "$out"
ck_exit "exit 0 on a goal-less plan" 0 "$(runec "$tmp/repo")"

# CLOSED plan: nothing to carry
printf -- '<!-- plan: portal-m8 status: CLOSED -->\nfrontier: done\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run "$tmp/repo")"
check "CLOSED plan is silent" '!portal-m8' "$out"
ck_exit "exit 0 on a CLOSED plan" 0 "$(runec "$tmp/repo")"

# no plans dir, no .superstack at all: silent, never blocking
rm -rf "$tmp/repo/.superstack/plans"
check "no plans dir is silent" '!plan' "$(run "$tmp/repo")"
ck_exit "exit 0 with no plans dir" 0 "$(runec "$tmp/repo")"
mkdir -p "$tmp/bare"
check "no .superstack is silent" '!plan' "$(run "$tmp/bare")"
ck_exit "exit 0 with no .superstack" 0 "$(runec "$tmp/bare")"

# garbage stdin must not block compaction
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\n%s\n%s\n' "$goal" "$fr" > /dev/null
ec="$(printf 'not json' | ( cd "$tmp/repo" && bash "$hook" ) >/dev/null 2>&1; echo $?)"
ck_exit "garbage stdin exits 0" 0 "$ec"

# T2 (THREAT-MODEL.md): a poisoned plan file gets no raw control bytes into
# the compaction channel, and no uncapped line — verbatim means the words,
# not the bytes. Clean lines under the cap are untouched (cases above).
mkdir -p "$tmp/repo/.superstack/plans"
esc="$(printf '\033')"
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\ngoal: clean words %s[2Jthen a screen-wipe escape and a\rcarriage return\n%s\n' "$esc" "$fr" > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run "$tmp/repo")"
check "control bytes are stripped from carried lines" "!${esc}" "$out"
check "carriage return is stripped too"               "!$(printf '\015')" "$out"
check "the words around the poison still carried"     "clean words" "$out"
ck_exit "exit 0 on a poisoned plan" 0 "$(runec "$tmp/repo")"

long="goal: $(printf 'x%.0s' $(seq 1 2000))"
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\n%s\n%s\n' "$long" "$fr" > "$tmp/repo/.superstack/plans/portal-m8.md"
gl="$(run "$tmp/repo" | grep '^goal:' | head -1)"
if [ "${#gl}" -le 620 ] && [ "${#gl}" -ge 100 ]; then pass=$((pass+1)); echo "PASS: oversized goal line is capped (${#gl} chars)"
else fail=$((fail+1)); echo "FAIL: oversized goal line not capped sanely (${#gl} chars)"; fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
