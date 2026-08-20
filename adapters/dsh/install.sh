#!/usr/bin/env bash
# Installs superstack into DeepSeek Harness as its own profile:
# $DSH_HOME/profiles/superstack — manifest, patch layer, and hooks file,
# fully superstack-owned. A profile not carrying our marker is refused,
# never merged and never clobbered. Uninstall: rm -rf that directory.
# The hooks bridge and its protocol package are not in the host's shipped
# bundles, so the finishing step installs both into the profile
# (SUPERSTACK_DSH_NO_INSTALL=1 prints the command instead of running it).
# Sessions get their own root with readable logs because the stop-time
# gates read the final message from the session log, and the host refuses
# mixed compression under one root. jq required at session time; without
# it every hook fails open, the README's standing disclosure.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
# Same refusal set as the other installers: any of these five characters
# silently produces a hooks file whose commands never fire.
case "$root" in
  *"|"*|*"&"*|*"\\"*|*"'"*|*'"'*) echo "refusing: superstack path contains one of | & \\ ' \" (move the clone to a plain path)" >&2; exit 1;;
esac
home="${DSH_HOME:-$HOME/.dsh}"
prof="$home/profiles/superstack"
if [ -d "$prof" ] && ! grep -q "superstack adapter" "$prof/cordis.patch.yml" 2>/dev/null; then
  echo "refusing: $prof already exists and was not written by this installer." >&2
  echo "Move it aside, or add the rows from $here/hooks.template.json to your own profile." >&2
  exit 1
fi
mkdir -p "$prof"
tmpf="$(mktemp)"
sed "s|__SUPERSTACK_ROOT__|$root|g" "$here/hooks.template.json" > "$tmpf"
jq -e . "$tmpf" >/dev/null
mv "$tmpf" "$prof/superstack-hooks.json"
cat > "$prof/package.json" <<EOF
{
  "name": "dsh-profile-superstack",
  "private": true,
  "dsh": { "profile": { "bundles": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app"] } }
}
EOF
# The workspace boundary keeps pnpm inside the profile, and the empty
# composition root is what the boot layers patches onto — both are part
# of the host's own profile scaffold, and boot or install fails without
# them.
cat > "$prof/pnpm-workspace.yaml" <<EOF
packages:
  - .

nodeLinker: hoisted
autoInstallPeers: false
EOF
cat > "$prof/cordis.yml" <<EOF
# dsh profile root: an empty entry list; the tree is composed as patches.
# Edit cordis.patch.yml, not this file.
[]
EOF
cat > "$prof/cordis.patch.yml" <<EOF
# superstack adapter — written by adapters/dsh/install.sh; uninstall by
# deleting this profile directory
- insert:
    - id: superstack-hooks
      name: '@deepseek-ai/dsh-hooks-claude-code'
      config:
        configPath: "$prof/superstack-hooks.json"
- id: session-persistence-jsonl
  config:
    root: "$home/sessions-superstack"
    compression: none
    packChunks: false
EOF
echo "wrote $prof (superstack root: $root)"
addcmd="npx -y @deepseek-ai/dsh plugin --profile superstack add @deepseek-ai/dsh-hooks-claude-code @deepseek-ai/dsh-hook-protocol"
if [ -n "${SUPERSTACK_DSH_NO_INSTALL:-}" ]; then
  echo "finish by installing the hooks bridge into the profile:"
  echo "  $addcmd"
else
  $addcmd || {
    echo "the plugin install step failed; run it yourself:" >&2
    echo "  $addcmd" >&2
  }
fi
echo "use it:  npx -y @deepseek-ai/dsh --profile superstack"
