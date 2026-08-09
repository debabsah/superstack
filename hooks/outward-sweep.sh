#!/bin/bash
# superstack outward gate — PreToolUse hook on Bash.
# When a command PUBLISHES (push, PR create/merge, release, package publish,
# infra apply), require a fresh go-public sweep receipt (.superstack/outward-pass,
# written by the superstack-outward skill). No receipt -> block ONCE (exit 2,
# instructions on stderr); the same command retried passes (a trapped session
# is the worse failure — the sweep is the point, not the block).
#
# Judged ONLY on the structured tool_input.command value — prose can't arm it.
# Accepted cost: a command that merely *quotes* a publish verb (echo "git push")
# arms once; blast radius is one bounce. Fail-open on any parsing doubt.
# TUNABLE (dogfooding): receipt freshness ceiling 3600s — tune from .superstack/outward-log.
set -u

# The off switch (S4, PREREG.md §3): `off` silences every superstack gate and
# `claims` keeps only the claims Stop gate — this gate yields on both.
case "${SUPERSTACK_GATES:-all}" in off|claims) cat >/dev/null 2>&1; exit 0;; esac

payload="$(cat 2>/dev/null)" || exit 0
[ -n "$payload" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null)" || exit 0
[ "$tool" = "Bash" ] || exit 0
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

lc="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

# Rehearsals are how you check a publish, not make one.
case "$lc" in *--dry-run*) exit 0;; esac

# Publish verbs, word-anchored. Read-only siblings (gh pr checks/view,
# gh repo view, terraform plan, kubectl get/rollout, npm view, twine check,
# cargo build) do not match by construction. The second row is S6 (PREREG.md
# §3): INTENT §10 step 2's own list, no more than this.
#
# The flag gaps (D-68): `git -C <clone> push` rode past this gate at a real
# cut — the verb pair was anchored adjacent, so a flag between binary and
# verb matched nothing. The gaps admit git's -c-with-arg (the lowercase fold
# above makes -C the same shape) and long flags before push, and gh's
# -r-with-arg and long flags before its publish subcommands. Nothing else
# widens: a gap exists only where a bypass was verified, and the read-only
# siblings with the same gap (git -C pull/log, gh -R pr view, git stash
# push) are pinned silent in the suite.
ggap='( +-c +[^ ]+| +--[a-z][a-z0-9-]*(=[^ ]*)?)*'
hgap='( +-r +[^ ]+| +--[a-z][a-z0-9-]*(=[^ ]*)?)*'
armre="(^|[^a-z0-9_-])(git$ggap push|gh$hgap pr (create|merge)|gh$hgap release create|npm publish|docker push|terraform apply|kubectl apply|gh$hgap repo create|twine upload|(poetry|cargo|uv) publish)([^a-z0-9-]|\$)"
printf '%s' "$lc" | grep -Eq "$armre" || exit 0
verb="$(printf '%s' "$lc" | grep -Eo "$armre" | head -1 | sed 's/^[^a-z]*//; s/[^a-z]*$//')"

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
# The one .superstack/ root rule, resolved from the payload's cwd (this hook is
# the only one that gets the session's directory handed to it, so it passes it in
# rather than relying on the hook process's own).
. "$(dirname "$0")/superstack-root.sh" 2>/dev/null
root="$(superstack_root "$cwd" 2>/dev/null)"
[ -n "$root" ] || root="$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$root" ] || root="$cwd"

if [ -d "$root/.superstack" ]; then
  sdir="$root/.superstack"
else
  sdir="${TMPDIR:-/tmp}/superstack-outward-$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
  mkdir -p "$sdir" 2>/dev/null || exit 0
fi

now="$(date +%s)"
snip="$(printf '%s' "$cmd" | tr -d '[:cntrl:]' | cut -c1-80)"
log() { printf '%s %s verb=%s cmd=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" "$verb" "$snip" >> "$sdir/outward-log" 2>/dev/null; }

# Fresh sweep receipt -> pass. Content first, mtime second (S7, PREREG.md
# §3): a receipt vouches only if its newest line parses as a sweep result —
# the skill's grammar carries a `findings:` field — and is not a recorded
# failure. An empty/`touch`ed file, a symlink, or a SWEEP FAILED line never
# vouches, however fresh: F1 §7 reproduced a receipt reading "SWEEP FAILED
# ... DO NOT PUBLISH" waving a publish through on mtime alone. The minimal
# content form on purpose — a findings line, not a bind-hash grammar.
rp="$sdir/outward-pass"
if [ -f "$rp" ] && [ ! -L "$rp" ]; then
  rline="$(tail -n 1 "$rp" 2>/dev/null)"
  if printf '%s' "$rline" | grep -qE 'findings: *[^ ]' && ! printf '%s' "$rline" | grep -q 'SWEEP FAILED'; then
    # GNU order first: GNU's -f is filesystem mode and prints a status block
    # to stdout BEFORE failing on the stray format string, so a BSD-first
    # fallback captures that block and the arithmetic below dies under
    # set -u. BSD's unknown -c fails to stderr only. The numeric guard keeps
    # any future stat shape from killing the script the same way.
    mt="$(stat -c %Y "$rp" 2>/dev/null || stat -f %m "$rp" 2>/dev/null || echo 0)"
    case "$mt" in ''|*[!0-9]*) mt=0 ;; esac
    if [ $(( now - mt )) -le 3600 ]; then log "PASS-receipt"; exit 0; fi
  fi
fi

# The destructive/production tier (D-69): infra applies, docker push, and
# the registry publishes do not take the one-bounce override — an identical
# retry alone never passes. This tier takes a one-shot GRANT the owner
# writes: .superstack/outward-grant, a regular file (a symlink never
# vouches) whose last line reads `grant: <text>` with <text> non-empty and
# contained in the command. The grant is EVIDENCE OF THE OWNER'S
# AUTHORIZATION, never access control: one file-write the owner can always
# make, consumed by its one use (moved to outward-grant-consumed), logged
# either way. The sweep-receipt pass above is untouched for every tier, and
# everything below this block keeps the one-bounce charter. git push and
# the gh verbs stay one-bounce on purpose: grants on everyday publishes are
# on the refused list, and gh release create is deletable — the boundary is
# irreversibility, not outwardness.
t3re='(terraform apply|kubectl apply|docker push|npm publish|twine upload|(poetry|cargo|uv) publish)'
if printf '%s' "$verb" | grep -Eq "$t3re"; then
  gp="$sdir/outward-grant"
  if [ -f "$gp" ] && [ ! -L "$gp" ]; then
    gtext="$(tail -n 1 "$gp" 2>/dev/null | sed -n 's/^grant: *//p' | sed 's/ *$//' | tr '[:upper:]' '[:lower:]')"
    if [ -n "$gtext" ]; then
      case "$lc" in *"$gtext"*)
        mv "$gp" "$sdir/outward-grant-consumed" 2>/dev/null || log "GRANT-consume-failed"
        log "PASS-grant"
        exit 0;;
      esac
    fi
  fi
  log "BOUNCE-t3"
  cat >&2 <<EOF
superstack outward gate: this command is in the destructive/production tier ($verb) and no fresh go-public sweep receipt exists. An identical retry will NOT pass for this tier. Do ONE:
- Have the owner write the one-shot grant, then retry the identical command:
    printf 'grant: $verb\n' > .superstack/outward-grant
  The grant is evidence of the owner's authorization, never access control; it is consumed by one use and logged.
- Or run the full sweep — invoke superstack-outward — then append its receipt line (grammar ends in "findings: <n fixed / none>") to .superstack/outward-pass and retry.
(Knob: SUPERSTACK_GATES=all|claims|off — claims or off silences this gate.)
EOF
  exit 2
fi

# One bounce per exact command: a repeat passes.
h="$(printf '%s' "$cmd" | cksum | cut -d' ' -f1)"
bp="$sdir/outward-bounce"
if [ -f "$bp" ] && grep -q "^$h\$" "$bp" 2>/dev/null; then log "PASS-override"; exit 0; fi
printf '%s\n' "$h" >> "$bp" 2>/dev/null

log "BOUNCE"
cat >&2 <<EOF
superstack outward gate: this command publishes ($verb) and no fresh go-public sweep receipt exists.
Run the sweep now — invoke superstack-outward: secrets scan, AI-trace/PII scrub, stale-public-claim audit on what ships — then append a receipt line (its grammar ends in "findings: <n fixed / none>") to .superstack/outward-pass and retry.
If the sweep genuinely doesn't apply, retry the identical command: it passes once ungated, and the override is logged.
(Knob: SUPERSTACK_GATES=all|claims|off — claims or off silences this gate.)
EOF
exit 2
