#!/usr/bin/env bash
# install-icons.sh – installerer Fluent-ikonene (vinceliuice, GPL-3.0-or-later) for din bruker.
#
# Henter en fast versjon fra GitHub, kjører pakkens eget installasjonsskript med
# ~/.local/share/icons som mål, og legger Mint-Y, Adwaita og hicolor til som reserve,
# så apper Fluent mangler ikon for, fortsatt får et. Aktiverer ingenting med mindre
# du ber om det. Krever git, ikke sudo.
#
# Bruk:
#   ./scripts/install-icons.sh                 # grønn variant (passer Mint-Ro)
#   ./scripts/install-icons.sh teal            # annen farge: standard green grey orange pink purple red yellow teal
#   ./scripts/install-icons.sh --activate      # installer og bruk (via apply-profile.sh ikoner)
#   ./scripts/install-icons.sh --remove        # fjern Fluent-ikoner installert av dette skriptet

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${MINT_RO_ICONS_REPO:-https://github.com/vinceliuice/Fluent-icon-theme}"   # kan overstyres (speil/test)
TAG="2026-07-27"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
MARK=".mint-ro-installed"
COLORS=(standard green grey orange pink purple red yellow teal)
FALLBACK="Mint-Y,Adwaita,hicolor"

COLOR="green"; ACTIVATE=0; REMOVE=0; YES_ARG=()
usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }
tilde() { printf '%s' "${1/#"$HOME"/\~}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --activate) ACTIVATE=1 ;;
    --remove) REMOVE=1 ;;
    --yes|-y) YES_ARG=(--yes) ;;
    -h|--help) usage; exit 0 ;;
    -*) die "ukjent valg: $1 (se --help)" ;;
    *) printf '%s\n' "${COLORS[@]}" | grep -qx "$1" || die "ukjent farge: $1 (se --help)"; COLOR="$1" ;;
  esac
  shift
done

[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."

# Mappenavn Fluent lager for en farge: Fluent[-farge], -dark og -light.
names_for() {
  local base="Fluent"; [ "$1" = "standard" ] || base="Fluent-$1"
  printf '%s\n' "$base" "$base-dark" "$base-light"
}

# ---------- Fjerning ----------
if [ "$REMOVE" -eq 1 ]; then
  current="$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null || true)"
  case "$current" in "'Fluent"*) die "Fluent-ikoner er i bruk ($current). Bytt ikontema først, for eksempel med restore.sh." ;; esac
  removed=0
  for d in "$DEST"/Fluent*; do
    [ -d "$d" ] && [ -f "$d/$MARK" ] || continue
    rm -rf -- "$d" && { echo "Fjernet: $(tilde "$d")"; removed=1; }
  done
  # Fluents skjulte basismapper fjernes når ingen synlige Fluent-mapper er igjen.
  if ! compgen -G "$DEST/Fluent*" >/dev/null; then
    for d in "$DEST"/.Fluent*-base; do
      [ -d "$d" ] && [ -f "$d/$MARK" ] && rm -rf -- "$d"
    done
  fi
  [ "$removed" -eq 1 ] || echo "Fant ingen Fluent-ikoner installert av Mint-Ro."
  exit 0
fi

# ---------- Installasjon ----------
command -v git >/dev/null 2>&1 || die "git mangler. Installer med: sudo apt install git"
mapfile -t NAMES < <(names_for "$COLOR")

# Overskriv bare mapper dette skriptet selv har installert (også Fluents skjulte basismapper).
for n in "${NAMES[@]}" .Fluent-base .Fluent-dark-base .Fluent-light-base; do
  if [ -e "$DEST/$n" ] && [ ! -f "$DEST/$n/$MARK" ]; then
    die "$(tilde "$DEST/$n") finnes allerede og er ikke installert av Mint-Ro. Flytt eller fjern den først."
  fi
done

mkdir -p "$DEST" || die "kunne ikke opprette $(tilde "$DEST")."
TMP="$(mktemp -d)" || die "kunne ikke lage midlertidig mappe."
trap 'rm -rf "$TMP"' EXIT

echo "Henter Fluent-ikoner $TAG ..."
git clone --quiet --depth 1 --branch "$TAG" "$REPO" "$TMP/src" 2>/dev/null \
  || die "kunne ikke hente $REPO ($TAG). Sjekk nettforbindelsen."

echo "Installerer fargen «$COLOR» til $(tilde "$DEST") ..."
( cd "$TMP/src" && bash ./install.sh "$COLOR" -d "$DEST" ) >"$TMP/install.log" 2>&1 \
  || { tail -5 "$TMP/install.log" >&2; die "Fluents installasjonsskript feilet."; }

for n in "${NAMES[@]}"; do
  f="$DEST/$n/index.theme"
  [ -f "$f" ] || die "forventet $(tilde "$f") etter installasjonen, men fant den ikke."
  # Reserve for ikoner Fluent ikke har.
  # Rekkefølge: Fluents egne arvinger, så Mint-Y og Adwaita, og hicolor til slutt.
  inherits="$(sed -n 's/^Inherits=//p' "$f" | head -1)"
  new=""
  for fb in ${inherits//,/ } ${FALLBACK//,/ }; do
    [ "$fb" = "hicolor" ] && continue
    case ",$new," in *",$fb,"*) ;; *) new="${new:+$new,}$fb" ;; esac
  done
  new="${new:+$new,}hicolor"
  if grep -q '^Inherits=' "$f"; then
    sed -i "s/^Inherits=.*/Inherits=$new/" "$f"
  else
    sed -i "/^\[Icon Theme\]/a Inherits=$new" "$f"
  fi
  printf 'Fluent-icon-theme %s (%s), installert av Mint-Ro\n' "$TAG" "$COLOR" >"$DEST/$n/$MARK"
  echo "Installert: $(tilde "$DEST/$n")"
done
for d in "$DEST"/.Fluent*-base; do
  [ -d "$d" ] && printf 'Fluent-icon-theme %s, installert av Mint-Ro\n' "$TAG" >"$d/$MARK"
done

if [ "$ACTIVATE" -eq 1 ]; then
  trap - EXIT; rm -rf "$TMP"
  exec "$SCRIPT_DIR/apply-profile.sh" "${YES_ARG[@]}" ikoner "--ikonfarge=$COLOR"
fi
echo "Bruk med:  $SCRIPT_DIR/apply-profile.sh ikoner"
echo "eller velg «${NAMES[0]}» i Systeminnstillinger → Temaer → Ikoner."
