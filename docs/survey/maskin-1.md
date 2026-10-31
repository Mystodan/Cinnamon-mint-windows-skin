# Kartlegging av maskin-1

- Tidspunkt: 2026-10-31T12:58:43+01:00
- Bruker: (fjernet)
- map-mint.sh versjon 2
- Økt: x11 / X-Cinnamon

## System
```
RELEASE=22.3
CODENAME=zena
EDITION="Cinnamon"
DESCRIPTION="Linux Mint 22.3 Zena"
Linux 7.0.0-42-generic
```

## Versjoner

| Komponent | Versjon |
| --- | --- |
| Linux Mint | 22.3 |
| Cinnamon | Cinnamon 6.6.9 |
| Muffin | 6.6.3+zena (muffin) |
| Nemo | nemo 6.6.3 |
| GTK 3 | 3.24.41-4ubuntu1.3 (libgtk-3-0t64) |
| GTK 4 | 4.14.5+ds-0ubuntu0.10 (libgtk-4-1) |
| libadwaita | 1.5.0-2mint3+zara (libadwaita-1-0) |
| libAdapta (Mint-fork) | (ikke installert) |
| XApp | 3.2.4+mint22.3 (libxapp1) |

## Aktive temaer og utseende

| Innstilling | Verdi |
| --- | --- |
| Skrivebord (Cinnamon) | 'cinnamon' |
| Programmer (GTK) | 'Mint-L-Blue' |
| Vindusrammer | 'Mint-Y' |
| Ikoner | 'Mint-Y-Sand' |
| Markør | 'DMZ-White' |
| Markørstørrelse | 28 |
| Skrift | 'Ubuntu 10' |
| Skalering | uint32 0 |
| Fargeskjema (portal) | 'default' |
| Vindusknapper | ':minimize,maximize,close' |

## Panel og applets
```
panels-enabled:   ['1:0:bottom']
panels-height:    ['1:40']
panel-zone-icon-sizes: '[{"panelId": 1, "left": 0, "center": 0, "right": 24}]'
enabled-applets:
  panel1:left:0:menu@cinnamon.org:0
  panel1:left:1:separator@cinnamon.org:1
  panel1:left:2:grouped-window-list@cinnamon.org:2
  panel1:right:0:systray@cinnamon.org:3
  panel1:right:1:xapp-status@cinnamon.org:4
  panel1:right:2:notifications@cinnamon.org:5
  panel1:right:3:printers@cinnamon.org:6
  panel1:right:4:removable-drives@cinnamon.org:7
  panel1:right:5:keyboard@cinnamon.org:8
  panel1:right:6:favorites@cinnamon.org:9
  panel1:right:7:network@cinnamon.org:10
  panel1:right:8:sound@cinnamon.org:11
  panel1:right:9:power@cinnamon.org:12
  panel1:right:10:calendar@cinnamon.org:13
  panel1:right:11:cornerbar@cinnamon.org:14
enabled-extensions: @as []

panels-autohide:                   ['1:false']
panel-zone-symbolic-icon-sizes:    '[{"panelId": 1, "left": 28, "center": 28, "right": 16}]'
panel-zone-text-sizes:             '[{"panelId": 1, "left":0.0, "center":0.0, "right":0.0}]'
favorite-apps:                     ['org.gnome.Calculator.desktop', 'org.gnome.Calendar.desktop', 'org.x.editor.desktop', 'mintinstall.desktop', 'cinnamon-settings.desktop']
desktop-effects-workspace:         true
enabled-desklets:                  @as []
```

## Cinnamon-spices (applets, utvidelser, desklets)
### applets – brukerinstallert (~/.local/share/cinnamon/applets)
- (tom)
### applets – system (/usr/share/cinnamon/applets)
- `a11y@cinnamon.org` – Accessibility
- `calendar@cinnamon.org` – Calendar
- `cornerbar@cinnamon.org` – Corner bar
- `expo@cinnamon.org` – Expo
- `favorites@cinnamon.org` – Favorites
- `grouped-window-list@cinnamon.org` – Grouped window list
- `inhibit@cinnamon.org` – Inhibit Applet
- `keyboard@cinnamon.org` – Keyboard
- `menu@cinnamon.org` – Menu
- `network@cinnamon.org` – Network Manager
- `nightlight@cinnamon.org` – Night Light
- `notifications@cinnamon.org` – Notifications
- `on-screen-keyboard@cinnamon.org` – On-Screen keyboard
- `panel-launchers@cinnamon.org` – Panel launchers
- `power@cinnamon.org` – Power Manager
- `printers@cinnamon.org` – Printers
- `recent@cinnamon.org` – Recent documents
- `removable-drives@cinnamon.org` – Removable drives
- `scale@cinnamon.org` – Scale
- `separator@cinnamon.org` – Separator
- `settings@cinnamon.org` – Settings Applet
- `settings-example@cinnamon.org` – Settings API Demo
- `show-desktop@cinnamon.org` – Show desktop
- `slideshow@cinnamon.org` – Slideshow Controls
- `sound@cinnamon.org` – Sound
- `spacer@cinnamon.org` – Spacer
- `systray@cinnamon.org` – System Tray
- `trash@cinnamon.org` – Trash
- `user@cinnamon.org` – User Applet
- `window-list@cinnamon.org` – Window list
- `windows-quick-list@cinnamon.org` – Windows Quick List
- `workspace-switcher@cinnamon.org` – Workspace switcher
- `xapp-status@cinnamon.org` – XApp Status Applet (1.0)
- `xrandr@cinnamon.org` – Display
### extensions – brukerinstallert (~/.local/share/cinnamon/extensions)
- (tom)
### extensions – system (/usr/share/cinnamon/extensions)
- (mappen finnes ikke)
### desklets – brukerinstallert (~/.local/share/cinnamon/desklets)
- (tom)
### desklets – system (/usr/share/cinnamon/desklets)
- `clock@cinnamon.org` – Clock desklet
- `launcher@cinnamon.org` – Launcher desklet
- `photoframe@cinnamon.org` – Digital photo frame
### Lagrede innstillinger for spices
- calendar@cinnamon.org
- cornerbar@cinnamon.org
- favorites@cinnamon.org
- grouped-window-list@cinnamon.org
- menu@cinnamon.org
- network@cinnamon.org
- notifications@cinnamon.org
- power@cinnamon.org
- printers@cinnamon.org
- sound@cinnamon.org
- (gammel plassering) (mappen finnes ikke)

## Nemo (filutforsker)

### Utvidelser og relaterte pakker

| Pakke | Versjon |
| --- | --- |
| nemo-python | (ikke installert) |
| nemo-preview | 6.6.0+zena (nemo-preview) |
| nemo-terminal | (ikke installert) |
| nemo-fileroller | 6.6.0+zena (nemo-fileroller) |
| nemo-share | 6.6.0+zena (nemo-share) |
| nemo-image-converter | (ikke installert) |
| nemo-emblems | 6.6.0+zena (nemo-emblems) |
| nemo-compare | (ikke installert) |
| nemo-audio-tab | (ikke installert) |
| nemo-gtkhash | (ikke installert) |

### Handlinger og skript
#### ~/.local/share/nemo/actions
- (tom)
#### /usr/share/nemo/actions
- 90_new-launcher.nemo_action
- 90_new-workspace.nemo_action
- 91_delete-workspace.nemo_action
- 92_show-expo.nemo_action
- add-desklets.nemo_action
- change-background.nemo_action
- mintstick-format.nemo_action
- mintstick.nemo_action
- mintstick-verify.nemo_action
- mount-archive.nemo_action
- myaction.py
- sample.nemo_action
- set-as-background.nemo_action
- set-resolution.nemo_action
- warpinator-send-check
- warpinator-send.nemo_action
#### ~/.local/share/nemo/scripts
- (tom)

### Innstillinger
#### org.nemo.preferences
```
always-use-browser true
bulk-rename-tool b'bulky'
click-double-parent-folder false
click-policy 'double'
close-device-view-on-device-eject false
confirm-move-to-trash false
confirm-trash true
context-menus-show-all-actions false
date-font-choice 'auto-mono'
date-format 'locale'
default-folder-viewer 'icon-view'
default-sort-in-reverse-order false
default-sort-order 'name'
deferred-attribute-preload-limit 150
desktop-is-home-dir false
detect-content true
disable-menu-warning false
enable-delete true
enable-mime-actions-make-executable false
executable-text-activation 'ask'
expand-row-on-dnd-dwell true
ignore-view-metadata false
image-viewers-with-external-sort ['xviewer', 'feh', 'sxiv']
inherit-folder-viewer false
inherit-show-thumbnails false
last-server-connect-method 2
mouse-back-button 8
mouse-forward-button 9
mouse-use-extra-buttons true
never-queue-file-ops false
quick-renames-with-pause-in-between false
show-advanced-permissions false
show-bookmarks-in-to-menus true
show-compact-view-icon-toolbar true
show-computer-icon-toolbar false
show-directory-item-counts 'local-only'
show-edit-icon-toolbar true
show-full-path-titles false
show-hidden-files true
show-home-icon-toolbar false
show-icon-view-icon-toolbar true
show-image-thumbnails 'local-only'
show-list-view-icon-toolbar true
show-location-entry false
show-new-folder-icon-toolbar false
show-next-icon-toolbar true
show-open-in-terminal-toolbar false
show-places-in-to-menus true
show-previous-icon-toolbar true
show-reload-icon-toolbar false
show-root-warning true
show-search-icon-toolbar true
show-show-thumbnails-toolbar false
show-toggle-extra-pane-toolbar false
show-up-icon-toolbar true
size-prefixes 'base-10'
sort-directories-first true
sort-favorites-first true
start-with-dual-pane false
swap-trash-delete false
tabs-open-position 'after-current-tab'
thumbnail-limit uint64 34359738368
thumbnail-threads -1
tooltips-in-icon-view false
tooltips-in-list-view false
tooltips-on-desktop false
tooltips-show-access-date false
tooltips-show-birth-date false
tooltips-show-file-type false
tooltips-show-mod-date false
tooltips-show-path false
treat-root-as-normal false
```
#### org.nemo.window-state
```
bookmarks-expanded true
devices-expanded true
geometry ''
maximized false
my-computer-expanded true
network-expanded true
sidebar-bookmark-breakpoint 5
sidebar-width 170
side-pane-view 'places'
start-with-location-bar true
start-with-menu-bar true
start-with-sidebar true
start-with-status-bar true
start-with-toolbar true
```
#### org.nemo.icon-view
```
captions ['none', 'size', 'date_modified']
default-use-tighter-layout false
default-zoom-level 'standard'
labels-beside-icons false
text-ellipsis-limit ['3']
thumbnail-size 64
```
#### org.nemo.list-view
```
default-column-order ['name', 'size', 'type', 'date_modified']
default-visible-columns ['name', 'size', 'type', 'date_modified']
default-zoom-level 'smaller'
enable-folder-expansion false
```

## Effekter og tilgjengelighet
```
desktop-effects-workspace:         true
startup-animation:                 true
enable-animations:                 true
text-scaling-factor:               1.0
gtk-overlay-scrollbars:            true
high-contrast:                     (skjema org.cinnamon.desktop.a11y.interface finnes ikke)
screen-reader-enabled:             false
screen-magnifier-enabled:          false
edge-tiling:                       true
tile-maximize:                     false
```

## Relevante pakker

| Pakke | Versjon |
| --- | --- |
| mint-themes | 2.3.8 (mint-themes) |
| mint-y-icons | 1.9.1 (mint-y-icons) |
| mint-x-icons | 1.7.5 (mint-x-icons) |
| mint-l-icons | 1.8.0 (mint-l-icons) |
| mint-l-theme | 2.0.6 (mint-l-theme) |
| adwaita-icon-theme | 46.0-1 (adwaita-icon-theme) |
| papirus-icon-theme | 20240201-1 (papirus-icon-theme) |
| dmz-cursor-theme | 0.4.5ubuntu1 (dmz-cursor-theme) |
| bibata-cursor-theme | (ikke installert) |
| gnome-themes-extra | 3.28-2ubuntu5 (gnome-themes-extra) |
| gtk2-engines-murrine | 0.98.2-4 (gtk2-engines-murrine) |
| sassc | (ikke installert) |
| dconf-cli | 0.40.0-4ubuntu0.1 (dconf-cli) |

## Installerte temaer
### ~/.themes
- (tom)
### ~/.local/share/themes
- (mappen finnes ikke)
### /usr/share/themes
- Adwaita
- Adwaita-dark
- Default
- Emacs
- HighContrast
- Mint-L
- Mint-L-Aqua
- Mint-L-Blue
- Mint-L-Brown
- Mint-L-Dark
- Mint-L-Dark-Aqua
- Mint-L-Dark-Blue
- Mint-L-Dark-Brown
- Mint-L-Darker
- Mint-L-Darker-Aqua
- Mint-L-Darker-Blue
- Mint-L-Darker-Brown
- Mint-L-Darker-Grey
- Mint-L-Darker-Orange
- Mint-L-Darker-Pink
- Mint-L-Darker-Purple
- Mint-L-Darker-Red
- Mint-L-Darker-Sand
- Mint-L-Darker-Teal
- Mint-L-Dark-Grey
- Mint-L-Dark-Orange
- Mint-L-Dark-Pink
- Mint-L-Dark-Purple
- Mint-L-Dark-Red
- Mint-L-Dark-Sand
- Mint-L-Dark-Teal
- Mint-L-Grey
- Mint-L-Orange
- Mint-L-Pink
- Mint-L-Purple
- Mint-L-Red
- Mint-L-Sand
- Mint-L-Teal
- Mint-X
- Mint-X-Aqua
- Mint-X-Blue
- Mint-X-Brown
- Mint-X-compact
- Mint-X-Grey
- Mint-X-Orange
- Mint-X-Pink
- Mint-X-Purple
- Mint-X-Red
- Mint-X-Sand
- Mint-X-Teal
- Mint-Y
- Mint-Y-Aqua
- Mint-Y-Blue
- Mint-Y-Dark
- Mint-Y-Dark-Aqua
- Mint-Y-Dark-Blue
- Mint-Y-Dark-Grey
- Mint-Y-Dark-Orange
- Mint-Y-Dark-Pink
- Mint-Y-Dark-Purple
- Mint-Y-Dark-Red
- Mint-Y-Dark-Sand
- Mint-Y-Dark-Teal
- Mint-Y-Grey
- Mint-Y-Orange
- Mint-Y-Pink
- Mint-Y-Purple
- Mint-Y-Red
- Mint-Y-Sand
- Mint-Y-Teal
- Raleigh

## Installerte ikoner og markører
### ~/.icons
- default
### ~/.local/share/icons
- default
### /usr/share/icons
- Adwaita
- Bibata-Modern-Classic
- Bibata-Modern-Ice
- Bibata-Original-Classic
- Bibata-Original-Ice
- default
- DMZ-Black
- DMZ-White
- ePapirus
- ePapirus-Dark
- GoogleDot-Black
- GoogleDot-White
- hicolor
- HighContrast
- Humanity
- Humanity-Dark
- locolor
- LoginIcons
- Mint-L
- Mint-L-Aqua
- Mint-L-Blue
- Mint-L-Brown
- Mint-L-Grey
- Mint-L-Orange
- Mint-L-Pink
- Mint-L-Purple
- Mint-L-Red
- Mint-L-Sand
- Mint-L-Teal
- Mint-L-Yellow
- Mint-X
- Mint-X-Aqua
- Mint-X-Blue
- Mint-X-Brown
- Mint-X-Grey
- Mint-X-Orange
- Mint-X-Pink
- Mint-X-Purple
- Mint-X-Red
- Mint-X-Sand
- Mint-X-Teal
- Mint-X-Yellow
- Mint-Y
- Mint-Y-Aqua
- Mint-Y-Blue
- Mint-Y-Cyan
- Mint-Y-Grey
- Mint-Y-Navy
- Mint-Y-Orange
- Mint-Y-Pink
- Mint-Y-Purple
- Mint-Y-Red
- Mint-Y-Sand
- Mint-Y-Teal
- Mint-Y-Yaru
- Papirus
- Papirus-Dark
- Papirus-Light
- ubuntu-mono-dark
- ubuntu-mono-light
- XCursor-Pro-Dark
- XCursor-Pro-Light
- Yaru
- Yaru-bark
- Yaru-bark-dark
- Yaru-blue
- Yaru-blue-dark
- Yaru-dark
- Yaru-magenta
- Yaru-magenta-dark
- Yaru-olive
- Yaru-olive-dark
- Yaru-prussiangreen
- Yaru-prussiangreen-dark
- Yaru-purple
- Yaru-purple-dark
- Yaru-red
- Yaru-red-dark
- Yaru-sage
- Yaru-sage-dark
- Yaru-viridian
- Yaru-viridian-dark

## Brukerens GTK-overstyringer
- `~/.config/gtk-3.0/gtk.css` finnes ikke
- `~/.config/gtk-3.0/settings.ini` finnes ikke
- `~/.config/gtk-4.0/gtk.css` finnes ikke
- `~/.config/gtk-4.0/settings.ini` finnes ikke

## Grafikk og skjerm
```
01:00.0 VGA compatible controller: NVIDIA Corporation GP107 [GeForce GTX 1050] (rev a1)
None-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 0mm x 0mm
```

## Sikkerhetskopi

- dconf: tatt
  - `/org/cinnamon/` → `dconf/org.cinnamon.dconf`
  - `/org/nemo/` → `dconf/org.nemo.dconf`
  - `/org/x/` → `dconf/org.x.dconf`
  - `/org/gtk/settings/` → `dconf/org.gtk.settings.dconf`
  - `/org/gnome/desktop/interface/` → `dconf/org.gnome.desktop.interface.dconf`
  - `/org/gnome/desktop/wm/preferences/` → `dconf/org.gnome.desktop.wm.preferences.dconf`
- Filer:
  - `~/.config/gtk-3.0` kopiert
  - `~/.config/gtk-4.0` fantes ikke
  - `~/.gtkrc-2.0` kopiert
  - `~/.config/cinnamon` kopiert
  - `~/.cinnamon/configs` fantes ikke
  - `~/.config/xsettingsd` fantes ikke
  - `~/.config/nemo` kopiert
  - `~/.local/share/nemo` kopiert
  - `~/.local/share/cinnamon` kopiert
