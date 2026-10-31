#!/usr/bin/env bash
# restore.sh – gjenoppretter skrivebordsinnstillinger fra en sikkerhetskopi
# laget av map-mint.sh.
#
# Før noe endres, tas en ny sikkerhetskopi av dagens tilstand, slik at også
# gjenopprettingen kan angres.
#
# Bruk:
#   ./scripts/restore.sh                 # siste sikkerhetskopi
#   ./scripts/restore.sh <mappe>         # en bestemt sikkerhetskopi
#   ./scripts/restore.sh --list          # vis tilgjengelige sikkerhetskopier
#   ./scripts/restore.sh --dry-run [..]  # vis hva som ville skjedd
#   ./scripts/restore.sh --yes [..]      # ikke spør om bekreftelse

set -uo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${MINT_RO_BACKUP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mint-ro/backups}"
YES=0; DRY=0; LIST=0; SRC=""

# Bare disse stiene kan gjenopprettes (samme liste som map-mint.sh).
ALLOWED_FILES=" .config/gtk-3.0 .config/gtk-4.0 .gtkrc-2.0 .config/cinnamon .cinnamon/configs .config/xsettingsd .config/nemo .local/share/nemo .local/share/cinnamon "
ALLOWED_DCONF=" /org/cinnamon/ /org/nemo/ /org/x/ /org/gtk/settings/ /org/gnome/desktop/interface/ /org/gnome/desktop/wm/preferences/ "

usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1; shift ;;
    --dry-run|-n) DRY=1; shift ;;
    --list) LIST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "ukjent valg: $1 (se --help)" ;;
    *) [ -z "$SRC" ] || die "bare én mappe kan oppgis."; SRC="$1"; shift ;;
  esac
done

[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."

list_backups() {
  [ -d "$ROOT" ] || return 0
  find "$ROOT" -mindepth 2 -maxdepth 2 -name FORMAT -printf '%h\n' 2>/dev/null | sort
}

if [ "$LIST" -eq 1 ]; then
  out="$(list_backups)"
  if [ -n "$out" ]; then echo "Sikkerhetskopier i $ROOT:"; printf '%s\n' "$out" | sed 's/^/  /'
  else echo "Ingen sikkerhetskopier funnet i $ROOT."; fi
  exit 0
fi

if [ -z "$SRC" ]; then
  SRC="$(list_backups | grep -v -- '-for-gjenoppretting' | tail -1)"
  [ -n "$SRC" ] || die "fant ingen sikkerhetskopi i $ROOT. Kjør scripts/map-mint.sh først, eller oppgi en mappe."
fi
SRC="$(cd "$SRC" 2>/dev/null && pwd)" || die "finner ikke mappen."
[ -f "$SRC/FORMAT" ] && grep -q '^mint-ro-backup' "$SRC/FORMAT" \
  || die "$SRC ser ikke ut som en sikkerhetskopi fra map-mint.sh (mangler FORMAT)."

# ---------- Plan ----------
PLAN_DCONF=(); PLAN_FILES=()
if [ -s "$SRC/dconf/paths.tsv" ]; then
  while IFS=$'\t' read -r f p; do
    [[ "$ALLOWED_DCONF" == *" $p "* ]] || { echo "Hopper over ukjent dconf-sti: $p" >&2; continue; }
    [ -f "$SRC/dconf/$f" ] || { echo "Mangler $f, hopper over $p" >&2; continue; }
    PLAN_DCONF+=("$p"$'\t'"$f")
  done <"$SRC/dconf/paths.tsv"
fi
if [ -s "$SRC/files/manifest.tsv" ]; then
  while IFS=$'\t' read -r rel st; do
    [[ "$ALLOWED_FILES" == *" $rel "* ]] || { echo "Hopper over ukjent fil: $rel" >&2; continue; }
    PLAN_FILES+=("$rel"$'\t'"$st")
  done <"$SRC/files/manifest.tsv"
fi

echo "Gjenoppretter fra: $SRC"
echo
echo "dconf (nullstilles og lastes inn på nytt):"
if [ "${#PLAN_DCONF[@]}" -eq 0 ]; then echo "  (ingenting)"; fi
for e in "${PLAN_DCONF[@]}"; do echo "  ${e%%$'\t'*}"; done
echo "Filer i hjemmemappen:"
for e in "${PLAN_FILES[@]}"; do
  rel="${e%%$'\t'*}"; st="${e#*$'\t'}"
  case "$st" in
    copied)  echo "  ~/$rel  ← erstattes med kopien" ;;
    partial) echo "  ~/$rel  ← kopien legges over (var bare delvis kopiert)" ;;
    absent)  if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then echo "  ~/$rel  ← fjernes (fantes ikke da kopien ble tatt)"; else echo "  ~/$rel  (fantes ikke, ingen endring)"; fi ;;
  esac
done
echo

if [ "${#PLAN_DCONF[@]}" -gt 0 ] && ! have dconf; then
  die "dconf mangler, så innstillingene kan ikke gjenopprettes. Installer med: sudo apt install dconf-cli"
fi

if [ "$DRY" -eq 1 ]; then echo "Prøvekjøring – ingenting ble endret."; exit 0; fi

if [ "$YES" -ne 1 ]; then
  [ -t 0 ] || die "ingen terminal for bekreftelse. Bruk --yes for å fortsette uten spørsmål."
  read -r -p "Fortsette? [j/N] " ans
  case "$ans" in j|J|ja|Ja|y|Y|yes) ;; *) echo "Avbrutt. Ingenting ble endret."; exit 0 ;; esac
fi

# ---------- Sikkerhetskopi av dagens tilstand ----------
PRE="$("$SCRIPT_DIR/map-mint.sh" --quiet --label for-gjenoppretting 2>/dev/null | tail -1)"
[ -n "$PRE" ] && [ -f "$PRE/FORMAT" ] || die "kunne ikke ta sikkerhetskopi av dagens tilstand. Ingenting ble endret."
echo "Dagens tilstand er lagret i: $PRE"

# ---------- Gjenoppretting ----------
fail=0
for e in "${PLAN_DCONF[@]}"; do
  p="${e%%$'\t'*}"; f="${e#*$'\t'}"
  if dconf reset -f "$p" && dconf load "$p" <"$SRC/dconf/$f"; then echo "  dconf $p gjenopprettet"
  else echo "  FEIL: dconf $p" >&2; fail=1; fi
done

for e in "${PLAN_FILES[@]}"; do
  rel="${e%%$'\t'*}"; st="${e#*$'\t'}"; dst="$HOME/$rel"
  case "$st" in
    copied)
      rm -rf -- "$dst" && mkdir -p "$(dirname "$dst")" && cp -a "$SRC/files/$rel" "$dst" \
        && echo "  ~/$rel gjenopprettet" || { echo "  FEIL: ~/$rel" >&2; fail=1; } ;;
    partial)
      if [ -d "$SRC/files/$rel" ]; then
        mkdir -p "$dst" && cp -a "$SRC/files/$rel/." "$dst/"
      else
        mkdir -p "$(dirname "$dst")" && cp -a "$SRC/files/$rel" "$dst"
      fi && echo "  ~/$rel lagt tilbake (delvis kopi)" || { echo "  FEIL: ~/$rel" >&2; fail=1; } ;;
    absent)
      if [ -e "$dst" ] || [ -L "$dst" ]; then rm -rf -- "$dst" && echo "  ~/$rel fjernet" || { echo "  FEIL: ~/$rel" >&2; fail=1; }; fi ;;
  esac
done

echo
if [ "$fail" -eq 0 ]; then echo "Ferdig. Logg ut og inn igjen, eller trykk Ctrl+Alt+Esc for å laste Cinnamon på nytt."
else echo "Ferdig med feil. Dagens tilstand før gjenoppretting ligger i: $PRE" >&2; exit 1; fi
echo "Angre gjenopprettingen med: $SCRIPT_DIR/restore.sh \"$PRE\""
