#!/usr/bin/env python3
"""Bygger Mint-Ro fra kildekoden til Mint-Y (linuxmint/mint-themes).

Trinn:
  1. Hent mint-themes på fast versjon (UPSTREAM_TAG) eller bruk --mint-themes.
  2. Kopier Mint-Y til en arbeidsmappe og bytt Mint-grønt mot Mint-Ro-aksent.
  3. Injiser Mint-Ro-tokens rett etter Mint-Ys fargefil, og Mint-Ro-justeringer til slutt.
  4. Kompiler SCSS med sassc (samme libsass-motor som Mint bruker).
  5. Tegn på nytt bare de bildene som inneholder aksentfargen, i samme mål som Mint-Y.
  6. Skriv det ferdige temaet til repoets temamapper.

Bare utviklere trenger å kjøre dette; ferdig CSS og bilder sjekkes inn.
Krever: git, sassc, rsvg-convert.

Bruk:
  python3 -I src/build.py [--mint-themes MAPPE] [--sassc STI]
"""
import argparse
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile

UPSTREAM_REPO = "https://github.com/linuxmint/mint-themes"
UPSTREAM_TAG = "2.3.8"
MINT_ACCENT = "#35a854"
ACCENT = "#1f7a57"          # accent (lys) i docs/DESIGN.md
THEME_NAME = "Mint-Ro"

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SASS_SRC = os.path.join(REPO, "src", "sass")
OUTPUT_DIRS = ["cinnamon", "gtk-2.0", "gtk-3.0", "gtk-4.0", "libadwaita-1.5", "libadwaita-1.7", "metacity-1"]
TEXT_SUFFIXES = (".scss", ".css", ".svg", ".xml", ".rc", ".ini", ".txt")
TEXT_NAMES = ("gtkrc", "gtkrc-dark", "themerc", "themerc-dark")

# Inngangsfiler og hvilken token-mappe de skal få.
ENTRIES = {
    "cinnamon/sass/cinnamon.scss": "cinnamon",
    "gtk-3.0/sass/gtk.scss": "gtk-3.0",
    "gtk-3.0/sass/gtk-dark.scss": "gtk-3.0",
    "gtk-4.0/sass/gtk.scss": "gtk-4.0",
    "gtk-4.0/sass/gtk-dark.scss": "gtk-4.0",
}
COLORS_IMPORT = re.compile(r"""^(\s*@import\s+['"]_?colors['"];.*)$""", re.M)


class BuildError(Exception):
    pass


def log(msg):
    print(msg, flush=True)


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise BuildError("kommandoen feilet: %s\n%s" % (" ".join(cmd), (r.stderr or r.stdout).strip()))
    return r.stdout


def fetch_upstream(cache):
    dest = os.path.join(cache, "mint-themes-" + UPSTREAM_TAG)
    if os.path.isdir(os.path.join(dest, "src", "Mint-Y")):
        return dest
    os.makedirs(cache, exist_ok=True)
    log("Henter mint-themes %s ..." % UPSTREAM_TAG)
    run(["git", "clone", "--quiet", "--depth", "1", "--branch", UPSTREAM_TAG, UPSTREAM_REPO, dest])
    return dest


def is_text(path):
    name = os.path.basename(path)
    return name.endswith(TEXT_SUFFIXES) or name in TEXT_NAMES


def colorize(root):
    pat = re.compile(re.escape(MINT_ACCENT), re.I)
    n = 0
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            if not is_text(p):
                continue
            with open(p, encoding="utf-8", errors="surrogateescape") as fh:
                s = fh.read()
            s2, k = pat.subn(ACCENT, s)
            if k:
                with open(p, "w", encoding="utf-8", errors="surrogateescape") as fh:
                    fh.write(s2)
                n += k
    if n == 0:
        raise BuildError("fant ikke Mint-aksenten %s i kilden – har mint-themes endret seg?" % MINT_ACCENT)
    log("  aksent byttet %d steder" % n)


def inject(work):
    for rel, tokens in ENTRIES.items():
        p = os.path.join(work, rel)
        with open(p, encoding="utf-8") as fh:
            s = fh.read()
        if not COLORS_IMPORT.search(s):
            raise BuildError("fant ikke import av colors i %s" % rel)
        s = COLORS_IMPORT.sub(r"\1\n@import 'mint-ro-tokens';", s, count=1)
        s = s.rstrip("\n") + "\n@import 'mint-ro';\n"
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(s)
        for f in ("_mint-ro-tokens.scss", "_mint-ro.scss"):
            shutil.copy(os.path.join(SASS_SRC, tokens, f), os.path.join(os.path.dirname(p), f))


def compile_sass(work, sassc):
    for rel in ENTRIES:
        src = os.path.join(work, rel)
        out = os.path.join(os.path.dirname(os.path.dirname(src)), os.path.basename(rel).replace(".scss", ".css"))
        run([sassc, "-t", "expanded", src, out])
        log("  %s" % os.path.relpath(out, work))


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise BuildError("ikke en PNG: %s" % path)
    return struct.unpack(">II", head[16:24])


def render(svg, obj_id, w, h, out):
    run(["rsvg-convert", "-i", obj_id, "-w", str(w), "-h", str(h), "-o", out, svg])


def rerender_assets(orig_dir, work_dir, tmp):
    """Tegner bare bilder hvis objekt endret seg etter fargebyttet, i Mint-Ys mål."""
    svg_old = os.path.join(orig_dir, "assets.svg")
    svg_new = os.path.join(work_dir, "assets.svg")
    index = os.path.join(work_dir, "assets.txt")
    assets = os.path.join(work_dir, "assets")
    if not (os.path.exists(svg_new) and os.path.exists(index) and os.path.isdir(assets)):
        return 0
    changed = 0
    with open(index) as fh:
        ids = [l.strip() for l in fh if l.strip()]
    for obj in ids:
        for suffix in ("", "@2"):
            png = os.path.join(assets, obj + suffix + ".png")
            if not os.path.exists(png):
                continue
            w, h = png_size(png)
            a, b = os.path.join(tmp, "a.png"), os.path.join(tmp, "b.png")
            try:
                render(svg_old, obj, w, h, a)
            except BuildError:
                continue                    # objektet finnes ikke i svg-en; behold Mint-Ys bilde
            render(svg_new, obj, w, h, b)
            with open(a, "rb") as fa, open(b, "rb") as fb:
                if fa.read() == fb.read():
                    continue
            shutil.copy(b, png)
            changed += 1
    return changed


def assemble(work, out):
    """Samme utvalg som Mint-Ys build-themes.py for lys variant."""
    def cp(src, dst):
        s, d = os.path.join(work, src), os.path.join(out, dst)
        os.makedirs(os.path.dirname(d), exist_ok=True)
        (shutil.copytree if os.path.isdir(s) else shutil.copy)(s, d)

    cp("gtk-2.0/assets", "gtk-2.0/assets")
    for f in os.listdir(os.path.join(work, "gtk-2.0")):
        if f.endswith(".rc") or f == "gtkrc":
            cp("gtk-2.0/" + f, "gtk-2.0/" + f)
    for v in ("gtk-3.0", "gtk-4.0"):
        cp(v + "/assets", v + "/assets")
        cp(v + "/gtk.css", v + "/gtk.css")
        cp(v + "/gtk-dark.css", v + "/gtk-dark.css")
    cp("gtk-3.0/thumbnail.png", "gtk-3.0/thumbnail.png")
    cp("metacity-1", "metacity-1")
    cp("cinnamon/common-assets", "cinnamon/common-assets")
    cp("cinnamon/light-assets", "cinnamon/light-assets")
    cp("cinnamon/mint-y-thumbnail.png", "cinnamon/thumbnail.png")
    cp("cinnamon/cinnamon.css", "cinnamon/cinnamon.css")
    for d in os.listdir(work):
        if d.startswith("libadwaita-"):
            cp(d, d)


def rename_theme(out):
    """Visningsnavn i metacity-temaet."""
    p = os.path.join(out, "metacity-1", "metacity-theme-3.xml")
    with open(p, encoding="utf-8") as fh:
        s = fh.read()
    s = re.sub(r"<name>[^<]*</name>", "<name>%s</name>" % THEME_NAME, s, count=1)
    with open(p, "w", encoding="utf-8") as fh:
        fh.write(s)


GENERATED_README = """# {d}

Generert av `src/build.py` fra Mint-Y i mint-themes {tag}, med Mint-Ro-tokens.
Ikke rediger filene her direkte: endre `src/sass/` og kjør `python3 -I src/build.py`.
"""

INDEX_THEME = """[Desktop Entry]
Type=X-GNOME-Metatheme
Name={name}
Comment=Moderne Cinnamon-tema bygget på Mint-Y og Fluent-prinsipper
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme={name}
MetacityTheme={name}
IconTheme=Mint-Y
CursorTheme=DMZ-White
ButtonLayout=:minimize,maximize,close
"""


def main():
    ap = argparse.ArgumentParser(description="Bygg Mint-Ro fra Mint-Y.")
    ap.add_argument("--mint-themes", help="ferdig utsjekket mint-themes %s" % UPSTREAM_TAG)
    ap.add_argument("--sassc", default="sassc", help="sti til sassc")
    ap.add_argument("--cache", default=os.path.join(os.path.expanduser("~"), ".cache", "mint-ro-build"))
    a = ap.parse_args()

    for tool in (a.sassc, "rsvg-convert", "git"):
        if not shutil.which(tool):
            raise BuildError("mangler %s. På Mint: sudo apt install sassc librsvg2-bin git" % tool)

    upstream = a.mint_themes or fetch_upstream(a.cache)
    mint_y = os.path.join(upstream, "src", "Mint-Y")
    if not os.path.isdir(mint_y):
        raise BuildError("fant ikke src/Mint-Y i %s" % upstream)

    with tempfile.TemporaryDirectory(prefix="mint-ro-") as tmp:
        work = os.path.join(tmp, "Mint-Y")
        shutil.copytree(mint_y, work)
        log("Bytter aksentfarge %s → %s" % (MINT_ACCENT, ACCENT))
        colorize(work)
        log("Injiserer Mint-Ro-tokens")
        inject(work)
        log("Kompilerer SCSS")
        compile_sass(work, a.sassc)
        log("Tegner bilder med aksentfarge")
        for v in ("gtk-2.0", "gtk-3.0", "gtk-4.0"):
            n = rerender_assets(os.path.join(mint_y, v), os.path.join(work, v), tmp)
            log("  %s: %d bilder" % (v, n))

        out = os.path.join(tmp, "out")
        os.makedirs(out)
        assemble(work, out)
        rename_theme(out)

        log("Skriver tema til repoet")
        for d in OUTPUT_DIRS:
            dst = os.path.join(REPO, d)
            if os.path.isdir(dst):
                shutil.rmtree(dst)
            if os.path.isdir(os.path.join(out, d)):
                shutil.copytree(os.path.join(out, d), dst)
                with open(os.path.join(dst, "README.md"), "w", encoding="utf-8") as fh:
                    fh.write(GENERATED_README.format(d=d, tag=UPSTREAM_TAG))
        with open(os.path.join(REPO, "index.theme"), "w", encoding="utf-8") as fh:
            fh.write(INDEX_THEME.format(name=THEME_NAME))
    log("Ferdig.")


if __name__ == "__main__":
    try:
        main()
    except BuildError as e:
        print("Feil: %s" % e, file=sys.stderr)
        sys.exit(1)
