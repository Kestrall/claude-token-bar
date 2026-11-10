#!/usr/bin/env bash
# Tests du rendu : chaque cas passe un JSON de session au script et vérifie la sortie.
set -u
cd "$(dirname "$0")/.." || exit 1
SCRIPT=skill/statusline.sh
fail=0

render() { sed "s/RESET/$(( $(date +%s) + 7500 ))/" "tests/fixtures/$1.json" | "$SCRIPT"; }

check() { # $1 = nom, $2 = sortie, $3 = motif attendu (grep -F)
  if printf '%s' "$2" | grep -qF -- "$3"; then echo "ok   $1"
  else echo "FAIL $1 : « $3 » absent de :"; printf '%s\n' "$2"; fail=1; fi
}
absent() {
  if printf '%s' "$2" | grep -qF -- "$3"; then echo "FAIL $1 : « $3 » ne devrait pas apparaître"; fail=1
  else echo "ok   $1"; fi
}

out=$(render subscription)
check  "contexte : pourcentage fourni"      "$out" " 64%"
check  "contexte : tokens et reste"         "$out" "128k/200k · 72k libres"
check  "contexte : jaune à 64 %"            "$out" $'\033[33m'
check  "Session 5h : orange à 85 %"                 "$out" $'\033[38;5;208m'
check  "Session 5h : compte à rebours"              "$out" "reset 2h0"
check  "Semaine : rouge vif à 97 %"              "$out" $'\033[1;31m'

out=$(render api)
check  "API : pourcentage calculé"          "$out" "  5%"
check  "API : fenêtre 1M"                   "$out" "51k/1.0M"
absent "API : pas de barre Session 5h"      "$out" "Session 5h"

out=$(render empty)
check  "JSON vide : barre à 0 %"            "$out" "  0% 0/200k"

out=$(echo '{"context_window":{"used_percentage":130}}' | "$SCRIPT")
check  "plafonné à 100 %"                   "$out" "100%"

exit $fail
