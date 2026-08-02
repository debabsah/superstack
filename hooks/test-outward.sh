#!/bin/bash
# Self-checks for outward-sweep.sh — synthetic PreToolUse payloads, temp cwd
# so no live outward-log is polluted. Style matches hooks/test-gate.sh.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/outward-sweep.sh"
pass=0; fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q -b main repo && cd repo && mkdir .superstack

payload() { jq -n --arg t "$1" --arg c "$2" --arg d "$PWD" '{tool_name:$t, tool_input:{command:$c}, cwd:$d}'; }

check() { # desc expect_exit payload_json
  desc="$1"; want="$2"; pj="$3"
  printf '%s' "$pj" | bash "$hook" >/dev/null 2>"$tmp/err"; got=$?
  if [ "$got" -eq "$want" ]; then pass=$((pass+1)); echo "PASS: $desc"
  else fail=$((fail+1)); echo "FAIL: $desc (exit $got, wanted $want)"; fi
}

# -- blocking behavior ------------------------------------------------------
check "git push with no receipt bounces"            2 "$(payload Bash 'git push origin main')"
grep -q ' BOUNCE ' .superstack/outward-log || { fail=$((fail+1)); echo "FAIL: bounce not logged"; }
check "identical retry passes once (override)"      0 "$(payload Bash 'git push origin main')"
grep -q ' PASS-override ' .superstack/outward-log || { fail=$((fail+1)); echo "FAIL: override not logged"; }
check "a different publish command bounces on its own" 2 "$(payload Bash 'gh pr create --fill')"
check "npm publish bounces"                         2 "$(payload Bash 'npm publish')"
check "kubectl apply bounces"                       2 "$(payload Bash 'kubectl apply -f deploy.yml')"
check "gh pr merge bounces"                         2 "$(payload Bash 'gh pr merge 42 --squash')"

# -- S6 (PREREG.md §3): the publish verbs INTENT §10 step 2 names -----------
# Exactly these and no more; the read-only siblings pin the boundary.
check "gh repo create bounces"                      2 "$(payload Bash 'gh repo create me/proj --private --source=.')"
check "twine upload bounces"                        2 "$(payload Bash 'twine upload dist/*')"
check "poetry publish bounces"                      2 "$(payload Bash 'poetry publish --build')"
check "cargo publish bounces"                       2 "$(payload Bash 'cargo publish')"
check "uv publish bounces"                          2 "$(payload Bash 'uv publish')"
check "gh repo view is silent"                      0 "$(payload Bash 'gh repo view me/proj')"
check "twine check is silent"                       0 "$(payload Bash 'twine check dist/*')"
check "cargo build is silent"                       0 "$(payload Bash 'cargo build --release')"

# -- receipt behavior (S7, PREREG.md §3: content first, mtime second) -------
# The passing fixture is a REAL receipt in the skill's grammar (a findings
# line): a `touch`ed file passing was exactly the reproduced defect (F1 §7 —
# a receipt reading "SWEEP FAILED ... DO NOT PUBLISH" let a publish through).
printf '%s\n' '2026-07-31 17:00 swept: repo delta — findings: none' > .superstack/outward-pass
check "fresh well-formed receipt passes a new publish command" 0 "$(payload Bash 'docker push repo/img:1')"
grep -q ' PASS-receipt ' .superstack/outward-log || { fail=$((fail+1)); echo "FAIL: receipt pass not logged"; }
touch -t 202001010000 .superstack/outward-pass
check "stale receipt does not vouch (mtime still enforced)" 2 "$(payload Bash 'terraform apply')"
# ...and content refusals: empty/touched, SWEEP FAILED, symlinked, or no
# findings line never vouch, however fresh the mtime. Mtime alone never passes.
rm -f .superstack/outward-pass; touch .superstack/outward-pass
check "touched empty receipt does not vouch"        2 "$(payload Bash 'docker push repo/img:2')"
printf '%s\n' 'SWEEP FAILED: 14 live AWS keys found. DO NOT PUBLISH. — findings: 14' > .superstack/outward-pass
check "SWEEP FAILED receipt does not vouch"         2 "$(payload Bash 'docker push repo/img:3')"
printf '%s\n' '2026-07-31 17:00 swept: repo delta — findings: none' > "$tmp/elsewhere-pass"
ln -sf "$tmp/elsewhere-pass" .superstack/outward-pass
check "symlinked receipt does not vouch"            2 "$(payload Bash 'docker push repo/img:4')"
printf '%s\n' 'ran the sweep, all good' > .superstack/outward-pass
check "a receipt without a findings line does not vouch" 2 "$(payload Bash 'docker push repo/img:5')"
rm -f .superstack/outward-pass

# -- portability: the freshness stat must survive GNU stat -------------------
# GNU stat's -f is filesystem mode: it prints a status BLOCK to stdout for
# the file operand and exits nonzero on the stray format string, so a
# BSD-first fallback captures block-plus-epoch and the freshness arithmetic
# dies under set -u mid-path — one platform's bash exits 1 (blocking a swept
# publish), another exits 0 without ever logging. The mock must reproduce
# the stdout pollution, not merely fail (a fail-only mock cannot catch the
# capture bug), and the assertion requires BOTH the pass exit AND the
# logged receipt pass, because the silent-death shape fakes the exit alone.
mockdir="$tmp/gnustat"; mkdir -p "$mockdir"
cat > "$mockdir/stat" <<'MOCK'
#!/bin/sh
case "$1" in
  -c) [ "$2" = "%Y" ] || exit 1; date +%s; exit 0 ;;
  -f) echo "  File: \"$3\""; echo "    ID: 6864 Namelen: 255     Type: ext4"; exit 1 ;;
esac
exit 1
MOCK
chmod +x "$mockdir/stat"
printf '%s\n' '2026-07-31 17:00 swept: repo delta — findings: none' > .superstack/outward-pass
: > .superstack/outward-log
printf '%s' "$(payload Bash 'docker push repo/img:9')" | PATH="$mockdir:$PATH" bash "$hook" >/dev/null 2>"$tmp/err"; got=$?
if [ "$got" -eq 0 ] && grep -q ' PASS-receipt ' .superstack/outward-log 2>/dev/null; then
  pass=$((pass+1)); echo "PASS: receipt vouches and logs under GNU-shaped stat"
else
  fail=$((fail+1)); echo "FAIL: receipt vouches and logs under GNU-shaped stat (exit $got)"
fi
rm -f .superstack/outward-pass

# -- read-only siblings stay silent ----------------------------------------
check "gh pr checks is silent"                      0 "$(payload Bash 'gh pr checks 42')"
check "gh pr view is silent"                        0 "$(payload Bash 'gh pr view 42')"
check "terraform plan is silent"                    0 "$(payload Bash 'terraform plan')"
check "kubectl get is silent"                       0 "$(payload Bash 'kubectl get pods')"
check "npm view is silent"                          0 "$(payload Bash 'npm view superstack')"
check "git push --dry-run is silent"                0 "$(payload Bash 'git push --dry-run origin main')"
check "plain git commit is silent"                  0 "$(payload Bash 'git commit -m x')"
check "gitleaks-push-main string in a path is silent" 0 "$(payload Bash 'cat docs/git-pushing-guide.md')"

# -- fail-open and scope ----------------------------------------------------
check "non-Bash tool is silent"                     0 "$(jq -n '{tool_name:"Read", tool_input:{file_path:"/x"}, cwd:"'"$PWD"'"}')"
check "malformed payload fails open"                0 "not json at all"
check "empty payload fails open"                    0 ""
# accepted cost, pinned so a change is a conscious decision:
check "quoted verb in echo arms (one-bounce blast radius, documented)" 2 "$(payload Bash 'echo "git push is how you publish"')"

# -- S4 (PREREG.md §3): the off switch -------------------------------------
# `claims` keeps only the claims Stop gate, so this PreToolUse gate yields on
# both `claims` and `off`; unset/unknown stays armed.
check_env() { # env_val desc expect_exit payload_json
  ev="$1"; desc="$2"; want="$3"; pj="$4"
  printf '%s' "$pj" | SUPERSTACK_GATES="$ev" bash "$hook" >/dev/null 2>"$tmp/err"; got=$?
  if [ "$got" -eq "$want" ]; then pass=$((pass+1)); echo "PASS: $desc"
  else fail=$((fail+1)); echo "FAIL: $desc (exit $got, wanted $want)"; fi
}
check_env off    "SUPERSTACK_GATES=off silences the outward gate"    0 "$(payload Bash 'git push origin s4-off')"
check_env claims "SUPERSTACK_GATES=claims silences the outward gate" 0 "$(payload Bash 'git push origin s4-claims')"
check_env all    "SUPERSTACK_GATES=all keeps the outward gate"       2 "$(payload Bash 'git push origin s4-all')"

# -- no-overlay project still gates (state in tmp) --------------------------
cd "$tmp"; git init -q -b main bare-repo && cd bare-repo
check "no .superstack dir still bounces (tmp state)" 2 "$(payload Bash 'git push origin main')"
check "and its identical retry passes"               0 "$(payload Bash 'git push origin main')"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
