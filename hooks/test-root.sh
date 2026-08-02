#!/usr/bin/env bash
# Self-checks for the shared .superstack/ root rule (superstack-root.sh) and the
# six sites that resolve it. Rationale: DECISIONS.md D-6.
#
# THE INVARIANT: the directory the HOOKS READ is the directory the SKILL BODIES
# WRITE (skills write relative `.superstack/…` paths — i.e. the cwd).
#
# FIXTURES MUST NEST INSIDE A GIT REPO. 291 checks stayed green over this defect
# because every other suite builds its workspace with `mktemp -d`, which is never
# a repo: the git-root branch was never once exercised.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

check() { # desc expected actual
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "PASS: $1"
  else fail=$((fail+1)); echo "FAIL: $1 (expected '$2', got '$3')"; fi
}
# `git rev-parse --show-toplevel` reports the PHYSICAL path while a bare `pwd`
# reports the logical one, and on macOS $TMPDIR is /var -> /private/var. So the
# resolver's two branches must agree on form (it uses `pwd -P`) and so must these
# expectations — otherwise every check fails on path form rather than on
# behaviour, which is a red no fix can clear.
abs() { (cd "$1" 2>/dev/null && pwd -P); }

# ---------------------------------------------------------------- the resolver
. "$here/superstack-root.sh" 2>/dev/null || { echo "FAIL: superstack-root.sh not sourceable"; exit 1; }

git init -q -b main "$tmp/repo"
mkdir -p "$tmp/repo/sub/work/.superstack"     # nested workspace owning its record
mkdir -p "$tmp/repo/pkg/api"                  # monorepo subdir owning none
mkdir -p "$tmp/bare/.superstack"              # no git root at all

check "resolver: cwd's own .superstack wins over the git root" \
  "$(abs "$tmp/repo/sub/work")" "$(cd "$tmp/repo/sub/work" && superstack_root)"
check "resolver: subdir with no record falls back to the git root" \
  "$(abs "$tmp/repo")" "$(cd "$tmp/repo/pkg/api" && superstack_root)"
check "resolver: no git root at all binds to the cwd" \
  "$(abs "$tmp/bare")" "$(cd "$tmp/bare" && superstack_root)"
check "resolver: nothing anywhere still answers with the cwd" \
  "$(abs "$tmp")" "$(cd "$tmp" && superstack_root)"

# ------------------------------------------------------- SessionStart injection
printf '%s\n' '<!-- pointer: nested — oracle: make test -->' \
  > "$tmp/repo/sub/work/.superstack/project.md"
out="$(printf '{"source":"startup"}' | (cd "$tmp/repo/sub/work" && bash "$here/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'oracle: make test'
check "nested workspace: SessionStart surfaces the cwd's overlay pointer" 0 "$?"

# The ACTIVE-plan line is superstack-execute's whole deterministic mechanism.
mkdir -p "$tmp/repo/sub/work/.superstack/plans"
printf '%s\n' '<!-- plan: nested-campaign status: ACTIVE -->' 'frontier: m1 in-progress' \
  > "$tmp/repo/sub/work/.superstack/plans/p.md"
out="$(printf '{"source":"startup"}' | (cd "$tmp/repo/sub/work" && bash "$here/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'plan nested-campaign ACTIVE'
check "nested workspace: the ACTIVE-plan line fires" 0 "$?"

# Regression guard: the monorepo case the git-root rule existed to serve. Created
# only now, so every nested check above ran with NO record at the git root — the
# nested case must win on its own merits, not by the root's absence.
mkdir -p "$tmp/repo/.superstack"
printf '%s\n' '<!-- pointer: monorepo — oracle: cargo test -->' > "$tmp/repo/.superstack/project.md"
out="$(printf '{"source":"startup"}' | (cd "$tmp/repo/pkg/api" && bash "$here/inject-superstack.sh" 2>/dev/null))"
printf '%s' "$out" | grep -q 'oracle: cargo test'
check "monorepo subdir: still reads the repo-root overlay (no regression)" 0 "$?"

# ------------------------------------------------------------------- the gate
w="$tmp/repo/sub/work"
printf '%s\n' \
  '{"type":"user","message":{"role":"user","content":"go"}}' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}' \
  > "$w/t.jsonl"
printf '{"session_id":"t","transcript_path":"%s","stop_hook_active":false,"last_assistant_message":"All done."}' "$w/t.jsonl" \
  | (cd "$w" && bash "$here/gate-claims.sh") >/dev/null 2>&1
[ -f "$w/.superstack/gate-log" ]
check "nested workspace: gate-log is written to the cwd's record" 0 "$?"
[ -f "$tmp/repo/.superstack/gate-log" ]
check "nested workspace: gate-log does NOT leak to the git root" 1 "$?"

# ------------------------------------------------------------ the outward gate
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"git push origin main"},"cwd":"%s"}' "$w" \
  | bash "$here/outward-sweep.sh" 2>/dev/null; echo "exit=$?")"
[ -f "$w/.superstack/outward-log" ]
check "nested workspace: outward-log is written to the cwd's record" 0 "$?"

# ------------------------------------------------------------ the status doctor
out="$(cd "$w" && bash "$here/../scripts/superstack-status.sh" 2>/dev/null)"
printf '%s' "$out" | grep -qF "$(abs "$w")/.superstack"
check "nested workspace: the status doctor reports the cwd's record" 0 "$?"

# ------------------------------------------------------------------ fail-open
mkdir -p "$tmp/repo/empty"
out="$(printf '{"source":"startup"}' | (cd "$tmp/repo/empty" && bash "$here/inject-doctrine.sh" 2>/dev/null); echo "exit=$?")"
check "no record anywhere: doctrine hook is silent and exits 0" "exit=0" "$out"

echo
if [ "$fail" -eq 0 ]; then echo "all checks pass ($pass)"; exit 0
else echo "$fail check(s) FAILED ($pass passed)"; exit 1; fi
