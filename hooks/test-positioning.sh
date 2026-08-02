#!/bin/bash
# Self-checks for the ruled position (DECISIONS.md D-21; plan M0) on the three
# shipped surfaces: README.md, .claude-plugin/plugin.json,
# .claude-plugin/marketplace.json.
# The contract: each surface's lead text carries the memory-and-law position
# (goals/corrections/evidence + across sessions + gates), and no shipped
# surface carries a module auto-fire promise or a "machine receipts" claim.
# Rewording the position is fine as long as the three phrase families survive;
# relaxing or removing a case needs the owner (ratchet rule).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0

# First PROSE paragraph: skip headings, HTML (hero embed), images, tables.
readme_p1="$(awk '/./ && !/^#/ && !/^</ && !/^!/ && !/^\|/ && !/^ /{print; exit}' "$root/README.md")"
plug_desc="$(jq -r '.description' "$root/.claude-plugin/plugin.json")"
mkt_top="$(jq -r '.description' "$root/.claude-plugin/marketplace.json")"
mkt_plug="$(jq -r '.plugins[0].description' "$root/.claude-plugin/marketplace.json")"

carries_position() { # desc text
  desc="$1"; text="$2"; missing=""
  for ph in "goals, corrections" "session" "gate"; do
    printf '%s' "$text" | grep -qi "$ph" || missing="$missing '$ph'"
  done
  if [ -z "$missing" ]; then pass=$((pass+1)); echo "PASS: $desc carries the position"
  else fail=$((fail+1)); echo "FAIL: $desc missing:$missing"; fi
}

carries_position "README first paragraph" "$readme_p1"
carries_position "plugin.json description" "$plug_desc"
carries_position "marketplace.json top description" "$mkt_top"
carries_position "marketplace.json plugin description" "$mkt_plug"

# Promise phrases: each only ever appears as an auto-fire/overclaim promise,
# so an honest surface never needs the literal string.
for ph in "rarely need to pick" "without being asked" "shows up at each moment" "machine receipts"; do
  hits="$(grep -ril "$ph" "$root/README.md" "$root/.claude-plugin/plugin.json" "$root/.claude-plugin/marketplace.json" 2>/dev/null || true)"
  if [ -z "$hits" ]; then pass=$((pass+1)); echo "PASS: no surface says '$ph'"
  else fail=$((fail+1)); echo "FAIL: '$ph' found in: $(echo "$hits" | tr '\n' ' ')"; fi
done

echo "positioning: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
