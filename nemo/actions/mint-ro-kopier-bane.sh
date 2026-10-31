#!/usr/bin/env bash
# Mint-Ro: kopierer banene som Nemo sender inn, én per linje, til utklippstavlen.
# Bruker det som finnes: wl-copy (Wayland), xclip, xsel, eller GTK via Python.
set -uo pipefail

[ $# -gt 0 ] || exit 0
text="$(printf '%s\n' "$@")"
text="${text%$'\n'}"

have() { command -v "$1" >/dev/null 2>&1; }

if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && have wl-copy; then
  printf '%s' "$text" | wl-copy && exit 0
fi
if have xclip; then
  printf '%s' "$text" | xclip -selection clipboard && exit 0
fi
if have xsel; then
  printf '%s' "$text" | xsel --clipboard --input && exit 0
fi
if have python3; then
  # GTK lagrer teksten hos skrivebordets utklippshåndterer, så den overlever at skriptet avslutter.
  printf '%s' "$text" | python3 -c '
import sys, gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk
cb = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
cb.set_text(sys.stdin.read(), -1)
cb.store()
' 2>/dev/null && exit 0
fi

msg="Fant ingen måte å kopiere til utklippstavlen. Installer xclip: sudo apt install xclip"
if have notify-send; then notify-send -i dialog-warning "Kopier som bane" "$msg"; else echo "$msg" >&2; fi
exit 1
