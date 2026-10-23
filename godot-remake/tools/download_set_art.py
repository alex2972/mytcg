"""Download the art-only images of a set from YGOPRODeck into art_incoming/<CODE>/ (files named by card number).

  python tools/download_set_art.py LOD

Reads data/sets/<CODE>.json (the set and its "exclude" list) and data/cards.json (card numbers), skips files already
present, and writes names.txt (number, name, set code) next to the images.
"""
import json
import os
import sys
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
code = sys.argv[1]
src = json.load(open(os.path.join(ROOT, "data", "sets", code + ".json"), encoding="utf-8"))
excluded = {n.lower() for n in src.get("exclude", [])}
in_game = {c["passcode"]: c["number"] for c in json.load(open(os.path.join(ROOT, "data", "cards.json"), encoding="utf-8"))["cards"] if "passcode" in c}
out = os.path.join(ROOT, "art_incoming", code)
os.makedirs(out, exist_ok=True)
lines, got, skipped, failed = [], 0, 0, []
for c in src["cards"]:
    number = in_game.get(c["passcode"])
    if number is None or c["name"]["eng"].lower() in excluded:
        continue
    lines.append("%d\t%s\t%s" % (number, c["name"]["eng"], c["set_code"]))
    path = os.path.join(out, "%d.jpg" % number)
    if os.path.exists(path):
        skipped += 1
        continue
    url = "https://images.ygoprodeck.com/images/cards_cropped/%d.jpg" % c["passcode"]
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "joey-remake-art/1"})
        data = urllib.request.urlopen(req, timeout=60).read()
        open(path, "wb").write(data)
        got += 1
    except Exception as e:
        failed.append((c["name"]["eng"], str(e)))
open(os.path.join(out, "names.txt"), "w", encoding="utf-8").write("number\tname\tset code\n" + "\n".join(sorted(lines)) + "\n")
print("downloaded %d, already there %d, failed %s -> %s" % (got, skipped, failed, out))
