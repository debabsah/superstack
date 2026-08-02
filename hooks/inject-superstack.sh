#!/bin/bash
# superstack SessionStart — the ONE ambient voice. Composes, in order:
#   1. ACTIVE plan goal/frontier (execute module) — FIRST, undroppable
#   2. kernel overlay pointer (task lines split out and held for the tail)
#   3. standing doctrine line (inject-doctrine.sh)
#   4. continuity resume ritual line (resume/compact sources only)
#   5. open skipped-gates count (autonomy ledger), value-log, queue
#   6. in-flight task lines — LAST, first to go under pressure
# then enforces one total budget, so ambient context can never sprawl however
# many modules exist. The budget drops from the END, so compose order is
# survival order (S2, PREREG.md §3) — and a drop is disclosed, never silent.
# Wired as the single SessionStart entry in hooks.json.
# Fail-open everywhere: a broken part yields silence, never a blocked session.
# TUNABLE (dogfooding): LINE_BUDGET / CHAR_BUDGET.
set -u
LINE_BUDGET=8
CHAR_BUDGET=1600

here="$(cd "$(dirname "$0")" && pwd)"
# The one .superstack/ root rule, shared with every other hook and the doctor.
. "$here/superstack-root.sh" 2>/dev/null
payload="$(cat 2>/dev/null)" || payload=""
src="startup"
if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  s="$(printf '%s' "$payload" | jq -r '.source // empty' 2>/dev/null)" && [ -n "$s" ] && src="$s"
fi

root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="$PWD"

out=""
append() { [ -n "$1" ] && out="${out:+$out
}$1"; }

# ACTIVE plan (execute module): surface slug + goal + frontier, and make the
# module required reading the deterministic way rather than a remembered rule.
# Rationale: DECISIONS.md D-9. Composed FIRST because the goal is the one line
# a starved session cannot be without (F1: three task files silently ate it).
# Two constraints: absence is REPORTED, not blanked (missing must read
# differently from never-needed); and the goal is capped tighter than the
# frontier so it cannot push this line past the shared budget.
pd="$root/.superstack/plans"
if [ -d "$pd" ]; then
  for pf in "$pd"/*.md; do
    [ -f "$pf" ] || continue
    head -1 "$pf" 2>/dev/null | grep -q 'status: ACTIVE' || continue
    slug="$(head -1 "$pf" | sed -n 's/.*plan: \([a-z0-9-]*\).*/\1/p')"
    goal="$(grep -m1 '^goal:' "$pf" 2>/dev/null | sed -E 's/^goal: *//' | cut -c1-120 | tr -d '[:cntrl:]')"
    fr="$(grep -m1 '^frontier:' "$pf" 2>/dev/null | cut -c1-160 | tr -d '[:cntrl:]')"
    append "superstack execute: plan ${slug:-unnamed} ACTIVE — goal: ${goal:-not recorded — add a goal: line to the plan header} — ${fr:-frontier unknown} — superstack-execute is required reading before any build action."
    break
  done
fi

# Kernel pointer output, with the task lines SPLIT OUT and held for the tail
# (S2): under budget pressure they are the first to go — disclosed below —
# while the overlay pointer and residual count ride near the head.
ptr="$(bash "$here/inject-project-pointer.sh" 2>/dev/null)"
tasks="$(printf '%s\n' "$ptr" | grep -E '^superstack: (in-flight task |\+[0-9]+ more in-flight)')"
append "$(printf '%s\n' "$ptr" | grep -vE '^superstack: (in-flight task |\+[0-9]+ more in-flight)')"
append "$(bash "$here/inject-doctrine.sh" 2>/dev/null)"

# Estate seam (DECISIONS.md D-2): a co-installed godmode project with no
# overlay yet gets one orientation line, so the bootstrap offer is made with
# the ruling in hand instead of re-litigated per session.
if [ -d "$root/.godmode" ] && [ ! -f "$root/.superstack/project.md" ]; then
  append "superstack estate (D-2): .godmode coexists here — superstack owns durable project truth (oracle, gotchas, statutes; the thin overlay offer stands), godmode owns trial/plan frontier; point across the seam, never copy."
fi

case "$src" in
  resume|compact)
    append "superstack continuity: session resumed — before continuing, verify the ground truth (git status/log, the suite) and check any inherited HANDOFF/state-file claims against disk; inherited state is a claim, not evidence." ;;
esac

# Q10 backstop: the overlay's ignore rule must not depend on the model
# remembering the gateway's instruction. Untracked + unignored -> write the
# rule once and say so. A TRACKED .superstack stays the kernel warning's
# case — untracking needs git rm --cached, never a hook's call. Fail-open:
# an unwritable .gitignore yields silence.
if [ -d "$root/.superstack" ] && git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$root" ls-files --error-unmatch -- .superstack >/dev/null 2>&1 \
     && ! git -C "$root" check-ignore -q .superstack 2>/dev/null; then
    if printf '.superstack/\n' >> "$root/.gitignore" 2>/dev/null; then
      append "superstack: added .superstack/ to .gitignore — the overlay is per-machine and never committed."
    fi
  fi
fi

# Bootstrap line: fires when .superstack/ is ABSENT (D-12).
# Key the marker on the WORKING DIRECTORY, never $root: nested scratch dirs share
# a root, so root-keying lets one silence the rest of the repo.
# Marker stays outside the workspace. Silent where the estate-seam line fired.
if [ ! -d "$root/.superstack" ] && [ ! -d "$root/.godmode" ]; then
  seen="${TMPDIR:-/tmp}/superstack-seen-$(pwd -P 2>/dev/null | cksum | cut -d' ' -f1)"
  if [ ! -f "$seen" ]; then
    : > "$seen" 2>/dev/null
    append "superstack: no project overlay here yet — on non-trivial work, load the superstack skill and it will offer one (acceptance oracle, conventions, gotchas; git-ignored, per-machine). Shown once per workspace."
  fi
fi

sg="$root/.superstack/skipped-gates.md"
if [ -f "$sg" ]; then
  n="$(grep -c '^- G' "$sg" 2>/dev/null)" || n=0
  c="$(grep -c '^- G.*\[closed' "$sg" 2>/dev/null)" || c=0
  open=$(( n - c ))
  [ "$open" -gt 0 ] && append "superstack autonomy: $open open skipped gate(s) — close or re-authorize (.superstack/skipped-gates.md)."
fi

# value-log: open predictions whose check-by date has passed (ISO dates
# compare lexicographically; malformed lines simply never count — fail-open).
vl="$root/.superstack/value-log"
if [ -f "$vl" ]; then
  today="$(date +%Y-%m-%d)"
  due="$(grep '^- V' "$vl" 2>/dev/null | grep -v '\[HELD\|\[MISSED' | sed -n 's/.*check by \([0-9-]*\).*/\1/p' | awk -v t="$today" '$0 != "" && $0 <= t' | wc -l | tr -d ' ')"
  [ "${due:-0}" -gt 0 ] && append "superstack value: $due prediction(s) due — settle HELD/MISSED (.superstack/value-log)."
fi

# queue: open parked items; oldest = first open entry's date (append order).
qf="$root/.superstack/queue.md"
if [ -f "$qf" ]; then
  openq="$(grep '^- Q' "$qf" 2>/dev/null | grep -v '\[taken\|\[dropped\|\[retired')"
  if [ -n "$openq" ]; then
    qn="$(printf '%s\n' "$openq" | wc -l | tr -d ' ')"
    oldest="$(printf '%s\n' "$openq" | head -1 | sed -n 's/^- Q[0-9]* (\([0-9-]*\)).*/\1/p')"
    append "superstack queue: $qn parked item(s), oldest ${oldest:-unknown} — read before starting fresh work (.superstack/queue.md)."
  fi
fi

# Task lines land LAST (S2): the goal says what the work is FOR; where each
# piece stopped is the first thing the budget may take.
append "$tasks"

[ -n "$out" ] || exit 0
total="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
emit="$(printf '%s\n' "$out" | head -n "$LINE_BUDGET" | cut -c1-"$CHAR_BUDGET" | awk -v max="$CHAR_BUDGET" 'BEGIN{t=0} {t+=length($0)+1; if (t<=max) print}')"
kept="$(printf '%s\n' "$emit" | wc -l | tr -d ' ')"
if [ "$kept" -ge "$total" ]; then
  printf '%s\n' "$emit"
else
  # Withheld lines are DISCLOSED (S2): a silent drop reads as "nothing more",
  # which is exactly how the goal starved unnoticed. One line and ~100 chars
  # are re-reserved so the disclosure itself always fits the budget.
  emit="$(printf '%s\n' "$out" | head -n $((LINE_BUDGET - 1)) | cut -c1-"$CHAR_BUDGET" | awk -v max="$((CHAR_BUDGET - 100))" 'BEGIN{t=0} {t+=length($0)+1; if (t<=max) print}')"
  kept="$(printf '%s\n' "$emit" | wc -l | tr -d ' ')"
  printf '%s\n' "$emit"
  printf 'superstack: %s line(s) withheld (session budget) — read .superstack/ for the rest\n' "$((total - kept))"
fi
exit 0
