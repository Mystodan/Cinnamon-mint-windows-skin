#!/usr/bin/env python3
"""Bygger Mint-Ro og Mint-Ro-Dark fra kildekoden til Mint-Y (linuxmint/mint-themes).

Trinn per variant:
  1. Hent mint-themes på fast versjon (UPSTREAM_TAG) eller bruk --mint-themes.
  2. Kopier Mint-Y til en arbeidsmappe og bytt Mint-grønt mot variantens aksentfarge.
  3. Injiser Mint-Ro-tokens rett etter Mint-Ys fargefil, og Mint-Ro-justeringer til slutt.
  4. Kompiler SCSS med sassc (samme libsass-motor som Mint bruker).
  5. Tegn på nytt bare de bildene som inneholder aksentfargen, i samme mål som Mint-Y.
  6. Juster vindusrammen (avrunding) og libadwaita-farger.
  7. Skriv temaet til repoet: lys variant i roten, mørk i Mint-Ro-Dark/.

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

# Aksentfarger fra docs/DESIGN.md. «fill» brukes som bakgrunn med hvit tekst,
# «text» som tekst/lenke på variantens bakgrunn.
ACCENT_LIGHT_FILL = "#1f7a57"
ACCENT_DARK_FILL = "#22855f"
ACCENT_DARK_TEXT = "#4fc79a"
WINDOW_RADIUS = 8

VARIANTS = {
    "light": {"name": "Mint-Ro", "dir": "", "accent": ACCENT_LIGHT_FILL,
              "cinnamon": "cinnamon.scss", "gtk": "gtk.scss"},
    "dark": {"name": "Mint-Ro-Dark", "dir": "Mint-Ro-Dark", "accent": ACCENT_DARK_FILL,
             "cinnamon": "cinnamon-dark.scss", "gtk": "gtk-dark.scss"},
}

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SASS_SRC = os.path.join(REPO, "src", "sass")
OUTPUT_DIRS = ["cinnamon", "gtk-2.0", "gtk-3.0", "gtk-4.0", "libadwaita-1.5", "libadwaita-1.7", "metacity-1"]
TEXT_SUFFIXES = (".scss", ".css", ".svg", ".xml", ".rc", ".ini", ".txt")
TEXT_NAMES = ("gtkrc", "gtkrc-dark", "themerc", "themerc-dark")

# Inngangsfiler og hvilken token-mappe de skal få.
ENTRIES = {
    "cinnamon/sass/cinnamon.scss": "cinnamon",
    "cinnamon/sass/cinnamon-dark.scss": "cinnamon",
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


def read(p):
    with open(p, encoding="utf-8", errors="surrogateescape") as fh:
        return fh.read()


def write(p, s):
    with open(p, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(s)


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


def colorize(root, accent):
    pat = re.compile(re.escape(MINT_ACCENT), re.I)
    n = 0
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            if not is_text(p):
                continue
            s2, k = pat.subn(accent, read(p))
            if k:
                write(p, s2)
                n += k
    if n == 0:
        raise BuildError("fant ikke Mint-aksenten %s i kilden – har mint-themes endret seg?" % MINT_ACCENT)
    return n


def inject(work):
    for rel, tokens in ENTRIES.items():
        p = os.path.join(work, rel)
        s = read(p)
        if not COLORS_IMPORT.search(s):
            raise BuildError("fant ikke import av colors i %s" % rel)
        s = COLORS_IMPORT.sub(r"\1\n@import 'mint-ro-tokens';", s, count=1)
        write(p, s.rstrip("\n") + "\n@import 'mint-ro';\n")
        for f in ("_mint-ro-tokens.scss", "_mint-ro.scss"):
            shutil.copy(os.path.join(SASS_SRC, tokens, f), os.path.join(os.path.dirname(p), f))


def compile_sass(work, sassc):
    for rel in ENTRIES:
        src = os.path.join(work, rel)
        out = os.path.join(os.path.dirname(os.path.dirname(src)), os.path.basename(rel).replace(".scss", ".css"))
        run([sassc, "-t", "expanded", src, out])


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise BuildError("ikke en PNG: %s" % path)
    return struct.unpack(">II", head[16:24])


def render(svg, obj_id, w, h, out):
    run(["rsvg-convert", "-i", obj_id, "-w", str(w), "-h", str(h), "-o", out, svg])


def rerender_assets(orig_dir, work_dir, tmp, svg_name="assets.svg", assets_name="assets"):
    """Tegner bare bilder hvis objekt endret seg etter fargebyttet, i Mint-Ys mål."""
    svg_old = os.path.join(orig_dir, svg_name)
    svg_new = os.path.join(work_dir, svg_name)
    index = os.path.join(work_dir, "assets.txt")
    assets = os.path.join(work_dir, assets_name)
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


def build_variant(mint_y, tmp, key, sassc):
    v = VARIANTS[key]
    work = os.path.join(tmp, key, "Mint-Y")
    shutil.copytree(mint_y, work)
    n = colorize(work, v["accent"])
    log("  aksent %s byttet %d steder" % (v["accent"], n))
    inject(work)
    compile_sass(work, sassc)
    counts = [
        rerender_assets(os.path.join(mint_y, "gtk-3.0"), os.path.join(work, "gtk-3.0"), tmp),
        rerender_assets(os.path.join(mint_y, "gtk-4.0"), os.path.join(work, "gtk-4.0"), tmp),
    ]
    if key == "light":
        counts.append(rerender_assets(os.path.join(mint_y, "gtk-2.0"), os.path.join(work, "gtk-2.0"), tmp))
    else:
        counts.append(rerender_assets(os.path.join(mint_y, "gtk-2.0"), os.path.join(work, "gtk-2.0"), tmp,
                                      "assets-dark.svg", "assets-dark"))
    log("  %d bilder tegnet på nytt" % sum(counts))
    return work


def assemble(work, out, key):
    """Samme utvalg som Mint-Ys build-themes.py, per variant."""
    def cp(src, dst):
        s, d = os.path.join(work, src), os.path.join(out, dst)
        os.makedirs(os.path.dirname(d), exist_ok=True)
        (shutil.copytree if os.path.isdir(s) else shutil.copy)(s, d)

    if key == "light":
        cp("gtk-2.0/assets", "gtk-2.0/assets")
        cp("gtk-2.0/gtkrc", "gtk-2.0/gtkrc")
        for f in os.listdir(os.path.join(work, "gtk-2.0")):
            if f.endswith(".rc"):
                cp("gtk-2.0/" + f, "gtk-2.0/" + f)
        for g in ("gtk-3.0", "gtk-4.0"):
            cp(g + "/assets", g + "/assets")
            cp(g + "/gtk.css", g + "/gtk.css")
            cp(g + "/gtk-dark.css", g + "/gtk-dark.css")
        cp("gtk-3.0/thumbnail.png", "gtk-3.0/thumbnail.png")
        cp("cinnamon/light-assets", "cinnamon/light-assets")
        cp("cinnamon/mint-y-thumbnail.png", "cinnamon/thumbnail.png")
        cp("cinnamon/cinnamon.css", "cinnamon/cinnamon.css")
    else:
        cp("gtk-2.0/assets-dark", "gtk-2.0/assets")
        cp("gtk-2.0/gtkrc-dark", "gtk-2.0/gtkrc")
        for f in os.listdir(os.path.join(work, "gtk-2.0")):
            if f.endswith(".rc") and f != "menubar-toolbar-dark.rc":
                cp("gtk-2.0/" + f, "gtk-2.0/" + f)
        cp("gtk-2.0/menubar-toolbar-dark.rc", "gtk-2.0/menubar-toolbar.rc")
        for g in ("gtk-3.0", "gtk-4.0"):
            cp(g + "/assets", g + "/assets")
            cp(g + "/gtk-dark.css", g + "/gtk.css")
            cp(g + "/gtk-dark.css", g + "/gtk-dark.css")
        cp("gtk-3.0/thumbnail-dark.png", "gtk-3.0/thumbnail.png")
        cp("cinnamon/dark-assets", "cinnamon/dark-assets")
        cp("cinnamon/mint-y-dark-thumbnail.png", "cinnamon/thumbnail.png")
        cp("cinnamon/cinnamon-dark.css", "cinnamon/cinnamon.css")
    cp("cinnamon/common-assets", "cinnamon/common-assets")
    cp("metacity-1", "metacity-1")
    for d in os.listdir(work):
        if d.startswith("libadwaita-"):
            cp(d, d)


def patch_metacity(out, name):
    """Visningsnavn, og avrunding på alle fire hjørner for vanlige vinduer."""
    p = os.path.join(out, "metacity-1", "metacity-theme-3.xml")
    s = read(p)
    s = re.sub(r"<name>[^<]*</name>", "<name>%s</name>" % name, s, count=1)
    pat = re.compile(r'(<frame_geometry name="normal"[^>]*?)(\s*>)')
    m = pat.search(s)
    if not m:
        raise BuildError("fant ikke frame_geometry «normal» i metacity-temaet")
    head = m.group(1)
    for corner in ("top_left", "top_right", "bottom_left", "bottom_right"):
        attr = "rounded_%s" % corner
        if re.search(r'\b%s="[^"]*"' % attr, head):
            head = re.sub(r'\b%s="[^"]*"' % attr, '%s="%d"' % (attr, WINDOW_RADIUS), head)
        else:
            head += ' %s="%d"' % (attr, WINDOW_RADIUS)
    s = s[:m.start()] + head + m.group(2) + s[m.end():]
    write(p, s)


def patch_libadwaita(out):
    """Mørk libadwaita 1.5: lysere aksent som tekst og mørk-varianten av fyllfargen."""
    for d in os.listdir(out):
        if not d.startswith("libadwaita-"):
            continue
        p = os.path.join(out, d, "defaults-dark.css")
        if not os.path.exists(p):
            continue
        s = read(p)
        if "@define-color mint_accent" not in s:
            continue                        # libadwaita 1.7+ henter aksenten fra systemet selv
        s, a = re.subn(r"(@define-color mint_accent )#[0-9a-fA-F]{6};", r"\g<1>%s;" % ACCENT_DARK_FILL, s, count=1)
        s, b = re.subn(r"(@define-color accent_color )@mint_accent;", r"\g<1>%s;" % ACCENT_DARK_TEXT, s, count=1)
        if not (a and b):
            raise BuildError("uventet innhold i %s/defaults-dark.css" % d)
        write(p, s)


# Oppgavelinje-indikatorer (Windows 11-lignende piller). viewBox 24×48 skaleres med
# «background-size: contain» til panelhøyden; pillen ligger nederst (eller øverst).
INDICATOR_COLORS = {
    "light": {"running": "#8a8a8a", "focused": ACCENT_LIGHT_FILL},   # stroke-control / accent
    "dark": {"running": "#9e9e9e", "focused": ACCENT_DARK_TEXT},
}
INDICATOR_WIDTH = {"running": 6, "focused": 16}


def write_indicators(out):
    d = os.path.join(out, "cinnamon", "common-assets", "mint-ro")
    os.makedirs(d, exist_ok=True)
    for variant, colors in INDICATOR_COLORS.items():
        for kind, color in colors.items():
            w = INDICATOR_WIDTH[kind]
            for edge, y in (("bottom", 44), ("top", 1)):
                svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="48" viewBox="0 0 24 48">'
                       '<rect x="%g" y="%d" width="%d" height="3" rx="1.5" fill="%s"/></svg>\n'
                       % ((24 - w) / 2, y, w, color))
                write(os.path.join(d, "indicator-%s-%s-%s.svg" % (kind, edge, variant)), svg)


GENERATED_README = """# {d}

Generert av `src/build.py` fra Mint-Y i mint-themes {tag}, med Mint-Ro-tokens og deler\ntilpasset fra Fluent GTK theme (vinceliuice, GPL-3.0-or-later).
Ikke rediger filene her direkte: endre `src/sass/` og kjør `python3 -I src/build.py`.
"""

INDEX_THEME = """[Desktop Entry]
Type=X-GNOME-Metatheme
Name={name}
Comment={comment}
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme={name}
MetacityTheme={name}
IconTheme=Mint-Y
CursorTheme=DMZ-White
ButtonLayout=:minimize,maximize,close
"""
COMMENTS = {
    "light": "Moderne Cinnamon-tema bygget på Mint-Y og Fluent-prinsipper",
    "dark": "Mørk variant av Mint-Ro",
}


def write_variant(out, key):
    v = VARIANTS[key]
    base = os.path.join(REPO, v["dir"]) if v["dir"] else REPO
    if v["dir"] and os.path.isdir(base):
        shutil.rmtree(base)
    os.makedirs(base, exist_ok=True)
    for d in OUTPUT_DIRS:
        dst = os.path.join(base, d)
        if os.path.isdir(dst):
            shutil.rmtree(dst)
        if os.path.isdir(os.path.join(out, d)):
            shutil.copytree(os.path.join(out, d), dst)
            write(os.path.join(dst, "README.md"), GENERATED_README.format(d=d, tag=UPSTREAM_TAG))
    write(os.path.join(base, "index.theme"), INDEX_THEME.format(name=v["name"], comment=COMMENTS[key]))
    if v["dir"]:
        write(os.path.join(base, "README.md"),
              "# %s\n\nMørk variant av Mint-Ro. Generert av `src/build.py` – ikke rediger direkte.\n" % v["name"])


def main():
    ap = argparse.ArgumentParser(description="Bygg Mint-Ro og Mint-Ro-Dark fra Mint-Y.")
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
        outs = {}
        for key in ("light", "dark"):
            log("Bygger %s" % VARIANTS[key]["name"])
            work = build_variant(mint_y, tmp, key, a.sassc)
            out = os.path.join(tmp, key, "out")
            os.makedirs(out)
            assemble(work, out, key)
            patch_metacity(out, VARIANTS[key]["name"])
            patch_libadwaita(out)
            write_indicators(out)
            outs[key] = out
        log("Skriver temaene til repoet")
        for key, out in outs.items():
            write_variant(out, key)
    log("Ferdig.")


if __name__ == "__main__":
    try:
        main()
    except BuildError as e:
        print("Feil: %s" % e, file=sys.stderr)
        sys.exit(1)
