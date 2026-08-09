#!/bin/bash
# Self-checks for scripts/superstack-mint.sh — runtime-owned receipt minting
# (plan superstack-v2 M1; ruling D-66). The contract: the minter RUNS the
# named check itself and writes the receipt from what it observed (command,
# exit, output tail, revision, covered files, working-state signature), so
# receipt content is never prose from memory; a failing check is recorded
# honestly and the minter's own exit mirrors it; --files is mandatory (the
# binding is the point). The signature recipe must match the claims gate's —
# that pairing is pinned by an integration row in test-gate.sh, not here.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
mint="$here/../scripts/superstack-mint.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$mint" ] && ok "minter exists" || bad "minter exists (missing: $mint)"

r="$tmp/repo"
git init -q -b main "$r"
( cd "$r" && printf 'v1\n' > covered.txt && git add covered.txt && git -c user.email=t@t -c user.name=t commit -qm one )

( cd "$r" && bash "$mint" --receipt emitted-green --files covered.txt -- bash -c 'echo forty-two checks; true' ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "minter exits 0 when the check passes" || bad "minter exit on green check (rc=$rc)"
f="$r/.superstack/receipts/emitted-green"
[ -f "$f" ] && ok "receipt written under receipts/" || bad "receipt file missing"
grep -q '^command: ' "$f" 2>/dev/null && ok "receipt records the command" || bad "command line missing"
grep -q '^exit: 0' "$f" 2>/dev/null && ok "receipt records exit 0" || bad "exit line missing or wrong"
grep -q 'forty-two checks' "$f" 2>/dev/null && ok "receipt carries the output tail" || bad "output tail missing"
grep -q "^revision: $(git -C "$r" rev-parse --short HEAD)" "$f" 2>/dev/null && ok "receipt names the repo revision" || bad "revision line wrong"
grep -q '^files: covered.txt' "$f" 2>/dev/null && ok "receipt names its covered files" || bad "files line missing"
grep -qE '^filesig: [0-9]+' "$f" 2>/dev/null && ok "receipt carries the working-state signature" || bad "filesig missing"

( cd "$r" && bash "$mint" --receipt emitted-red --files covered.txt -- bash -c 'echo boom; exit 3' ) >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && ok "minter's own exit mirrors a failing check" || bad "minter exited 0 on a failing check"
grep -q '^exit: 3' "$r/.superstack/receipts/emitted-red" 2>/dev/null && ok "a failing check is recorded honestly" || bad "failing exit not recorded"

( cd "$r" && bash "$mint" --receipt emitted-nofiles -- true ) >/dev/null 2>&1
[ $? -ne 0 ] && [ ! -f "$r/.superstack/receipts/emitted-nofiles" ] \
  && ok "--files is mandatory (no binding, no mint)" || bad "minted without a files binding"

nr="$tmp/nogit"; mkdir -p "$nr"
( cd "$nr" && bash "$mint" --receipt emitted-ng --files x.txt -- true ) >/dev/null 2>&1
grep -q '^revision: none' "$nr/.superstack/receipts/emitted-ng" 2>/dev/null \
  && ok "no-git workspace records revision none, honestly" || bad "no-git revision handling wrong"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
