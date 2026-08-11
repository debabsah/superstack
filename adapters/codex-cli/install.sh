#!/usr/bin/env bash
# Installs the superstack hooks into Codex CLI: writes the resolved config to
# ${CODEX_HOME:-~/.codex}/hooks.json. Codex keeps ONE user-level hooks file,
# so a hooks.json this installer did not write is refused, never merged and
# never clobbered — the refusal message says what to copy where. Uninstall:
# rm that file. After installing, approve the hooks once inside Codex with
# /hooks (scripted runs use Codex's own bypass flag instead). jq required at
# session time; without it every hook fails open, the README's standing
# disclosure.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
# sed's replacement side treats & and \ specially, and the template wraps the
# path in single quotes for bash; any of the four silently writes a config
# whose hooks never fire, so all four are refused before anything is written.
case "$root" in
  *"|"*|*"&"*|*"\\"*|*"'"*) echo "refusing: superstack path contains one of | & \\ ' (move the clone to a plain path)" >&2; exit 1;;
esac
dest="${CODEX_HOME:-$HOME/.codex}"
f="$dest/hooks.json"
if [ -f "$f" ] && ! grep -q "superstack" "$f"; then
  echo "refusing: $f already exists and was not written by this installer." >&2
  echo "Copy the hook entries from $here/hooks.template.json into it by hand" >&2
  echo "(replace __SUPERSTACK_ROOT__ with $root), or move your file aside first." >&2
  exit 1
fi
mkdir -p "$dest"
tmpf="$(mktemp)"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$here/hooks.template.json" > "$tmpf"
jq -e . "$tmpf" >/dev/null
mv "$tmpf" "$f"
echo "wrote $f (superstack root: $root)"
echo "one step remains: approve these hooks once inside an interactive Codex session (its documentation names /hooks as the review command)"
