# Mint-Ro

Et moderne tema og oppsett for Linux Mint Cinnamon, bygget på prinsippene i
Fluent Design. Målet er at **filutforskeren, startmenyen og oppgavelinjen** skal føles
moderne og kjente for en Windows 11-bruker – med arbeidsflyt foran visuell likhet –
samtidig som skrivebordet beholder sin Mint- og Cinnamon-identitet.

Prosjektet bruker bare Cinnamons egne komponenter, tema- og innstillingsformater.
Det inneholder ingen Microsoft-logoer, varemerker, ikoner, lyder eller annen
proprietær grafikk. Se [designgrunnlaget](docs/DESIGN.md) og [planen](docs/PLAN.md).

> **Status – milepæl 1 ferdig:** grunnstruktur, kartlegging og sikkerhetskopiering.
> **Testet:** oppsettsprofil for Nemo og oppgavelinjen.
> **Klart til test:** Fluent-inspirert oppgavelinje og Nemo, mørk variant, avrundede vinduer og ny startmeny (`git pull` + `install.sh`).
> **Neste:** stil for Nemo, deretter panel og meny.

## Krav

- Cinnamon forblir skrivebordsmiljøet. Bare formater Cinnamon og GTK selv støtter brukes.
- Mint-funksjoner og vanlig Cinnamon-oppførsel beholdes.
- Alt installeres per bruker. Ingen systemfiler endres, og `sudo` trengs ikke.
- Ingenting aktiveres uten en sikkerhetskopi som kan gjenopprettes med én kommando.
- Ingen versjon av Cinnamon, GTK eller tema antas – kartleggingen avgjør.

## Mappestruktur

| Mappe | Innhold |
| --- | --- |
| `cinnamon/`, `gtk-2.0/`, `gtk-3.0/`, `gtk-4.0/`, `libadwaita-1.5/`, `libadwaita-1.7/`, `metacity-1/`, `index.theme` | Det ferdige lyse temaet Mint-Ro (generert, ikke rediger direkte) |
| `Mint-Ro-Dark/` | Det ferdige mørke temaet (generert) |
| `src/` | Kilde: designtokens og justeringer i SCSS, og byggeskriptet |
| `nemo/actions/` | Nemo-handlinger, som «Kopier som bane» |
| `scripts/` | Kartlegging, sikkerhetskopi, gjenoppretting og oppsettsprofiler |
| `backups/` | Tom i Git – sikkerhetskopier lagres lokalt (se under) |
| `docs/` | Designgrunnlag, plan og kartleggingsrapporter som deles bevisst |

Repoet er selve temamappen: `install.sh` kopierer temadelene til `~/.themes/Mint-Ro/`.

## Steg 1: kartlegg maskinen og ta sikkerhetskopi

Kjør dette på Mint-maskinen, som vanlig bruker (ikke med `sudo`):

```bash
git clone https://github.com/Mystodan/cinnamon-mint-windows-skin.git
cd cinnamon-mint-windows-skin
./scripts/map-mint.sh
```

Skriptet:

1. viser Linux Mint-, Cinnamon-, Muffin-, Nemo-, GTK 3-, GTK 4- og libadwaita-versjon
2. viser aktivt Cinnamon-, GTK-, vindusramme-, ikon- og markørtema
3. lister relevante temaer, ikonpakker og pakker som er installert
4. kartlegger panelet, applets, utvidelser og desklets (innebygde og fra Spices)
5. kartlegger Nemo: innstillinger, verktøylinje, utvidelser, handlinger og skript
6. viser effekter og tilgjengelighetsinnstillinger (animasjoner, tekstskalering, høy kontrast)
7. tar en datert sikkerhetskopi av innstillingene (`dconf`) og brukerens GTK-, Cinnamon- og Nemo-filer
8. lagrer en lesbar rapport, `rapport.md`, sammen med sikkerhetskopien
9. skriver ut hvor alt ble lagret og hvilken kommando som gjenoppretter det

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
  files/             ~/.config/gtk-3.0, gtk-4.0, cinnamon, nemo, xsettingsd, ~/.cinnamon/configs,
                     ~/.local/share/cinnamon (Spices), ~/.local/share/nemo (handlinger), ~/.gtkrc-2.0
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

## Steg 2: oppsett for Nemo og oppgavelinjen

`apply-profile.sh` gjør Nemo og panelet mer kjent for Windows 11-brukere, bare ved hjelp
av Cinnamons egne innstillinger. Det endrer ikke temaet og installerer ingen pakker.

```bash
./scripts/apply-profile.sh --dry-run alt   # se nøyaktig hva som endres
./scripts/apply-profile.sh alt             # nemo + sentrert oppgavelinje
```

| Profil | Hva den gjør |
| --- | --- |
| `nemo` | Oppdater-knapp i verktøylinjen, kolonner i rekkefølgen navn, endret, type, størrelse, litt luftigere listevisning, og «Kopier som bane» i høyreklikkmenyen |
| `oppgavelinje` | Menyknapp og apper i midten, panelhøyde 48 px, systemstatus samlet til høyre, varsler ved klokka, klokke over dato. Skillelinjen og favoritt-appleten fjernes fra panelet; favorittene ligger fortsatt i menyen |
| `oppgavelinje-venstre` | Som over, men menyknapp og apper til venstre |
| `meny` | Startmenyen med søkefelt øverst og uten beskrivelser under appnavnene |
| `alt` | `nemo` + `oppgavelinje` + `meny` |
| `startmeny` | Windows 11-lignende meny med Cinnamenu (se under) |
| `ikoner` | Fluent-ikoner (se under) |

Skriptet viser hver endring med gammel og ny verdi, ber om bekreftelse og tar
sikkerhetskopi med `map-mint.sh` først. Angre med kommandoen det skriver ut, eller med
`./scripts/restore.sh`. Dine egne valg, som skjulte filer og dobbeltklikk, røres ikke.

«Kopier som bane» bruker `xclip`, `xsel`, `wl-copy` eller GTK, avhengig av hva som finnes.

## Steg 3: installer og aktiver temaet

```bash
./scripts/install.sh                        # kopier Mint-Ro og Mint-Ro-Dark til ~/.themes
./scripts/apply-profile.sh tema             # aktiver lys variant
./scripts/apply-profile.sh tema-mork        # eller mørk variant
```

Begge profilene viser endringene og tar sikkerhetskopi først. `tema-mork` setter også
systemets fargeskjema til mørkt, så GTK 4/libadwaita-programmer følger; `tema` setter det
tilbake. `install.sh --activate` / `--activate-dark` gjør alt i ett. Temaene kan også velges
i Systeminnstillinger → Temaer. Ikoner, markør og skrift endres ikke.

Gå tilbake med `./scripts/restore.sh`, og fjern deretter temaet med
`./scripts/uninstall.sh` (som nekter så lenge Mint-Ro er i bruk).

**Status:** Mint-Ro bygger på Mint-Y med Mint-Ro-farger i lys og mørk variant, vinduer
avrundet på alle hjørner, startmeny og flyouts som svever over panelet, oppgavelinje med
Windows 11-lignende indikatorer, og Nemo med flat verktøylinje og rolig markering av valgte
filer. Flere detaljer er tilpasset fra Fluent GTK.

### Valgfritt: Fluent-ikoner

```bash
./scripts/install-icons.sh              # grønn variant, passer Mint-Ro
./scripts/apply-profile.sh ikoner       # ta dem i bruk
```

Henter [Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme) (vinceliuice,
GPL-3.0-or-later) på fast versjon og installerer bare for din bruker i `~/.local/share/icons`.
Andre farger: `standard green grey orange pink purple red yellow teal`. Mangler Fluent et ikon,
brukes Mint-Y. Profilen velger lys eller mørk utgave etter temaet, og `tema` / `tema-mork`
bytter utgave automatisk. Gå tilbake med `restore.sh`, fjern med `install-icons.sh --remove`.

### Valgfritt: Windows 11-lignende startmeny

Den innebygde menyen kan ikke vise apper i rutenett. Det kan **Cinnamenu** fra Spices:

1. Systeminnstillinger → **Applets** → fanen **Last ned** → søk «Cinnamenu» → Installer
   (du trenger ikke legge den til i panelet selv).
2. `./scripts/apply-profile.sh startmeny`

Profilen bytter menyknappen med Cinnamenu på samme plass og setter opp: festede apper i rutenett
først, kategorier og nylig brukte filer (som «Anbefalt»), søk øverst, av/på-linje nederst, ingen
emoji- eller hjemmemappe-kategori. Festede apper er Cinnamons favoritter – høyreklikk en app for
å feste den. `restore.sh` bytter tilbake til den innebygde menyen.

### Valgfritt: eget ikon på menyknappen

```bash
./scripts/apply-profile.sh --menyikon=https://eksempel.no/ikon.svg   # fra nettet (https, SVG/PNG, maks 2 MB)
./scripts/apply-profile.sh --menyikon=~/Bilder/ikon.png              # fra en fil
./scripts/apply-profile.sh --menyikon=start-here-symbolic            # et ikon fra ikontemaet
```

Virker både med den innebygde menyen og med Cinnamenu, og kan kombineres med `startmeny`.
Ikonet lagres i `~/.local/share/mint-ro/`, teksten ved siden av knappen fjernes, og størrelsen
settes til 28 px. Har filnavnet `-symbolic`, farges ikonet etter temaet. Windows-logoen er et
varemerke og brukes ikke i prosjektet. `restore.sh` gir deg det gamle ikonet tilbake.

### Valgfritt: akryl (uskarp bakgrunn)

Cinnamon-temaer kan ikke gjøre bakgrunnen uskarp selv, så Mint-Ro er solid og lesbart som
standard. Vil du ha Windows 11-akryl bak panel, startmeny og varsler, kan utvidelsen
**Blur Cinnamon** legges til via Mints egen utvidelsesbehandling:

1. Systeminnstillinger → **Utvidelser** → fanen **Last ned** → søk «Blur Cinnamon» → Installer.
2. Fanen **Administrer** → velg Blur Cinnamon → **+** for å slå den på.
3. Åpne innstillingene (tannhjulet):
   - Slå på **Panels**, **Popup Menus** og **Notifications** (menyer og varsler er av som standard).
   - Uskarphet: **Dual Kawase Dynamic** (lett for skjermkortet, viser vinduene bak).
   - **Tint**: `#f3f3f3` med Mint-Ro, `#202020` med Mint-Ro-Dark, intensitet 60–75 % så teksten
     forblir lesbar.
   - Ikke velg «Transparent» for menyer – det gir gjennomsiktighet uten uskarphet.

Utvidelsen gjør bakgrunnene gjennomsiktige selv; temaet trenger ingen endring. Slå den av
igjen i samme vindu hvis noe hakker (det er rapportert treg rulling i menyer på GTX 1050).

### Bygge temaet selv

Ferdig CSS og bilder ligger i repoet, så vanlige brukere trenger ikke bygge noe.
Utviklere endrer `src/sass/` og bygger på nytt:

```bash
sudo apt install sassc librsvg2-bin
python3 -I src/build.py
```

Skriptet henter Mint-Y fra mint-themes 2.3.8, bytter aksentfarge, legger inn tokenene,
kompilerer og tegner bildene med aksentfarge på nytt.

## Lisens

GPL-3.0-or-later – se [LICENSE](LICENSE).

Mint-Ro er bygget på Mint-Y fra [mint-themes](https://github.com/linuxmint/mint-themes)
av Clement Lefebvre og Linux Mint-teamet, lisensiert GPL-3.0-or-later. Deler av stilen for
Nemo, oppgavelinjen og menyer er tilpasset fra [Fluent GTK theme](https://github.com/vinceliuice/Fluent-gtk-theme)
av vinceliuice, lisensiert GPL-3.0-or-later. Fluent-ikonene og Cinnamenu hentes fra sine egne prosjekter
og følger ikke med i repoet.
