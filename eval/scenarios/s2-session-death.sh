#!/bin/bash
# Scenario: session death. A session that dies mid-step must leave the next
# session able to see, from disk alone: the torn signal (a frontier not
# camped), an intact camped frontier when the close was clean, the in-flight
# task with its next action, and the undischarged-obligation count. A
# shipped-behavior invariant: hooks/test-eval-lab.sh pins full marks here.
# LAB_HOOKS overrides the hooks dir under test. Always exit 0.
set -u
H="${LAB_HOOKS:-$(cd "$(dirname "$0")/../../hooks" && pwd)}"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
mkdir -p "$t/cfg"
say() { if [ "$1" = 0 ]; then echo "PASS: $2"; else echo "MISS: $2"; fi; }

# A hard kill mid-step: the frontier was never camped. The next session must
# be shown the in-progress state so the torn protocol can run.
git init -q -b main "$t/torn"; mkdir -p "$t/torn/.superstack/plans"
printf -- '<!-- plan: died status: ACTIVE -->\ngoal: ship the widget\nfrontier: M2 in-progress @ 2026-08-09 abc1234 model-x\n' > "$t/torn/.superstack/plans/died.md"
out="$(printf '{"source":"startup"}' | (cd "$t/torn" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'plan died ACTIVE';  say $? "a dead session's plan surfaces at the next start"
printf '%s' "$out" | grep -q 'M2 in-progress';    say $? "the torn signal (frontier not camped) is visible from disk"
printf '%s' "$out" | grep -q 'ship the widget';   say $? "the goal survives the death"

# A clean camp: the next session sees camped, not torn.
git init -q -b main "$t/camp"; mkdir -p "$t/camp/.superstack/plans"
printf -- '<!-- plan: rested status: ACTIVE -->\ngoal: ship the widget\nfrontier: M2 camped @ 2026-08-09 abc1234 model-x\n' > "$t/camp/.superstack/plans/rested.md"
out="$(printf '{"source":"startup"}' | (cd "$t/camp" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'M2 camped'; say $? "a clean camp reads as camped, never as torn"

# Death with a task open and obligations undischarged: both must surface.
git init -q -b main "$t/task"; mkdir -p "$t/task/.superstack/tasks"
printf -- '<!-- task: half-done — goal: the export works — next: wire the retry -->\n' > "$t/task/.superstack/tasks/half-done.md"
printf -- '# residuals\n- 2026-08-09 (2.0) Assumed: staging matches prod — unchecked — discharge: diff configs\n' > "$t/task/.superstack/residuals.md"
out="$(printf '{"source":"startup"}' | (cd "$t/task" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'wire the retry';           say $? "the in-flight task's next action survives the death"
printf '%s' "$out" | grep -q '1 undischarged residual';  say $? "undischarged obligations are counted at the next start"

# Resume source arms the ritual.
out="$(printf '{"source":"resume"}' | (cd "$t/task" && CLAUDE_CONFIG_DIR="$t/cfg" bash "$H/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'inherited state is a claim'; say $? "a resumed session is told to distrust inherited state"
exit 0
