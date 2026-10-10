"""List the cards that still have no effect data, most important first.

Usage (from the project root):  python tools/list_missing_effects.py [--all]
Order: cards used by the preset decks (data/decks.json) by how many decks play them, then the 350-card Card List pool, then the rest.
Normal monsters and fusion monsters without effect text need nothing and are skipped.
"""
import collections
import glob
import json
import struct
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
cards = json.load(open("data/cards.json", encoding="utf-8"))["cards"]
effects = {}
for f in glob.glob("data/effects/*.json"):
    effects.update({k: v for k, v in json.load(open(f, encoding="utf-8")).items() if not k.startswith("_")})
decks = json.load(open("data/decks.json", encoding="utf-8"))
pack_bytes = open("data/card_pack.bin", "rb").read()
pack = [struct.unpack_from("<H", pack_bytes, i * 2)[0] for i in range(len(pack_bytes) // 2)]

usage = collections.Counter()
for d in decks.values():
    for i in set(d["main"] + d["extra"]):
        usage[i] += 1

def needs_effect(i):
    c = cards[i]
    if "name" not in c or c["name"]["eng"] in effects:
        return False
    if c["type"] == "monster":
        if c["category"] == 0:
            return False                                  # Normal Monster
        if c["category"] == 2 and len(c["desc"]["eng"]) < 60:
            return False                                  # plain Fusion Monster (just a recipe)
    return True

missing = [i for i in range(1, len(cards)) if needs_effect(i)]
in_deck = sorted([i for i in missing if usage[i]], key=lambda i: -usage[i])
in_pool = [i for i in missing if not usage[i] and i < len(pack) and pack[i] & 4]
rest = [i for i in missing if not usage[i] and not (i < len(pack) and pack[i] & 4)]

def show(title, lst):
    print("\n## %s (%d)" % (title, len(lst)))
    for i in lst:
        c = cards[i]
        kind = c["type"] if c["type"] != "monster" else "monster lv%d %s/%s" % (c["level"], c["atk"], c["def"])
        print("- %s [%s]%s: %s" % (c["name"]["eng"], kind, " x%d decks" % usage[i] if usage[i] else "", c["desc"]["eng"].replace("\n", " ")))

show("Used by the preset decks", in_deck)
show("In the 350-card Card List", in_pool)
if "--all" in sys.argv:
    show("Everything else", rest)
else:
    print("\n(%d more cards outside the decks and the Card List; use --all to list them)" % len(rest))
