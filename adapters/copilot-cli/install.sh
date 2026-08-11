#!/usr/bin/env bash
# Installs the superstack hooks into GitHub Copilot CLI: writes the resolved
# hook config to ~/.copilot/hooks/superstack.json (user level fires without
# the per-folder trust prompt that repo-level .github/hooks needs). Uninstall
# is the mirror: rm ~/.copilot/hooks/superstack.json. Requires jq at session
# time; without it every shim path fails open, the same disclosure the README
# makes for the native spine.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
# sed's replacement side treats & and \ specially, and the template wraps the
# path in single quotes for bash; any of the four silently writes a config
# whose hooks never fire, so all four are refused before anything is written.
case "$root" in
  *"|"*|*"&"*|*"\\"*|*"'"*) echo "refusing: superstack path contains one of | & \\ ' (move the clone to a plain path)" >&2; exit 1;;
esac
dest="${COPILOT_CONFIG_DIR:-$HOME/.copilot}/hooks"
mkdir -p "$dest"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$here/hooks.template.json" > "$dest/superstack.json"
jq -e . "$dest/superstack.json" >/dev/null
echo "wrote $dest/superstack.json (superstack root: $root)"
