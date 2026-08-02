#!/bin/bash
# Routing-accuracy eval — method and limitations in README.md (read it before
# citing the number). One pass: for each prompts.tsv row, a FRESH model is
# shown the name+description listing (built live from skills/ frontmatter,
# exactly what the harness router sees) and the user prompt, and must answer
# with one skill name; exact match scores. Runs from a neutral temp cwd so
# no workspace hooks contaminate the call. Requires the claude CLI.
# Usage: bash run.sh [prompts-file]   (default prompts.tsv beside this script)
#   EVAL_MODEL overrides the model (default claude-sonnet-5); the run record
#   must state whichever was used.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
prompts="${1:-$here/prompts.tsv}"
model="${EVAL_MODEL:-claude-sonnet-5}"

listing=""
for d in "$root"/skills/*/; do
  s="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue
  desc="$(awk '
    /^---$/ { fm++; next }
    fm==1 && /^description:/ { sub(/^description:[ ]*/,""); buf=$0; on=1; next }
    fm==1 && on && /^[a-zA-Z_-]+:/ { on=0 }
    fm==1 && on { buf=buf" "$0 }
    fm==2 { exit }
    END { print buf }' "$d/SKILL.md" | tr -s ' ')"
  listing="$listing- superstack:$s: $desc
"
done

neutral="$(mktemp -d)"; trap 'rm -rf "$neutral"' EXIT
correct=0; total=0; misses=""
while IFS='	' read -r p e; do
  [ -n "$p" ] || continue
  total=$((total+1))
  # </dev/null is load-bearing: without it the claude call inherits this
  # loop's stdin and reads the remaining prompt rows into its own prompt.
  raw="$(cd "$neutral" && claude -p --model "$model" "You are the skill router for a coding agent. Below is the installed skill listing (name: description). A user just typed a prompt. Reply with ONLY the chosen skill's full name exactly as listed — for example superstack-debug; the front door's name is just superstack. One name, nothing else. If none fits, reply none.

Skill listing:
$listing
User prompt: \"$p\"" </dev/null 2>/dev/null)"
  ans="$(printf '%s' "$raw" | awk 'NF{print $1; exit}' | sed 's/^superstack://' | tr -d '`",.:;*')"
  case "$ans" in
    superstack|superstack-*|none|'') ;;
    *) ans="superstack-$ans" ;;
  esac
  if [ "$ans" = "$e" ]; then correct=$((correct+1))
  else misses="$misses
  MISS: wanted $e, got ${ans:-<empty>} — \"$p\""
  fi
done < "$prompts"

echo "routing eval: $correct/$total intended-route matches (model $model, commit $(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown), $(date +%F))"
[ -n "$misses" ] && printf '%s\n' "$misses"
exit 0
