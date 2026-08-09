#!/bin/bash
# Self-checks for scripts/superstack-outside.sh — mock CLI, never a real one:
# CI machines carry no outside model, and a mock must reproduce the shape the
# wrapper consumes (argv + stdout), not just an exit code.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../scripts/superstack-outside.sh"
pass=0; fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

[ -f "$script" ] && ok "script exists" || bad "script exists (missing: $script)"

printf 'The artifact under review. MARKER-7f3a inside.\n' > "$tmp/artifact.md"

out="$(OUTSIDE_CLI= bash "$script" "$tmp/artifact.md" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "refuses when no CLI is named" || bad "refuses when no CLI is named (rc=0)"
printf '%s' "$out" | grep -qi "name collision" && ok "refusal teaches the collision trap" || bad "refusal teaches the collision trap (got: $out)"

out="$(OUTSIDE_CLI="$tmp/absent-tool" bash "$script" "$tmp/artifact.md" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "refuses a named-but-missing binary" || bad "refuses a named-but-missing binary (rc=0)"

mkdir -p "$tmp/bin"
cat > "$tmp/bin/mockvoice" <<MOCK
#!/bin/bash
pwd > "$tmp/mock-cwd"
printf '%s\n' "\$*" > "$tmp/mock-argv"
echo "I am mock-model-1 by mockcorp."
echo "Finding: the artifact overreaches."
MOCK
chmod +x "$tmp/bin/mockvoice"

out="$(OUTSIDE_CLI="$tmp/bin/mockvoice" bash "$script" "$tmp/artifact.md" "attack the claims" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "runs the named mock cleanly" || bad "runs the named mock (rc=$rc: $out)"
printf '%s' "$out" | grep -q "OUTSIDE VOICE" && ok "output carries the outside-voice header" || bad "output header missing"
printf '%s' "$out" | grep -qi "unverified claim" && ok "output stamps itself an unverified claim" || bad "unverified-claim stamp missing"
printf '%s' "$out" | grep -q "mock-model-1" && ok "the tool's self-identification is shown" || bad "self-identification missing"
grep -q "MARKER-7f3a" "$tmp/mock-argv" 2>/dev/null && ok "artifact content travels inline in the prompt" || bad "artifact content not in prompt"
grep -q "attack the claims" "$tmp/mock-argv" 2>/dev/null && ok "the question travels in the prompt" || bad "question not in prompt"
grep -qi "identify" "$tmp/mock-argv" 2>/dev/null && ok "prompt demands model self-identification" || bad "prompt lacks the self-identify demand"
mcwd="$(cat "$tmp/mock-cwd" 2>/dev/null)"
case "$mcwd" in
  "$here"*|"$(cd "$here/.." && pwd)"*) bad "mock ran inside the repo (cwd $mcwd)";;
  *) ok "mock ran from a scratch directory, not the repo";;
esac

out="$(OUTSIDE_CLI="$tmp/bin/mockvoice --flag subcmd" bash "$script" "$tmp/artifact.md" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "a multi-word OUTSIDE_CLI (command plus flags) runs" || bad "multi-word OUTSIDE_CLI refused (rc=$rc: $out)"
grep -q -- "--flag subcmd" "$tmp/mock-argv" 2>/dev/null && ok "the extra words reach the tool as arguments" || bad "extra words lost"

if command -v timeout >/dev/null 2>&1; then
  cat > "$tmp/bin/sleeper" <<'MOCK'
#!/bin/bash
sleep 30
MOCK
  chmod +x "$tmp/bin/sleeper"
  out="$(OUTSIDE_CLI="$tmp/bin/sleeper" OUTSIDE_TIMEOUT=2 bash "$script" "$tmp/artifact.md" 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] && ok "a hung tool is cut off at the timeout" || bad "timeout did not fire (rc=0)"
else
  ok "timeout branch untestable here (no timeout binary) — wrapper degrades to uncapped, disclosed in its output"
fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
