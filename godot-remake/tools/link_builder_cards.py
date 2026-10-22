"""Link the cards made with tools/card_builder (output/card_builder and output/card_builder_batches/*) into the game.

For every exported card the big image goes to assets/art_override/<number>.png and the builder's own 50x72 miniature to
assets/art_override_mini/<number>.png. The numbers of those miniatures are written to assets/art_override_mini/custom.txt so that
tools/make_override_minis.py leaves them alone. The card is found by the name stored in its .json (and the Konami number when given).
Usage (project root):  python tools/link_builder_cards.py
"""
import glob
import json
import os
import shutil
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
cards = json.load(open("data/cards.json", encoding="utf-8"))["cards"]
by_name = {}
for c in cards[1:]:
    by_name.setdefault(c["name"]["eng"].lower(), []).append(c)

sources = sorted(glob.glob("output/card_builder/*.json")) + sorted(glob.glob("output/card_builder_batches/*/*.json"))
os.makedirs("assets/art_override_mini", exist_ok=True)
custom = set()
if os.path.exists("assets/art_override_mini/custom.txt"):
    custom = {int(x) for x in open("assets/art_override_mini/custom.txt").read().split()}
linked, problems = [], []
for js in sources:                                  # later batches win over earlier ones
    d = json.load(open(js, encoding="utf-8"))
    base = js[:-5]
    name = d.get("name", "")
    hits = by_name.get(name.lower(), [])
    if d.get("gameNumber"):
        exact = [c for c in hits if c["number"] == int(d["gameNumber"])]
        hits = exact or hits
    if not hits or not os.path.exists(base + ".png"):
        problems.append((os.path.basename(js), name, "no card or no image"))
        continue
    token_hits = [c for c in hits if c["art"] == "token_sl"]
    for c in (token_hits or hits):
        n = c["number"]
        shutil.copy(base + ".png", "assets/art_override/%d.png" % n)
        if os.path.exists(base + "-mini.png"):
            shutil.copy(base + "-mini.png", "assets/art_override_mini/%d.png" % n)
            custom.add(n)
        linked.append((name, n, "token" if token_hits else "REAL ART REPLACED"))
open("assets/art_override_mini/custom.txt", "w").write("\n".join(map(str, sorted(custom))) + "\n")
print(len(linked), "cards linked")
for l in linked:
    print("  ", l)
print("problems:", problems)
