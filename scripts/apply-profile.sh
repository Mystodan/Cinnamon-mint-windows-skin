#!/usr/bin/env bash
# apply-profile.sh – setter Mint-Ro-oppsett for Nemo og oppgavelinjen.
#
# Endrer bare innstillinger (gsettings), Nemo-handlinger i ~/.local/share/nemo/actions
# og kalender-appletens egne innstillinger. Viser alltid hva som endres, ber om
# bekreftelse og tar sikkerhetskopi med map-mint.sh først. Alt kan angres med
# restore.sh. Krever ikke sudo, installerer ingen pakker og endrer ikke tema.
#
# Bruk:
#   ./scripts/apply-profile.sh nemo                  # Nemo som Windows 11-filutforsker
#   ./scripts/apply-profile.sh oppgavelinje          # sentrert oppgavelinje
#   ./scripts/apply-profile.sh oppgavelinje-venstre  # samme, venstrestilt
#   ./scripts/apply-profile.sh alt                   # nemo + oppgavelinje
#   ./scripts/apply-profile.sh --dry-run <profil>    # vis bare hva som ville skjedd
#   ./scripts/apply-profile.sh --yes <profil>        # ikke spør om bekreftelse

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HELPER="$SCRIPT_DIR/lib/profile.py"
ACTIONS_SRC="$REPO_DIR/nemo/actions"
ACTIONS_DST="$HOME/.local/share/nemo/actions"
PANEL_HEIGHT=48

YES=0; DRY=0; DO_NEMO=0; DO_TASKBAR=""

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
py() { python3 -I "$HELPER" "$@"; }

[ $# -gt 0 ] || { usage; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --dry-run|-n) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    nemo) DO_NEMO=1 ;;
    oppgavelinje) DO_TASKBAR=center ;;
    oppgavelinje-venstre) DO_TASKBAR=left ;;
    alt) DO_NEMO=1; DO_TASKBAR=center ;;
    *) die "ukjent profil eller valg: $1 (se --help)" ;;
  esac
  shift
done
[ "$DO_NEMO" -eq 1 ] || [ -n "$DO_TASKBAR" ] || die "velg minst én profil (se --help)."

# ---------- Forutsetninger ----------
[ "$(id -u)" -ne 0 ] || die "kjør som vanlig bruker, ikke med sudo."
have gsettings || die "gsettings mangler."
have python3 || die "python3 mangler."
[ -r "$HELPER" ] || die "fant ikke $HELPER. Kjør skriptet fra repoet."
if [ "$DRY" -eq 0 ]; then
  have dconf || die "dconf mangler, så sikkerhetskopi er ikke mulig. Installer med: sudo apt install dconf-cli"
fi

SCHEMAS="$(gsettings list-schemas 2>/dev/null)"
has_schema() { grep -qxF -- "$1" <<<"$SCHEMAS"; }
if [ "$DO_NEMO" -eq 1 ]; then
  has_schema org.nemo.preferences && has_schema org.nemo.list-view \
    || die "Nemos innstillinger finnes ikke. Er Nemo installert?"
fi
if [ -n "$DO_TASKBAR" ]; then
  has_schema org.cinnamon || die "Cinnamons innstillinger finnes ikke. Kjøres dette i Cinnamon?"
fi

# ---------- Plan ----------
# Hver gsettings-endring: «skjema<TAB>nøkkel<TAB>gammel<TAB>ny»
SETS=(); NOTES=(); FILES=(); CAL_FILE=""; CAL_CHANGES=""
add_set() {   # skjema nøkkel ny-verdi
  local old; old="$(gsettings get "$1" "$2" 2>/dev/null)" || die "kunne ikke lese $1 $2"
  [ "$old" = "$3" ] || SETS+=("$1"$'\t'"$2"$'\t'"$old"$'\t'"$3")
}

if [ "$DO_NEMO" -eq 1 ]; then
  add_set org.nemo.preferences show-reload-icon-toolbar true
  cols="$(gsettings get org.nemo.list-view default-column-order)"
  new="$(py columns "$cols")" || die "kunne ikke beregne kolonnerekkefølge."
  add_set org.nemo.list-view default-column-order "$new"
  vis="$(gsettings get org.nemo.list-view default-visible-columns)"
  new="$(py columns "$vis")" || die "kunne ikke beregne synlige kolonner."
  add_set org.nemo.list-view default-visible-columns "$new"
  zoom="$(gsettings get org.nemo.list-view default-zoom-level)"
  case "$zoom" in "'smallest'"|"'smaller'") add_set org.nemo.list-view default-zoom-level "'small'" ;; esac

  for f in "$ACTIONS_SRC"/*; do
    [ -f "$f" ] || continue
    dst="$ACTIONS_DST/$(basename "$f")"
    if ! cmp -s "$f" "$dst" 2>/dev/null; then FILES+=("$f"); fi
  done
fi

if [ -n "$DO_TASKBAR" ]; then
  cur="$(gsettings get org.cinnamon enabled-applets)"
  new="$(py taskbar "$DO_TASKBAR" "$cur")" || die "kunne ikke beregne nytt paneloppsett."
  add_set org.cinnamon enabled-applets "$new"
  gone="$(py removed "$cur" "$new")"
  [ -z "$gone" ] || NOTES+=("Fjernes fra panelet: $gone (favorittene ligger fortsatt i menyen)")

  pid="$(py target-panel "$cur")" || die "fant ikke panelet med menyknappen."
  heights="$(gsettings get org.cinnamon panels-height)"
  new="$(py panels-height "$heights" "$pid" "$PANEL_HEIGHT")" || die "kunne ikke beregne panelhøyde."
  add_set org.cinnamon panels-height "$new"

  cal_id="$(py instance-id "$cur" calendar@cinnamon.org "panel$pid")"
  if [ -n "$cal_id" ]; then
    f="$HOME/.config/cinnamon/spices/calendar@cinnamon.org/$cal_id.json"
    if [ -f "$f" ]; then
      use24="$(gsettings get org.cinnamon.desktop.interface clock-use-24h 2>/dev/null || echo true)"
      if [ "$use24" = "false" ]; then fmt='%l:%M %p%n%x'; else fmt='%H:%M%n%x'; fi
      CAL_CHANGES="$(py calendar "$f" "$fmt" '%A %e. %B %Y' 2>&1)" || die "kalenderinnstillingene kunne ikke leses: $CAL_CHANGES"
      [ -z "$CAL_CHANGES" ] || CAL_FILE="$f"
    else
      NOTES+=("Klokke i to linjer hoppes over: fant ikke ${f/#"$HOME"/\~}")
    fi
  else
    NOTES+=("Klokke i to linjer hoppes over: fant ikke kalender-appleten i panelet")
  fi
fi

# ---------- Vis plan ----------
if [ "${#SETS[@]}" -eq 0 ] && [ "${#FILES[@]}" -eq 0 ] && [ -z "$CAL_FILE" ]; then
  echo "Ingenting å endre – profilen er allerede i bruk."
  for n in "${NOTES[@]}"; do echo "Merk: $n"; done
  exit 0
fi

echo "Disse endringene gjøres:"
for s in "${SETS[@]}"; do
  IFS=$'\t' read -r schema key old new <<<"$s"
  echo "  $schema $key"
  echo "      nå:  $old"
  echo "      ny:  $new"
done
for f in "${FILES[@]}"; do echo "  Nemo-handling: $(basename "$f") → ${ACTIONS_DST/#"$HOME"/\~}/"; done
if [ -n "$CAL_FILE" ]; then
  echo "  Klokke (${CAL_FILE/#"$HOME"/\~}):"
  while IFS= read -r l; do echo "      $l"; done <<<"$CAL_CHANGES"
fi
for n in "${NOTES[@]}"; do echo "Merk: $n"; done
echo

if [ "$DRY" -eq 1 ]; then echo "Prøvekjøring – ingenting ble endret."; exit 0; fi

if [ "$YES" -ne 1 ]; then
  [ -t 0 ] || die "ingen terminal for bekreftelse. Bruk --yes for å fortsette uten spørsmål."
  read -r -p "Fortsette? [j/N] " ans
  case "$ans" in j|J|ja|Ja|y|Y|yes) ;; *) echo "Avbrutt. Ingenting ble endret."; exit 0 ;; esac
fi

# ---------- Sikkerhetskopi ----------
BK="$("$SCRIPT_DIR/map-mint.sh" --quiet --label foer-profil 2>/dev/null | tail -1)"
[ -n "$BK" ] && [ -s "$BK/dconf/paths.tsv" ] || die "sikkerhetskopien feilet. Ingenting ble endret."
echo "Sikkerhetskopi: $BK"

# ---------- Utfør ----------
fail=0
for s in "${SETS[@]}"; do
  IFS=$'\t' read -r schema key old new <<<"$s"
  if gsettings set "$schema" "$key" "$new"; then echo "  ✓ $schema $key"
  else echo "  ✗ $schema $key" >&2; fail=1; fi
done
if [ "${#FILES[@]}" -gt 0 ]; then
  mkdir -p "$ACTIONS_DST" || fail=1
  for f in "${FILES[@]}"; do
    mode=644; [ -x "$f" ] && mode=755
    if install -m "$mode" "$f" "$ACTIONS_DST/"; then echo "  ✓ $(basename "$f")"
    else echo "  ✗ $(basename "$f")" >&2; fail=1; fi
  done
fi
if [ -n "$CAL_FILE" ]; then
  if py calendar "$CAL_FILE" "$fmt" '%A %e. %B %Y' --write >/dev/null; then echo "  ✓ klokke i to linjer"
  else echo "  ✗ klokke" >&2; fail=1; fi
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "Noe feilet. Gå tilbake med: $SCRIPT_DIR/restore.sh \"$BK\"" >&2
  exit 1
fi
echo "Ferdig. Lukk og åpne Nemo på nytt for å se endringene der."
[ -z "$DO_TASKBAR" ] || echo "Panelet oppdateres med en gang. Trykk Ctrl+Alt+Esc hvis klokka ikke endrer seg."
echo "Angre alt med: $SCRIPT_DIR/restore.sh \"$BK\""
