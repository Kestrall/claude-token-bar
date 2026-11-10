#!/usr/bin/env bash
# Installe token-bar : copie le skill dans ~/.claude/skills/token-bar
# et branche la status line dans ~/.claude/settings.json (sauvegarde faite avant).
set -euo pipefail

command -v jq >/dev/null || { echo "❌ jq est requis (apt install jq / brew install jq)"; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/skill"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DEST="$CLAUDE_DIR/skills/token-bar"
SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$DEST"
cp "$SRC/statusline.sh" "$SRC/SKILL.md" "$DEST/"
chmod +x "$DEST/statusline.sh"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
current=$(jq -r '.statusLine.command // empty' "$SETTINGS")
if [ -n "$current" ] && [[ "$current" != *token-bar/statusline.sh* ]]; then
  echo "⚠️  Une status line existe déjà : $current"
  read -r -p "La remplacer par token-bar ? [o/N] " ans
  [[ "$ans" =~ ^[oOyY] ]] || { echo "Skill copié, status line inchangée."; exit 0; }
fi

cp "$SETTINGS" "$SETTINGS.bak-token-bar"
tmp=$(mktemp)
jq --arg cmd "$DEST/statusline.sh" \
   '.statusLine = {"type":"command","command":$cmd,"padding":0}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "✅ token-bar installé. Sauvegarde : $SETTINGS.bak-token-bar"
echo "   Relance Claude Code si la barre n'apparaît pas tout de suite."
