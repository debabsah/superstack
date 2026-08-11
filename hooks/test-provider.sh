#!/bin/bash
# Self-checks for scripts/superstack-prove.sh — the evidence provider
# interface (plan adoption M7; ruling D-74). The contract: a provider row in
# .superstack/providers is the owner's ack of an external driver command;
# the script resolves the named row, substitutes {url}/{out}, and delegates
# the receipt write to scripts/superstack-mint.sh — one receipt writer, so
# the mint/gate signature pairing pinned in test-gate.sh covers these
# receipts unchanged. Refusals never mint; a failing driver is recorded
# honestly and its receipt never vouches at the gate.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
prove="$here/../scripts/superstack-prove.sh"
gate="$here/gate-claims.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$prove" ] && ok "prove script exists" || bad "prove script exists (missing: $prove)"

r="$tmp/repo"
git init -q -b main "$r"
( cd "$r" && printf '<html>hi</html>\n' > page.html && git add page.html && git -c user.email=t@t -c user.name=t commit -qm one )

# Refusal: no providers file — exit 65, grammar taught, nothing minted.
outp="$( cd "$r" && bash "$prove" --provider browser --url page.html --receipt emitted-p1 --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && ok "missing providers file refuses (65)" || bad "missing providers file rc=$rc"
printf '%s' "$outp" | grep -q 'command template' && ok "refusal teaches the row grammar" || bad "refusal message lacks the grammar"
[ ! -f "$r/.superstack/receipts/emitted-p1" ] && ok "refusal mints nothing" || bad "refusal minted a receipt"

# Refusal: file present, unknown name — a probe result is never a row.
mkdir -p "$r/.superstack"
printf '%s\n' '# rows' 'browser [open screenshot]: bash stub.sh "{url}" "{out}"' > "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider ci --url page.html --receipt emitted-p2 --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && printf '%s' "$outp" | grep -q "no row named 'ci'" \
  && ok "unknown provider name refuses and names it" || bad "unknown-name refusal wrong (rc=$rc)"
[ ! -f "$r/.superstack/receipts/emitted-p2" ] && ok "unknown-name refusal mints nothing" || bad "unknown name minted"

# Green stub driver: receipt minted through the one writer, files-bound.
cat > "$r/stub.sh" <<'EOS'
#!/bin/bash
echo "args=$#"
echo "url=$1"
[ -n "${2:-}" ] && printf 'shot\n' > "$2" 2>/dev/null
echo "rendered ok"
EOS
outp="$( cd "$r" && bash "$prove" --provider browser --url "a b.html" --receipt emitted-green --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 0 ] && ok "green stub run exits 0" || bad "green stub run rc=$rc"
printf '%s' "$outp" | grep -q 'caps: open screenshot' && ok "caps come from the row, never invented" || bad "caps line wrong"
f="$r/.superstack/receipts/emitted-green"
[ -f "$f" ] && ok "receipt written under receipts/" || bad "receipt missing"
grep -q '^exit: 0' "$f" 2>/dev/null && ok "receipt records exit 0" || bad "receipt exit wrong"
grep -q '^files: page.html' "$f" 2>/dev/null && ok "receipt is files-bound" || bad "files binding missing"
grep -q 'rendered ok' "$f" 2>/dev/null && ok "receipt carries the driver output tail" || bad "driver output missing"
grep -q 'args=2' "$f" 2>/dev/null && ok "quoted {url} with a space stays one argument" || bad "URL word-split"
# THE DEFAULT ARTIFACT MUST NOT LAND IN THE RECORD. The driver writes the
# artifact, so wherever it lands is caller-chosen bytes; inside receipts/
# the gate's cite class reaches them and honors them as evidence.
grep -q 'artifacts/emitted-green.png' "$f" 2>/dev/null && ok "the default artifact lands outside the record" || bad "default artifact path wrong"
[ -z "$(ls "$r/.superstack/receipts" 2>/dev/null | grep '\.png$')" ] \
  && ok "no driver-written file lands in the receipts directory" || bad "a driver wrote into the record"

# Gate fast path honors a prove-minted receipt end to end (recipe pairing
# itself is pinned in test-gate.sh; this row pins the delegation).
printf '{"session_id":"t","transcript_path":"%s/none.jsonl","stop_hook_active":false,"last_assistant_message":"Done. receipt: receipts/emitted-green"}' "$tmp" \
  | ( cd "$r" && bash "$gate" ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && grep -q 'FASTPASS' "$r/.superstack/gate-log" 2>/dev/null \
  && ok "gate fast path honors the prove-minted receipt" || bad "gate integration failed (rc=$rc)"

# Failing driver: honest receipt, mirrored exit, never vouches at the gate.
printf '%s\n' 'redbot [open]: bash redstub.sh "{url}"' >> "$r/.superstack/providers"
printf '%s\n' '#!/bin/bash' 'echo boom; exit 7' > "$r/redstub.sh"
outp="$( cd "$r" && bash "$prove" --provider redbot --url page.html --receipt emitted-red --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 7 ] && ok "prove's own exit mirrors the failing driver exactly (7)" || bad "failing driver exit not mirrored (rc=$rc)"
grep -q '^exit: 7' "$r/.superstack/receipts/emitted-red" 2>/dev/null && ok "failing driver recorded honestly" || bad "failing exit not recorded"
printf '{"session_id":"t","transcript_path":"%s/none.jsonl","stop_hook_active":false,"last_assistant_message":"Done. receipt: receipts/emitted-red"}' "$tmp" \
  | ( cd "$r" && bash "$gate" ) >/dev/null 2>&1
grep -q 'FASTRED' "$r/.superstack/gate-log" 2>/dev/null \
  && ok "a failing-driver receipt never vouches (FASTRED)" || bad "FASTRED row missing"

# Audit repairs (M7 cold audit findings 1, 3, 4): an empty template, an
# injectable {url}, and a metacharacter provider name must refuse or
# neutralize — a receipt may only ever vouch for the acked command.
printf '%s\n' 'empty:' >> "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider empty --url page.html --receipt emitted-p3 --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && printf '%s' "$outp" | grep -q 'empty command template' \
  && ok "a matched row with an empty template refuses" || bad "empty template drove (rc=$rc)"
[ ! -f "$r/.superstack/receipts/emitted-p3" ] && ok "empty-template refusal mints nothing" || bad "empty template minted"

outp="$( cd "$r" && bash "$prove" --provider browser --url '$(touch INJECTED; echo x)' --receipt emitted-inj --files page.html 2>&1 )"
[ ! -f "$r/INJECTED" ] && ok "a dollar command-substitution in --url stays inert" || bad "url injection executed"
grep -qF 'url=$(touch' "$r/.superstack/receipts/emitted-inj" 2>/dev/null \
  && ok "an injection-shaped url passes through as literal text" || bad "literal passthrough missing"

outp="$( cd "$r" && bash "$prove" --provider browser --url 'x"; touch QUOTE_PWNED; :"' --receipt emitted-inj2 --files page.html 2>&1 )"
[ ! -f "$r/QUOTE_PWNED" ] && ok "a double quote in --url cannot break the template quoting" || bad "quote injection executed via --url"
outp="$( cd "$r" && bash "$prove" --provider browser --url 'x OUT_PWNED' --receipt emitted-inj3 --files page.html 2>&1 )"
grep -q 'artifacts/emitted-inj3.png' "$r/.superstack/receipts/emitted-inj3" 2>/dev/null \
  && ok "the artifact path is computed from the receipt name, not from any value" || bad "artifact path not computed"
grep -q 'OUT_PWNED.*artifacts/emitted-inj3' "$r/.superstack/receipts/emitted-inj3" 2>/dev/null \
  && ok "a value cannot reach the artifact path even when it looks like one" || bad "caller text reached the artifact path"

outp="$( cd "$r" && bash "$prove" --provider '.*' --url page.html --receipt emitted-p4 --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "a metacharacter provider name refuses (64)" || bad "metacharacter name accepted (rc=$rc)"
[ ! -f "$r/.superstack/receipts/emitted-p4" ] && ok "metacharacter-name refusal mints nothing" || bad "metacharacter name minted"

printf '%s\n' 'plainrow: bash stub.sh "{url}"' >> "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider plainrow --url page.html --receipt emitted-p5 --files page.html 2>&1 )"
printf '%s' "$outp" | grep -q 'caps: undeclared' && ok "a row without brackets reports caps undeclared" || bad "undeclared caps wrong"

# Containment, asserted as the property rather than the mechanism (rounds
# three to five, where escaping and blacklists each failed by enumeration):
# a value is never parsed by a shell. The template is tokenized ONCE and
# the driver runs as an argument vector, so whatever quoting shape the row
# uses — single, double, bare, or a construct that would once have
# re-parsed — the value arrives as one literal argument. Every shape below
# carries the same lethal payload and none of them may execute it.
cat >> "$r/.superstack/providers" <<'EOS'
sq [open]: bash stub.sh '{url}'
nq [open]: bash stub.sh {url}
sqout [screenshot]: bash stub.sh "{url}" '{out}'
cmdsub [open]: bash stub.sh "$(echo {url})"
tick [open]: bash stub.sh "`echo {url}`"
brace [open]: bash stub.sh "${x:-{url}}"
arith [open]: bash stub.sh "$[{url}]"
bs [open]: bash stub.sh \{url}
fixedrow [test]: bash stub.sh fixed-argument
dollarvar [open]: bash stub.sh "$HOME{url}"
EOS
pay='a"; touch PWNED; :"$(touch PWNED)`touch PWNED`; touch PWNED'
for _row in sq nq sqout tick brace arith bs; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url "$pay" --receipt "emitted-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 0 ] && ok "the acked command runs whatever quoting shape the row uses ($_row)" || bad "$_row rc=$rc"
  grep -qF 'touch PWNED' "$r/.superstack/receipts/emitted-$_row" 2>/dev/null \
    && ok "the payload reached the driver as literal text ($_row)" || bad "$_row lost the literal value"
done
[ ! -f "$r/PWNED" ] && ok "no quoting shape let the payload execute" || bad "a payload executed as a command"

outp="$( cd "$r" && bash "$prove" --provider fixedrow --url page.html --receipt emitted-fixed --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 0 ] && ok "a row carrying no placeholder still runs (CI and test-runner rows)" || bad "placeholder-free row refused (rc=$rc)"

outp="$( cd "$r" && bash "$prove" --provider dollarvar --url page.html --receipt emitted-dv --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 0 ] && ok "a dollar in the template runs, no expansion and no ban" || bad "dollar-carrying row refused (rc=$rc)"
grep -qF 'url=$HOME' "$r/.superstack/receipts/emitted-dv" 2>/dev/null \
  && ok "the template itself is never shell-expanded" || bad "template expansion leaked"

# Tokenizing cannot make two shapes safe, so both refuse: a placeholder in
# the command word would let a value name the program, and a command word
# that re-parses its own arguments hands the value back to a parser.
printf '%s\n' '#!/bin/bash' 'touch CMDWORD_PWNED' > "$r/evil.sh"
cat >> "$r/.superstack/providers" <<'EOS'
cmdword [open]: "{url}" --headless
evalword [open]: eval bash stub.sh "{url}"
builtinword [open]: builtin eval bash stub.sh "{url}"
commandword [open]: command eval bash stub.sh "{url}"
midquote [open]: bash stub.sh "{url}
EOS
outp="$( cd "$r" && bash "$prove" --provider cmdword --url "bash evil.sh" --receipt emitted-cw --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && printf '%s' "$outp" | grep -q 'command word' \
  && ok "a placeholder in the command word refuses (65)" || bad "command-word placeholder ran (rc=$rc)"
[ ! -f "$r/CMDWORD_PWNED" ] && ok "a value can never name the program" || bad "the value named the program"
[ ! -f "$r/.superstack/receipts/emitted-cw" ] && ok "command-word refusal mints nothing" || bad "command-word row minted"

for _row in evalword builtinword commandword; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url 'a; touch EVAL_PWNED' --receipt "emitted-ev-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 65 ] && ok "a re-parsing command word refuses ($_row)" || bad "$_row ran (rc=$rc)"
done
[ ! -f "$r/EVAL_PWNED" ] && ok "no re-parsing spelling let the payload reach a shell" || bad "eval injection executed"

outp="$( cd "$r" && bash "$prove" --provider midquote --url page.html --receipt emitted-mq --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && ok "a template ending inside an open quote refuses" || bad "mid-quote template rc=$rc (a shell syntax error is not a receipt)"

# Receipt integrity through this path: a value carries into the receipt the
# minter writes, and the gate reads that file first-match-wins, so a value
# containing a newline would forge the freshness and binding fields beneath
# it — an eternally-vouching receipt for a surface it never covered. The
# writer owns the sanitizing; this row proves the reachable path.
forge="$(printf 'ok.html\nfiles: never-changes\nfilesig: 4294967295\nrevision: deadbeef')"
outp="$( cd "$r" && bash "$prove" --provider plainrow --url "$forge" --receipt emitted-forge --files page.html 2>&1 )"
f="$r/.superstack/receipts/emitted-forge"
[ "$(grep -c '^files: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in a value cannot forge a second files line" || bad "value newline forged the files binding"
[ "$(grep -c '^revision: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in a value cannot forge a second revision line" || bad "value newline forged the revision"
[ "$(grep -c '^filesig: ' "$f" 2>/dev/null)" -eq 1 ] && ok "a newline in a value cannot forge a second filesig line" || bad "value newline forged the signature"
grep -q '^files: page.html$' "$f" 2>/dev/null && ok "the binding recorded is the one the caller declared" || bad "declared binding lost"

# A value is data to the driver, and a value that begins with a dash would
# be read as one of the driver's own flags instead — subverting what the
# acked command does while the receipt still attests success.
outp="$( cd "$r" && bash "$prove" --provider plainrow --url '--version' --receipt emitted-flag --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "a flag-shaped value refuses (64)" || bad "flag-shaped value accepted (rc=$rc)"
[ ! -f "$r/.superstack/receipts/emitted-flag" ] && ok "flag-shaped refusal mints nothing" || bad "flag-shaped value minted"

# A caps bracket may carry a colon; the template starts after the row's own
# colon, not the first one in the line.
printf '%s\n' 'colon [a:b]: bash stub.sh "{url}"' >> "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider colon --url page.html --receipt emitted-colon --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$outp" | grep -q 'caps: a:b' \
  && ok "a colon inside the caps bracket does not cut the template" || bad "caps-bracket colon broke the row (rc=$rc)"

# THE ARTIFACT PATH IS NOT THE CALLER'S. Every finding from round nine to
# round thirteen was a path-guard defect and none was a containment defect:
# an --out into the record, through a symlinked leaf, through a symlinked
# directory, past the symlink-follow limit, in another case spelling,
# through the unguarded default, and finally through an unnormalized `..`
# that walked out of the one allowed subtree. Guarding a caller-chosen path
# means predicting where an external program's bytes land, across symlinks,
# hardlinks, case folding, non-existent prefixes and races. The product
# computes the path instead, from a receipt name already validated as a
# name, so there is nothing to resolve and nothing to short-circuit.
printf '%s\n' 'writer [screenshot]: bash stub.sh "{url}" "{out}"' >> "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --out "$r/anywhere.png" --receipt emitted-outgone --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "a caller-chosen artifact path is refused outright" || bad "--out still accepted (rc=$rc)"
[ ! -f "$r/anywhere.png" ] && ok "no caller-named artifact is written" || bad "a caller-named artifact appeared"
printf '%s' "$outp" | grep -q 'artifacts' && ok "the refusal says where artifacts do land" || bad "refusal does not name the artifact location"

# The traversal that defeated round twelve's guard has no path to travel:
# the receipt name is the only caller input to the artifact path, and it is
# validated as a name.
for _bad in "../../escape" ".superstack/receipts/x" "a/b"; do
  outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --receipt "$_bad" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 64 ] && ok "a receipt name that is a path refuses ($_bad)" || bad "path-shaped receipt name accepted ($_bad, rc=$rc)"
done
[ -z "$(find "$r" -name 'escape*' 2>/dev/null)" ] && ok "nothing escaped through a receipt name" || bad "a receipt name escaped the record"

# The artifact directory is the product's own; replaced by a link, the door
# it guards is already gone.
rm -rf "$r/.superstack/artifacts"; ln -s "$r/.superstack/receipts" "$r/.superstack/artifacts" 2>/dev/null
if [ -L "$r/.superstack/artifacts" ]; then
  ok "the symlink fixture landed (the probe is real)"
  outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --receipt emitted-artlink --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 64 ] && ok "an artifact directory replaced by a link refuses" || bad "linked artifact directory accepted (rc=$rc)"
  [ -z "$(ls "$r/.superstack/receipts" 2>/dev/null | grep 'artlink')" ] && ok "nothing landed in the record through the linked directory" || bad "the linked directory reached the record"
  rm -f "$r/.superstack/artifacts"
else
  # The attack needs a real symlink; a platform that cannot create one
  # cannot express the shape (the gate suite's standing skip pattern).
  # The two Unix CI runners keep these rows biting.
  rm -rf "$r/.superstack/artifacts"
  echo "SKIP: linked artifact directory x3 (platform cannot create symlinks)"
fi
mkdir -p "$r/.superstack/artifacts"

# THE LEAF RESOLVES TOO. The directory being a real directory says nothing
# about the name inside it: the kernel follows a link at open(), so a link
# or a hardlink planted at the computed path walks driver bytes into a
# receipt — planting a forged one, or destroying a genuine one under a name
# the caller never asked for.
mkdir -p "$r/.superstack/artifacts"
printf 'command: genuine\nexit: 0\n' > "$r/.superstack/receipts/emitted-victim"
ln -s "$r/.superstack/receipts/emitted-victim" "$r/.superstack/artifacts/emitted-hop.png" 2>/dev/null
outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --receipt emitted-hop --files page.html 2>&1 )"
grep -q '^command: genuine' "$r/.superstack/receipts/emitted-victim" 2>/dev/null \
  && ok "a symlink at the computed artifact path cannot reach a receipt" || bad "a receipt was written through the artifact leaf"
ln "$r/.superstack/receipts/emitted-victim" "$r/.superstack/artifacts/emitted-hard.png" 2>/dev/null
outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --receipt emitted-hard --files page.html 2>&1 )"
grep -q '^command: genuine' "$r/.superstack/receipts/emitted-victim" 2>/dev/null \
  && ok "a hardlink at the computed artifact path cannot reach a receipt" || bad "a receipt was overwritten through a hardlink"

# An artifacts path that is not a directory at all must refuse, rather than
# minting a receipt that names an artifact nothing wrote.
rm -rf "$r/.superstack/artifacts"; printf 'notadir\n' > "$r/.superstack/artifacts"
outp="$( cd "$r" && bash "$prove" --provider writer --url page.html --receipt emitted-notadir --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "an artifacts path that is not a directory refuses" || bad "non-directory artifacts path accepted (rc=$rc)"
rm -f "$r/.superstack/artifacts"; mkdir -p "$r/.superstack/artifacts"

# The receipt-name rule is THIS script's guarantee about the artifact path,
# so it is pinned here rather than borrowed from the writer: with a stub
# minter that accepts anything, prove's own check is the only one left.
mkdir -p "$tmp/lax/scripts" "$tmp/lax/hooks"
cp "$prove" "$tmp/lax/scripts/superstack-prove.sh"
cp "$here/superstack-root.sh" "$tmp/lax/hooks/superstack-root.sh"
printf '%s\n' '#!/bin/bash' 'echo lax-minter-ran' 'exit 0' > "$tmp/lax/scripts/superstack-mint.sh"
outp="$( cd "$r" && bash "$tmp/lax/scripts/superstack-prove.sh" --provider writer --url page.html --receipt '../../escape' --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "prove validates the receipt name itself, not by the writer's leave" || bad "prove passed a path-shaped receipt name to the writer (rc=$rc)"
printf '%s' "$outp" | grep -q 'lax-minter-ran' && bad "prove reached the writer with a path-shaped name" || ok "the writer was never reached with a path-shaped name"

# A wrapper is one word in front of the program slot, and the row's rule is
# that the row names the program. env, timeout and their family hand the
# next argument exactly that slot.
cat >> "$r/.superstack/providers" <<'EOS'
envprog [open]: env {url}
timeoutprog [open]: timeout 5 {url}
nohupprog [open]: nohup {url}
EOS
for _row in envprog timeoutprog nohupprog; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url "$r/evil.sh" --receipt "emitted-wrap-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 65 ] && ok "a value in the program slot behind a wrapper refuses ($_row)" || bad "$_row let a value name the program (rc=$rc)"
done
[ ! -f "$r/CMDWORD_PWNED" ] && ok "no wrapper row let the value run as the program" || bad "a wrapper row ran the value"

# The bare-value rule is for -c exactly. A flag cluster that merely
# contains a c is an ordinary flag at ordinary tools, and refusing those
# costs honest rows.
printf '%s\n' '#!/bin/bash' 'echo "argc=$#"' > "$r/echoer.sh"
cat >> "$r/.superstack/providers" <<'EOS'
noclobber [open]: bash echoer.sh -nc "{url}"
archive [open]: bash echoer.sh -avc "{url}"
EOS
for _row in noclobber archive; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url page.html --receipt "emitted-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 0 ] && ok "a plain value after an ordinary flag cluster still runs ($_row)" || bad "$_row over-refused (rc=$rc)"
done

# A receipt name is a name; one beginning with a dash is a flag to whatever
# reads it next.
outp="$( cd "$r" && bash "$prove" --provider plainrow --url page.html --receipt '-rf' --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "a dash-leading receipt name refuses" || bad "dash-leading receipt name accepted (rc=$rc)"

# The receipt names an artifact; when the driver wrote none, say so rather
# than leaving the reader to assume one is there.
printf '%s\n' 'noshot [screenshot]: bash echoer.sh "{url}"' >> "$r/.superstack/providers"
outp="$( cd "$r" && bash "$prove" --provider noshot --url page.html --receipt emitted-noshot --files page.html 2>&1 )"
printf '%s' "$outp" | grep -qi 'no artifact' && ok "a missing artifact is reported, not assumed" || bad "a missing artifact passed unmentioned"

# Every flag that takes a value must say so when it has none, not spin:
# shifting two positions past one argument shifts nothing.
for _f in --provider --url --receipt --files; do
  ( cd "$r" && bash "$prove" --provider plainrow "$_f" ) >/dev/null 2>&1 &
  _p=$!; ( sleep 5; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 &
  _k=$!; wait $_p 2>/dev/null; rc=$?; kill $_k 2>/dev/null
  [ "$rc" -eq 64 ] && ok "$_f with no value refuses instead of hanging" || bad "$_f valueless rc=$rc (137 means it hung)"
done

# Substitution is one pass: a value can never pull in another value.
outp="$( cd "$r" && bash "$prove" --provider plainrow --url '{out}' --receipt emitted-selfref --files page.html 2>&1 )"
grep -qF 'url={out}' "$r/.superstack/receipts/emitted-selfref" 2>/dev/null \
  && ok "a value naming a placeholder stays literal" || bad "a value pulled in another value"

# The command word is the owner's ack, and an acked interpreter does what
# interpreters do — so this catches the common footgun rather than pretending
# to be the boundary: the boundary is that the row is acked at all.
cat >> "$r/.superstack/providers" <<'EOS'
shellrow [open]: sh -c "echo {url}"
combflag [open]: bash -lc "echo {url} > /dev/null"
wrapped [open]: env bash -c "echo {url}"
pyrow [open]: python3 -c "print({url})"
longopt [open]: node --eval "console.log('{url}')"
attached [open]: perl -e'print "{url}"'
bareatt [open]: perl -eprint{url}
bareatt2 [open]: python3 -cprint{url}
barec [open]: bash -c {url}
barelc [open]: bash -lc {url}
EOS
for _row in shellrow combflag wrapped pyrow longopt attached bareatt bareatt2 barec barelc; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url 'x; touch SHELL_PWNED; echo y' --receipt "emitted-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 65 ] && ok "a placeholder handed to an interpreter as script text refuses ($_row)" || bad "$_row ran (rc=$rc)"
done
[ ! -f "$r/SHELL_PWNED" ] && ok "no interpreter row let the payload run" || bad "an interpreter row executed the payload"

# Refused for its punctuation, not for its command word: stub.sh is no
# interpreter, so this row is about the template's shape alone.
outp="$( cd "$r" && bash "$prove" --provider cmdsub --url page.html --receipt emitted-cmdsub --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 65 ] && ok "code punctuation around a placeholder refuses whatever the driver is" || bad "cmdsub ran (rc=$rc)"

# The catch must not refuse ordinary rows: a flag ending in c, e or r is
# also how tools take an environment variable, a referer, a recursion
# switch. A value that is a plain value is a plain value.
printf '%s\n' '#!/bin/bash' 'echo "argc=$#"' > "$r/echoer.sh"
cat >> "$r/.superstack/providers" <<'EOS'
envrow [test]: bash echoer.sh --rm -e URL={url}
referer [open]: bash echoer.sh -e "{url}"
recurse [open]: bash echoer.sh -r "{url}"
EOS
for _row in envrow referer recurse; do
  outp="$( cd "$r" && bash "$prove" --provider "$_row" --url page.html --receipt "emitted-$_row" --files page.html 2>&1 )"
  rc=$?
  [ "$rc" -eq 0 ] && ok "a plain value after a c/e/r flag still runs ($_row)" || bad "$_row over-refused (rc=$rc)"
done

# A receipt name is a name, never a path: the record is where receipts live
# and the gate looks them up by name, so a traversing name would write
# outside it and vouch nowhere.
outp="$( cd "$r" && bash "$prove" --provider plainrow --url page.html --receipt '../../../ESCAPED' --files page.html 2>&1 )"
rc=$?
[ "$rc" -eq 64 ] && ok "a traversing receipt name refuses (64)" || bad "traversing receipt name accepted (rc=$rc)"
[ -z "$(find "$tmp" -name 'ESCAPED' 2>/dev/null)" ] && ok "nothing is written outside the record" || bad "a receipt landed outside the record"

# Delegation tripwire (audit finding 2): prove must reach the minter, and
# no receipt may appear except the one the minter writes — the stub minter
# writes only its marker, so a receipt file here means a second writer.
mkdir -p "$tmp/iso/scripts" "$tmp/iso/hooks"
cp "$prove" "$tmp/iso/scripts/superstack-prove.sh"
cp "$here/superstack-root.sh" "$tmp/iso/hooks/superstack-root.sh"
printf '%s\n' '#!/bin/bash' 'echo tripwire > .superstack/mint-called' 'exit 0' > "$tmp/iso/scripts/superstack-mint.sh"
before="$(ls "$r/.superstack/receipts" 2>/dev/null | wc -l | tr -d ' ')"
( cd "$r" && bash "$tmp/iso/scripts/superstack-prove.sh" --provider browser --url page.html --receipt emitted-trip --files page.html ) >/dev/null 2>&1
[ -f "$r/.superstack/mint-called" ] && ok "receipt writing is delegated to the minter (tripwire)" || bad "prove bypassed the minter"
# Counted, not named: a second writer choosing any other filename was
# invisible while this asserted one exact name. The stub minter writes no
# receipt, so the count must not move at all.
after="$(ls "$r/.superstack/receipts" 2>/dev/null | wc -l | tr -d ' ')"
[ "$after" -eq "$before" ] \
  && ok "the minter is the only receipt writer (no receipt of any name appears)" || bad "a receipt appeared beside the minter's"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
