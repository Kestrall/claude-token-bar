#!/usr/bin/env bash
# Retire la status line token-bar et le skill.
set -euo pipefail
command -v jq >/dev/null || { echo "❌ jq est requis"; exit 1; }

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS" ] && jq -e '.statusLine.command // "" | test("token-bar/statusline.sh")' "$SETTINGS" >/dev/null; then
  tmp=$(mktemp); jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
fi
rm -rf "$CLAUDE_DIR/skills/token-bar"
echo "🗑️  token-bar désinstallé."
