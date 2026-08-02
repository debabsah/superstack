#!/usr/bin/env bash
# One fact, one home — DECISIONS.md D-2 rules this for state; this extends it to
# prose. Flags passages of N+ consecutive words appearing verbatim in two or more
# shipped files.
#
# Why a check and not another rule: the rule is already written in four places
# (superstack-smith's "cited, not restated"; its gate 4 "reuse an existing
# grammar"; the code stance's "constraints, not narration"; the overlay's
# "can't be cheaply re-derived") and the prose duplicated anyway. A fifth
# statement of a rule that four statements did not hold is not an intervention.
#
# Scope is SHIPPED prose only — skills, README, KERNEL, DECISIONS. Excluded:
# dogfood/ (verbatim historical quotes, by the same rule that bars it from
# renames) and the design/analysis docs, which supersede each other by citation
# and are expected to overlap while they are being consolidated.
#
# Known blind spots, stated rather than tuned away:
# - Code fences and YAML frontmatter are stripped. A duplicated FORMAT block or
#   a duplicated description is invisible here.
# - It matches words, not meaning. superstack-continuity's duty is duplicated by
#   inject-superstack.sh in different words; this check cannot see that.
# - Shell comments are out of scope, so the four-file narrative that motivated
#   this check would have been caught in its .md half only.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$here/.."
N="${DUP_WORDS:-12}"
# The ratchet. This is today's real duplication debt, not a target — it may only
# ever be lowered. Raising it to make a red build green is the one edit that
# defeats the check, so it gets a number in the file rather than a flag someone
# passes at the call site.
CEILING="${DUP_CEILING:-7}"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

files="$(find "$root/skills" -name '*.md' 2>/dev/null | sort)
$root/README.md
$root/KERNEL.md
$root/DECISIONS.md"

# Normalize to a bare word stream: drop YAML frontmatter, fenced code, inline
# code, link targets and BLOCKQUOTES, then lowercase and reduce to alphanumerics.
# What survives is the prose a human actually reads.
#
# Blockquotes are excluded because a verbatim quote is not a second home for a
# fact, it is evidence about one — and superstack-doctrine MANDATES the form
# (`> verbatim: "<the user's own words>"`), so without this every correctly
# written statute quoting a rule that also lives in a skill fires the check.
# The loophole is accepted and named: prose laundered through a `>` escapes.
# Marking text as a quote is a deliberate, visible act, which is the signal.
norm() {
  awk 'NR==1 && /^---$/ {fm=1; next}
       fm==1 && /^---$/  {fm=0; next}
       fm==1             {next}
       /^```/            {fence=!fence; next}
       fence             {next}
       /^[[:space:]]*>/  {next}
       {print}' "$1" \
  | sed -E 's/`[^`]*`/ /g; s/\[([^]]*)\]\([^)]*\)/\1/g' \
  | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' ' ' | tr '\n' ' ' | tr -s ' '
}

printf '%s\n' "$files" | while IFS= read -r f; do
  [ -f "$f" ] || continue
  norm "$f" | tr ' ' '\n' | grep -v '^$' \
    | awk -v n="$N" -v file="$(basename "$(dirname "$f")")/$(basename "$f")" '
        {w[++c]=$0}
        END{ for(i=1;i+n-1<=c;i++){ s=w[i]; for(j=1;j<n;j++) s=s" "w[i+j]; print s "\t" file } }'
done | sort -u > "$tmp/shingles"

# Every unordered file-pair that shares a shingle, carrying one example each.
awk -F'\t' '
  function flush(  i,j,a,b,t){
    if (nf>=2) for(i=1;i<=nf;i++) for(j=i+1;j<=nf;j++){
      a=fs[i]; b=fs[j]; if(a>b){t=a;a=b;b=t}
      print a "\t" b "\t" prev
    }
    nf=0; delete fs
  }
  $1!=prev { flush(); prev=$1 }
  { fs[++nf]=$2 }
  END { flush() }
' "$tmp/shingles" | sort > "$tmp/pairs"

cut -f1,2 "$tmp/pairs" | uniq -c | sort -rn > "$tmp/counts"
pairs="$(wc -l < "$tmp/counts" | tr -d ' ')"

echo "duplication: $pairs file-pair(s) share a ${N}+ word passage (ceiling $CEILING)"
echo
while read -r cnt a b; do
  printf '%4d  %s  <->  %s\n' "$cnt" "$a" "$b"
  ex="$(awk -F'\t' -v a="$a" -v b="$b" '$1==a && $2==b {print length($3) "\t" $3}' "$tmp/pairs" \
        | sort -rn | head -1 | cut -f2-)"
  printf '      "%s"\n' "$(printf '%s' "$ex" | cut -c1-100)"
done < "$tmp/counts"

echo
if [ "$pairs" -le "$CEILING" ]; then
  echo "all checks pass ($pairs pair(s), ceiling $CEILING)"
  [ "$pairs" -lt "$CEILING" ] && echo "NOTE: below the ceiling — lower DUP_CEILING to $pairs to keep the ratchet tight."
  exit 0
else
  echo "$((pairs - CEILING)) new duplicated passage(s) — give the fact one home and cite it from the other, or lower the ceiling if you removed one."
  exit 1
fi
