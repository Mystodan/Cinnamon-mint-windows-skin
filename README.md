# Mint-Ro

Et moderne tema og oppsett for Linux Mint Cinnamon, bygget på prinsippene i
Fluent Design. Målet er at **filutforskeren, startmenyen og oppgavelinjen** skal føles
moderne og kjente for en Windows 11-bruker – med arbeidsflyt foran visuell likhet –
samtidig som skrivebordet beholder sin Mint- og Cinnamon-identitet.

Prosjektet bruker bare Cinnamons egne komponenter, tema- og innstillingsformater.
Det inneholder ingen Microsoft-logoer, varemerker, ikoner, lyder eller annen
proprietær grafikk. Se [designgrunnlaget](docs/DESIGN.md) og [planen](docs/PLAN.md).

> **Status – milepæl 1 ferdig:** grunnstruktur, kartlegging og sikkerhetskopiering.
> **Klart til test:** oppsettsprofil for Nemo og oppgavelinjen (`apply-profile.sh`).
> **Neste:** tema-skjelett, deretter Nemo-, panel- og menystil.

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
| `nemo/actions/` | Nemo-handlinger, som «Kopier som bane» |
| `scripts/` | Kartlegging, sikkerhetskopi, gjenoppretting og oppsettsprofiler |
| `backups/` | Tom i Git – sikkerhetskopier lagres lokalt (se under) |
| `docs/` | Designgrunnlag, plan og kartleggingsrapporter som deles bevisst |

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
| `alt` | `nemo` + `oppgavelinje` |

Skriptet viser hver endring med gammel og ny verdi, ber om bekreftelse og tar
sikkerhetskopi med `map-mint.sh` først. Angre med kommandoen det skriver ut, eller med
`./scripts/restore.sh`. Dine egne valg, som skjulte filer og dobbeltklikk, røres ikke.

«Kopier som bane» bruker `xclip`, `xsel`, `wl-copy` eller GTK, avhengig av hva som finnes.

## Installasjon av temaet

Kommer i neste milepæl, når kartleggingen er gjort. Installasjonen vil:

- kopiere temaet til `~/.themes/Mint-Ro/`
- kjøre `map-mint.sh` før noe aktiveres
- bare røre `~/.config/gtk-4.0` (for libadwaita-apper) hvis du ber om det

## Lisens

Ikke valgt ennå. Forslag: GPL-3.0-or-later, i tråd med Cinnamon og Mint-temaene.
