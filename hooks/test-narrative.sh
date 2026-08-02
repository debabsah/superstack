#!/usr/bin/env bash
# PROVENANCE-STRING LINTER. Not a narrative check: it matches dates, version
# stamps and a fixed verb list, which is a proxy, not the property. Rationale:
# DECISIONS.md D-11.
#
# DO NOT CITE GREEN HERE AS COMPLIANCE. Its in-situ record against the offences
# that prompted it is 2 of 5; it cannot see rhetoric, KERNEL.md, README.md,
# commit messages, or chat replies.
#
# Scope: superstack-owned shell + module skill bodies. Kernel files excluded:
# their style is upstream's and their comments cannot be edited here.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
CEILING="${NARRATIVE_CEILING:-0}"

# Do not add a `because …` tell: it fires on logical causes that are load-bearing
# (superstack-spike's "legal because the contract above exists" guards the
# exemption) and catches nothing these already catch. See D-11.
TELLS='([0-9]{4}-[0-9]{2}-[0-9]{2}|\([0-9]+\.[0-9]+\.[0-9]+\)|until [0-9]+\.[0-9]|\b(measured|verified by|was written|used to|had never|has never|turns out|it turned out)\b)'  # narrative-exempt

kernel="superstack-scope superstack-debug superstack-review superstack-verify superstack-ship superstack-status"

# Two grep passes over all files at once, and no subprocess per file: the
# PostToolUse arm runs this on EVERY edit, so it has to stay cheap. Do not
# reintroduce a per-file loop or a `basename` call here without re-timing it.
sh_files=""
for f in "$root"/hooks/*.sh "$root"/scripts/*.sh; do
  case "${f##*/}" in
    gate-claims.sh|inject-project-pointer.sh|test-gate.sh|superstack-status.sh) continue ;;  # kernel-owned
  esac
  sh_files="$sh_files $f"
done
md_files=""
for d in "$root"/skills/superstack-*/; do
  name="${d%/}"; name="${name##*/}"
  case " $kernel " in *" $name "*) continue ;; esac
  [ -f "$d/SKILL.md" ] && md_files="$md_files $d/SKILL.md"
done

# `narrative-exempt` on a line is the only escape hatch, and it is per-line, never
# per-file. THIS FILE IS SCANNED LIKE ANY OTHER: excluding it wholesale is how the
# checker stopped being checkable, and a padded comment landed in it unseen. Only
# the lines that must spell the tells out carry the marker.
# Shell: comment lines only. Code that legitimately holds a date is not prose.
found="$( { grep -nE '^[[:space:]]*#' $sh_files 2>/dev/null | grep -E "$TELLS"
            grep -nE "$TELLS" $md_files 2>/dev/null; } | grep -v 'narrative-exempt' | sed "s|^$root/||" )"
hits="$(printf '%s' "$found" | grep -c .)"
[ -n "$found" ] && printf '%s\n' "$found" | cut -c1-110 | sed 's/^/  /'

echo
if [ "$hits" -le "$CEILING" ]; then
  echo "all checks pass ($hits narrative tell(s), ceiling $CEILING)"
  exit 0
else
  echo "$hits narrative tell(s) over a ceiling of $CEILING — move the history to the decision record or the dogfood note, and leave the comment its constraints."
  exit 1
fi
