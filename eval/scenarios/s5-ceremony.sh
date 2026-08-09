#!/bin/bash
# Scenario: ceremony. What the product costs a user per event, as numbers:
# the ambient session-start voice against its own coded budget, and hook
# latency on the paths that run every turn. INFO rows carry the raw numbers
# for the results record; PASS/MISS rows pin only the coded budget and a
# generous latency ceiling (CI machines vary; the ceiling flags order-of-
# magnitude regressions, not jitter). RUN_MODEL_ARMS=1 adds two real model
# calls measuring a trivial task bare vs with the ambient context prepended —
# kept off by default so the lab stays free. LAB_HOOKS overrides the hooks
# dir. Always exit 0.
set -u
H="${LAB_HOOKS:-$(cd "$(dirname "$0")/../../hooks" && pwd)}"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
mkdir -p "$t/cfg"
say() { if [ "$1" = 0 ]; then echo "PASS: $2"; else echo "MISS: $2"; fi; }

# A loaded-but-ordinary workspace: overlay, two statutes, one task, an ACTIVE
# plan, two parked items — the shape a real week produces.
git init -q -b main "$t/w"; mkdir -p "$t/w/.superstack/plans" "$t/w/.superstack/tasks"
printf -- '<!-- pointer: proj — oracle: make test -->\n' > "$t/w/.superstack/project.md"
printf '# doctrine\n## 2026-08-01 — rule one\ntext\n## 2026-08-02 — rule two\ntext\n' > "$t/w/.superstack/doctrine.md"
printf -- '<!-- task: t — goal: g — next: n -->\n' > "$t/w/.superstack/tasks/t.md"
printf -- '<!-- plan: p status: ACTIVE -->\ngoal: ship the widget\nfrontier: M1 camped @ 2026-08-09 abc1234 m\n' > "$t/w/.superstack/plans/p.md"
printf -- '- Q1 (2026-08-01) idea - why: x - revisit: later\n- Q2 (2026-08-02) idea - why: y - revisit: later\n' > "$t/w/.superstack/queue.md"

out="$(printf '{"source":"startup"}' | (cd "$t/w" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
lines="$(printf '%s\n' "$out" | grep -c .)"
chars="${#out}"
echo "INFO: ambient voice on a loaded workspace: $lines line(s), $chars chars (coded budget 8/1600)"
[ "$lines" -le 8 ] && [ "$chars" -le 1600 ]; say $? "the ambient voice honors its coded budget"

ms() { # median-ish latency of a command over 5 runs, whole milliseconds
  perl -MTime::HiRes=time -e '
    my @t; for (1..5) { my $s=time; system(@ARGV)==0 or 1; push @t,(time-$s)*1000; }
    @t=sort {$a<=>$b} @t; printf "%d", $t[2];' -- "$@"
}
pay='{"session_id":"t","transcript_path":"/nonexistent","stop_hook_active":false,"last_assistant_message":"Here is the analysis you asked for."}'
g="$(ms bash -c "printf '%s' '$pay' | (cd '$t/w' && bash '$H/gate-claims.sh') >/dev/null 2>&1")"
p="$(ms bash -c "printf '{\"trigger\":\"auto\"}' | (cd '$t/w' && bash '$H/pre-compact.sh') >/dev/null 2>&1")"
d="$(ms bash -c "printf '{\"prompt\":\"fix the failing test\",\"cwd\":\"$t/w\"}' | (cd '$t/w' && bash '$H/front-door.sh') >/dev/null 2>&1")"
echo "INFO: hook latency (median of 5): claims-gate no-claim path ${g}ms · pre-compact ${p}ms · front-door non-idea ${d}ms"
[ "$g" -lt 1000 ] && [ "$p" -lt 1000 ] && [ "$d" -lt 1000 ]; say $? "every-turn hook paths stay under the coarse 1s ceiling"

# Model arms: the marginal cost of the ambient context on a trivial task.
# Two arms today (bare, current product); the third arm is each future
# revision, which is the whole point of re-running this after a milestone.
if [ "${RUN_MODEL_ARMS:-0}" = 1 ] && command -v claude >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  task='Reply with only a one-line docstring for this function: def retry(fn, n): ...'
  ambient="$out"
  neutral="$(mktemp -d)"
  a="$(cd "$neutral" && claude -p --output-format json "$task" </dev/null 2>/dev/null)"
  b="$(cd "$neutral" && claude -p --output-format json "$ambient

$task" </dev/null 2>/dev/null)"
  for arm in a b; do
    j="$(eval "printf '%s' \"\$$arm\"")"
    it="$(printf '%s' "$j" | jq -r '.usage.input_tokens // "?"' 2>/dev/null)"
    ot="$(printf '%s' "$j" | jq -r '.usage.output_tokens // "?"' 2>/dev/null)"
    ms_="$(printf '%s' "$j" | jq -r '.duration_ms // "?"' 2>/dev/null)"
    cost="$(printf '%s' "$j" | jq -r '.total_cost_usd // "?"' 2>/dev/null)"
    name=bare; [ "$arm" = b ] && name=with-ambient
    echo "INFO: model arm $name: input=$it output=$ot duration=${ms_}ms cost=\$$cost"
  done
  rm -rf "$neutral"
else
  echo "INFO: model arms skipped (set RUN_MODEL_ARMS=1 with the claude CLI and jq present)"
fi
exit 0
