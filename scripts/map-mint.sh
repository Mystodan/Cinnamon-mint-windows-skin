#!/usr/bin/env bash
# map-mint.sh – kartlegger Linux Mint/Cinnamon-miljøet og tar en datert
# sikkerhetskopi av skrivebordsinnstillingene.
#
# Skriptet LESER system og innstillinger. Det endrer ikke aktivt tema,
# installerer ingenting, overskriver ingen konfigurasjon og trenger ikke sudo.
# Det eneste det skriver, er en ny mappe med sikkerhetskopi og rapport.
#
# Bruk:
#   ./scripts/map-mint.sh                 # kartlegg og ta sikkerhetskopi
#   ./scripts/map-mint.sh --dir <mappe>   # lagre et annet sted
#   ./scripts/map-mint.sh --label <navn>  # legg til en merkelapp i mappenavnet
#   ./scripts/map-mint.sh --quiet         # skriv bare stien til sikkerhetskopien
#   ./scripts/map-mint.sh --help

set -uo pipefail
umask 077   # sikkerhetskopien kan inneholde personlige innstillinger

VERSION="1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/mint-ro/backups"
ROOT="${MINT_RO_BACKUP_DIR:-$DEFAULT_ROOT}"
LABEL=""
QUIET=0

usage() { sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)   [ $# -ge 2 ] || { echo "Feil: --dir trenger en mappe." >&2; exit 2; }; ROOT="$2"; shift 2 ;;
    --label) [ $# -ge 2 ] || { echo "Feil: --label trenger et navn." >&2; exit 2; }; LABEL="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Ukjent valg: $1 (se --help)" >&2; exit 2 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  echo "Advarsel: kjøres som root. Da kartlegges root-brukerens innstillinger, ikke dine." >&2
  echo "Kjør skriptet som vanlig bruker, uten sudo." >&2
  exit 1
fi

say()  { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
warn() { printf 'Merk: %s\n' "$*" >&2; WARNINGS+=("$*"); }
have() { command -v "$1" >/dev/null 2>&1; }
WARNINGS=()

# ---------- Mappe for sikkerhetskopi ----------
STAMP="$(date +%Y%m%d-%H%M%S)"
SAFE_LABEL="$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9_-' '-' )"
DEST="$ROOT/$STAMP${SAFE_LABEL:+-$SAFE_LABEL}"
n=1; while [ -e "$DEST" ]; do DEST="$ROOT/$STAMP${SAFE_LABEL:+-$SAFE_LABEL}-$n"; n=$((n+1)); done

if ! mkdir -p "$DEST/dconf" "$DEST/files" 2>/dev/null; then
  echo "Feil: kunne ikke opprette $DEST. Sjekk skrivetilgang, eller velg en annen mappe med --dir." >&2
  exit 1
fi
REPORT="$DEST/rapport.md"

# ---------- Hjelpefunksjoner for kartlegging ----------
# Returnerer verdien eller en lesbar forklaring, aldri en feil.
gs() {
  if ! have gsettings; then echo "(gsettings mangler)"; return; fi
  if ! gsettings list-schemas 2>/dev/null | grep -qx "$1"; then echo "(skjema $1 finnes ikke)"; return; fi
  gsettings get "$1" "$2" 2>/dev/null || echo "(nøkkel $2 finnes ikke)"
}

pkgver() {
  local p v
  if ! have dpkg-query; then echo "(dpkg-query mangler)"; return; fi
  for p in "$@"; do
    v="$(dpkg-query -W -f='${db:Status-Abbrev}|${Version}' "$p" 2>/dev/null)" || continue
    case "$v" in ii*) echo "${v#*|} ($p)"; return ;; esac
  done
  echo "(ikke installert)"
}

cinnamon_version() {
  local v=""
  have cinnamon && v="$(timeout 5 cinnamon --version 2>/dev/null | head -1)"
  [ -n "$v" ] && { echo "$v"; return; }
  pkgver cinnamon
}

gtk3_version() {
  local v
  v="$(pkgver libgtk-3-0t64 libgtk-3-0)"
  if [[ "$v" == \(* ]] && have pkg-config; then
    v="$(pkg-config --modversion gtk+-3.0 2>/dev/null || echo "$v")"
  fi
  echo "$v"
}

list_dirs() {
  if [ -d "$1" ]; then
    local out; out="$(find "$1" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -printf '%f\n' 2>/dev/null | sort)"
    if [ -n "$out" ]; then printf '%s\n' "$out" | sed 's/^/- /'; else echo "- (tom)"; fi
  else
    echo "- (mappen finnes ikke)"
  fi
}

mint_info() {
  if [ -r /etc/linuxmint/info ]; then
    grep -E '^(RELEASE|CODENAME|EDITION|DESCRIPTION)=' /etc/linuxmint/info
  elif [ -r /etc/os-release ]; then
    echo "Fant ikke /etc/linuxmint/info – dette ser ikke ut som Linux Mint."
    grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  else
    echo "Fant verken /etc/linuxmint/info eller /etc/os-release."
  fi
}

# ---------- Sikkerhetskopi: dconf ----------
# Stiene som påvirker utseende og skrivebordsoppførsel.
DCONF_PATHS=(
  /org/cinnamon/
  /org/nemo/
  /org/x/
  /org/gtk/settings/
  /org/gnome/desktop/interface/
  /org/gnome/desktop/wm/preferences/
)
: >"$DEST/dconf/paths.tsv"
dconf_status="ikke tatt"
if have dconf; then
  dconf_status="tatt"
  for p in "${DCONF_PATHS[@]}"; do
    f="$(printf '%s' "${p#/}" | sed 's#/$##; s#/#.#g').dconf"
    if dconf dump "$p" >"$DEST/dconf/$f" 2>/dev/null; then
      if [ -s "$DEST/dconf/$f" ]; then
        printf '%s\t%s\n' "$f" "$p" >>"$DEST/dconf/paths.tsv"
      else
        rm -f "$DEST/dconf/$f"   # stien har ingen lagrede verdier
      fi
    else
      rm -f "$DEST/dconf/$f"; warn "dconf dump av $p feilet."
    fi
  done
  # Full dump som referanse. Gjenopprettingsskriptet bruker den ikke automatisk.
  dconf dump / >"$DEST/dconf/full.dconf" 2>/dev/null || warn "Full dconf dump feilet."
else
  dconf_status="hoppet over – dconf mangler (pakken dconf-cli)"
  warn "dconf er ikke installert. Innstillinger ble ikke sikkerhetskopiert. Installer med: sudo apt install dconf-cli"
fi

# ---------- Sikkerhetskopi: filer ----------
# Hver linje: relativ sti fra $HOME. Status skrives til files/manifest.tsv:
#   copied   – fantes og ble kopiert
#   absent   – fantes ikke da kopien ble tatt
FILE_PATHS=(
  .config/gtk-3.0
  .config/gtk-4.0
  .gtkrc-2.0
  .config/cinnamon
  .cinnamon/configs
  .config/xsettingsd
)
: >"$DEST/files/manifest.tsv"
for rel in "${FILE_PATHS[@]}"; do
  src="$HOME/$rel"
  if [ -e "$src" ] || [ -L "$src" ]; then
    mkdir -p "$DEST/files/$(dirname "$rel")"
    if cp -a "$src" "$DEST/files/$rel" 2>/dev/null; then
      printf '%s\tcopied\n' "$rel" >>"$DEST/files/manifest.tsv"
    else
      warn "Kunne ikke kopiere ~/$rel fullstendig."
      printf '%s\tpartial\n' "$rel" >>"$DEST/files/manifest.tsv"
    fi
  else
    printf '%s\tabsent\n' "$rel" >>"$DEST/files/manifest.tsv"
  fi
done

# ---------- Rapport ----------
{
  echo "# Kartlegging av $(hostname 2>/dev/null || echo maskin)"
  echo
  echo "- Tidspunkt: $(date -Iseconds)"
  echo "- Bruker: $(id -un)"
  echo "- map-mint.sh versjon $VERSION"
  echo "- Økt: ${XDG_SESSION_TYPE:-ukjent} / ${XDG_CURRENT_DESKTOP:-ukjent}"
  echo
  echo "## System"
  echo '```'
  mint_info
  uname -sr 2>/dev/null
  echo '```'
  echo
  echo "## Versjoner"
  echo
  echo "| Komponent | Versjon |"
  echo "| --- | --- |"
  echo "| Linux Mint | $( (grep -E '^RELEASE=' /etc/linuxmint/info 2>/dev/null || echo 'RELEASE=(ukjent)') | cut -d= -f2) |"
  echo "| Cinnamon | $(cinnamon_version) |"
  echo "| Muffin | $(pkgver muffin) |"
  echo "| GTK 3 | $(gtk3_version) |"
  echo "| GTK 4 | $(pkgver libgtk-4-1) |"
  echo "| libadwaita | $(pkgver libadwaita-1-0) |"
  echo "| XApp | $(pkgver libxapp1) |"
  echo
  echo "## Aktive temaer og utseende"
  echo
  echo "| Innstilling | Verdi |"
  echo "| --- | --- |"
  echo "| Skrivebord (Cinnamon) | $(gs org.cinnamon.theme name) |"
  echo "| Programmer (GTK) | $(gs org.cinnamon.desktop.interface gtk-theme) |"
  echo "| Vindusrammer | $(gs org.cinnamon.desktop.wm.preferences theme) |"
  echo "| Ikoner | $(gs org.cinnamon.desktop.interface icon-theme) |"
  echo "| Markør | $(gs org.cinnamon.desktop.interface cursor-theme) |"
  echo "| Markørstørrelse | $(gs org.cinnamon.desktop.interface cursor-size) |"
  echo "| Skrift | $(gs org.cinnamon.desktop.interface font-name) |"
  echo "| Skalering | $(gs org.cinnamon.desktop.interface scaling-factor) |"
  echo "| Fargeskjema (portal) | $(gs org.x.apps.portal color-scheme) |"
  echo "| Vindusknapper | $(gs org.cinnamon.desktop.wm.preferences button-layout) |"
  echo
  echo "## Panel og applets"
  echo '```'
  echo "panels-enabled:   $(gs org.cinnamon panels-enabled)"
  echo "panels-height:    $(gs org.cinnamon panels-height)"
  echo "panel-zone-icon-sizes: $(gs org.cinnamon panel-zone-icon-sizes)"
  echo "enabled-applets:"
  applets="$(gs org.cinnamon enabled-applets)"
  case "$applets" in
    \[*) printf '%s\n' "$applets" | tr ',' '\n' | sed "s/[][' ]//g; /^$/d; s/^/  /" ;;
    *)   echo "  $applets" ;;
  esac
  echo "enabled-extensions: $(gs org.cinnamon enabled-extensions)"
  echo '```'
  echo
  echo "## Relevante pakker"
  echo
  echo "| Pakke | Versjon |"
  echo "| --- | --- |"
  for p in mint-themes mint-y-icons mint-x-icons mint-l-icons mint-l-theme \
           adwaita-icon-theme papirus-icon-theme dmz-cursor-theme bibata-cursor-theme \
           gnome-themes-extra gtk2-engines-murrine sassc dconf-cli; do
    echo "| $p | $(pkgver "$p") |"
  done
  echo
  echo "## Installerte temaer"
  echo "### ~/.themes"; list_dirs "$HOME/.themes"
  echo "### ~/.local/share/themes"; list_dirs "$HOME/.local/share/themes"
  echo "### /usr/share/themes"; list_dirs /usr/share/themes
  echo
  echo "## Installerte ikoner og markører"
  echo "### ~/.icons"; list_dirs "$HOME/.icons"
  echo "### ~/.local/share/icons"; list_dirs "$HOME/.local/share/icons"
  echo "### /usr/share/icons"; list_dirs /usr/share/icons
  echo
  echo "## Brukerens GTK-overstyringer"
  for rel in .config/gtk-3.0/gtk.css .config/gtk-3.0/settings.ini .config/gtk-4.0/gtk.css .config/gtk-4.0/settings.ini; do
    if [ -e "$HOME/$rel" ]; then echo "- \`~/$rel\` finnes ($(wc -l <"$HOME/$rel" 2>/dev/null || echo '?') linjer)"
    else echo "- \`~/$rel\` finnes ikke"; fi
  done
  echo
  echo "## Grafikk og skjerm"
  echo '```'
  if have lspci; then lspci 2>/dev/null | grep -Ei 'vga|3d|display' || echo "Ingen skjermkort funnet med lspci."
  else echo "lspci mangler (pakken pciutils)."; fi
  if have xrandr && [ -n "${DISPLAY:-}" ]; then xrandr --current 2>/dev/null | grep -E ' connected' || true
  else echo "xrandr ikke tilgjengelig eller ingen grafisk økt."; fi
  echo '```'
  echo
  echo "## Sikkerhetskopi"
  echo
  echo "- dconf: $dconf_status"
  if [ -s "$DEST/dconf/paths.tsv" ]; then
    while IFS=$'\t' read -r f p; do echo "  - \`$p\` → \`dconf/$f\`"; done <"$DEST/dconf/paths.tsv"
  fi
  echo "- Filer:"
  while IFS=$'\t' read -r rel st; do
    case "$st" in
      copied)  echo "  - \`~/$rel\` kopiert" ;;
      partial) echo "  - \`~/$rel\` delvis kopiert" ;;
      absent)  echo "  - \`~/$rel\` fantes ikke" ;;
    esac
  done <"$DEST/files/manifest.tsv"
  if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo
    echo "## Advarsler"
    for w in "${WARNINGS[@]}"; do echo "- $w"; done
  fi
} >"$REPORT"

# ---------- Instruksjoner for gjenoppretting ----------
cat >"$DEST/GJENOPPRETT.txt" <<EOF
Sikkerhetskopi tatt $(date -Iseconds) av map-mint.sh.

Gjenopprett med skriptet fra repoet:
  ./scripts/restore.sh "$DEST"

Eller manuelt, én dconf-sti om gangen (eksempel for Cinnamon):
  dconf reset -f /org/cinnamon/
  dconf load /org/cinnamon/ < "$DEST/dconf/org.cinnamon.dconf"

Filer ligger under files/ med samme relative sti som i hjemmemappen.
files/manifest.tsv viser hva som fantes da kopien ble tatt.
Logg ut og inn igjen (eller trykk Ctrl+Alt+Esc) etter gjenoppretting.
EOF

printf 'mint-ro-backup\t%s\n' "$VERSION" >"$DEST/FORMAT"

# ---------- Oppsummering ----------
if [ "$QUIET" -eq 1 ]; then
  echo "$DEST"
else
  say ""
  say "Kartlegging ferdig."
  say "  Rapport:          $REPORT"
  say "  Sikkerhetskopi:   $DEST"
  say ""
  say "Gjenopprett senere med:"
  say "  $SCRIPT_DIR/restore.sh \"$DEST\""
  if [ "${#WARNINGS[@]}" -gt 0 ]; then
    say ""
    say "${#WARNINGS[@]} advarsel/advarsler – se slutten av rapporten."
  fi
fi
exit 0
