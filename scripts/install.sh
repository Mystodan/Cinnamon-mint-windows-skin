#!/usr/bin/env bash
# install.sh – installerer Mint-Ro-temaet for din bruker i ~/.themes/Mint-Ro.
#
# Kopierer bare temafilene. Aktiverer ingenting med mindre du ber om det, og
# endrer ingen andre temaer. Krever ikke sudo.
#
# Bruk:
#   ./scripts/install.sh              # installer eller oppdater temaet
#   ./scripts/install.sh --activate   # installer og aktiver (via apply-profile.sh tema)
#   ./scripts/install.sh --activate --yes

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
THEME_NAME="Mint-Ro"
THEMES_DIR="$HOME/.themes"
DEST="$THEMES_DIR/$THEME_NAME"
PARTS=(index.theme cinnamon gtk-2.0 gtk-3.0 gtk-4.0 libadwaita-1.5 libadwaita-1.7 metacity-1)
REQUIRED=(index.theme cinnamon/cinnamon.css gtk-3.0/gtk.css gtk-4.0/gtk.css metacity-1/metacity-theme-3.xml)

ACTIVATE=0; YES_ARG=()
usage() { sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --activate) ACTIVATE=1 ;;
    --yes|-y) YES_ARG=(--yes) ;;
    -h|--help) usage; exit 0 ;;
    *) die "ukjent valg: $1 (se --help)" ;;
  esac
  shift
done

[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."
for f in "${REQUIRED[@]}"; do
  [ -e "$REPO_DIR/$f" ] || die "mangler $f i repoet. Er temaet bygget? (python3 -I src/build.py)"
done

# Overskriv bare en mappe som faktisk er Mint-Ro.
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  grep -qx "Name=$THEME_NAME" "$DEST/index.theme" 2>/dev/null \
    || die "$DEST finnes allerede og er ikke Mint-Ro. Flytt den og prøv igjen."
fi

mkdir -p "$THEMES_DIR" || die "kunne ikke opprette $THEMES_DIR."
TMP="$(mktemp -d "$THEMES_DIR/.$THEME_NAME.XXXXXX")" || die "kunne ikke lage midlertidig mappe."
trap 'rm -rf "$TMP"' EXIT

for p in "${PARTS[@]}"; do
  [ -e "$REPO_DIR/$p" ] || continue
  cp -R "$REPO_DIR/$p" "$TMP/" || die "kopiering av $p feilet. Ingenting ble endret."
done
find "$TMP" -name README.md -delete
chmod -R u=rwX,go=rX "$TMP"

OLD=""
if [ -d "$DEST" ]; then OLD="$TMP.old"; mv "$DEST" "$OLD" || die "kunne ikke flytte gammel versjon."; fi
if ! mv "$TMP" "$DEST"; then
  [ -n "$OLD" ] && mv "$OLD" "$DEST"
  die "installasjonen feilet. Forrige versjon er beholdt."
fi
[ -z "$OLD" ] || rm -rf "$OLD"
trap - EXIT

echo "Installert: ${DEST/#"$HOME"/\~}"
if [ "$ACTIVATE" -eq 1 ]; then
  exec "$SCRIPT_DIR/apply-profile.sh" "${YES_ARG[@]}" tema
fi
echo "Aktiver med:  $SCRIPT_DIR/apply-profile.sh tema"
echo "eller velg Mint-Ro i Systeminnstillinger → Temaer."
