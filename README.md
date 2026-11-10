# token-bar ⛽

**Ta conso de tokens Claude Code en un coup d'œil**, directement sous le prompt, à côté de `auto mode on`.

```
ctx █░░░░░░░░░░░░░░░░░░░   5% 51k/1.0M (reste 949k)  │  5h █████████░░░░░░░░░░░  46% ↻1h10  │  7j ███░░░░░░░░░░░░░░░░░  19% ↻1j04h
```

| Barre | Ce qu'elle montre |
|---|---|
| `ctx` | Tokens dans la conversation en cours, et ce qui reste avant que Claude Code résume (compacte) la conversation |
| `5h` | Part utilisée de ton quota d'abonnement sur 5 h, et temps avant remise à zéro (↻) |
| `7j` | Pareil sur 7 jours |

🟢 moins de 60 % · 🟡 jusqu'à 85 % · 🔴 au-delà

Les barres `5h` et `7j` n'apparaissent que si Claude Code transmet ces infos (abonnement Pro/Max). En usage API, seule `ctx` s'affiche.

## Installation

Prérequis : `bash` et [`jq`](https://jqlang.org/) (`sudo apt install jq` ou `brew install jq`). Linux, macOS ou WSL.

```bash
git clone https://github.com/Kestrall/claude-token-bar.git
cd claude-token-bar
./install.sh
```

Relance Claude Code : la barre apparaît en bas.

L'installeur :
- copie le skill dans `~/.claude/skills/token-bar/`
- ajoute la clé `statusLine` dans `~/.claude/settings.json` (sans toucher au reste)
- sauvegarde l'ancien fichier en `settings.json.bak-token-bar`
- te demande avant d'écraser une status line déjà configurée

## Désinstallation

```bash
./uninstall.sh
```

## Le skill

Le dossier installé contient aussi un **skill Claude Code**. Tu peux simplement demander à Claude :

- « désactive la barre de tokens »
- « mets des barres plus larges »
- « la barre n'affiche plus rien, regarde pourquoi »

Claude sait où est le script et comment le régler.

## Personnaliser

- **Largeur** : dans `settings.json`, préfixe la commande par `TOKEN_BAR_WIDTH=30 `.
- **Seuils, couleurs, libellés** : fonction `bar()` dans `skill/statusline.sh`.
- **Dépannage** : préfixe la commande par `TOKEN_BAR_DEBUG=1 ` pour enregistrer le dernier JSON reçu dans `~/.claude/skills/token-bar/last-input.json`.

## Comment ça marche

Claude Code exécute la commande `statusLine` à chaque rafraîchissement et lui passe sur stdin un JSON décrivant la session (`context_window`, `rate_limits`…). Le script le lit avec `jq` et dessine les barres. Rien n'est envoyé nulle part, tout reste en local.

Doc officielle : [Status line](https://docs.claude.com/en/docs/claude-code/statusline).

## Licence

MIT
