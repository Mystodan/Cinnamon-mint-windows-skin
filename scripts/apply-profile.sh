#!/usr/bin/env bash
# apply-profile.sh – setter Mint-Ro-oppsett for Nemo, oppgavelinjen, startmenyen og temaet.
#
# Endrer bare innstillinger (gsettings), Nemo-handlinger i ~/.local/share/nemo/actions
# og innstillingene til panelets egne applets (klokke og meny). Viser alltid hva som
# endres, ber om bekreftelse og tar sikkerhetskopi med map-mint.sh først. Alt kan angres
# med restore.sh. Krever ikke sudo og installerer ingen pakker. Temaet må være
# installert med install.sh før profilene «tema» og «tema-mork» kan brukes.
#
# Bruk:
#   ./scripts/apply-profile.sh nemo                  # Nemo som Windows 11-filutforsker
#   ./scripts/apply-profile.sh oppgavelinje          # sentrert oppgavelinje
#   ./scripts/apply-profile.sh oppgavelinje-venstre  # samme, venstrestilt
#   ./scripts/apply-profile.sh meny                  # startmeny: søk øverst, ryddigere liste
#   ./scripts/apply-profile.sh tema                  # aktiver Mint-Ro (lys)
#   ./scripts/apply-profile.sh tema-mork             # aktiver Mint-Ro-Dark (mørk)
#   ./scripts/apply-profile.sh alt                   # nemo + oppgavelinje + meny
#   ./scripts/apply-profile.sh --dry-run <profil>    # vis bare hva som ville skjedd
#   ./scripts/apply-profile.sh --yes <profil>        # ikke spør om bekreftelse

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HELPER="$SCRIPT_DIR/lib/profile.py"
ACTIONS_SRC="$REPO_DIR/nemo/actions"
ACTIONS_DST="$HOME/.local/share/nemo/actions"
SPICES_CFG="$HOME/.config/cinnamon/spices"
PANEL_HEIGHT=48

YES=0; DRY=0; DO_NEMO=0; DO_TASKBAR=""; DO_MENU=0; DO_THEME=""

usage() { sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "Feil: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
py() { python3 -I "$HELPER" "$@"; }
tilde() { printf '%s' "${1/#"$HOME"/\~}"; }

[ $# -gt 0 ] || { usage; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --dry-run|-n) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    nemo) DO_NEMO=1 ;;
    oppgavelinje) DO_TASKBAR=center ;;
    oppgavelinje-venstre) DO_TASKBAR=left ;;
    meny) DO_MENU=1 ;;
    tema) DO_THEME=light ;;
    tema-mork|tema-mørk) DO_THEME=dark ;;
    alt) DO_NEMO=1; DO_TASKBAR=center; DO_MENU=1 ;;
    *) die "ukjent profil eller valg: $1 (se --help)" ;;
  esac
  shift
done
[ "$DO_NEMO" -eq 1 ] || [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ] || [ -n "$DO_THEME" ] \
  || die "velg minst én profil (se --help)."

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
if [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ]; then
  has_schema org.cinnamon || die "Cinnamons innstillinger finnes ikke. Kjøres dette i Cinnamon?"
fi
THEME_NAME=""
if [ -n "$DO_THEME" ]; then
  if [ "$DO_THEME" = "dark" ]; then THEME_NAME="Mint-Ro-Dark"; else THEME_NAME="Mint-Ro"; fi
  for sc in org.cinnamon.theme org.cinnamon.desktop.interface org.cinnamon.desktop.wm.preferences; do
    has_schema "$sc" || die "innstillingen $sc finnes ikke. Kjøres dette i Cinnamon?"
  done
  theme_dir=""
  for d in "$HOME/.themes/$THEME_NAME" "$HOME/.local/share/themes/$THEME_NAME"; do
    [ -f "$d/index.theme" ] && [ -f "$d/cinnamon/cinnamon.css" ] && { theme_dir="$d"; break; }
  done
  [ -n "$theme_dir" ] || die "$THEME_NAME er ikke installert. Kjør først: $SCRIPT_DIR/install.sh"
fi

# ---------- Plan ----------
# gsettings-endringer: «skjema<TAB>nøkkel<TAB>gammel<TAB>ny»
SETS=(); NOTES=(); FILES=()
# Applet-endringer: parallelle lister med etikett, fil, nøkkel=verdi-par (skilt med \x1f) og endringer.
JOB_LABEL=(); JOB_FILE=(); JOB_PAIRS=(); JOB_CHANGES=()
US=$'\x1f'

add_set() {   # skjema nøkkel ny-verdi
  local old; old="$(gsettings get "$1" "$2" 2>/dev/null)" || die "kunne ikke lese $1 $2"
  [ "$old" = "$3" ] || SETS+=("$1"$'\t'"$2"$'\t'"$old"$'\t'"$3")
}

# applet_file UUID PANEL ETIKETT -> setter APPLET_PATH, eller forklarer i NOTES og returnerer 1.
# (Kalles ikke i $(...), så NOTES overlever.)
APPLET_PATH=""
applet_file() {
  local uuid="$1" panel="$2" label="$3" id
  APPLET_PATH=""
  id="$(py instance-id "$APPLETS" "$uuid" "$panel")"
  if [ -z "$id" ]; then NOTES+=("$label hoppes over: fant ikke $uuid i panelet"); return 1; fi
  if [ ! -f "$SPICES_CFG/$uuid/$id.json" ]; then
    NOTES+=("$label hoppes over: fant ikke $(tilde "$SPICES_CFG/$uuid/$id.json")"); return 1
  fi
  APPLET_PATH="$SPICES_CFG/$uuid/$id.json"
}

# add_applet ETIKETT FIL nøkkel=json ...
add_applet() {
  local label="$1" file="$2"; shift 2
  local changes
  changes="$(py applet "$file" "$@" 2>&1)" || die "$label: $changes"
  [ -n "$changes" ] || return 0
  local IFS="$US"
  JOB_LABEL+=("$label"); JOB_FILE+=("$file"); JOB_PAIRS+=("$*"); JOB_CHANGES+=("$changes")
}

if [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ]; then
  APPLETS="$(gsettings get org.cinnamon enabled-applets)"
  PANEL_ID="$(py target-panel "$APPLETS")" || die "fant ikke panelet med menyknappen."
fi

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
  new="$(py taskbar "$DO_TASKBAR" "$APPLETS")" || die "kunne ikke beregne nytt paneloppsett."
  add_set org.cinnamon enabled-applets "$new"
  gone="$(py removed "$APPLETS" "$new")"
  [ -z "$gone" ] || NOTES+=("Fjernes fra panelet: $gone (favorittene ligger fortsatt i menyen)")

  heights="$(gsettings get org.cinnamon panels-height)"
  new="$(py panels-height "$heights" "$PANEL_ID" "$PANEL_HEIGHT")" || die "kunne ikke beregne panelhøyde."
  add_set org.cinnamon panels-height "$new"

  if applet_file calendar@cinnamon.org "panel$PANEL_ID" "Klokke i to linjer"; then
    use24="$(gsettings get org.cinnamon.desktop.interface clock-use-24h 2>/dev/null || echo true)"
    if [ "$use24" = "false" ]; then fmt='%l:%M %p%n%x'; else fmt='%H:%M%n%x'; fi
    add_applet "Klokke" "$APPLET_PATH" use-custom-format=true \
      "custom-format=\"$fmt\"" 'custom-tooltip-format="%A %e. %B %Y"'
  fi
fi

if [ "$DO_MENU" -eq 1 ]; then
  if applet_file menu@cinnamon.org "panel$PANEL_ID" "Startmenyen"; then
    add_applet "Startmeny" "$APPLET_PATH" 'search-position="top"' show-description=false
  fi
fi

if [ -n "$DO_THEME" ]; then
  add_set org.cinnamon.theme name "'$THEME_NAME'"
  add_set org.cinnamon.desktop.interface gtk-theme "'$THEME_NAME'"
  add_set org.cinnamon.desktop.wm.preferences theme "'$THEME_NAME'"
  if has_schema org.x.apps.portal; then
    scheme="$(gsettings get org.x.apps.portal color-scheme 2>/dev/null)"
    if [ "$DO_THEME" = "dark" ]; then
      add_set org.x.apps.portal color-scheme "'prefer-dark'"
    elif [ "$scheme" = "'prefer-dark'" ]; then
      add_set org.x.apps.portal color-scheme "'default'"
    fi
  fi
  NOTES+=("Ikoner, markør og skrift endres ikke.")
fi

# ---------- Vis plan ----------
if [ "${#SETS[@]}" -eq 0 ] && [ "${#FILES[@]}" -eq 0 ] && [ "${#JOB_FILE[@]}" -eq 0 ]; then
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
for f in "${FILES[@]}"; do echo "  Nemo-handling: $(basename "$f") → $(tilde "$ACTIONS_DST")/"; done
for i in "${!JOB_FILE[@]}"; do
  echo "  ${JOB_LABEL[$i]} ($(tilde "${JOB_FILE[$i]}")):"
  while IFS= read -r l; do echo "      $l"; done <<<"${JOB_CHANGES[$i]}"
done
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
for i in "${!JOB_FILE[@]}"; do
  IFS="$US" read -r -a pairs <<<"${JOB_PAIRS[$i]}"
  if py applet "${JOB_FILE[$i]}" --write "${pairs[@]}" >/dev/null; then echo "  ✓ ${JOB_LABEL[$i]}"
  else echo "  ✗ ${JOB_LABEL[$i]}" >&2; fail=1; fi
done

echo
if [ "$fail" -ne 0 ]; then
  echo "Noe feilet. Gå tilbake med: $SCRIPT_DIR/restore.sh \"$BK\"" >&2
  exit 1
fi
echo "Ferdig."
[ "$DO_NEMO" -eq 0 ] || echo "Lukk og åpne Nemo på nytt for å se endringene der."
[ -z "$DO_TASKBAR" ] && [ "$DO_MENU" -eq 0 ] || echo "Panel og meny oppdateres med en gang. Trykk Ctrl+Alt+Esc hvis noe ikke endrer seg."
[ -z "$DO_THEME" ] || echo "Temaet tas i bruk med en gang. Allerede åpne programmer kan trenge omstart."
echo "Angre alt med: $SCRIPT_DIR/restore.sh \"$BK\""
