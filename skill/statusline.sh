#!/usr/bin/env bash
# Barre(s) de progression tokens pour la status line Claude Code.
# Lit le JSON de session sur stdin (fourni par Claude Code à chaque rafraîchissement).
input=$(cat)
[ -n "$TOKEN_BAR_DEBUG" ] && printf '%s' "$input" > "$HOME/.claude/skills/token-bar/last-input.json"

WIDTH=${TOKEN_BAR_WIDTH:-20}

bar() { # $1 = pourcentage utilisé (0-100), $2 = libellé, $3 = suffixe
  local pct=${1%.*}; [ -z "$pct" ] && pct=0
  (( pct > 100 )) && pct=100; (( pct < 0 )) && pct=0
  local filled=$(( pct * WIDTH / 100 )) empty color
  empty=$(( WIDTH - filled ))
  if   (( pct >= 85 )); then color='\033[31m'   # rouge
  elif (( pct >= 60 )); then color='\033[33m'   # jaune
  else                       color='\033[32m'; fi # vert
  local full rest
  full=$(printf '%*s' "$filled" ''); full=${full// /█}
  rest=$(printf '%*s' "$empty" '');   rest=${rest// /░}
  printf "%s ${color}%s\033[2m%s\033[0m %3d%%%s" "$2" "$full" "$rest" "$pct" "$3"
}

human() { awk -v n="$1" 'BEGIN{ if(n>=1e6) printf "%.1fM", n/1e6; else if(n>=1e3) printf "%.0fk", n/1e3; else printf "%d", n }'; }

until_reset() { # epoch -> "2h14" / "3j"
  local s=$(( ${1%.*} - $(date +%s) )); (( s < 0 )) && s=0
  if (( s >= 86400 )); then printf '%dj%02dh' $((s/86400)) $((s%86400/3600))
  else printf '%dh%02d' $((s/3600)) $((s%3600/60)); fi
}

# --- Fenêtre de contexte -------------------------------------------------
size=$(jq -r '.context_window.context_window_size // 200000' <<<"$input")
used=$(jq -r '.context_window.current_usage
               | if . == null then 0 else
                 ((.input_tokens//0)+(.cache_creation_input_tokens//0)+(.cache_read_input_tokens//0)) end' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
[ -z "$pct" ] && pct=$(( size > 0 ? used * 100 / size : 0 ))
left=$(( size - used )); (( left < 0 )) && left=0
out=$(bar "$pct" "ctx" " $(human "$used")/$(human "$size") (reste $(human "$left"))")

# --- Limites d'abonnement (si Claude Code les fournit) -------------------
for win in five_hour:5h seven_day:7j; do
  key=${win%%:*}; label=${win##*:}
  p=$(jq -r ".rate_limits.${key}.used_percentage // empty" <<<"$input")
  [ -z "$p" ] && continue
  r=$(jq -r ".rate_limits.${key}.resets_at // empty" <<<"$input")
  suffix=""; [ -n "$r" ] && suffix=" ↻$(until_reset "$r")"
  out+="  │  $(bar "$p" "$label" "$suffix")"
done

printf '%b\n' "$out"
