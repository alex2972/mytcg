"""Card tier sorter: drag cards into Tier 1 / Tier 2 / Tier 3 (or Special) and save to data/card_tiers.json.

Run from the project root:  python tools/tier_sorter/server.py   (opens http://127.0.0.1:8766; --no-browser to skip)
Only uses the Python standard library. Nothing here touches the game or the engine: the file is for pack/deck design later.
"""
import argparse
import json
import re
import struct
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
TIERS_FILE = ROOT / "data" / "card_tiers.json"
RACES = ["", "Dragon", "Zombie", "Fiend", "Pyro", "Sea Serpent", "Rock", "Machine", "Fish", "Dinosaur", "Insect", "Beast",
         "Beast-Warrior", "Plant", "Aqua", "Warrior", "Winged Beast", "Fairy", "Spellcaster", "Thunder", "Reptile"]
ATTRS = {1: "LIGHT", 2: "DARK", 3: "WATER", 4: "FIRE", 5: "EARTH", 6: "WIND", 7: "DIVINE"}
CATEGORIES = ["Normal", "Effect", "Fusion", "Ritual"]

# Cards that are strong in the original ruleset: only used by the "suggest" button, you decide in the end.
BEST = """Raigeki|Dark Hole|Monster Reborn|Change of Heart|Pot of Greed|Heavy Storm|Mirror Force|Torrential Tribute|Harpie's Feather Duster|
Mystical Space Typhoon|Delinquent Duo|Premature Burial|Snatch Steal|Jinzo|Sangan|Witch of the Black Forest|Magician of Faith|Magic Cylinder|
Call Of The Haunted|Solemn Judgment|Imperial Order|Sinister Serpent|Giant Trunade|Graceful Charity|Graverobber|Painful Choice|The Forceful Sentry|
Nobleman of Crossout|Nobleman of Extermination|Gravity Bind|Swords of Revealing Light|Ring of Destruction|Confiscation|Exodia the Forbidden One|
Thousand Dragon|Blue-Eyes Ultimate Dragon|Black Luster Soldier|Obelisk the Tormentor|Slifer the Sky Dragon|The Winged Dragon of Ra|Time Wizard|
Dark Magician Girl|Morphing Jar|Cyber Jar|Tribe-Infecting Virus|Mirage of Nightmare|Upstart Goblin|Fusion Gate|Mage Power|Gearfried the Iron Knight|
Metamorphosis|Last Will|Black Pendant|Reinforcements|Magic Jammer|Seven Tools of the Bandit|Horn of Heaven|Solemn Wishes|Zombyra the Dark|Buster Blader""".replace("\n", "").split("|")


def load_cards():
    raw = json.loads((ROOT / "data" / "cards.json").read_text(encoding="utf-8"))["cards"][1:]
    pack = (ROOT / "data" / "card_pack.bin").read_bytes()
    pk = [struct.unpack_from("<H", pack, i * 2)[0] for i in range(len(pack) // 2)]
    out, seen = [], {}
    for c in raw:
        name = c["name"]["eng"]
        if not name:
            continue
        kind = (CATEGORIES[c["category"]] if c["type"] == "monster" else c["type"].title())
        has_art = c["art"] != "token_sl" or (ROOT / "assets" / "art_override" / ("%d.png" % c["number"])).is_file()
        card = {"number": c["number"], "name": name, "type": c["type"], "kind": kind, "subtype": c.get("subtype_name") or "",
                "level": c["level"], "atk": c["atk"], "def": c["def"], "attribute": ATTRS.get(c["attribute"], ""),
                "race": RACES[c["kind"]] if c["type"] == "monster" and c["kind"] < len(RACES) else "",
                "text": c["desc"]["eng"], "art": c["art"], "has_art": has_art,
                "listed": c["index"] < len(pk) and bool(pk[c["index"]] & 4)}
        if name.lower() in seen:                      # twin entry of the same card: keep the one with real art
            old = seen[name.lower()]
            if has_art and not old["has_art"]:
                out[out.index(old)] = card
                seen[name.lower()] = card
            continue
        seen[name.lower()] = card
        out.append(card)
    return out


def art_file(card):
    """Best image for a card: replacement art first, then the game's own."""
    for p in (ROOT / "assets" / "art_override" / ("%d.png" % card["number"]), ROOT / "assets" / "cards" / (card["art"] + ".png")):
        if p.is_file():
            return p
    return None


CARDS = load_cards()
BY_NUMBER = {c["number"]: c for c in CARDS}


def suggest():
    """A rough first guess for every card (the user has the final say)."""
    out = {}
    best = {b.strip().lower() for b in BEST}
    for c in CARDS:
        n = c["number"]
        if c["name"].lower() in best:
            out[n] = 3
        elif c["type"] == "monster":
            power = max(c["atk"], c["def"])
            effect = c["kind"] == "Effect"
            if c["kind"] in ("Fusion", "Ritual"):
                out[n] = 2 if power >= 2200 else 1
            elif effect and power >= 1200:
                out[n] = 2
            elif power >= 1900 or (c["level"] <= 4 and c["atk"] >= 1700):
                out[n] = 2
            else:
                out[n] = 1
        else:
            text = c["text"].lower()
            if any(k in text for k in ("destroy", "draw", "special summon", "take control", "negate", "return", "discard")):
                out[n] = 2
            else:
                out[n] = 1
    return out


def load_tiers():
    if TIERS_FILE.is_file():
        return json.loads(TIERS_FILE.read_text(encoding="utf-8"))
    return {"_about": "Developer-only power tiers. 1 = bottom, 2 = most of the pool, 3 = the best cards (power pack), 0 = special / never in packs. Key = Konami number.",
            "tiers": {}}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            return self.send(200, (HERE / "index.html").read_text(encoding="utf-8"), "text/html; charset=utf-8")
        if self.path == "/api/cards":
            return self.send(200, json.dumps({"cards": CARDS, "tiers": load_tiers()["tiers"]}))
        if self.path == "/api/suggest":
            return self.send(200, json.dumps(suggest()))
        m = re.fullmatch(r"/art/(\d+)", self.path)
        if m and int(m.group(1)) in BY_NUMBER:
            f = art_file(BY_NUMBER[int(m.group(1))])
            if f:
                return self.send(200, f.read_bytes(), "image/png")
        self.send(404, "{}")

    def do_POST(self):
        if self.path != "/api/tiers":
            return self.send(404, "{}")
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        doc = load_tiers()
        doc["tiers"] = {str(k): int(v) for k, v in body["tiers"].items() if int(v) in (0, 1, 2, 3)}
        doc["names"] = {str(n): BY_NUMBER[int(n)]["name"] for n in doc["tiers"] if int(n) in BY_NUMBER}      # readable copy
        TIERS_FILE.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        self.send(200, json.dumps({"saved": len(doc["tiers"])}))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", 8766), Handler)
    if not args.no_browser:
        threading.Timer(0.7, lambda: webbrowser.open("http://127.0.0.1:8766")).start()
    print("Tier sorter on http://127.0.0.1:8766  (Ctrl+C to stop); %d cards" % len(CARDS))
    server.serve_forever()
