# Mint-Ro

Et moderne tema for Linux Mint Cinnamon, med Windows 11 som visuell inspirasjon:
avrundede former, rolige farger, luftige avstander og diskret transparens.
Temaet er laget for Cinnamon og Mint – ikke en kopi av Windows. Det inneholder ingen
Windows-logoer, varemerker eller proprietær grafikk.

> **Status – milepæl 1:** grunnstruktur, kartlegging og sikkerhetskopiering er på plass.
> Selve utseendet bygges trinnvis etter [planen](docs/PLAN.md), basert på
> kartleggingen av den faktiske maskinen.

## Krav

- Cinnamon forblir skrivebordsmiljøet. Bare formater Cinnamon og GTK selv støtter brukes.
- Mint-funksjoner og vanlig Cinnamon-oppførsel beholdes.
- Alt installeres per bruker. Ingen systemfiler endres, og `sudo` trengs ikke.
- Ingenting aktiveres uten en sikkerhetskopi som kan gjenopprettes med én kommando.
- Ingen versjon av Cinnamon, GTK eller tema antas – kartleggingen avgjør.

## Mappestruktur

| Mappe | Innhold |
| --- | --- |
| `cinnamon/` | Cinnamon-skalltemaet: panel, meny, varsler, dialoger, OSD |
| `gtk-3.0/` | GTK 3-temaet |
| `gtk-4.0/` | GTK 4-temaet |
| `scripts/` | Kartlegging, sikkerhetskopi og gjenoppretting |
| `backups/` | Tom i Git – sikkerhetskopier lagres lokalt (se under) |
| `docs/` | Plan og kartleggingsrapporter som deles bevisst |

Repoet er selve temamappen: når temaet er klart, kopieres `cinnamon/`, `gtk-3.0/`,
`gtk-4.0/` og `index.theme` til `~/.themes/Mint-Ro/`.

## Steg 1: kartlegg maskinen og ta sikkerhetskopi

Kjør dette på Mint-maskinen, som vanlig bruker (ikke med `sudo`):

```bash
git clone https://github.com/Mystodan/cinnamon-mint-windows-skin.git
cd cinnamon-mint-windows-skin
./scripts/map-mint.sh
```

Skriptet:

1. viser Linux Mint-, Cinnamon-, Muffin-, GTK 3-, GTK 4- og libadwaita-versjon
2. viser aktivt Cinnamon-, GTK-, vindusramme-, ikon- og markørtema
3. lister relevante temaer, ikonpakker og pakker som er installert
4. tar en datert sikkerhetskopi av innstillingene (`dconf`) og brukerens GTK- og Cinnamon-filer
5. lagrer en lesbar rapport, `rapport.md`, sammen med sikkerhetskopien
6. skriver ut hvor alt ble lagret og hvilken kommando som gjenoppretter det

Det endrer ikke aktivt tema, installerer ingenting og overskriver ingen konfigurasjon.
Mangler et verktøy (for eksempel `dconf`), sier rapporten det tydelig i stedet for å feile.

Valg:

```bash
./scripts/map-mint.sh --label foer-tema   # merkelapp i mappenavnet
./scripts/map-mint.sh --dir ~/Mine-kopier # lagre et annet sted
./scripts/map-mint.sh --help
```

**Del rapporten:** kopier `rapport.md` til `docs/survey/<maskinnavn>.md` hvis den skal
brukes i videre arbeid. Les gjennom den først – den viser maskinnavn og brukernavn.

## Sikkerhetskopi og gjenoppretting

Sikkerhetskopier lagres lokalt, aldri i Git:

```
~/.local/share/mint-ro/backups/<ÅÅÅÅMMDD-TTMMSS>[-merkelapp]/
  rapport.md         lesbar kartleggingsrapport
  GJENOPPRETT.txt    kommandoer for gjenoppretting
  dconf/             org.cinnamon, org.nemo, org.x, org.gtk.settings, gnome interface/wm
                     + full.dconf (hele dconf, kun til referanse)
  files/             ~/.config/gtk-3.0, gtk-4.0, cinnamon, xsettingsd, ~/.cinnamon/configs, ~/.gtkrc-2.0
  files/manifest.tsv hva som fantes da kopien ble tatt
```

Mappene får bare lesetilgang for deg selv (`umask 077`).

Gjenopprett:

```bash
./scripts/restore.sh --list            # vis tilgjengelige sikkerhetskopier
./scripts/restore.sh --dry-run         # se hva som ville skjedd, uten å endre noe
./scripts/restore.sh                   # gjenopprett siste sikkerhetskopi
./scripts/restore.sh <mappe>           # gjenopprett en bestemt sikkerhetskopi
```

`restore.sh` viser hva som skal endres, ber om bekreftelse og tar alltid en ny
sikkerhetskopi av dagens tilstand først (`*-for-gjenoppretting`), slik at også
gjenopprettingen kan angres. Filer som ikke fantes da kopien ble tatt (for eksempel
`~/.config/gtk-4.0`), fjernes. Logg ut og inn igjen, eller trykk `Ctrl+Alt+Esc`,
etterpå.

Uten skriptet går det også manuelt – se `GJENOPPRETT.txt` i sikkerhetskopien.

## Installasjon av temaet

Kommer i neste milepæl, når kartleggingen er gjort. Installasjonen vil:

- kopiere temaet til `~/.themes/Mint-Ro/`
- kjøre `map-mint.sh` før noe aktiveres
- bare røre `~/.config/gtk-4.0` (for libadwaita-apper) hvis du ber om det

## Lisens

Ikke valgt ennå. Forslag: GPL-3.0-or-later, i tråd med Cinnamon og Mint-temaene.
