#!/usr/bin/env python3
"""Hjelpefunksjoner for apply-profile.sh.

Leser verdier slik `gsettings get` skriver dem, og skriver nye verdier i samme
GVariant-format som `gsettings set` forventer. Ingen funksjon her endrer
systemet, bortsett fra `calendar --write`, som bare skriver til fila den får.
"""
import ast
import json
import os
import sys

MENU = "menu@cinnamon.org"
TASK_LISTS = ("grouped-window-list@cinnamon.org", "window-list@cinnamon.org")
REMOVE_IN_TASKBAR = ("separator@cinnamon.org", "favorites@cinnamon.org")
# Rekkefølge i høyre sone, fra venstre mot høyre. Ukjente applets havner før «network».
RIGHT_ORDER = [
    "systray@cinnamon.org", "xapp-status@cinnamon.org", "removable-drives@cinnamon.org",
    "printers@cinnamon.org", "keyboard@cinnamon.org", "a11y@cinnamon.org",
    "inhibit@cinnamon.org", "nightlight@cinnamon.org",
    "network@cinnamon.org", "sound@cinnamon.org", "power@cinnamon.org",
    "calendar@cinnamon.org", "notifications@cinnamon.org", "cornerbar@cinnamon.org",
]
NEMO_COLUMNS = ["name", "date_modified", "type", "size"]


class ProfileError(Exception):
    pass


def parse_strv(text):
    text = text.strip()
    if text.startswith("@as "):
        text = text[4:]
    try:
        value = ast.literal_eval(text)
    except (ValueError, SyntaxError):
        raise ProfileError("kunne ikke tolke verdien: %s" % text)
    if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
        raise ProfileError("forventet en liste med tekst: %s" % text)
    return value


def fmt_strv(values):
    if not values:
        return "@as []"
    for v in values:
        if "'" in v or "\\" in v:
            raise ProfileError("uventet tegn i verdi: %s" % v)
    return "[" + ", ".join("'%s'" % v for v in values) + "]"


def parse_applets(values):
    """'panel1:left:0:menu@cinnamon.org:0' -> dict. Instans-id beholdes uendret."""
    out = []
    for i, raw in enumerate(values):
        parts = raw.split(":")
        if len(parts) < 4:
            raise ProfileError("ukjent format på applet: %s" % raw)
        out.append({
            "panel": parts[0], "zone": parts[1], "order": int(parts[2]) if parts[2].isdigit() else 0,
            "uuid": parts[3], "rest": parts[4:], "seq": i,
        })
    return out


def fmt_applets(applets):
    return [":".join([a["panel"], a["zone"], str(a["order"]), a["uuid"]] + a["rest"]) for a in applets]


def target_panel(applets):
    for a in applets:
        if a["uuid"] == MENU:
            return a["panel"]
    raise ProfileError("fant ikke menyknappen (menu@cinnamon.org) i noe panel")


def taskbar(values, mode):
    """Flytter menyknapp og vindusliste til midten (mode=center) eller venstre (mode=left),
    fjerner skillelinjen og favoritt-appleten i det panelet, og sorterer høyre sone."""
    if mode not in ("center", "left"):
        raise ProfileError("ukjent modus: %s" % mode)
    applets = parse_applets(values)
    panel = target_panel(applets)
    menu = next(a for a in applets if a["panel"] == panel and a["uuid"] == MENU)
    menu_zone = menu["zone"]

    others = [a for a in applets if a["panel"] != panel]
    mine = [a for a in applets if a["panel"] == panel]

    kept = []
    for a in mine:
        if a["uuid"] == "favorites@cinnamon.org":
            continue
        if a["uuid"] == "separator@cinnamon.org" and a["zone"] in (menu_zone, mode):
            continue
        kept.append(a)

    main = [a for a in kept if a["uuid"] == MENU]
    lists = [a for a in kept if a["uuid"] in TASK_LISTS]
    main += sorted(lists, key=lambda a: TASK_LISTS.index(a["uuid"]))
    rest = [a for a in kept if a not in main]

    def by_order(xs):
        return sorted(xs, key=lambda a: (a["order"], a["seq"]))

    zones = {"left": [], "center": [], "right": []}
    for a in rest:
        zones.setdefault(a["zone"], []).append(a)
    for z in zones:
        zones[z] = by_order(zones[z])
    zones[mode] = main + zones[mode]

    net = RIGHT_ORDER.index("network@cinnamon.org")
    zones["right"].sort(key=lambda a: (
        RIGHT_ORDER.index(a["uuid"]) if a["uuid"] in RIGHT_ORDER else net - 0.5, a["order"], a["seq"]))

    result = []
    for z in ("left", "center", "right"):
        for i, a in enumerate(zones[z]):
            a["zone"], a["order"] = z, i
            result.append(a)
    for z, xs in zones.items():
        if z not in ("left", "center", "right"):
            result.extend(xs)
    return fmt_applets(others + result)


def removed(old_values, new_values):
    old = {":".join(v.split(":")[3:]) for v in old_values}
    new = {":".join(v.split(":")[3:]) for v in new_values}
    return sorted(u.split(":")[0] for u in old - new)


def panels_height(values, panel_id, height):
    out, found = [], False
    for v in values:
        pid, _, h = v.partition(":")
        if pid == panel_id:
            out.append("%s:%d" % (pid, height)); found = True
        else:
            out.append(v)
    if not found:
        out.append("%s:%d" % (panel_id, height))
    return out


def instance_id(values, uuid, panel=None):
    for a in parse_applets(values):
        if a["uuid"] == uuid and (panel is None or a["panel"] == panel) and a["rest"]:
            return a["rest"][0]
    return ""


def reorder_columns(values):
    first = [c for c in NEMO_COLUMNS if c in values]
    return first + [c for c in values if c not in first]


def applet_settings(path, wanted, write):
    """Setter verdier i en applets innstillingsfil (~/.config/cinnamon/spices/<uuid>/<id>.json).
    Returnerer «nøkkel: gammel → ny» for hver endring; skriver fila bare med write=True."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    changes = []
    for k, v in wanted.items():
        if k not in data or not isinstance(data[k], dict):
            raise ProfileError("innstillingen %s finnes ikke i %s" % (k, os.path.basename(path)))
        if data[k].get("value") != v:
            changes.append("%s: %s → %s" % (k, json.dumps(data[k].get("value"), ensure_ascii=False),
                                            json.dumps(v, ensure_ascii=False)))
            data[k]["value"] = v
    if write and changes:
        tmp = path + ".mint-ro.tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
            f.write("\n")
        os.replace(tmp, path)
    return changes


def calendar(path, fmt, tooltip, write):
    return applet_settings(path, {"use-custom-format": True, "custom-format": fmt,
                                  "custom-tooltip-format": tooltip}, write)


def parse_pairs(pairs):
    """key=JSON-verdi, f.eks. search-position="top" show-description=false."""
    out = {}
    for p in pairs:
        k, sep, v = p.partition("=")
        if not sep or not k:
            raise ProfileError("forventet nøkkel=verdi: %s" % p)
        try:
            out[k] = json.loads(v)
        except json.JSONDecodeError:
            raise ProfileError("ugyldig JSON-verdi for %s: %s" % (k, v))
    return out


def main(argv):
    if not argv:
        raise ProfileError("mangler kommando")
    cmd, args = argv[0], argv[1:]
    if cmd == "taskbar":            # MODE CURRENT
        print(fmt_strv(taskbar(parse_strv(args[1]), args[0])))
    elif cmd == "removed":          # OLD NEW
        print(" ".join(removed(parse_strv(args[0]), parse_strv(args[1]))))
    elif cmd == "target-panel":     # CURRENT  -> «1»
        print(target_panel(parse_applets(parse_strv(args[0])))[len("panel"):])
    elif cmd == "panels-height":    # CURRENT PANELID HEIGHT
        print(fmt_strv(panels_height(parse_strv(args[0]), args[1], int(args[2]))))
    elif cmd == "instance-id":      # CURRENT UUID [PANEL]
        print(instance_id(parse_strv(args[0]), args[1], args[2] if len(args) > 2 else None))
    elif cmd == "columns":          # CURRENT
        print(fmt_strv(reorder_columns(parse_strv(args[0]))))
    elif cmd == "calendar":         # FILE FORMAT TOOLTIP [--write]
        for c in calendar(args[0], args[1], args[2], "--write" in args[3:]):
            print(c)
    elif cmd == "applet":           # FILE [--write] key=json ...
        write = "--write" in args[1:]
        pairs = [x for x in args[1:] if x != "--write"]
        for c in applet_settings(args[0], parse_pairs(pairs), write):
            print(c)
    else:
        raise ProfileError("ukjent kommando: %s" % cmd)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except ProfileError as e:
        print("Feil: %s" % e, file=sys.stderr)
        sys.exit(3)
    except (IndexError, ValueError, OSError, json.JSONDecodeError) as e:
        print("Feil: %s" % e, file=sys.stderr)
        sys.exit(3)
