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
grep -q '^files: covered.txt$' "$f" 2>/dev/null && ok "receipt names its covered files" || bad "files line missing"
grep -qE '^filesig: [0-9]+' "$f" 2>/dev/null && ok "receipt carries the working-state signature" || bad "filesig missing"

( cd "$r" && bash "$mint" --receipt emitted-red --files covered.txt -- bash -c 'echo boom; exit 3' ) >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && ok "minter's own exit mirrors a failing check" || bad "minter exited 0 on a failing check"
grep -q '^exit: 3' "$r/.superstack/receipts/emitted-red" 2>/dev/null && ok "a failing check is recorded honestly" || bad "failing exit not recorded"

( cd "$r" && bash "$mint" --receipt emitted-nofiles -- true ) >/dev/null 2>&1
[ $? -ne 0 ] && [ ! -f "$r/.superstack/receipts/emitted-nofiles" ] \
  && ok "--files is mandatory (no binding, no mint)" || bad "minted without a files binding"

# A receipt is a field-structured file the gate reads first-match-wins, so
# a newline inside any value the minter records would let the recorded text
# forge the fields beneath it — freshness, binding, exit. One line per
# field, whatever arrives.
( cd "$r" && bash "$mint" --receipt emitted-nl --files covered.txt -- echo "$(printf 'a\nrevision: forged\nfilesig: 0\nexit: 0')" ) >/dev/null 2>&1
f="$r/.superstack/receipts/emitted-nl"
[ "$(grep -c '^revision: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in the command cannot forge a second revision line" || bad "command newline forged the revision field"
[ "$(grep -c '^filesig: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in the command cannot forge a second filesig line" || bad "command newline forged the filesig field"
[ "$(grep -c '^exit: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in the command cannot forge a second exit line" || bad "command newline forged the exit field"

( cd "$r" && bash "$mint" --receipt emitted-nl2 --files "$(printf 'covered.txt\nfilesig: 4294967295')" -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-nl2" ] \
  && ok "a newline in the files binding refuses before it can forge anything" || bad "files newline minted (rc=$rc)"

# A binding that names nothing real vouches for nothing real: both writers
# reduce a path that does not exist to the signature of empty, which
# recomputes to empty forever, so the receipt never stales. The binding is
# the whole point, so it is checked where it is written.
( cd "$r" && bash "$mint" --receipt emitted-ghost --files "no/such/path.txt" -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-ghost" ] \
  && ok "a binding naming a path that does not exist refuses" || bad "ghost binding minted (rc=$rc)"
( cd "$r" && bash "$mint" --receipt emitted-ws --files " " -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-ws" ] \
  && ok "a whitespace-only binding refuses (it reads as no binding at the gate)" || bad "whitespace binding minted (rc=$rc)"

# A glob is recorded as the paths it named at mint time, so deleting one of
# them shows up as a change; re-expanding at read time would hide it.
( cd "$r" && mkdir -p cov && printf 'a\n' > cov/a.txt && printf 'b\n' > cov/b.txt && git add cov && git -c user.email=t@t -c user.name=t commit -qm cov ) >/dev/null 2>&1
( cd "$r" && bash "$mint" --receipt emitted-glob --files 'cov/*' -- true ) >/dev/null 2>&1
grep -q '^files: cov/a.txt cov/b.txt$' "$r/.superstack/receipts/emitted-glob" 2>/dev/null \
  && ok "a glob binding records the concrete paths it covered" || bad "glob binding recorded unexpanded"

# EXISTENCE IS THE WRONG PREDICATE. The signature is computed by git, so a
# path git cannot see reduces to the signature of empty and recomputes
# equal forever — the eternal receipt again, now reached by binding an
# ignored file, an untracked one, a path outside the repo, or the same name
# in the wrong case on a case-insensitive filesystem.
( cd "$r" && printf 'ignored/\n' > .gitignore && mkdir -p ignored && printf 'i\n' > ignored/f.txt \
  && printf 'u\n' > untracked.txt && git add .gitignore && git -c user.email=t@t -c user.name=t commit -qm ign ) >/dev/null 2>&1
for _b in "ignored/f.txt" "untracked.txt" "/etc/hosts" "COVERED.TXT"; do
  ( cd "$r" && bash "$mint" --receipt emitted-blind --files "$_b" -- true ) >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-blind" ] \
    && ok "a binding git cannot see refuses ($_b)" || bad "binding '$_b' minted (rc=$rc)"
done

# The signature must MEAN something: dirtying a covered file must move it.
( cd "$r" && bash "$mint" --receipt emitted-sig1 --files covered.txt -- true ) >/dev/null 2>&1
s1="$(sed -n 's/^filesig: //p' "$r/.superstack/receipts/emitted-sig1" 2>/dev/null)"
( cd "$r" && printf 'dirty\n' >> covered.txt && bash "$mint" --receipt emitted-sig2 --files covered.txt -- true ) >/dev/null 2>&1
s2="$(sed -n 's/^filesig: //p' "$r/.superstack/receipts/emitted-sig2" 2>/dev/null)"
[ -n "$s1" ] && [ -n "$s2" ] && [ "$s1" != "$s2" ] \
  && ok "the signature moves when a covered file changes" || bad "signature did not move ($s1 vs $s2)"
( cd "$r" && git checkout -- covered.txt ) >/dev/null 2>&1

# A receipt name must not clobber something that is not a receipt: the
# artifact of an earlier run shares the receipts directory.
printf 'PNGBYTES\n' > "$r/.superstack/receipts/emitted-artifact.png"
( cd "$r" && bash "$mint" --receipt emitted-artifact.png --files covered.txt -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && grep -q PNGBYTES "$r/.superstack/receipts/emitted-artifact.png" 2>/dev/null \
  && ok "a receipt name cannot clobber a file that is not a receipt" || bad "artifact overwritten by a receipt (rc=$rc)"

# A relative binding means the caller's own directory, never a same-named
# file at the root: the silent case is the dangerous one.
( cd "$r" && mkdir -p sub && printf 'root\n' > same.txt && printf 'sub\n' > sub/same.txt \
  && git add same.txt sub/same.txt && git -c user.email=t@t -c user.name=t commit -qm same ) >/dev/null 2>&1
( cd "$r/sub" && bash "$mint" --receipt emitted-sub --files same.txt -- true ) >/dev/null 2>&1
grep -q '^files: sub/same.txt$' "$r/.superstack/receipts/emitted-sub" 2>/dev/null \
  && ok "a relative binding resolves against the caller's directory" || bad "relative binding silently bound the root's file"

# The binding is ONE FIELD, re-split on whitespace by the signature recipe
# and again by the gate, so a covered path carrying a space is torn into
# fragments matching nothing — the eternal receipt again, and a glob
# delivers it without the caller ever typing a space.
( cd "$r" && mkdir -p shots && printf 'a\n' > 'shots/hero shot.txt' && printf 'b\n' > shots/plain.txt \
  && git add shots && git -c user.email=t@t -c user.name=t commit -qm shots ) >/dev/null 2>&1
( cd "$r" && bash "$mint" --receipt emitted-space --files 'shots/*' -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-space" ] \
  && ok "a covered path carrying whitespace refuses (the field cannot hold it)" || bad "whitespace path minted (rc=$rc)"

# Where git has been told to stop looking, a receipt must not keep vouching.
( cd "$r" && git update-index --assume-unchanged covered.txt ) >/dev/null 2>&1
( cd "$r" && bash "$mint" --receipt emitted-au --files covered.txt -- true ) >/dev/null 2>&1
rc=$?
( cd "$r" && git update-index --no-assume-unchanged covered.txt ) >/dev/null 2>&1
[ "$rc" -eq 64 ] && ok "a path git was told to stop watching refuses" || bad "assume-unchanged path minted (rc=$rc)"

# The signature is the tree the check SAW. A tree that moves under the run
# would otherwise be baked in as though the check had seen the new one.
( cd "$r" && bash "$mint" --receipt emitted-race --files covered.txt -- bash -c 'printf "moved\n" >> covered.txt' ) >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && [ ! -f "$r/.superstack/receipts/emitted-race" ] \
  && ok "a covered file moving during the run refuses instead of baking in the new tree" || bad "mid-run movement minted (rc=$rc)"
( cd "$r" && git checkout -- covered.txt ) >/dev/null 2>&1

# A recorded path is re-split AND re-globbed by two independent readers, so
# the field can only carry names that survive both. Allow a safe set rather
# than banning one more character each round: a glob metacharacter makes
# the binding a pattern, which can bind a file nobody named and can be made
# to match nothing later.
( cd "$r" && printf 'l\n' > 'lit[a]l.txt' && printf 'd\n' > decoy.txt && printf 'decoy.txt\n' >> .gitignore \
  && git add .gitignore && git -c user.email=t@t -c user.name=t commit -qm dec ) >/dev/null 2>&1
( cd "$r" && bash "$mint" --receipt emitted-glob2 --files 'lit[a]l.txt' -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-glob2" ] \
  && ok "a name carrying glob metacharacters refuses rather than binding something else" || bad "pattern name minted (rc=$rc)"
( cd "$r" && bash "$mint" --receipt emitted-glob3 --files 'dec*.txt' -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ ! -f "$r/.superstack/receipts/emitted-glob3" ] \
  && ok "a pattern resolving to something git cannot see refuses" || bad "ignored-decoy pattern minted (rc=$rc)"

# Movement includes a COMMIT: comparing dirty-state signatures alone reads
# clean-then-clean across one, so the receipt would name a revision the
# check never saw.
( cd "$r" && bash "$mint" --receipt emitted-commitrace --files covered.txt -- bash -c 'printf "mid\n" >> covered.txt; git add covered.txt; git -c user.email=t@t -c user.name=t commit -qm mid' ) >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && [ ! -f "$r/.superstack/receipts/emitted-commitrace" ] \
  && ok "a commit during the run refuses (the revision would not be the one checked)" || bad "mid-run commit minted (rc=$rc)"

# A receipt path that is a symlink writes wherever the link points; a
# dangling one slips the not-a-receipt guard because it does not exist.
mkdir -p "$r/.superstack/receipts"
ln -s "$r/escaped-receipt" "$r/.superstack/receipts/emitted-link" 2>/dev/null
if [ -L "$r/.superstack/receipts/emitted-link" ]; then
  ( cd "$r" && bash "$mint" --receipt emitted-link --files covered.txt -- true ) >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 64 ] && [ ! -e "$r/escaped-receipt" ] \
    && ok "a symlinked receipt path refuses instead of writing through it" || bad "wrote through a receipt symlink (rc=$rc)"
else
  # The attack needs a real symlink; a platform that cannot create one
  # (Git Bash without link privileges) cannot express the shape, and a row
  # that fails there fails over nothing. The two Unix CI runners keep it.
  rm -f "$r/.superstack/receipts/emitted-link"
  echo "SKIP: symlinked receipt path (platform cannot create symlinks)"
fi

( cd "$r" && bash "$mint" --receipt '../../ESCAPED' --files covered.txt -- true ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && [ -z "$(find "$tmp" -name 'ESCAPED' 2>/dev/null)" ] \
  && ok "the writer validates a receipt name as a name, like its caller" || bad "traversing receipt name written (rc=$rc)"

# The command runs BETWEEN the receipt-path checks and the write, so a run
# that plants a link at its own receipt path would redirect the write out
# of the record or onto a genuine receipt. The write must decide again.
printf 'command: genuine\nexit: 0\n' > "$r/.superstack/receipts/emitted-target"
( cd "$r" && bash "$mint" --receipt emitted-race2 --files covered.txt -- bash -c 'ln -sf "$PWD/.superstack/receipts/emitted-target" "$PWD/.superstack/receipts/emitted-race2"' ) >/dev/null 2>&1
grep -q '^command: genuine' "$r/.superstack/receipts/emitted-target" 2>/dev/null \
  && ok "a link planted during the run cannot redirect the write onto a receipt" || bad "the write followed a link planted mid-run"
( cd "$r" && bash "$mint" --receipt emitted-race3 --files covered.txt -- bash -c 'ln -sf "$PWD/escaped-mid" "$PWD/.superstack/receipts/emitted-race3"' ) >/dev/null 2>&1
[ ! -e "$r/escaped-mid" ] && ok "a link planted during the run cannot write outside the record" || bad "the write escaped the record mid-run"

# A WRITE THAT DID NOT LAND IS NOT A RECEIPT. Nothing here needs an
# adversary: a full disk, a quota or a read-only record all end with the
# writer announcing evidence that does not exist.
( cd "$r" && bash "$mint" --receipt emitted-blocked --files covered.txt -- bash -c 'mkdir -p .superstack/receipts/emitted-blocked' ) >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && ok "a write that cannot land fails loudly instead of announcing a receipt" || bad "the writer claimed a receipt it did not write (rc=$rc)"
outp="$( cd "$r" && bash "$mint" --receipt emitted-blocked2 --files covered.txt -- bash -c 'mkdir -p .superstack/receipts/emitted-blocked2' 2>&1 )"
printf '%s' "$outp" | grep -qi 'wrote' && bad "the writer printed 'wrote' for a write that did not land" || ok "no success line for a write that did not land"

# A record that cannot be written to is the ordinary case with no
# adversary in it: a full disk, a quota, a read-only checkout.
chmod a-w "$r/.superstack/receipts" 2>/dev/null
if touch "$r/.superstack/receipts/.probe-w" 2>/dev/null; then
  # The write bit did nothing (Windows ACLs): the read-only shape cannot
  # exist here and the three rows would fail over nothing. Unix CI keeps them.
  rm -f "$r/.superstack/receipts/.probe-w"
  chmod u+w "$r/.superstack/receipts" 2>/dev/null
  echo "SKIP: read-only record x3 (platform ignores directory write bits)"
else
  outp="$( cd "$r" && bash "$mint" --receipt emitted-ro --files covered.txt -- echo hello 2>&1 )"
  rc=$?
  chmod u+w "$r/.superstack/receipts" 2>/dev/null
  [ "$rc" -ne 0 ] && ok "an unwritable record fails loudly rather than reporting success" || bad "the writer reported success into an unwritable record (rc=$rc)"
  printf '%s' "$outp" | grep -qi 'wrote' && bad "the writer announced a receipt it could not install" || ok "no success line when the receipt could not be installed"
  [ ! -f "$r/.superstack/receipts/emitted-ro" ] && ok "no receipt exists after a failed install" || bad "a receipt appeared despite the failure"
fi

# The rename is what keeps a link from redirecting the write; without it a
# hardlink planted mid-run destroys a genuine receipt in place.
printf 'command: genuine\nexit: 0\n' > "$r/.superstack/receipts/emitted-hardvictim"
( cd "$r" && bash "$mint" --receipt emitted-hardrace --files covered.txt -- bash -c 'ln -f .superstack/receipts/emitted-hardvictim .superstack/receipts/emitted-hardrace 2>/dev/null || true' ) >/dev/null 2>&1
grep -q '^command: genuine' "$r/.superstack/receipts/emitted-hardvictim" 2>/dev/null \
  && ok "a hardlink planted mid-run cannot rewrite a receipt in place" || bad "a hardlink mid-run destroyed a receipt"

# The staging name lives outside the receipts directory: inside it, a
# leftover is a citable receipt name and the status doctor counts it.
( cd "$r" && bash "$mint" --receipt emitted-staged --files covered.txt -- true ) >/dev/null 2>&1
[ -z "$(ls "$r/.superstack/receipts" 2>/dev/null | grep minting)" ] \
  && ok "no staging file is left in the receipts directory" || bad "a staging file sits in the receipts directory"

# A FIFO at the receipt path blocks the reader forever; refusing beats
# hanging with no message.
mkfifo "$r/.superstack/receipts/emitted-fifo" 2>/dev/null
( cd "$r" && bash "$mint" --receipt emitted-fifo --files covered.txt -- true ) >/dev/null 2>&1 &
_p=$!; ( sleep 5; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 &
_k=$!; wait $_p 2>/dev/null; rc=$?; kill $_k 2>/dev/null
[ "$rc" -eq 64 ] && ok "a pipe at the receipt path refuses instead of hanging" || bad "FIFO receipt path rc=$rc (137 means it hung)"
rm -f "$r/.superstack/receipts/emitted-fifo"

# stdin comes from nowhere: a driver that reads it would otherwise wait on
# the caller's terminal with no receipt and no word about why.
# Feed the minter real input: with stdin redirected the driver must see
# end-of-file, and without it the driver would swallow the caller's input.
printf 'CALLER_INPUT\n' | ( cd "$r" && bash "$mint" --receipt emitted-stdin --files covered.txt -- bash -c 'read -t 2 x; echo "got=[$x]"' ) >/dev/null 2>&1
grep -q 'got=\[\]' "$r/.superstack/receipts/emitted-stdin" 2>/dev/null \
  && ok "a driver reading stdin gets end-of-file, never the caller's input" || bad "the driver read the caller's stdin"

# A receipt name that differs only by case is the SAME FILE here, so
# writing it destroys evidence under a name nobody asked for.
( cd "$r" && bash "$mint" --receipt emitted-victim --files covered.txt -- echo genuine ) >/dev/null 2>&1
( cd "$r" && bash "$mint" --receipt EMITTED-VICTIM --files covered.txt -- echo replacement ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 64 ] && grep -q 'genuine' "$r/.superstack/receipts/emitted-victim" 2>/dev/null \
  && ok "a receipt name colliding only by case refuses" || bad "a case-varied name clobbered a receipt (rc=$rc)"

# A flag with no value must say so, not spin.
( cd "$r" && bash "$mint" --receipt emitted-noval --files ) >/dev/null 2>&1 &
_p=$!; ( sleep 5; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 &
_k=$!; wait $_p 2>/dev/null; rc=$?; kill $_k 2>/dev/null
[ "$rc" -eq 64 ] && ok "a flag with no value refuses instead of hanging" || bad "valueless flag rc=$rc (137 means it hung)"

nr="$tmp/nogit"; mkdir -p "$nr"; : > "$nr/x.txt"
( cd "$nr" && bash "$mint" --receipt emitted-ng --files x.txt -- true ) >/dev/null 2>&1
rc=$?
grep -q '^revision: none' "$nr/.superstack/receipts/emitted-ng" 2>/dev/null \
  && ok "no-git workspace records revision none, honestly" || bad "no-git revision handling wrong"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
