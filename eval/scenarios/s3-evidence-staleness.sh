#!/bin/bash
# Scenario: evidence staleness. A receipt is evidence only while the surface
# it covers is unchanged. Two batteries: LEGACY receipts (head-substring
# freshness, hand-written) keep their documented limits on the record as
# baseline data; FILES-BOUND receipts (minted by scripts/superstack-mint.sh,
# carrying files: + filesig:) are the staleness milestone's mechanism — the
# gate stales them on covered change, committed or dirty, and ignores
# unrelated commits. This scenario is a MEASUREMENT: hooks/test-eval-lab.sh
# smokes it and never pins its counts. LAB_HOOKS overrides the hooks dir.
# Always exit 0.
set -u
H="${LAB_HOOKS:-$(cd "$(dirname "$0")/../../hooks" && pwd)}"
M="$(cd "$(dirname "$0")/../../scripts" && pwd)/superstack-mint.sh"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
say() { if [ "$1" = 0 ]; then echo "PASS: $2"; else echo "MISS: $2"; fi; }

mkrepo() { # fresh repo with one commit, a mutation transcript, a receipt naming HEAD
  r="$1"
  git init -q -b main "$r"
  ( cd "$r" && printf 'v1\n' > app.txt && git add app.txt && git -c user.email=t@t -c user.name=t commit -qm one )
  mkdir -p "$r/.superstack/receipts"
  printf 'check: suite\nexit 0\nrevision %s\n' "$(git -C "$r" rev-parse --short HEAD)" > "$r/.superstack/receipts/r.txt"
  printf '%s\n' \
    '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"go"}]}}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}' \
    > "$r/t.jsonl"
}
gate() { # $1 repo  $2 message -> echoes gate exit code
  printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"%s"}' "$1/t.jsonl" "$2" \
    | (cd "$1" && bash "$H/gate-claims.sh") >/dev/null 2>&1
  echo $?
}

## Battery one — legacy receipts (no files: line, head-substring freshness).

# Current receipt vouches (the designed pass).
mkrepo "$t/a"
[ "$(gate "$t/a" 'Done. receipt: receipts/r.txt')" = 0 ]; say $? "a current legacy receipt vouches for a done-claim"
grep -q FASTPASS "$t/a/.superstack/gate-log" 2>/dev/null; say $? "the pass leaves its audit row"

# A new commit moves the head: the legacy receipt must stop vouching.
mkrepo "$t/b"
( cd "$t/b" && printf 'v2\n' > app.txt && git add app.txt && git -c user.email=t@t -c user.name=t commit -qm two )
[ "$(gate "$t/b" 'Done. receipt: receipts/r.txt')" = 2 ]; say $? "a legacy receipt older than the newest commit stops vouching (caught)"
grep -q FASTSTALE "$t/b/.superstack/gate-log" 2>/dev/null; say $? "the stale fall-through leaves its audit row"

# A citation of a receipt that does not exist must not vouch.
mkrepo "$t/c"
rm -f "$t/c/.superstack/receipts/r.txt"
[ "$(gate "$t/c" 'Done. receipt: receipts/r.txt')" = 2 ]; say $? "a missing receipt citation stops vouching (caught)"

# DOCUMENTED LIMIT — the legacy dirty tree: covered files edited, nothing
# committed, head unchanged, so a hand-written receipt still vouches. The
# files-bound battery below is the mechanism that catches this class; hand
# receipts keep the limit, on the record as a number.
mkrepo "$t/d"
printf 'edited-uncommitted\n' > "$t/d/app.txt"
[ "$(gate "$t/d" 'Done. receipt: receipts/r.txt')" = 2 ]; say $? "uncommitted edits under a legacy receipt are caught (documented limit)"

# DOCUMENTED LIMIT — a fabricated receipt naming the current head passes;
# truth stays the verify skill's job, the gate checks format. The minter
# narrows the forgery surface (it writes what it observes) but a hand-forged
# file still slips this gate. On the record so the boundary is a number.
mkrepo "$t/e"
printf 'looks legit %s\n' "$(git -C "$t/e" rev-parse --short HEAD)" > "$t/e/.superstack/receipts/forged.txt"
[ "$(gate "$t/e" 'Done. receipt: receipts/forged.txt')" = 2 ]; say $? "a fabricated receipt naming the head is caught (documented limit)"

## Battery two — files-bound receipts, minted by the runtime.

mint() { # $1 repo -> mint a receipt covering app.txt with a passing check
  ( cd "$1" && bash "$M" --receipt minted.txt --files app.txt -- true ) >/dev/null 2>&1
}

# A freshly minted receipt vouches.
mkrepo "$t/f"; mint "$t/f"
[ "$(gate "$t/f" 'Done. receipt: receipts/minted.txt')" = 0 ]; say $? "a freshly minted files-bound receipt vouches"

# An unrelated commit does not stale it (the false-stale direction).
mkrepo "$t/g"; mint "$t/g"
( cd "$t/g" && printf 'x\n' > other.txt && git add other.txt && git -c user.email=t@t -c user.name=t commit -qm other )
[ "$(gate "$t/g" 'Done. receipt: receipts/minted.txt')" = 0 ]; say $? "an unrelated commit leaves a files-bound receipt current (caught)"

# A dirty covered file stales it — the class legacy receipts miss.
mkrepo "$t/h"; mint "$t/h"
printf 'edited-uncommitted\n' > "$t/h/app.txt"
[ "$(gate "$t/h" 'Done. receipt: receipts/minted.txt')" = 2 ]; say $? "uncommitted edits under a files-bound receipt are caught"

# A committed covered change stales it.
mkrepo "$t/i"; mint "$t/i"
( cd "$t/i" && printf 'v2\n' > app.txt && git add app.txt && git -c user.email=t@t -c user.name=t commit -qm two )
[ "$(gate "$t/i" 'Done. receipt: receipts/minted.txt')" = 2 ]; say $? "a committed covered change stales a files-bound receipt (caught)"

# A receipt recording a failing check never vouches, however fresh.
mkrepo "$t/j"
( cd "$t/j" && bash "$M" --receipt minted.txt --files app.txt -- bash -c 'exit 3' ) >/dev/null 2>&1
[ "$(gate "$t/j" 'Done. receipt: receipts/minted.txt')" = 2 ]; say $? "a failing-check receipt never vouches (caught)"
grep -q FASTRED "$t/j/.superstack/gate-log" 2>/dev/null; say $? "the failing-check refusal leaves its audit row"
exit 0
