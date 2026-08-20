#!/usr/bin/env bash
# superstack — the status doctor. READ-ONLY: reports the health of this
# workspace's .superstack/ record (overlay, tasks, residuals, calibration logs)
# so the model-followed habits are checkable at a glance. Writes nothing.
# Run from anywhere in the project: bash scripts/superstack-status.sh
set +e

# .superstack/ resolves through the one shared rule (hooks/superstack-root.sh):
# the cwd's own record wins, else the git root's. The absolute path is printed
# below, because which record you are reading is the first thing to know.
. "$(dirname "$0")/../hooks/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$root" ]; then nogit=""; else root="$(pwd -P)"; nogit="  [no git root — this record is bound to this cwd; a session started elsewhere reads a different .superstack/]"; fi
f="$root/.superstack"

if [ ! -d "$f" ]; then
  echo "superstack-status: no .superstack/ here ($root) — the overlay bootstraps on first real work."
  exit 0
fi

echo "superstack-status — $root/.superstack$nogit"

# Degradation visibility (D-70): the silent-dark classes are REPORTED here,
# never left indistinguishable from health. Without jq the outward publish
# gate and the prompt front door both fail open — publishes go unswept and
# the workspace merely looks quiet. SUPERSTACK_JQ is the test seam (the
# LAB_HOOKS precedent). The off switch is reported when set in THIS
# environment, because a silenced gate looks identical to a passing one.
command -v "${SUPERSTACK_JQ:-jq}" >/dev/null 2>&1 || echo "degradation: jq MISSING — publishes go unswept (the outward gate fails open without it) and the prompt front door is quiet"
case "${SUPERSTACK_GATES:-}" in
  off|claims) echo "degradation: SUPERSTACK_GATES=${SUPERSTACK_GATES} in this environment (off silences every gate; claims keeps only the claims gate)";;
esac

# Overlay: pointer, oracle rows, stale rows (last-confirmed date > ~90 days old).
if [ -f "$f/project.md" ]; then
  pointer="$(sed -n 's/.*<!-- *pointer: *\(.*\) -->.*/\1/p' "$f/project.md" | head -n 1)"
  [ -n "$pointer" ] && echo "overlay: $pointer" || echo "overlay: present (no pointer line — add one; SessionStart surfaces it)"
  rows=$(grep -c '^|' "$f/project.md" 2>/dev/null)
  cutoff="$(date -v-90d +%F 2>/dev/null || date -d '90 days ago' +%F 2>/dev/null)"
  if [ -n "$cutoff" ]; then
    stale=$(grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$f/project.md" | awk -v c="$cutoff" '$0 < c' | wc -l | tr -d ' ')
    echo "overlay rows (incl. table headers): $rows; dates older than 90d: $stale (expiry rule: demote to working assumptions)"
  else
    echo "overlay rows (incl. table headers): $rows"
  fi
else
  echo "overlay: MISSING (dir exists, project.md does not)"
fi

# In-flight tasks and their staleness (same 7-day rule the SessionStart hook stamps).
tasks=0; stale_tasks=0
if [ -d "$f/tasks" ]; then
  for t in "$f/tasks"/*.md; do
    [ -f "$t" ] || continue
    tasks=$((tasks + 1))
    [ -n "$(find "$t" -mtime +7 2>/dev/null)" ] && stale_tasks=$((stale_tasks + 1))
  done
fi
echo "in-flight tasks: $tasks (untouched >7d: $stale_tasks)"

# Residuals: undischarged obligations. Count POSITIVELY against the residual
# grammar (project-template.md: one `- ` bullet per obligation) — not "any line
# with the words", which counted the file's own header (+1 forever, 0.6.1) and
# any prose mentioning a token. Same rule the gate-log tallies below follow.
# Keep this identical to hooks/inject-project-pointer.sh (R2: both callers).
if [ -f "$f/residuals.md" ]; then
  res=$(grep -cE '^[[:space:]]*[-*][[:space:]].*(Assumed:|PROVISIONAL)' "$f/residuals.md" 2>/dev/null)
else
  res=0
fi
echo "open residuals: $res"

# Gate log: both failure directions, so over- and under-firing are visible.
if [ -f "$f/gate-log" ]; then
  # Anchor on the log grammar (date + marker + phrase=), not bare substrings:
  # a snippet quoting "PASSED" must not count as an armed pass.
  bounces=$(grep -c ' BOUNCE phrase=' "$f/gate-log" 2>/dev/null)
  passes=$(grep -c ' PASS phrase=' "$f/gate-log" 2>/dev/null)
  lastb="$(grep ' BOUNCE phrase=' "$f/gate-log" | tail -n 1 | cut -c1-100)"
  echo "gate: $bounces bounces / $passes armed passes (the log self-rotates at 200 lines, so this is the recent window once it matures — not a lifetime total)"
  [ -n "$lastb" ] && echo "  last bounce: $lastb"
else
  echo "gate: no log yet (appears on the first armed pass or bounce in an overlay project)"
fi

# The run counters (D-81) outlive the log's rotation and exist before its
# first row, so they read out on their own, never under the log's branch.
runs=""
for g in claims look outward; do
  [ -f "$f/gate-runs.$g" ] && runs="$runs$(tr -d '\n' < "$f/gate-runs.$g" 2>/dev/null) "
done
runs="${runs% }"
[ -n "$runs" ] && echo "runs counted: $runs"

# Claims log: the trust record superstack-debug falsifies against. Read the archives
# too (`claims-log.<year>`, per superstack-ship) — a record that silently answers for
# this year only would read as "we have barely vouched for anything" every
# January, which is the trust question inverted. R2: every caller of the archive
# rule must know the archive exists.
set -- "$f"/claims-log "$f"/claims-log.*
logs=""; for c in "$@"; do [ -f "$c" ] && logs="$logs $c"; done
if [ -n "$logs" ]; then
  # Count POSITIVELY against the row grammar superstack-ship appends — `date ·
  # claim · evidence`. The Verified: token lives in reports, never in rows; a
  # token grep here reads 0 forever. A FALSIFIED row (superstack-debug's
  # marker) keeps its original text — count it once, as falsified.
  # shellcheck disable=SC2086
  claims=$(cat $logs 2>/dev/null | grep -E '^20[0-9]{2}-[0-9]{2}-[0-9]{2} · ' | grep -vc 'FALSIFIED')
  # shellcheck disable=SC2086
  falsified=$(cat $logs 2>/dev/null | grep -E '^20[0-9]{2}-[0-9]{2}-[0-9]{2} · ' | grep -c 'FALSIFIED')
  echo "claims: $claims shipped claim(s), $falsified falsified"
else
  echo "claims: no log yet (superstack-ship appends one row per shipped Verified: line)"
fi

# Everything below: the superstack-owned state files the kernel doctor
# predates (KERNEL.md deviation 12) — absent files stay silent, and every
# count grammar mirrors hooks/inject-superstack.sh (R2: two callers, one rule).
if [ -d "$f/tasks" ]; then
  for tf in "$f/tasks"/*.md; do
    [ -f "$tf" ] || continue
    grep -q '^## sheet' "$tf" 2>/dev/null || continue
    slug="$(basename "$tf" .md)"
    # Topic DEFINITION lines only — receipt: and revisit: lines legally share
    # a topic's id and must never count as duplicates.
    defs="$(grep -E '^- T[0-9]+ ' "$tf" 2>/dev/null | grep -vE '^- T[0-9]+ (receipt|revisit):')"
    tn="$(printf '%s\n' "$defs" | grep -c '^- T')"
    opn="$(printf '%s\n' "$defs" | grep -c 'status:open')"
    dup="$(printf '%s\n' "$defs" | grep -oE '^- T[0-9]+' | sort | uniq -d | sed 's/^- //' | tr '\n' ' ' | sed 's/ $//')"
    echo "sheet: $slug — $tn topic(s), $opn open${dup:+ — DUPLICATE topic id(s): $dup}"
  done
fi

if [ -d "$f/plans" ]; then
  for pf in "$f/plans"/*.md; do
    [ -f "$pf" ] || continue
    l1="$(head -1 "$pf" 2>/dev/null)"
    # A plan whose line 1 fails the grammar is invisible to every continuity
    # carrier (session voice, pre-compact, this doctor's ACTIVE loop) — a
    # present-but-dark campaign, indistinguishable from absent everywhere
    # but here (D-70; the Q40 class). Report it, never skip it.
    if ! printf '%s' "$l1" | grep -q '<!-- *plan:.*status:'; then
      echo "plan: $(basename "$pf") UNPARSEABLE line 1 — the continuity carriers skip it (ambient-dark); expected: <!-- plan: <slug> status: ... -->"
      continue
    fi
    printf '%s' "$l1" | grep -q 'status: ACTIVE' || continue
    slug="$(printf '%s' "$l1" | sed -n 's/.*plan: \([a-z0-9-]*\).*/\1/p')"
    fr="$(grep -m1 '^frontier:' "$pf" 2>/dev/null | cut -c1-120 | tr -d '[:cntrl:]')"
    echo "plan: ${slug:-unnamed} ACTIVE — ${fr:-no frontier stamp}"
  done
fi

if [ -f "$f/doctrine.md" ]; then
  ds=$(grep -c '^## ' "$f/doctrine.md" 2>/dev/null)
  echo "doctrine: $ds statute(s)"
fi

if [ -f "$f/queue.md" ]; then
  # Open = no closure annotation; [resolved and [reshaped are closures too, or
  # both the count and the oldest date point at finished work. Oldest = first
  # open entry (append order).
  openq="$(grep '^- Q' "$f/queue.md" 2>/dev/null | grep -v '\[taken\|\[dropped\|\[retired\|\[resolved\|\[reshaped')"
  if [ -n "$openq" ]; then
    qn="$(printf '%s\n' "$openq" | grep -c '^- Q')"
    oldest="$(printf '%s\n' "$openq" | head -1 | sed -n 's/^- Q[0-9]* (\([0-9-]*\)).*/\1/p')"
    echo "queue: $qn open parked item(s) (oldest open: ${oldest:-undated — a queue row is missing its (YYYY-MM-DD)})"
  else
    echo "queue: 0 open parked item(s)"
  fi
fi

if [ -f "$f/value-log" ]; then
  vo=$(grep '^- V' "$f/value-log" 2>/dev/null | grep -vc '\[HELD\|\[MISSED')
  today="$(date +%Y-%m-%d)"
  due=$(grep '^- V' "$f/value-log" 2>/dev/null | grep -v '\[HELD\|\[MISSED' | sed -n 's/.*check by \([0-9-]*\).*/\1/p' | awk -v t="$today" '$0 != "" && $0 <= t' | wc -l | tr -d ' ')
  echo "value: $vo open prediction(s), ${due:-0} due"
fi

if [ -f "$f/toured.md" ]; then
  echo "toured: $(grep -c '^- ' "$f/toured.md" 2>/dev/null) tour(s) recorded"
fi

# Domain language (D-70): glossary only. An entry without an owner
# [ack: date] is a proposal; an [expires:] date in the past demotes one.
# Count grammar mirrors hooks/inject-superstack.sh (R2: two callers).
if [ -f "$f/domain.md" ]; then
  dtoday="$(date +%F)"
  dtot=$(grep -c '^- ' "$f/domain.md" 2>/dev/null)
  dprop=$(grep '^- ' "$f/domain.md" 2>/dev/null | grep -vc '\[ack: ')
  dexp=$(grep '^- ' "$f/domain.md" 2>/dev/null | grep '\[ack: ' | sed -n 's/.*\[expires: *\([0-9-]*\)\].*/\1/p' | awk -v t="$dtoday" '$0 != "" && $0 <= t' | wc -l | tr -d ' ')
  dack=$((dtot - dprop - dexp))
  echo "domain: $dack term(s) ack'd, $dprop proposal(s), $dexp expired (glossary only — unacked entries are proposals, never house language)"
fi

# Review yield (D-70): one row per review panel; the record that shows
# whether a review configuration earns its cost.
if [ -f "$f/review-yield" ]; then
  ry=$(grep -cE '^20[0-9]{2}-[0-9]{2}-[0-9]{2} · ' "$f/review-yield" 2>/dev/null)
  echo "review-yield: $ry row(s) (a configuration whose rows stay at zero findings is the recorded shrink signal)"
fi

if [ -f "$f/skipped-gates.md" ]; then
  gn=$(grep -c '^- G' "$f/skipped-gates.md" 2>/dev/null) || gn=0
  gc=$(grep -c '^- G.*\[closed' "$f/skipped-gates.md" 2>/dev/null) || gc=0
  echo "skipped gates: $((gn - gc)) open of $gn"
fi

if [ -f "$f/outward-log" ]; then
  ob=$(grep -cE ' BOUNCE( |-t3 )' "$f/outward-log" 2>/dev/null)
  op=$(grep -c ' PASS' "$f/outward-log" 2>/dev/null)
  last="$(tail -1 "$f/outward-pass" 2>/dev/null | cut -c1-80)"
  echo "outward: $ob bounce(s) / $op pass(es)${last:+ — last sweep: $last}"
fi

if [ -d "$f/receipts" ]; then
  rn=$(find "$f/receipts" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "receipts: $rn file(s) (emitted/attested, plus load and delegation logs)"
fi

# Goal drift (D-74 M6): the quiet count the SessionStart check maintains.
if [ -f "$f/drift-state" ]; then
  dq="$(sed -n 's/^quiet: //p' "$f/drift-state" 2>/dev/null)"; case "$dq" in ''|*[!0-9]*) dq=0;; esac
  [ "$dq" -ge 1 ] && echo "drift: frontier unchanged across $dq active session start(s) while the work moved (the voice warns at 2; camping resets)"
fi

# Per-module muting (D-74 M5): the muted set is visible here, and a
# protected-core name in the file is warned about rather than silently
# ignored — the injector skips it either way, but a user who muted the
# goal-carrier should learn why nothing changed.
if [ -f "$f/muted" ]; then
  mreal=""; mn=0
  for m in $(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$f/muted" 2>/dev/null | tr -d ' '); do
    case "$m" in
      superstack|superstack-execute|superstack-continuity)
        echo "muted: protected and ignored: $m (the kernel, execute, and continuity carry the four ideas and cannot be muted)";;
      *) mn=$((mn+1)); mreal="${mreal:+$mreal, }$m";;
    esac
  done
  [ "$mn" -gt 0 ] && echo "muted: $mn module(s) ($mreal) — voices quiet, routing declined best-effort (.superstack/muted)"
fi

# Hook liveness (D-70): a workspace with real work whose record shows no
# hook line EVER is probably running without the hooks — a state invisible
# from inside a session, which is why the read-only doctor is the one to
# say it. Work evidence: a claims-log, a plan, or a task file. Hook
# evidence: any gate-log, outward-log, load receipt, or run counter (a
# growing counter proves the hooks fire even before a row lands). A fresh
# record has none of these and stays silent.
work=""
[ -f "$f/claims-log" ] && work=1
[ -z "$work" ] && [ -n "$(find "$f/plans" -name '*.md' 2>/dev/null | head -1)" ] && work=1
[ -z "$work" ] && [ -n "$(find "$f/tasks" -name '*.md' 2>/dev/null | head -1)" ] && work=1
hookseen=""
for g in claims look outward; do [ -f "$f/gate-runs.$g" ] && hookseen=1; done
if [ -n "$work" ] && [ -z "$hookseen" ] && [ ! -f "$f/gate-log" ] && [ ! -f "$f/outward-log" ] && [ ! -f "$f/receipts/loads.log" ]; then
  echo "degradation: no gate, outward, or load line has ever landed here — if sessions run in this workspace the hooks may not be firing (plugin off, or SUPERSTACK_GATES silencing them)"
fi
exit 0
