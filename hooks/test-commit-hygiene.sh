#!/bin/bash
# Commit messages carry no AI authorship trailers: no Co-Authored-By naming
# an AI, no session-link trailers. Ceiling ZERO over the full reachable
# history — the owner's identity is the author of record on every commit.
# Rationale: the no-AI-attribution statute in .superstack/doctrine.md.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
hits="$(cd "$root" && git log --format='%H %(trailers)' 2>/dev/null | grep -icE 'co-authored-by:.*(claude|anthropic)|claude-session:')"
echo
if [ "${hits:-0}" -eq 0 ]; then echo "all checks pass (0 AI authorship trailer(s), ceiling 0)"; exit 0
else echo "$hits commit(s) carry an AI authorship trailer over a ceiling of 0 — strip the trailer; authorship is the owner's."; exit 1; fi
