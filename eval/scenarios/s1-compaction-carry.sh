#!/bin/bash
# Scenario: the compaction-carry chain. An ACTIVE plan's goal must survive a
# compaction end to end — the PreCompact hook carries it out, and the
# compact-source SessionStart carries it back in with the resume ritual armed.
# A shipped-behavior invariant: hooks/test-eval-lab.sh pins full marks here.
# LAB_HOOKS overrides the hooks dir under test (the drill's lever).
# Prints PASS:/MISS: per assertion; always exit 0 (measurement, not gate).
set -u
H="${LAB_HOOKS:-$(cd "$(dirname "$0")/../../hooks" && pwd)}"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
mkdir -p "$t/cfg"
git init -q -b main "$t/w"; mkdir -p "$t/w/.superstack/plans"
goal='goal: a stranger can find any dashboard in two clicks'
fr='frontier: M3 in-progress @ 2026-08-09 abc1234 model-x'
printf -- '<!-- plan: carry status: ACTIVE -->\n%s\n%s\n' "$goal" "$fr" > "$t/w/.superstack/plans/carry.md"
say() { if [ "$1" = 0 ]; then echo "PASS: $2"; else echo "MISS: $2"; fi; }

out1="$(printf '{"trigger":"auto"}' | (cd "$t/w" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/pre-compact.sh" 2>/dev/null))"
printf '%s' "$out1" | grep -qF "$goal"; say $? "pre-compact carries the goal verbatim"
printf '%s' "$out1" | grep -qF "$fr";   say $? "pre-compact carries the frontier verbatim"
printf '%s' "$out1" | grep -q 'carry these lines into the summary'; say $? "pre-compact instructs the summarizer"

out2="$(printf '{"source":"compact"}' | (cd "$t/w" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out2" | grep -q 'two clicks';       say $? "post-compaction session voice re-reads the goal from disk"
printf '%s' "$out2" | grep -q 'M3 in-progress';   say $? "post-compaction session voice carries the frontier"
printf '%s' "$out2" | grep -q 'required reading'; say $? "post-compaction session voice names the campaign runner"
printf '%s' "$out2" | grep -q 'inherited state is a claim'; say $? "the resume ritual is armed after compaction"
exit 0
