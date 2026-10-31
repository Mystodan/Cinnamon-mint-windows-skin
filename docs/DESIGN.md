# Designgrunnlag

Mint-Ro bygger på prinsippene i Microsoft Fluent Design, tilpasset Cinnamon og
Linux Mint. Windows 11 er referanse for **arbeidsflyt og kjente mønstre** i
filutforsker, startmeny og oppgavelinje – ikke en mal som skal kopieres.

Hvert designvalg vurderes etter ett spørsmål: *gjør dette skrivebordet tydeligere,
mer sammenhengende eller enklere å bruke?* Hvis svaret er nei, droppes det.

## Prinsipper

| Fluent-prinsipp | Slik gjør vi det i Cinnamon |
| --- | --- |
| **Naturlig på plattformen** | Bruk Cinnamons egne komponenter (panel, applets, Nemo, Muffin) og Mints funksjoner. Mint-grønn aksent, systemets skrift, XApp-ikoner. Ingen erstatning av skrivebordet. |
| **Hjelper brukeren å holde fokus** | Tydelig hierarki med få nivåer, lite rammer og rot, én tydelig primærhandling per flate. |
| **Tilgjengelig for alle** | WCAG 2.2 AA-kontrast, synlig tastaturfokus, store nok klikkflater, støtte for tekstskalering, høy kontrast og redusert bevegelse. |
| **Konsekvent språk** | Felles tokens for avstand, typografi, farge, lag og bevegelse i panel, meny, Nemo, vinduer og dialoger. |

## Grenser

- Ingen Microsoft-logoer, varemerker, Segoe-skrift, Fluent-ikoner fra Microsoft, lyder eller grafikk.
- Ingen piksel-for-piksel-kopi. Proporsjoner og mønstre kan ligne; detaljene er våre egne.
- Transparens og animasjon brukes bare der de ikke svekker lesbarhet, ytelse eller tilgjengelighet.
  Cinnamon kan ikke gjøre ekte uskarphet (Mica/Acrylic). Vi bruker derfor **lagdelte, tette flater**
  i stedet for halvgjennomsiktige; eventuell transparens er valgfri og ligger aldri bak tekst.

## Designtokens

Alle stilfiler henter verdier herfra. Endringer gjøres her først.

### Farger

| Token | Lys | Mørk | Bruk |
| --- | --- | --- | --- |
| `bg-base` | `#f3f3f3` | `#202020` | Skrivebordsnære flater, vindusbakgrunn |
| `bg-layer` | `#fbfbfb` | `#2b2b2b` | Innholdsflater, meny, flyouts, sidestolpe-innhold |
| `bg-subtle-hover` | `#0000000a` | `#ffffff0f` | Hover på listeelementer og knapper uten fyll |
| `bg-subtle-pressed` | `#00000006` | `#ffffff0a` | Trykket tilstand |
| `fg-primary` | `#1b1b1b` | `#f2f2f2` | Brødtekst (15,5:1 / 14,6:1) |
| `fg-secondary` | `#5f5f5f` | `#a8a8a8` | Hjelpetekst, metadata (5,8:1 / 6,9:1) |
| `accent` | `#1f7a57` | `#4fc79a` | Primærknapp, valgt element, fokusring, lenker |
| `fg-on-accent` | `#ffffff` | `#0f2b1f` | Tekst på aksent (5,3:1 / 7,2:1) |
| `stroke-control` | `#8a8a8a` | `#8a8a8a` | Kant på felt, avkrysningsbokser (≥ 3:1) |
| `stroke-divider` | `#e5e5e5` | `#3b3b3b` | Dekorative skillelinjer (ikke informasjonsbærende) |
| `danger` | `#c42b1c` | `#ff99a4` | Feil, destruktive handlinger (5,5:1 / 7,0:1) |

Kontrastverdiene er regnet ut mot `bg-layer`/`bg-base`. Mint sin vanlige grønnfarge
`#35a77c` gir bare 3:1 med hvit tekst og er derfor ikke brukt til tekst eller knappefyll.

### Avstand

4 px-rutenett: `4 · 8 · 12 · 16 · 24 · 32`. Indre marg i kontroller 8/12 px,
mellom grupper 16–24 px.

### Hjørner

| Element | Radius |
| --- | --- |
| Knapper, felt, listeelementer, faner | 4 px |
| Vinduer, menyer, flyouts, varsler, dialoger | 8 px |
| Panel | 0 px (kant til kant) |

### Typografi

Systemets skrift (Mint: Ubuntu / Noto Sans), slik brukeren har valgt den. Størrelser
angis relativt (`em`) så tekstskalering virker overalt.

| Rolle | Relativ størrelse | Vekt |
| --- | --- | --- |
| Bildetekst | 0,85 em | normal |
| Brødtekst | 1 em | normal |
| Brødtekst sterk | 1 em | 600 |
| Undertittel | 1,4 em | 600 |
| Tittel | 2 em | 600 |

### Lag og skygger

| Nivå | Brukes til | Skygge |
| --- | --- | --- |
| 0 | Panel, vindusbakgrunn | ingen |
| 1 | Kort, valgt element | ingen, eventuelt 1 px `stroke-divider` |
| 2 | Kontekstmeny, verktøytips | `0 4px 8px rgba(0,0,0,.14)` |
| 3 | Startmeny, kalender, varsler, dialoger | `0 8px 16px rgba(0,0,0,.18)` |
| 4 | Aktive vinduer | `0 16px 32px rgba(0,0,0,.24)` |

### Bevegelse

| Token | Varighet | Bruk |
| --- | --- | --- |
| `motion-fast` | 150 ms | Hover, trykk, fokus |
| `motion-normal` | 250 ms | Åpne meny, flyout, varsel |
| Easing | avtagende (ease-out) | Inn; utgang er raskere enn inngang |

Når animasjoner er slått av (`enable-animations` eller Cinnamons effekter), skal alt
fungere uten bevegelse.

## Tilgjengelighet

- Tekst ≥ 4,5:1 kontrast, kontrollkanter og fokusring ≥ 3:1.
- Fokusring: 2 px `accent`, 1 px avstand, synlig i alle tastaturnavigerbare elementer.
- Minste klikkflate 32 × 32 px; panelikoner 40 × 40 px.
- Tilstand vises aldri bare med farge (valgt = farge + markør/vekt).
- Temaet må fungere med tekstskalering 1,0–1,5 og med HighContrast som eget valg.
- Testes med tastatur alene i Nemo, meny, panel og dialoger.

## Windows 11-mønstre vi tar med

| Område | Mønster | Hvorfor |
| --- | --- | --- |
| Oppgavelinje | Senterstilte festede og åpne apper, menyknapp først | Kjent for Windows-brukere; valgfritt venstrestilt |
| Oppgavelinje | Diskret indikator under åpne apper, lengre for aktivt vindu | Tydelig status uten tekst |
| Oppgavelinje | Klokke og dato i to linjer helt til høyre, varsler ved siden av | Kjent plassering |
| Startmeny | Søk tilgjengelig straks Super trykkes | Raskeste vei til apper |
| Startmeny | Festede apper øverst, alle apper ett klikk unna | Lite rot, rask tilgang |
| Filutforsker | Tilbake/fram/opp til venstre, adresse i midten, søk til høyre | Kjent navigasjon |
| Filutforsker | Adresse som brødsmuler, tekstfelt ved klikk (Ctrl+L) | Oversikt og presisjon |
| Filutforsker | Sidestolpe: Hjem, festede mapper, denne PC-en, nettverk | Kjent struktur |
| Filutforsker | «Kopier som bane», «Åpne i terminal» i kontekstmenyen | Vanlige oppgaver |
| Vinduer | Avrundede hjørner, tydelig aktivt vindu via skygge | Hierarki |
