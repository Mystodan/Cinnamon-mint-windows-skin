#!/usr/bin/env bash
# install.sh – installerer Mint-Ro og Mint-Ro-Dark for din bruker i ~/.themes.
#
# Kopierer bare temafilene. Aktiverer ingenting med mindre du ber om det, og
# endrer ingen andre temaer. Krever ikke sudo.
#
# Bruk:
#   ./scripts/install.sh              # installer eller oppdater temaet
#   ./scripts/install.sh --activate        # installer og aktiver lys variant
#   ./scripts/install.sh --activate-dark   # installer og aktiver mørk variant
#   ./scripts/install.sh --activate --yes

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
THEMES_DIR="$HOME/.themes"
PARTS=(index.theme cinnamon gtk-2.0 gtk-3.0 gtk-4.0 libadwaita-1.5 libadwaita-1.7 metacity-1)
REQUIRED=(index.theme cinnamon/cinnamon.css gtk-3.0/gtk.css gtk-4.0/gtk.css metacity-1/metacity-theme-3.xml)
# Tema-navn og kildemappe i repoet.
THEMES=("Mint-Ro|$REPO_DIR" "Mint-Ro-Dark|$REPO_DIR/Mint-Ro-Dark")

ACTIVATE=""; YES_ARG=()
usage() { sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --activate) ACTIVATE=tema ;;
    --activate-dark) ACTIVATE=tema-mork ;;
    --yes|-y) YES_ARG=(--yes) ;;
    -h|--help) usage; exit 0 ;;
    *) die "ukjent valg: $1 (se --help)" ;;
  esac
  shift
done

[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."
for t in "${THEMES[@]}"; do
  src="${t#*|}"
  for f in "${REQUIRED[@]}"; do
    [ -e "$src/$f" ] || die "mangler ${src#"$REPO_DIR"/}/$f i repoet. Er temaet bygget? (python3 -I src/build.py)"
  done
done
mkdir -p "$THEMES_DIR" || die "kunne ikke opprette $THEMES_DIR."

install_theme() {   # navn kildemappe
  local name="$1" src="$2" dest="$THEMES_DIR/$1" tmp old="" p
  # Overskriv bare en mappe som faktisk er dette temaet.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    grep -qx "Name=$name" "$dest/index.theme" 2>/dev/null \
      || die "$dest finnes allerede og er ikke $name. Flytt den og prøv igjen."
  fi
  tmp="$(mktemp -d "$THEMES_DIR/.$name.XXXXXX")" || die "kunne ikke lage midlertidig mappe."
  for p in "${PARTS[@]}"; do
    [ -e "$src/$p" ] || continue
    cp -R "$src/$p" "$tmp/" || { rm -rf "$tmp"; die "kopiering av $p feilet. Ingenting ble endret for $name."; }
  done
  find "$tmp" -name README.md -delete
  chmod -R u=rwX,go=rX "$tmp"
  if [ -d "$dest" ]; then old="$tmp.old"; mv "$dest" "$old" || { rm -rf "$tmp"; die "kunne ikke flytte gammel $name."; }; fi
  if ! mv "$tmp" "$dest"; then
    [ -n "$old" ] && mv "$old" "$dest"
    rm -rf "$tmp"
    die "installasjonen av $name feilet. Forrige versjon er beholdt."
  fi
  [ -z "$old" ] || rm -rf "$old"
  echo "Installert: $(printf '%s' "${dest/#"$HOME"/\~}")"
}

for t in "${THEMES[@]}"; do install_theme "${t%%|*}" "${t#*|}"; done

if [ -n "$ACTIVATE" ]; then
  exec "$SCRIPT_DIR/apply-profile.sh" "${YES_ARG[@]}" "$ACTIVATE"
fi
echo "Aktiver med:  $SCRIPT_DIR/apply-profile.sh tema        (lys)"
echo "         eller $SCRIPT_DIR/apply-profile.sh tema-mork   (mørk)"
echo "Du kan også velge Mint-Ro eller Mint-Ro-Dark i Systeminnstillinger → Temaer."
