#!/usr/bin/env bash
# Installs superstack into Kiro CLI: writes the superstack agent config to
# ~/.kiro/agents/superstack.json — on this host, hooks ride the agent
# config, so the adapter ships as an agent. A superstack.json this
# installer did not write is refused, never merged and never clobbered.
# Uninstall: rm that file. Using it stays the user's choice: per session
# (kiro-cli chat --agent superstack) or as the default
# (kiro-cli agent set-default superstack) — the installer changes no
# default itself. jq required at session time; without it every hook
# fails open, the README's standing disclosure.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
# sed's replacement side treats & and \ specially, the template wraps the
# path in single quotes for bash, and the config itself is JSON where a
# double quote tears the string; any of the five silently writes a config
# whose hooks never fire, so all five are refused before anything lands.
case "$root" in
  *"|"*|*"&"*|*"\\"*|*"'"*|*'"'*) echo "refusing: superstack path contains one of | & \\ ' \" (move the clone to a plain path)" >&2; exit 1;;
esac
dest="${KIRO_CONFIG_DIR:-$HOME/.kiro}/agents"
f="$dest/superstack.json"
if [ -f "$f" ] && ! grep -q "superstack adapter" "$f"; then
  echo "refusing: $f already exists and was not written by this installer." >&2
  echo "Copy the hooks block from $here/agent.template.json into your own agent config" >&2
  echo "(replace __SUPERSTACK_ROOT__ with $root), or move your file aside first." >&2
  exit 1
fi
mkdir -p "$dest"
tmpf="$(mktemp)"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$here/agent.template.json" > "$tmpf"
jq -e . "$tmpf" >/dev/null
mv "$tmpf" "$f"
echo "wrote $f (superstack root: $root)"
echo "use it per session:  kiro-cli chat --agent superstack"
echo "or make it default:  kiro-cli agent set-default superstack"
