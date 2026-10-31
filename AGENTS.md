# Retningslinjer for bidrag (mennesker og AI-agenter)

Dette repoet bygges av flere bidragsytere, også AI-agenter. Disse reglene gjelder alle.

## Må

- Behold Cinnamon som skrivebordsmiljø. Bruk bare formater Cinnamon, Muffin og GTK støtter.
- Installer kun per bruker (`~/.themes`, `~/.icons`, `~/.config`, `~/.local/share/cinnamon`, `~/.local/share/nemo`). Aldri `sudo`, aldri `/usr`.
- Kjør `scripts/map-mint.sh` (sikkerhetskopi) før noe aktiveres eller overskrives.
- Hver endring av brukeroppsett må kunne tilbakeføres med `scripts/restore.sh`.
- Temafiler i `cinnamon/`, `gtk-3.0/`, `gtk-4.0/` (og senere `metacity-1/`). Skript i `scripts/`, dokumentasjon i `docs/`.
- Sjekk aldri inn brukerens sikkerhetskopier eller rapporter med personlige data utenom `docs/survey/`.
- Bygg på kartleggingsrapporten i `docs/survey/`. Ikke anta Cinnamon- eller GTK-versjon.
- Følg designgrunnlaget og bruk tokens fra `docs/DESIGN.md` i stedet for spredte verdier.
- Prioriter filutforsker, startmeny og oppgavelinje (se `docs/PLAN.md`). Arbeidsflyt går foran visuell likhet.
- Sorter hver endring som A (tema/innstilling), B (applet/utvidelse/handling) eller C (ikke støttet trygt), og gjør ikke C.

## Må ikke

- Kopiere Windows-logoer, varemerker, ikoner, lyder eller annen proprietær grafikk.
- Bruke navnet «Windows» i temanavn eller filnavn som brukeren ser.
- Overskrive `~/.config/gtk-4.0` uten `--gtk4` og sikkerhetskopi.
- Endre systemfiler eller Mint-pakker.

## Arbeidsflyt

- Små, avgrensede commits på `main` med beskrivende melding (norsk eller engelsk).
- Skallskript: `bash`, `set -uo pipefail` med eksplisitt feilhåndtering og tydelige meldinger, må passere `bash -n` (og `shellcheck` hvis tilgjengelig).
- Oppdater `docs/PLAN.md` når et trinn er ferdig eller planen endres.
