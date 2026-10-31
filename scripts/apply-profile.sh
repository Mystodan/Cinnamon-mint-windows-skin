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
#   ./scripts/apply-profile.sh startmeny             # Windows 11-lignende startmeny med Cinnamenu (rutenett)
#   ./scripts/apply-profile.sh tema                  # aktiver Mint-Ro (lys)
#   ./scripts/apply-profile.sh tema-mork             # aktiver Mint-Ro-Dark (mørk)
#   ./scripts/apply-profile.sh ikoner                # bruk Fluent-ikoner (installer med install-icons.sh)
#   ./scripts/apply-profile.sh alt                   # nemo + oppgavelinje + meny
#   ./scripts/apply-profile.sh --menyikon=<URL|fil|ikonnavn>   # eget ikon på menyknappen
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

YES=0; DRY=0; DO_NEMO=0; DO_TASKBAR=""; DO_MENU=0; DO_THEME=""; DO_ICONS=0; ICON_COLOR=""; DO_STARTMENU=0; DO_MENUICON=0; MENU_ICON_SRC=""
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

usage() { sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
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
    ikoner) DO_ICONS=1 ;;
    startmeny) DO_STARTMENU=1 ;;
    --menyikon=*) DO_MENUICON=1; MENU_ICON_SRC="${1#--menyikon=}" ;;
    --ikonfarge=*) ICON_COLOR="${1#--ikonfarge=}" ;;
    alt) DO_NEMO=1; DO_TASKBAR=center; DO_MENU=1 ;;
    *) die "ukjent profil eller valg: $1 (se --help)" ;;
  esac
  shift
done
[ "$DO_NEMO" -eq 1 ] || [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ] || [ -n "$DO_THEME" ] || [ "$DO_ICONS" -eq 1 ] || [ "$DO_STARTMENU" -eq 1 ] || [ "$DO_MENUICON" -eq 1 ] \
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
if [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ] || [ "$DO_STARTMENU" -eq 1 ] || [ "$DO_MENUICON" -eq 1 ]; then
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

if [ -n "$DO_TASKBAR" ] || [ "$DO_MENU" -eq 1 ] || [ "$DO_STARTMENU" -eq 1 ] || [ "$DO_MENUICON" -eq 1 ]; then
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

# ---------- Eget menyikon ----------
# Lastes ned/kontrolleres nå (før bekreftelse) og installeres i ~/.local/share/mint-ro.
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mint-ro"
ICON_TMP=""; ICON_DEST=""; ICON_VALUE=""; ICON_CHANGED=0; ICON_PAIRS_CM=(); ICON_PAIRS_MENU=()
MENU_ICON_SIZE=28
if [ "$DO_MENUICON" -eq 1 ]; then
  [ -n "$MENU_ICON_SRC" ] || die "--menyikon trenger en nettadresse, en fil eller et ikonnavn."
  ICON_TMP="$(mktemp)" || die "kunne ikke lage midlertidig fil."
  trap 'rm -f "$ICON_TMP"' EXIT
  case "$MENU_ICON_SRC" in
    https://*)
      have curl || die "curl mangler. Installer med: sudo apt install curl"
      curl -fsSL --proto '=https' --max-time 30 --max-filesize 2000000 -o "$ICON_TMP" "$MENU_ICON_SRC" \
        || die "kunne ikke laste ned ikonet (bare https, maks 2 MB)." ;;
    http://*) die "bruk en https-adresse." ;;
    */*|*.svg|*.png)
      f="${MENU_ICON_SRC/#\~/$HOME}"
      [ -f "$f" ] || die "fant ikke filen $MENU_ICON_SRC"
      [ "$(stat -c %s "$f")" -le 2000000 ] || die "filen er større enn 2 MB."
      cp "$f" "$ICON_TMP" || die "kunne ikke lese $MENU_ICON_SRC" ;;
    *)
      [[ "$MENU_ICON_SRC" =~ ^[A-Za-z0-9._-]+$ ]] || die "ugyldig ikonnavn: $MENU_ICON_SRC"
      ICON_VALUE="$MENU_ICON_SRC"; rm -f "$ICON_TMP"; ICON_TMP="" ;;
  esac
  if [ -n "$ICON_TMP" ]; then
    # Bare SVG eller PNG.
    if [ "$(head -c 4 "$ICON_TMP" | od -An -tx1 | tr -d ' \n')" = "89504e47" ]; then ext=png
    elif head -c 4096 "$ICON_TMP" | grep -qi '<svg'; then ext=svg
    else die "ikonet må være SVG eller PNG."; fi
    name="menyikon"
    # Behold «-symbolic» i navnet hvis kilden har det, så Cinnamon farger ikonet etter temaet.
    case "$MENU_ICON_SRC" in *-symbolic*) name="menyikon-symbolic" ;; esac
    ICON_DEST="$ICON_DIR/$name.$ext"
    ICON_VALUE="$ICON_DEST"
    cmp -s "$ICON_TMP" "$ICON_DEST" 2>/dev/null || ICON_CHANGED=1
  fi
  ICON_PAIRS_CM=(menu-icon-custom=true "menu-icon=\"$ICON_VALUE\"" menu-icon-size-custom=true
    menu-icon-size=$MENU_ICON_SIZE 'menu-label=""')
  ICON_PAIRS_MENU=(menu-custom=true "menu-icon=\"$ICON_VALUE\"" menu-icon-size=$MENU_ICON_SIZE 'menu-label=""')
fi

# Windows 11-lignende oppsett for Cinnamenu: rutenett, festede apper først, nylig brukte
# som «anbefalt», av/på-linje nederst, ingen emoji/hjemmemappe-kategorier.
CINNAMENU_WIN11=(applications-view-mode=1 show-sidebar=true sidebar-placement=1 sidebar-favorites=0
  description-placement=0 show-categories=true show-places-category=false show-recents-category=true
  show-favorite-apps-category=true show-home-folder-category=false show-emoji-category=false
  open-on-category=1 apps-grid-icon-size=48 category-icon-size=16 sidebar-icon-size=24
  custom-menu-width=680 custom-menu-height=620)
NEW_CONFIG=""; NEW_CONFIG_SCHEMA=""
[ "$DO_STARTMENU" -eq 0 ] || [ "$DO_MENUICON" -eq 0 ] || CINNAMENU_WIN11+=("${ICON_PAIRS_CM[@]}")
if [ "$DO_STARTMENU" -eq 1 ]; then
  cm_dir=""
  for d in "$HOME/.local/share/cinnamon/applets/Cinnamenu@json" /usr/share/cinnamon/applets/Cinnamenu@json; do
    [ -f "$d/metadata.json" ] && { cm_dir="$d"; break; }
  done
  [ -n "$cm_dir" ] || die "Cinnamenu er ikke installert. Installer den i Systeminnstillinger → Applets → Last ned (søk «Cinnamenu»), og kjør profilen igjen."
  cver="$(cinnamon --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  NEW_CONFIG_SCHEMA="$(py pick-schema "$cm_dir" "${cver:-99}")" || die "fant ikke Cinnamenus innstillingsskjema."

  cm_id="$(py instance-id "$APPLETS" Cinnamenu@json "panel$PANEL_ID")"
  if [ -z "$cm_id" ]; then
    cm_id="$(py next-instance-id "$APPLETS")"
    new="$(py replace-applet "$APPLETS" menu@cinnamon.org Cinnamenu@json "$cm_id")" \
      || die "fant ikke menyknappen å bytte ut."
    add_set org.cinnamon enabled-applets "$new"
    NOTES+=("Den innebygde menyen byttes med Cinnamenu på samme plass. restore.sh bytter tilbake.")
  fi
  cm_cfg="$SPICES_CFG/Cinnamenu@json/$cm_id.json"
  if [ -f "$cm_cfg" ]; then
    add_applet "Cinnamenu" "$cm_cfg" "${CINNAMENU_WIN11[@]}"
  else
    NEW_CONFIG="$cm_cfg"
  fi
fi

if [ "$DO_MENUICON" -eq 1 ] && [ "$DO_STARTMENU" -eq 0 ]; then
  menu_uuid=""; for u in Cinnamenu@json menu@cinnamon.org; do
    [ -n "$(py instance-id "$APPLETS" "$u" "panel$PANEL_ID")" ] && { menu_uuid="$u"; break; }
  done
  if applet_file "$menu_uuid" "panel$PANEL_ID" "Menyikon"; then
    if [ "$menu_uuid" = "Cinnamenu@json" ]; then
      add_applet "Menyikon (Cinnamenu)" "$APPLET_PATH" "${ICON_PAIRS_CM[@]}"
    else
      add_applet "Menyikon" "$APPLET_PATH" "${ICON_PAIRS_MENU[@]}"
    fi
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
  [ "$DO_ICONS" -eq 1 ] || NOTES+=("Markør og skrift endres ikke.")
fi

# ---------- Fluent-ikoner ----------
# Basenavn (Fluent eller Fluent-<farge>) installert av install-icons.sh.
fluent_bases() {
  local d
  for d in "$ICONS_DIR"/Fluent*; do
    [ -f "$d/.mint-ro-installed" ] || continue
    case "$(basename "$d")" in *-dark|*-light) ;; *) basename "$d" ;; esac
  done
}
# Skal ikonene være mørke? Følger temaet som settes nå, ellers dagens tema/fargeskjema.
icons_dark() {
  if [ -n "$DO_THEME" ]; then [ "$DO_THEME" = "dark" ]; return; fi
  local g c
  g="$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null)"
  c="$(gsettings get org.x.apps.portal color-scheme 2>/dev/null || true)"
  case "$g" in *[Dd]ark*) return 0 ;; esac
  [ "$c" = "'prefer-dark'" ]
}
icon_target() {   # basenavn -> navn for lys/mørk
  if icons_dark; then printf '%s-dark' "$1"; else printf '%s' "$1"; fi
}

current_icons="$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
if [ "$DO_ICONS" -eq 1 ]; then
  mapfile -t bases < <(fluent_bases)
  [ "${#bases[@]}" -gt 0 ] || die "Fluent-ikoner er ikke installert. Kjør først: $SCRIPT_DIR/install-icons.sh"
  want=""
  if [ -n "$ICON_COLOR" ]; then
    [ "$ICON_COLOR" = "standard" ] && want="Fluent" || want="Fluent-$ICON_COLOR"
    printf '%s\n' "${bases[@]}" | grep -qx "$want" || die "$want er ikke installert. Kjør: $SCRIPT_DIR/install-icons.sh $ICON_COLOR"
  else
    for b in "${bases[@]}"; do [ "$b" = "Fluent-green" ] && want="$b"; done
    [ -n "$want" ] || want="${bases[0]}"
  fi
  add_set org.cinnamon.desktop.interface icon-theme "'$(icon_target "$want")'"
elif [ -n "$DO_THEME" ]; then
  # Fluent i bruk: bytt til riktig lys/mørk utgave sammen med temaet.
  base="${current_icons%-dark}"; base="${base%-light}"
  if [ -f "$ICONS_DIR/$base/.mint-ro-installed" ]; then
    add_set org.cinnamon.desktop.interface icon-theme "'$(icon_target "$base")'"
  else
    NOTES+=("Ikonene endres ikke.")
  fi
fi

# ---------- Vis plan ----------
if [ "${#SETS[@]}" -eq 0 ] && [ "${#FILES[@]}" -eq 0 ] && [ "${#JOB_FILE[@]}" -eq 0 ] && [ -z "$NEW_CONFIG" ] && [ "$ICON_CHANGED" -eq 0 ]; then
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
[ "$ICON_CHANGED" -eq 0 ] || echo "  Menyikon: $(tilde "$ICON_DEST") (fra $MENU_ICON_SRC)"
if [ -n "$NEW_CONFIG" ]; then
  echo "  Cinnamenu, ny innstillingsfil ($(tilde "$NEW_CONFIG")):"
  printf '      %s\n' "${CINNAMENU_WIN11[@]}"
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
if [ "$ICON_CHANGED" -eq 1 ]; then
  if mkdir -p "$ICON_DIR" && install -m 644 "$ICON_TMP" "$ICON_DEST"; then echo "  ✓ $(tilde "$ICON_DEST")"
  else echo "  ✗ kunne ikke lagre ikonet" >&2; fail=1; fi
fi
# Cinnamenus innstillinger må finnes før appleten legges i panelet.
if [ -n "$NEW_CONFIG" ]; then
  if py new-config "$NEW_CONFIG_SCHEMA" "$NEW_CONFIG" "${CINNAMENU_WIN11[@]}"; then echo "  ✓ Cinnamenu-oppsett"
  else echo "  ✗ Cinnamenu-oppsett – panelet endres ikke" >&2; fail=1; SETS=(); fi
fi
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
[ -z "$DO_TASKBAR" ] && [ "$DO_MENU" -eq 0 ] && [ "$DO_STARTMENU" -eq 0 ] || echo "Panel og meny oppdateres med en gang. Trykk Ctrl+Alt+Esc hvis noe ikke endrer seg."
[ -z "$DO_THEME" ] || echo "Temaet tas i bruk med en gang. Allerede åpne programmer kan trenge omstart."
[ "$DO_ICONS" -eq 0 ] || echo "Ikonene byttes med en gang. Noen programmer viser nye ikoner først etter omstart."
echo "Angre alt med: $SCRIPT_DIR/restore.sh \"$BK\""
