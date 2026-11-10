---
name: token-bar
description: Affiche la consommation de tokens (fenêtre de contexte + limites 5h/7j de l'abonnement) sous forme de barres de progression dans la status line de Claude Code, sous le prompt à côté de « auto mode on ». Utiliser quand l'utilisateur veut activer, désactiver, régler ou dépanner la barre de tokens / jauge de contexte / consommation.
---

# token-bar

Le rendu est fait par `~/.claude/skills/token-bar/statusline.sh`, branché sur la clé
`statusLine` de `~/.claude/settings.json`. Claude Code l'exécute à chaque rafraîchissement
avec le JSON de session sur stdin. Le skill ne sert qu'à l'installer, le régler ou le retirer.

Affichage : `Contexte ████████░░ 64% 128k/200k · 72k libres │ Session 5h ███░░ 42% · reset 2h13 │ Semaine …`
- `Contexte` : tokens dans la fenêtre de contexte actuelle (input + cache), et ce qui reste avant compaction.
- `Session 5h` / `Semaine` : quota d'abonnement utilisé et temps avant reset (affiché seulement si Claude Code transmet `rate_limits`).
- Vert < 60 %, jaune < 80 %, orange < 95 %, rouge à partir de 95 %.

## Activer
Avec jq, ajouter dans `~/.claude/settings.json` sans toucher au reste :
```bash
f=~/.claude/settings.json; tmp=$(mktemp)
jq '.statusLine = {"type":"command","command":"~/.claude/skills/token-bar/statusline.sh","padding":0}' "$f" > "$tmp" && mv "$tmp" "$f"
```

## Désactiver
```bash
f=~/.claude/settings.json; tmp=$(mktemp); jq 'del(.statusLine)' "$f" > "$tmp" && mv "$tmp" "$f"
```

## Régler
- Largeur des barres : préfixer la commande par `TOKEN_BAR_WIDTH=25 ` (15 par défaut).
- Seuils / couleurs / libellés : fonction `bar()` du script.

## Dépanner
Préfixer la commande par `TOKEN_BAR_DEBUG=1 ` : le dernier JSON reçu est écrit dans
`~/.claude/skills/token-bar/last-input.json`, ce qui permet de voir les champs réellement fournis.
Tester hors Claude Code : `echo '{}' | ~/.claude/skills/token-bar/statusline.sh`.
