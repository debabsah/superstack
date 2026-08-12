#!/usr/bin/env bash
# superstack — Stop-hook look-step gate. The second, narrower Stop hook: a turn
# that CHANGED AN ARTIFACT WITH A FACE and ends on a calibrated claim whose
# evidence is all from the layer below gets asked to look at it.
#
# Rationale: DECISIONS.md D-8, dogfood/atrium-session-notes.md.
#
# Keep it a SEPARATE hook: gate-claims.sh is kernel-owned (KERNEL.md) and
# hooks.json is not, so merging this in would cost a kernel deviation.
#
# THE TWO STOP HOOKS NEVER BOTH BOUNCE. This one exits silently whenever the
# ledger is absent, which is exactly the condition gate-claims.sh fires on. That
# mutual exclusion is a correctness property, not a coincidence, and
# hooks/test-experiential.sh pins both halves of it.
#
# Fail-open everywhere, same bias as the claims gate: any parsing doubt exits 0.
# One bounce per turn (the loop guard), so a restated claim always gets through.
# TUNABLE (dogfooding): facere, lookre.
set +e

# The off switch (S4, PREREG.md §3): `off` silences every superstack gate and
# `claims` keeps only gate-claims.sh — this gate yields on both.
case "${SUPERSTACK_GATES:-all}" in off|claims) cat >/dev/null 2>&1; exit 0;; esac

payload="$(cat)"

# Loop guard — a continuation from this gate always passes.
printf '%s' "$payload" | grep -qE '"stop_hook_active" *: *true' && exit 0

last="$(printf '%s' "$payload" | grep -oE '"last_assistant_message": *"([^"\\]|\\.)*"' | head -n 1)"
[ -n "$last" ] || exit 0
last="$(printf '%s' "$last" | sed -E 's/^"last_assistant_message": *"//; s/"$//')"
# The field arrives JSON-encoded; a claim beginning its own line is the most
# common real shape, so decode before matching (the lesson gate-claims.sh
# learned at 0.7.0 — a literal \n put a word character in front of the text).
last="$(printf '%s' "$last" | sed -E 's/\\[nrt]/ /g; s/\\"/"/g')"

# Silent unless the claim is ALREADY calibrated. A turn with no ledger belongs
# to gate-claims.sh; speaking here too would double-bounce it.
printf '%s' "$last" | grep -qE '(Verified|Assumed): *[^ "]|PROVISIONAL' || exit 0

# Did THIS turn change something with a face? Judged only on structured tool
# inputs, so prose naming a filename cannot arm it. Accepted misses, priced:
# a face written by a shell redirect, and a face whose extension is not listed.
# Both are in the fail-open direction.
transcript="$(printf '%s' "$payload" | sed -n 's/.*"transcript_path": *"\([^"]*\)".*/\1/p')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
cut="$(grep -an '"type": *"user"' "$transcript" 2>/dev/null | grep -v 'tool_use_id' | grep -v '"isSidechain" *: *true' | tail -n 1 | cut -d: -f1)"
if [ -n "$cut" ]; then seg="$(tail -n +"$((cut + 1))" "$transcript")"; else seg="$(tail -n 600 "$transcript")"; fi

# Only MUTATING tool_use lines are scanned for a face (S1, PREREG.md §3) — the
# name class gate-claims.sh:204 anchors on. Extension alone proved nothing: a
# lone read-only Read of a stylesheet bounced a pure question-answering turn,
# because Read/Write/Edit all carry file_path and nothing here checked the
# tool name. Accepted false arm, priced: one line naming both a mutating tool
# and a face path (an Edit beside a Read in the same assistant message).
mutre='"name" *: *"(Edit|MultiEdit|Write|NotebookEdit|Task|Agent|mcp__[A-Za-z0-9_-]*(edit|replace|insert|write|rename|delete|create|move|send|save|publish|upload|merge|append|remove|destroy)[A-Za-z0-9_-]*)"'
facere='"file_path" *: *"[^"]*\.(html|htm|css|svg|tsx|jsx|vue|svelte)"'
hit="$(printf '%s\n' "$seg" | grep -E "$mutre" | grep -oE "$facere" | head -n 1)"
[ -n "$hit" ] || exit 0
ext="$(printf '%s' "$hit" | sed -E 's/.*\.([a-z]+)"$/\1/')"

# Shared root rule (hooks/superstack-root.sh); both bounce paths log into the
# same gate-log the claims gate writes, under markers the doctor's claims-gate
# greps cannot match — a look or face bounce must not inflate those tallies.
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root 2>/dev/null)"; [ -n "$root" ] || root="."
log="$root/.superstack/gate-log"
logline() {
  if [ -d "$root/.superstack" ]; then
    printf '%s %s %s snippet=%s\n' "$(date +%F)" "$1" "$2" "$(printf '%s' "$last" | cut -c1-120)" >> "$log"
    # Same bound the claims gate keeps, for the same reason: this hook appends
    # on every armed turn, so the writer owns the cap rather than a model habit.
    if [ "$(wc -l < "$log" 2>/dev/null || echo 0)" -gt 200 ]; then
      t="$(mktemp "$log.XXXXXX" 2>/dev/null)" && tail -n 200 "$log" > "$t" 2>/dev/null && mv "$t" "$log" || rm -f "$t"
    fi
  fi
}

# The face-receipt clause: with a face mutated this turn, a sheet [face] topic
# still open, or settled without its receipt line, bounces BEFORE look language
# is consulted — the receipt records the USER's reaction, which the model's own
# look cannot substitute. Grammar: superstack-inception's sheet block. Suite:
# hooks/test-face-receipt.sh.
badline=""
for tf in "$root"/.superstack/tasks/*.md; do
  [ -f "$tf" ] || continue
  badline="$(grep -E '^- T[0-9]+ \[face\].*status:open' "$tf" 2>/dev/null | head -n 1)"
  [ -n "$badline" ] && break
  settled="$(grep -E '^- T[0-9]+ \[face\].*status:(grounded|assumed)' "$tf" 2>/dev/null)"
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    tid="$(printf '%s' "$l" | grep -oE '^- T[0-9]+' | sed 's/^- //')"
    [ -n "$tid" ] || continue
    grep -qE "^- $tid receipt:" "$tf" 2>/dev/null || { badline="$l"; break; }
  done <<SETTLED
$settled
SETTLED
  [ -n "$badline" ] && break
done
if [ -n "$badline" ]; then
  tid="$(printf '%s' "$badline" | grep -oE 'T[0-9]+' | head -n 1)"
  logline "FACE-BOUNCE" "topic=$tid"
  cat >&2 <<MSG
Nothing is broken: superstack flagged this reply because a design choice is still waiting for your reaction; the model has been asked to fix it and continue. The instructions below are for the model.

superstack look-step gate: this turn built on a face while the sheet holds an unreacted face topic ($tid). A [face] topic settles only by the user reacting to a rendered artifact — the model looking is not the user reacting. Do ONE of these:
- Render the variants, get the user's reaction, append the receipt line to the task file (- $tid receipt: <artifact> — reaction: "<their words>") and flip the topic's status.
- If the user already reacted, append the receipt line that records it.
- If this build genuinely precedes shaping, say so and continue: the continuation passes, and the bounce is logged.
(Knob: SUPERSTACK_GATES=all|claims|off — claims or off silences this gate.)
MSG
  exit 2
fi

# Did anyone look? Deliberately GENEROUS — this is a new trigger with no track
# record, so every ambiguity resolves toward silence. Note what is NOT here:
# a bare "saw". The canonical ledger line is "ran <cmd> -> saw <result>", so
# "saw" is satisfied by "ran pytest -> saw 40 passed" — which IS the failure
# this gate exists to catch. The honest-downgrade phrases pass on purpose:
# labelling the gap costs one line and is a legal answer, exactly as
# Assumed:/PROVISIONAL are to the claims gate.
judge="$(printf '%s' "$last" | tr '[:upper:]' '[:lower:]')"
lookre='(screenshot|screen shot|in the browser|opened (the |a )?(page|browser|url|app|dashboard|file|report)|render(s|ed|ing)|viewport|clicked|on screen|looked at|look-step|headless|playwright|puppeteer|devtools|visually|not looked at|needs your eyes|not seen|unlooked)'
printf '%s' "$judge" | grep -qE "$lookre" && exit 0

logline "LOOK-BOUNCE" "ext=$ext"
cat >&2 <<MSG
Nothing is broken: superstack flagged this reply because it changed something with a visible face that nobody looked at; the model has been asked to fix it and continue. The instructions below are for the model.

superstack look-step gate: this turn changed an artifact with a face (.$ext) and every piece of evidence in it comes from the layer below. Do ONE of these:
- Enter the modality NOW — open the page, render the chart, run the CLI and read its output as its user would — then restate what you literally saw:
  Verified: <claim> — opened <what> -> saw <what was actually on screen>
- If you cannot look right now, label the gap instead of implying it away:
  Assumed: not looked at — <why> — <how the user can check it>
Green tests prove the layer below. The most consistent failure class on record is work that shipped green, reviewed, and never once seen.
(Knob: SUPERSTACK_GATES=all|claims|off — claims or off silences this gate.)
MSG
exit 2
