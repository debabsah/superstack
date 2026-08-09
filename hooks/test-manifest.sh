#!/usr/bin/env bash
# The manifest validator, run as a suite so it rides the same oracle as every
# commit instead of depending on someone remembering it at release time. The
# badge suite pins the one version-agreement fact; this one owns the rest of
# the schema class (structure, references, field shapes). Rationale: D-59.
# MANIFEST_ROOT overrides the tree under test so the doctored-copy drill can
# prove the suite fires; unset means this repo.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="${MANIFEST_ROOT:-$here/..}"

command -v claude >/dev/null || { echo "the claude CLI is required for this suite"; exit 1; }

rc=0
out="$(claude plugin validate "$root" </dev/null 2>&1)" || rc=$?

# Warnings fail too: the validator exits 0 on a version-field disagreement
# (the exact class that once shipped) and only warns. A warning here is a
# defect to fix, not a note to read past.
if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qi "warning"; then
  echo "all checks pass (claude plugin validate, warnings treated as failures)"
  exit 0
else
  printf '%s\n' "$out" | sed 's/^/  /'
  echo "manifest validation FAILED — fix the manifests before committing."
  exit 1
fi
