# Implementeringsplan

Målet er at **filutforskeren, startmenyen og oppgavelinjen** i Cinnamon føles moderne og
kjente for en Windows 11-bruker, uten at Cinnamon eller Mint sine egne funksjoner går tapt.
Arbeidsflyt og brukervennlighet går foran visuell likhet. Designgrunnlaget står i
[DESIGN.md](DESIGN.md).

Hvert trinn leveres som egne commits på `main`. Ingenting aktiveres uten at
`scripts/map-mint.sh` har tatt sikkerhetskopi, og alt kan tilbakeføres med `scripts/restore.sh`.

## Utgangspunkt

Planen er skrevet for gjeldende Mint 22.3 med Cinnamon 6.6 og Nemo 6.6, men **ingen versjon
antas**: kartleggingsrapporten fra maskinen avgjør, og planen justeres etter den.
Relevant fra Cinnamon/Nemo 6.6:

- Hovedmenyen er redesignet, med flere valg (søkefeltets plassering, beskrivelser,
  kategoriikoner, filsøk) og systemknapper i sidestolpen.
- Oppgavelinjen kan vise merker med antall uleste varsler på appikoner.
- Nemo har fått mal-behandler i innstillingene, knapp for to ruter i verktøylinjen,
  pause og gjenoppta av filoperasjoner, og ikoner på handlinger.
- Mint 23 (Cinnamon 6.8, ventet rundt jul 2026) får full Wayland-støtte. Kartleggingen
  registrerer om økten er X11 eller Wayland.

### Funn fra første maskin (31.10.2026)

Første kartlegging (`map-mint.sh` v1) manglet alle `org.cinnamon`-innstillinger på grunn av
en feil i skriptet, rettet i v2. Panel, aktive temaer og effekter må derfor kartlegges på nytt.
Det som er bekreftet:

| Område | Funn | Betydning for planen |
| --- | --- | --- |
| System | Mint 22.3, Cinnamon 6.6.9, Muffin 6.6.3, Nemo 6.6.3, X11 | Planen for 6.6 gjelder. Bygg og test for X11 først |
| GTK | GTK 3.24.41, GTK 4.14.5, libadwaita 1.5.0 med Mint-patcher (`mint3`), libAdapta ikke installert | Undersøk om Mints libadwaita lar `gtk-4.0` i temaet virke, før `~/.config/gtk-4.0` vurderes |
| Grunntema | `mint-themes` 2.3.8, `mint-l-theme` 2.0.6 | Skjelettet bygges fra kildekoden til mint-themes 2.3.8, så alle selektorer i Cinnamon 6.6 dekkes |
| Grafikk | NVIDIA GTX 1050, én skjerm 1920×1080 | Skygger og compositing er realistisk; test også med skalering |
| Applets | Bare innebygde, ingen fra Spices | Standardprofilen kan bygges helt på innebygde applets (A) |
| Nemo-utvidelser | `nemo-preview`, `nemo-fileroller`, `nemo-share`, `nemo-emblems` | Hurtigvisning og komprimering finnes allerede |
| Nemo-handlinger | Ingen egne; Mints standardhandlinger | «Kopier som bane» må legges til som egen handling |
| Ikoner og markører | Papirus og Bibata er installert | Gode, frie kandidater – ingen nye pakker trengs |
| `sassc` | Ikke installert | Ferdig CSS sjekkes inn; brukeren trenger ikke byggeverktøy |

Nemo er allerede nær målet. Verktøylinjen viser tilbake, fram, opp, søk,
adressebytte og visningsvalg. Adressen vises som brødsmuler, og menylinje, sidestolpe
og statuslinje er på. Profilen trenger bare disse endringene:

| Nøkkel | Nå | Foreslått | Hvorfor |
| --- | --- | --- | --- |
| `show-reload-icon-toolbar` | `false` | `true` | Oppdater-knapp som i Windows 11 |
| `list-view default-column-order` / `default-visible-columns` | navn, størrelse, type, endret | navn, endret, type, størrelse | Kjent kolonnerekkefølge |
| `list-view default-zoom-level` | `smaller` | `small` | Litt luftigere rader, i tråd med 32 px-rader |

Disse beholdes som de er, fordi de er brukerens egne valg: skjulte filer vises,
dobbeltklikk, mapper først og ikonvisning som standard.

## Tre kategorier

Alle endringer sorteres i én av tre kategorier:

- **A – Tema og innstillinger.** CSS i temaet og `gsettings`-verdier. Tryggest, oppdateres
  med Mint, tilbakeføres med `restore.sh`.
- **B – Applet, utvidelse eller Nemo-handling.** Eksisterende, vedlikeholdte komponenter
  (Cinnamon-spices, Nemo-handlinger og -utvidelser fra Mint-arkivet). Alltid valgfritt.
- **C – Ikke støttet trygt.** Krever endring i Cinnamon- eller Nemo-kildekoden, eller en
  ustabil tredjepartskomponent. Gjøres ikke; vi bruker nærmeste trygge alternativ.

## Prioritet 1: Filutforsker (Nemo)

| Mål | Løsning | Kat. |
| --- | --- | --- |
| Ryddig verktøylinje: tilbake, fram, opp, oppdater til venstre | Nemos egne valg for knapper i verktøylinjen; skjul Hjem/Datamaskin-knappene (dekkes av sidestolpen) | A |
| Adressefelt som brødsmuler, tekstfelt med Ctrl+L | Nemos stilinje som standard; temaet tegner den som ett avrundet felt | A |
| Søk lett synlig | Søkeknapp plassert til høyre, Ctrl+F og Ctrl+L forklares i README | A |
| Alltid synlig søkefelt ved siden av adressen (som i Windows 11) | Nemo bytter adressefeltet ut med søkefelt; et eget fast felt krever kodeendring | C |
| Visningsvalg (ikoner/liste/kompakt) i verktøylinjen | Nemos visningsbytter, stilt som segmentert kontroll | A |
| Oversiktlig sidestolpe | Steder-visning; temaet gir seksjonsoverskrifter, 32 px rader, avrundet markering. Bokmerker fungerer som «festede mapper» (Ctrl+D) | A |
| Menylinje | Beholdes, men gjøres kompakt og flat. Valgfritt: skjules (F10/Alt viser den) | A |
| Konsistent ikonstørrelse og typografi | Standard zoomnivå per visning; kolonnerekkefølge Navn, Endret, Type, Størrelse | A |
| Faner og to ruter | Nemos faner (Ctrl+T) og to ruter (F3) stiles som Windows-faner, men innenfor vinduet | A |
| Faner i tittellinjen | Krever kodeendring i Nemo | C |
| Moderne kontekstmenyer | GTK-menyer med 8 px radius, 4 px avstand, ikoner og jevn radhøyde | A |
| Rekkefølge og innhold i kontekstmenyen | Nemos egen layout-editor for handlinger (nemo-action-layout-editor) | A |
| «Kopier som bane», «Åpne i terminal», «Komprimer» | Nemo-handlinger i `nemo/actions/` i repoet; `nemo-fileroller` for komprimering | B |
| Nye filer fra maler | Nemos mal-behandler (6.6) med noen vanlige maler | A |
| Hurtigvisning | `nemo-preview` (mellomrom), en Linux-fordel som beholdes | B |
| Kommandolinje med klipp/kopier/lim inn/gi nytt navn/slett som ikoner | Nemos verktøylinje støtter ikke disse knappene | C |
| Detalj- og forhåndsvisningsrute til høyre | Finnes ikke i Nemo; hurtigvisning og egenskaper dekker behovet | C |
| Statuslinje med antall elementer og zoom | Nemos statuslinje, gjort slank | A |

## Prioritet 2: Startmeny og oppgavelinje

### Oppgavelinje (panel)

| Mål | Løsning | Kat. |
| --- | --- | --- |
| Panel nederst, 48 px, ikoner i jevn størrelse | Panelinnstillinger og sonevise ikonstørrelser | A |
| Senterstilte apper med menyknapp først | Menyknapp og gruppert vindusliste flyttes til panelets midtsone. Venstrestilt som eget valg | A |
| Tydelige ikoner for festede og åpne apper | Innebygd gruppert vindusliste: bare ikoner, festede apper, temaet tegner indikator (prikk/strek) og hover-flate | A |
| Merker med uleste varsler | Innebygd i Cinnamon 6.6 | A |
| Systemstatus til høyre: brett, nettverk, lyd, batteri | Innebygde applets i fast rekkefølge, samme størrelse og hover | A |
| Klokke og dato i to linjer | Kalender-appletens eget tidsformat | A |
| Kalender og varsler | Innebygd kalender og varsel-applet; temaet gir dem samme flyout-stil | A |
| «Vis skrivebord» i hjørnet | Innebygd Cornerbar-applet helt til høyre | A |
| Samlet hurtiginnstillinger-flyout (nett + lyd + lys i én) | Finnes ikke i Cinnamon; separate applets stiles likt | C |
| Ekte uskarphet (Mica/Acrylic) bak panel og meny | Cinnamon-temaer kan ikke gjøre uskarphet; tredjeparts blur-utvidelser er ikke standard | C |

### Startmeny

| Mål | Løsning | Kat. |
| --- | --- | --- |
| Søk straks Super trykkes | Standard i Cinnamon-menyen | A |
| Ryddig meny med kjent struktur | Innebygd meny (6.6) med søkefelt (plassering kan velges), favoritter, kategorier og systemknapper; temaet gir 8 px radius, luft og tydelig hierarki | A |
| Festede apper som rutenett og «Alle apper»-liste | Cinnamenu fra Spices støtter rutenett, favoritter i sidestolpe og filsøk. Tilbys som **valgfri profil**; innebygd meny er standard | B |
| Anbefalte filer | Nylige filer finnes i begge menyer som kategori | A/B |
| Egen ny meny | Bygges ikke – Cinnamon har stabile løsninger | – |

## Prioritet 3: Helhet

| Område | Løsning | Kat. |
| --- | --- | --- |
| Vindusrammer og knapper | `metacity-1/` + GTK headerbar; avrundede øvre hjørner, tydelig aktivt vindu | A |
| Dialoger, OSD, Alt+Tab, varsler | `cinnamon.css` med samme lag og radius som menyen | A |
| GTK 3-apper | `gtk-3.0/` med tokens fra DESIGN.md | A |
| GTK 4 / libadwaita | `gtk-4.0/`; Mint-forken libAdapta kan gjøre at libadwaita-apper følger temaet – sjekkes i kartleggingen | A |
| Mørk modus | Egen `Mint-Ro-Dark` for Cinnamon-skallet; GTK følger systemets fargeskjema | A |
| Ikoner og markører | Fri ikonpakke som passer uttrykket; velges etter kartlegging | A |
| Fest vinduer til kanter og hjørner | Innebygd i Cinnamon (dra til kant, Super+piltaster) | A |
| Snap-layout-meny over maksimer-knappen | Finnes ikke i Cinnamon | C |

## Leveranse: oppsettsprofil

Innstillingene (kategori A uten CSS) samles i et skript, `scripts/apply-profile.sh`, med
profiler som `standard`, `sentrert` og `cinnamenu`. Skriptet:

1. kjører `map-mint.sh` først,
2. viser hva som endres og ber om bekreftelse,
3. setter bare `gsettings`-nøkler og kopierer Nemo-handlinger til `~/.local/share/nemo/actions`,
4. kan angres helt med `restore.sh`.

Tema og profil er uavhengige: temaet kan brukes med vanlig Mint-oppsett, og profilen med
vanlig Mint-tema.

## Milepæler

| # | Leveranse | Status |
| --- | --- | --- |
| 1 | Grunnstruktur, `map-mint.sh`, `restore.sh`, README | Ferdig |
| 2 | Kartlegging av faktisk maskin (inkl. Nemo, applets, utvidelser) og justert plan | Delvis – Nemo og pakker kartlagt; panel og temaer må kjøres på nytt med v2 |
| 3 | Tema-skjelett: `index.theme` og `cinnamon.css` bygget fra kildekoden til mint-themes for **installert** versjon (så alle selektorer dekkes), tokens innført | |
| 4 | **Nemo:** GTK-stil for verktøylinje, adresse, sidestolpe, visninger, kontekstmenyer + Nemo-del av profilen + handlinger | |
| 5 | **Oppgavelinje:** panel, vindusliste, systemstatus, kalender, varsler + panel-del av profilen | |
| 6 | **Startmeny:** stil for innebygd meny + valgfri Cinnamenu-profil | |
| 7 | Vinduer, dialoger, OSD, Alt+Tab | |
| 8 | GTK 3 generelt, GTK 4/libadwaita | |
| 9 | Mørk modus, tilgjengelighetstest (tastatur, tekstskalering, høy kontrast, uten animasjoner) | |
| 10 | `install.sh`/`uninstall.sh`, skjermbilder og brukerveiledning | |

## Testliste per milepæl

Nemo (alle visninger, faner, to ruter, søk, kontekstmeny), hovedmeny (søk, favoritter,
tastatur), panel (festede/åpne apper, systemstatus, kalender, varsler), Systeminnstillinger,
Programvarebehandler, Oppdateringshåndterer, Terminal, Firefox, én libadwaita-app,
Alt+Tab, Expo, låseskjerm, innloggingsdialog for passord.
