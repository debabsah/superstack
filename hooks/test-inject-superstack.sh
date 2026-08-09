#!/bin/bash
# Self-checks for inject-superstack.sh — the single consolidated SessionStart
# voice (kernel pointer/tasks + doctrine + continuity resume line + open
# skipped gates, under one budget). Temp repos; style of test-gate.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/inject-superstack.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

run() { # source_json_value -> stdout of hook from repo cwd
  printf '{"source":"%s"}' "$1" | ( cd "$tmp/repo" && bash "$hook" 2>/dev/null )
}
check() { # desc grep_pattern(or !pattern for absence) output
  desc="$1"; pat="$2"; out="$3"
  case "$pat" in
    '!'*) printf '%s' "$out" | grep -q "${pat#!}" && { fail=$((fail+1)); echo "FAIL: $desc"; } || { pass=$((pass+1)); echo "PASS: $desc"; } ;;
    *)    printf '%s' "$out" | grep -q "$pat" && { pass=$((pass+1)); echo "PASS: $desc"; } || { fail=$((fail+1)); echo "FAIL: $desc (got: $out)"; } ;;
  esac
}

git init -q -b main "$tmp/repo"; mkdir -p "$tmp/repo/.superstack"
printf '%s\n' '<!-- pointer: proj — oracle: make test -->' > "$tmp/repo/.superstack/project.md"
printf '# doctrine\n## 2026-07-28 — no module without its trigger\ntext\n' > "$tmp/repo/.superstack/doctrine.md"

# v0.7.2: the bootstrap line. A fresh workspace has no .superstack/, so every
# other line here is silent and superstack is invisible exactly where it must
# introduce itself. Fires ONCE per workspace; the marker lives outside it.
boot() { printf '{"source":"startup"}' | ( cd "$1" && bash "$hook" 2>/dev/null ); }

mkdir -p "$tmp/fresh"
check "fresh workspace gets the bootstrap line"      "no project overlay here yet" "$(boot "$tmp/fresh")"
check "bootstrap line fires only once per workspace" '!no project overlay here yet' "$(boot "$tmp/fresh")"

# Fixtures MUST include scratch dirs nested in a git repo: the standalone one
# above shares no root, so it cannot see root-keyed marker collisions.
git init -q -b main "$tmp/mono"
mkdir -p "$tmp/mono/scratch-a" "$tmp/mono/scratch-b"
check "nested scratch dir gets the line"             "no project overlay here yet" "$(boot "$tmp/mono/scratch-a")"
check "same nested dir stays silent after"           '!no project overlay here yet' "$(boot "$tmp/mono/scratch-a")"
check "a SIBLING dir in the same repo still gets it" "no project overlay here yet" "$(boot "$tmp/mono/scratch-b")"

out="$(run startup)"
check "startup carries the kernel pointer"          "oracle: make test" "$out"
check "a workspace WITH an overlay gets no bootstrap line" '!no project overlay here yet' "$out"
check "startup carries the doctrine line"           "1 standing statute" "$out"
check "startup has NO continuity resume line"       '!session resumed' "$out"

out="$(run resume)"
check "resume carries the continuity ritual line"   "session resumed" "$out"
check "resume ritual names inherited-state distrust" "against disk" "$out"
out="$(run compact)"
check "compact also carries the continuity line"    "session resumed" "$out"

# skipped-gates ledger surfacing
printf -- '- G1 (2026-07-28) push to origin — close: user runs git push\n- G2 (2026-07-28) prod migration — close: user approves [closed 2026-07-28]\n' > "$tmp/repo/.superstack/skipped-gates.md"
out="$(run startup)"
check "open skipped gate surfaces with count"       "1 open skipped gate" "$out"
check "closed gates are not counted"                '!2 open' "$out"

# budget: flood doctrine with statutes; total output stays capped
for i in $(seq 1 30); do printf '## 2026-07-2%d — statute number %d with a fairly long title padding padding\n' $((i%10)) "$i" >> "$tmp/repo/.superstack/doctrine.md"; done
out="$(run resume)"
lines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
[ "$lines" -le 8 ] && { pass=$((pass+1)); echo "PASS: line budget holds ($lines <= 8)"; } || { fail=$((fail+1)); echo "FAIL: line budget ($lines lines)"; }
chars="${#out}"
[ "$chars" -le 1600 ] && { pass=$((pass+1)); echo "PASS: char budget holds ($chars <= 1600)"; } || { fail=$((fail+1)); echo "FAIL: char budget ($chars chars)"; }


# v0.3: value-log due predictions and queue surfacing
printf -- '- V1 (2026-07-01) expected: signups rise - check by 2020-01-01 - from: launch\n- V2 (2026-07-01) expected: churn falls - check by 2099-01-01 - from: launch\n- V3 (2026-07-01) expected: x - check by 2020-01-01 - from: y [HELD 2026-07-20 - evidence]\n' > "$tmp/repo/.superstack/value-log"
out="$(run startup)"
check "one due open prediction surfaces"             "1 prediction(s) due" "$out"
check "future and settled predictions not counted"   '!2 prediction' "$out"
rm -f "$tmp/repo/.superstack/value-log"
printf -- '- Q1 (2026-06-15) go-link service - why: onboarding friction - revisit: after launch\n- Q2 (2026-07-01) dbt logbook v2 - why: demand signal - revisit: 2026-09-01\n- Q3 (2026-07-02) old idea - why: x - revisit: y [dropped 2026-07-10 - no demand]\n- Q4 (2026-07-03) done idea - why: x - revisit: y [resolved 2026-07-12 - shipped]\n- Q5 (2026-07-04) moved idea - why: x - revisit: y [reshaped 2026-07-13 - folded into Q2]\n' > "$tmp/repo/.superstack/queue.md"
out="$(run startup)"
check "open queue items surface with count"          "2 parked item" "$out"
check "queue line carries the oldest date"           "oldest 2026-06-15" "$out"
check "resolved queue items not counted"             '!3 parked' "$out"
printf -- '- Q4 (2026-07-05) retired old-dashboard - why: superseded - successor: new-dash [retired 2026-07-20]\n' >> "$tmp/repo/.superstack/queue.md"
out="$(run startup)"
check "retirement tombstones are born resolved"      "2 parked item" "$out"
check "tombstones never inflate the count"           '!3 parked' "$out"
rm -f "$tmp/repo/.superstack/queue.md"
out="$(run startup)"
check "absent value-log and queue are silent"        '!prediction' "$out"


# v0.3.1: co-installed estate seam line (D-2)
mkdir -p "$tmp/repo/.godmode"
mv "$tmp/repo/.superstack/project.md" "$tmp/repo/project.md.bak"
out="$(run startup)"
check "godmode present + no overlay -> seam line"    "superstack owns durable project truth" "$out"
mv "$tmp/repo/project.md.bak" "$tmp/repo/.superstack/project.md"
out="$(run startup)"
check "godmode present + overlay exists -> seam silent" '!durable project truth' "$out"
rm -rf "$tmp/repo/.godmode"
out="$(run startup)"
check "no godmode -> seam silent"                    '!durable project truth' "$out"


# v0.4: ACTIVE plan surfacing (execute module)
mkdir -p "$tmp/repo/.superstack/plans"
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\nfrontier: step-3 in-progress @ 2026-07-28 abc1234 opus-5\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run startup)"
check "ACTIVE plan surfaces with slug"               "plan portal-m8 ACTIVE" "$out"
check "ACTIVE plan line carries the frontier"        "step-3 in-progress" "$out"
check "ACTIVE plan names required reading"           "required reading" "$out"
# v0.7: the goal rides alongside the next action. Everything the session-start
# voice carried until now answered "where am I / what's next" and nothing
# answered "what for" — the owner's first-named requirement (INTENT.md 5.1).
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\ngoal: give the catalog a portal a stranger can navigate unaided\nfrontier: step-3 in-progress @ 2026-07-28 abc1234 opus-5\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run startup)"
check "ACTIVE plan line carries the goal"            "navigate unaided" "$out"
check "goal does not displace the frontier"          "step-3 in-progress" "$out"
# A plan written before 0.7 has no goal line and must still surface cleanly.
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\nfrontier: step-3 in-progress @ 2026-07-28 abc1234 opus-5\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run startup)"
check "pre-0.7 plan with no goal still surfaces"     "plan portal-m8 ACTIVE" "$out"
check "missing goal is named, not silently blank"    "goal: not recorded" "$out"

printf -- '<!-- plan: portal-m8 status: CLOSED -->\nfrontier: done\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
out="$(run startup)"
check "CLOSED plan is silent"                        '!portal-m8' "$out"
rm -rf "$tmp/repo/.superstack/plans"
out="$(run startup)"
check "no plans dir is silent"                       '!required reading' "$out"

# CHARACTERIZATION, not red-first: the kernel pointer hook prints everything
# between `task: ` and `-->`, so a goal in a task pointer already rides for free
# and these two passed before the grammar changed. They are here to pin that
# free ride — a kernel re-vendor that narrowed the pattern, or tightened
# clean()'s 220-char cap, would silently drop the anchor and no other check
# would notice. A goal at the far end of a realistic pointer is the case that
# would break first, so that is the fixture.
mkdir -p "$tmp/repo/.superstack/tasks"
printf -- '<!-- task: portal-shell — goal: a stranger can find any dashboard in two clicks — next: wire the sidebar -->\n' \
  > "$tmp/repo/.superstack/tasks/portal-shell.md"
out="$(run startup)"
check "task pointer carries the goal through the hook" "two clicks" "$out"
check "goal does not displace the next action"         "wire the sidebar" "$out"
rm -f "$tmp/repo/.superstack/tasks/portal-shell.md"

# v0.5: an open incident (00- prefix) survives the budget among many tasks
mkdir -p "$tmp/repo/.superstack/tasks"
for t in api-retry auth-refresh billing-export cache-warm dashboard-perf export-csv fix-login gc-tuning hydrate-cache index-audit jwt-rotate kafka-lag; do
  printf -- '<!-- task: %s — next: continue -->\n' "$t" > "$tmp/repo/.superstack/tasks/$t.md"
done
printf -- '<!-- task: 00-incident-payments-down — next: mitigate -->\n' > "$tmp/repo/.superstack/tasks/00-incident-payments-down.md"
out="$(run startup)"
check "00-incident sorts first and survives the budget" "00-incident-payments-down" "$out"
rm -rf "$tmp/repo/.superstack/tasks"

# S2 (PREREG.md §3): the goal line is undroppable. The budget drops from the
# END, so compose order is survival order: goal/frontier first, task lines
# last, tasks capped at 3 printing tasks/<basename>, and anything the budget
# drops is disclosed, never silent. F1: starvation began at 2-3 task files
# and goal/doctrine/continuity/queue were all gone by 5.
mkdir -p "$tmp/repo/.superstack/plans" "$tmp/repo/.superstack/tasks"
printf -- '<!-- plan: portal-m8 status: ACTIVE -->\ngoal: give the catalog a portal a stranger can navigate unaided\nfrontier: step-3 in-progress @ 2026-07-28 abc1234 opus-5\n' > "$tmp/repo/.superstack/plans/portal-m8.md"
for t in api-retry auth-refresh billing-export cache-warm dashboard-perf export-csv fix-login gc-tuning hydrate-cache index-audit jwt-rotate kafka-lag; do
  printf -- '<!-- task: %s — goal: keep %s healthy — next: continue -->\n' "$t" "$t" > "$tmp/repo/.superstack/tasks/$t.md"
done
out="$(run startup)"
check "goal survives a 12-task flood"               "navigate unaided" "$out"
printf '%s\n' "$out" | head -1 | grep -q 'plan portal-m8 ACTIVE' \
  && { pass=$((pass+1)); echo "PASS: goal/frontier line composes first"; } \
  || { fail=$((fail+1)); echo "FAIL: goal/frontier line composes first (got: $(printf '%s' "$out" | head -1))"; }
tn="$(printf '%s\n' "$out" | grep -c '^superstack: in-flight task')"
[ "$tn" -le 3 ] && { pass=$((pass+1)); echo "PASS: task lines capped at 3 ($tn shown)"; } \
  || { fail=$((fail+1)); echo "FAIL: task lines capped at 3 ($tn shown)"; }
check "task lines print tasks/<basename>"           "(tasks/api-retry.md)" "$out"
check "task lines never print the absolute path"    '!in-flight task (/' "$out"
# Overflow the line budget for real (plan + pointer + doctrine + skipped +
# value + queue + 3 tasks + the more-line = 9 lines against 8): the drop must
# be disclosed, and the goal line must still be the survivor at the head.
printf -- '- V9 (2026-07-01) expected: x - check by 2020-01-01 - from: y\n' > "$tmp/repo/.superstack/value-log"
printf -- '- Q9 (2026-06-15) parked idea - why: later - revisit: 2026-09-01\n' > "$tmp/repo/.superstack/queue.md"
out="$(run startup)"
check "withheld lines are disclosed, not silent"    "withheld" "$out"
check "goal still survives the overflowing compose" "navigate unaided" "$out"
rm -f "$tmp/repo/.superstack/value-log" "$tmp/repo/.superstack/queue.md"
rm -rf "$tmp/repo/.superstack/tasks" "$tmp/repo/.superstack/plans"

# fail-open: garbage stdin behaves as startup, kernel content still present
out="$(printf 'not json' | ( cd "$tmp/repo" && bash "$hook" 2>/dev/null ))"
check "garbage stdin fails open with kernel content" "oracle: make test" "$out"
check "garbage stdin adds no continuity line"        '!session resumed' "$out"

# Q10 backstop: an overlay in a git repo gets its ignore rule mechanically —
# untracked + unignored writes it once and says so; tracked stays the kernel
# warning's case (git rm --cached is never a hook's call); ignored is silent.
git init -q -b main "$tmp/q10"; mkdir -p "$tmp/q10/.superstack"
out="$(printf '{"source":"startup"}' | ( cd "$tmp/q10" && bash "$hook" 2>/dev/null ))"
check "unignored overlay: the hook says it wrote the rule" "added .superstack/ to .gitignore" "$out"
if grep -qx '\.superstack/' "$tmp/q10/.gitignore" 2>/dev/null; then pass=$((pass+1)); echo "PASS: .gitignore carries the rule"
else fail=$((fail+1)); echo "FAIL: .gitignore missing the rule"; fi
printf '{"source":"startup"}' | ( cd "$tmp/q10" && bash "$hook" >/dev/null 2>&1 )
if [ "$(grep -cx '\.superstack/' "$tmp/q10/.gitignore" 2>/dev/null)" = "1" ]; then pass=$((pass+1)); echo "PASS: rule written once, not per session"
else fail=$((fail+1)); echo "FAIL: rule duplicated on re-run"; fi

git init -q -b main "$tmp/q10t"; mkdir -p "$tmp/q10t/.superstack"
printf 'x\n' > "$tmp/q10t/.superstack/project.md"
( cd "$tmp/q10t" && git add .superstack >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm t >/dev/null 2>&1 )
printf '{"source":"startup"}' | ( cd "$tmp/q10t" && bash "$hook" >/dev/null 2>&1 )
if [ ! -f "$tmp/q10t/.gitignore" ]; then pass=$((pass+1)); echo "PASS: tracked overlay gets no ignore write"
else fail=$((fail+1)); echo "FAIL: hook wrote .gitignore over a tracked overlay"; fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
