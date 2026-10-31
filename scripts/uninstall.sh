#!/usr/bin/env bash
# uninstall.sh – fjerner Mint-Ro fra ~/.themes.
#
# Nekter hvis Mint-Ro er i bruk, slik at skrivebordet ikke står uten tema.
# Bytt tilbake først med restore.sh (eller velg et annet tema i Systeminnstillinger).
#
# Bruk:
#   ./scripts/uninstall.sh

set -uo pipefail

THEME_NAME="Mint-Ro"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "Feil: $*" >&2; exit 1; }

case "${1:-}" in -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;; "") ;; *) die "ukjent valg: $1" ;; esac
[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."

if command -v gsettings >/dev/null 2>&1; then
  in_use=()
  for k in "org.cinnamon.theme name" "org.cinnamon.desktop.interface gtk-theme" "org.cinnamon.desktop.wm.preferences theme"; do
    # shellcheck disable=SC2086
    v="$(gsettings get $k 2>/dev/null)" || continue
    [ "$v" = "'$THEME_NAME'" ] && in_use+=("$k")
  done
  if [ "${#in_use[@]}" -gt 0 ]; then
    echo "Mint-Ro er i bruk her:" >&2
    printf '  %s\n' "${in_use[@]}" >&2
    die "bytt tema først, for eksempel med: $SCRIPT_DIR/restore.sh"
  fi
fi

removed=0
for d in "$HOME/.themes/$THEME_NAME" "$HOME/.local/share/themes/$THEME_NAME"; do
  [ -e "$d" ] || continue
  grep -qx "Name=$THEME_NAME" "$d/index.theme" 2>/dev/null || { echo "Hopper over $d: ser ikke ut som Mint-Ro." >&2; continue; }
  rm -rf -- "$d" && { echo "Fjernet: ${d/#"$HOME"/\~}"; removed=1; }
done
[ "$removed" -eq 1 ] || echo "Mint-Ro var ikke installert."
echo "Sikkerhetskopier og Nemo-/panelinnstillinger er ikke rørt. Gå tilbake med restore.sh."
