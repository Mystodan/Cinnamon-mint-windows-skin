# Implementeringsplan

Planen følger arbeidsmåten i prosjektbeskrivelsen. Hvert trinn leveres som egne
commits på `main`, og ingenting aktiveres på maskinen uten sikkerhetskopi.

## Trinn 0 – Kartlegging (før alt annet)

Kjør `scripts/map-mint.sh` og kopier `rapport.md` til `docs/survey/`. Den avgjør:

- **Cinnamon-versjon** – hvilke CSS-selektorer `cinnamon.css` støtter, og om
  panel/meny har nye klasser (Cinnamon 6.x endret flere).
- **GTK 3- og GTK 4-versjon** – hvilke egenskaper som fungerer, og om
  libadwaita-apper trenger egen behandling.
- **Eksisterende tema** (som regel Mint-Y eller Mint-L) – mulig utgangspunkt.
- **Compositor/skjermkort** – om transparens og skygger er realistisk.
- **Applets i bruk** – hvilke panel-elementer temaet må dekke.

Ingen versjon antas før rapporten finnes.

## Hva kan gjøres med tema, og hva krever mer

| Del | Løsning | Merknad |
| --- | --- | --- |
| Panel, systemstatusfelt | `cinnamon/cinnamon.css` | Senterstilte oppgaveknapper krever panelinnstillinger (sonelayout), ikke CSS |
| Hovedmeny | `cinnamon.css` + innstillinger for Menu-applet | Søkefelt øverst og rutenett krever eventuelt en alternativ meny-applet fra Spices |
| Varsler, OSD, dialoger | `cinnamon.css` | |
| Vindusrammer og knapper | `metacity-1/` (XML + SVG) og GTK `headerbar` | Avrunding av rammer i Muffin er begrenset; skygger via GTK CSD |
| GTK 3-apper | `gtk-3.0/gtk.css` | Største arbeidsmengde |
| GTK 4 / libadwaita | `gtk-4.0/` + valgfri `~/.config/gtk-4.0` | Kun på uttrykkelig valg (`--gtk4`) |
| Ikoner | Eksisterende fri ikonpakke (f.eks. Fluent- eller Papirus-familien) | Velges etter kartlegging; ingen Microsoft-grafikk |
| Markører | Eksisterende fri markørpakke | |

## Struktur

Repoet er temamappen. Installasjonen kopierer dette til `~/.themes/Mint-Ro/`:

```
index.theme
cinnamon/cinnamon.css   (+ assets/)
gtk-3.0/gtk.css, gtk-dark.css
gtk-4.0/gtk.css, gtk-dark.css
metacity-1/metacity-theme-3.xml (+ SVG-knapper)
```

Mørk variant av Cinnamon-skallet krever et eget tema (`Mint-Ro-Dark`), fordi
Cinnamon ikke har `cinnamon-dark.css`. Den genereres fra samme kilde ved installasjon.

Stilfilene skrives som SCSS i `src/` hvis det blir behov for felles variabler
på tvers av lys/mørk; ferdig CSS sjekkes inn slik at installasjon ikke krever
byggeverktøy.

## Designtokens

Felles for alle deler, defineres én gang per variant:

| Token | Lys | Mørk |
| --- | --- | --- |
| Bakgrunn | `#f3f3f3` | `#202020` |
| Flate (kort, meny) | `#fbfbfb` | `#2b2b2b` |
| Tekst | `#1b1b1b` | `#f2f2f2` |
| Aksent | Mint-grønn `#35a77c` (justerbar) | `#4fc79a` |
| Radius vinduer / menyer | 8 px | 8 px |
| Radius kontroller | 4 px | 4 px |
| Panelhøyde | 48 px | 48 px |
| Skrift | systemets (Ubuntu/Noto Sans) | |

Verdiene er startpunkt og justeres etter test på faktisk maskin.

## Trinn

1. **Kartlegging** – `scripts/map-mint.sh`, rapport i `docs/survey/`. *(Verktøy ferdig, venter på kjøring på Mint-maskinen.)*
2. **Skjelett** – `index.theme`, minimal fungerende `cinnamon.css`, GTK 3/4 som
   arver fra eksisterende Mint-tema, så temaet kan aktiveres uten å knekke noe.
3. **Panel og systemstatusfelt.**
4. **Hovedmeny og appoversikt.**
5. **Vindusrammer, knapper, skygger** (metacity + GTK headerbar).
6. **Dialoger, kontekstmenyer, varsler, OSD.**
7. **GTK 3-kontroller** – knapper, felt, lister, faner, rullefelt.
8. **GTK 4** – samme uttrykk, og valgfri libadwaita-overstyring.
9. **Mørk variant.**
10. **Ikoner og markører** – velg og dokumenter fri pakke.
11. **Testrunde** – Nemo, Innstillinger, Programvaresenter, Oppdateringshåndterer,
    Terminal, Firefox, en libadwaita-app, Alt+Tab, Expo, låseskjerm.
12. **Dokumentasjon** – skjermbilder og tilpasning i README.

## Regler for alle bidragsytere

Se [AGENTS.md](../AGENTS.md).
