"""Add a TCG set to data/cards.json from the YGOPRODeck API (https://db.ygoprodeck.com/api-guide/).

  python tools/import_set.py fetch "Legacy of Darkness" LOD     download names/texts/stats (English, French, German, Italian)
                                                                   into data/sets/LOD.json (only the fields the game uses)
  python tools/import_set.py build LOD                          add/update the cards of data/sets/LOD.json in data/cards.json
                                                                   and the Fusion recipes in data/fusions.json

data/sets/<CODE>.json also holds the set's "number_base" (card number = base + number in the set, e.g. LOD-EN062 -> 10062)
and "exclude" (English names that are not added). A card already in cards.json with the same number is updated in place,
new ones are appended, so CardDB indices of existing cards never move. Images are not touched: cards without "art"
show the card back until art is linked (tools/link_builder_cards.py, assets/art_override/<number>.png).
Spanish and Japanese are not offered by the API; those texts fall back to English.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://db.ygoprodeck.com/api/v7/cardinfo.php"
LANGS = {"eng": None, "fra": "fr", "ger": "de", "ita": "it"}
RACES = ["", "Dragon", "Zombie", "Fiend", "Pyro", "Sea Serpent", "Rock", "Machine", "Fish", "Dinosaur", "Insect", "Beast",
         "Beast-Warrior", "Plant", "Aqua", "Warrior", "Winged Beast", "Fairy", "Spellcaster", "Thunder", "Reptile"]   # CardDB.RACES
ATTRIBUTES = {"LIGHT": 1, "DARK": 2, "WATER": 3, "FIRE": 4, "EARTH": 5, "WIND": 6, "DIVINE": 7}
SPELL_SUBTYPES = {"Normal": (0, "normal"), "Field": (2, "field"), "Equip": (3, "equip"), "Continuous": (4, "continuous"),
                  "Quick-Play": (5, "quickplay"), "Ritual": (6, "ritual")}
TRAP_SUBTYPES = {"Normal": (0, "normal"), "Counter": (1, "counter"), "Continuous": (4, "continuous")}


def set_path(code):
    return os.path.join(ROOT, "data", "sets", code + ".json")


def get(params):
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "joey-remake-import/1"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))["data"]


def fetch(set_name, code):
    by_id = {}
    for lang, api_lang in LANGS.items():
        params = {"cardset": set_name}
        if api_lang:
            params["language"] = api_lang
        for c in get(params):
            e = by_id.setdefault(c["id"], {"passcode": c["id"], "name": {}, "desc": {}})
            e["name"][lang] = c["name"]
            e["desc"][lang] = c["desc"].replace("\r\n", "\n")
            if lang == "eng":
                sets = [s for s in c.get("card_sets", []) if s["set_name"] == set_name and "-EN" in s["set_code"]]
                e.update({"set_code": sets[0]["set_code"], "rarity": sets[0]["set_rarity"], "type": c["type"],
                          "race": c.get("race", ""), "attribute": c.get("attribute", ""), "level": c.get("level", 0),
                          "atk": c.get("atk", 0), "def": c.get("def", 0)})
    old = json.load(open(set_path(code), encoding="utf-8")) if os.path.exists(set_path(code)) else {}
    out = {"set_name": set_name, "code": code, "source": API + " (cardset=%s)" % set_name,
           "number_base": old.get("number_base", 10000), "exclude": old.get("exclude", []),
           "cards": sorted(by_id.values(), key=lambda e: e["set_code"])}
    os.makedirs(os.path.dirname(set_path(code)), exist_ok=True)
    json.dump(out, open(set_path(code), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("fetched %d cards into %s" % (len(out["cards"]), set_path(code)))


def convert(e, number):
    t = e["type"]
    c = {"number": number, "intid": 0}
    if t.endswith("Trap Card") or t.endswith("Spell Card"):
        trap = t.startswith("Trap")
        sub, sub_name = (TRAP_SUBTYPES if trap else SPELL_SUBTYPES)[e["race"]]
        c.update({"kind": 21 if trap else 22, "type": "trap" if trap else "spell", "atk": 0, "def": 0, "level": 0,
                  "attribute": 9 if trap else 8, "category": 0, "subtype": sub, "subtype_name": sub_name})
    else:
        category = 2 if "Fusion" in t else 3 if "Ritual" in t else 0 if t == "Normal Monster" else 1
        c.update({"kind": RACES.index(e["race"]), "type": "monster", "atk": int(e["atk"]), "def": int(e["def"]),
                  "level": int(e["level"]), "attribute": ATTRIBUTES[e["attribute"]], "category": category, "subtype": 0})
    c["name"] = {lang: e["name"].get(lang, e["name"]["eng"]) for lang in ("eng", "fra", "ger", "ita", "spa", "jpn")}
    c["desc"] = {lang: e["desc"].get(lang, e["desc"]["eng"]) for lang in ("eng", "fra", "ger", "ita", "spa", "jpn")}
    c["set"] = e["set_code"]
    c["rarity"] = e["rarity"]
    c["passcode"] = e["passcode"]
    return c


def build(code):
    src = json.load(open(set_path(code), encoding="utf-8"))
    excluded = {n.lower() for n in src.get("exclude", [])}
    db_path = os.path.join(ROOT, "data", "cards.json")
    cards = json.load(open(db_path, encoding="utf-8"))["cards"]
    by_number = {c["number"]: c for c in cards}
    existing_names = {c["name"]["eng"].lower() for c in cards[1:] if not str(c.get("set", "")).startswith(code + "-")}
    added = updated = skipped = 0
    fusions = {}
    for e in src["cards"]:
        if e["name"]["eng"].lower() in excluded:
            skipped += 1
            continue
        if e["name"]["eng"].lower() in existing_names:
            print("already in the game, skipped:", e["name"]["eng"])
            skipped += 1
            continue
        number = int(src["number_base"]) + int(re.sub(r"\D", "", e["set_code"].split("-")[1]))
        c = convert(e, number)
        if number in by_number:
            c["index"] = by_number[number]["index"]
            for k in ("art", "mini"):                      # keep art linked later
                if k in by_number[number]:
                    c[k] = by_number[number][k]
            cards[c["index"]] = {"index": c["index"], **{k: v for k, v in c.items() if k != "index"}}
            updated += 1
        else:
            c = {"index": len(cards), **c}
            cards.append(c)
            by_number[number] = c
            added += 1
        if c["category"] == 2:
            mats = re.findall(r'"([^"]+)"', e["desc"]["eng"].split("\n")[0])
            if len(mats) >= 2:
                fusions[e["name"]["eng"]] = mats
    json.dump({"cards": cards}, open(db_path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    fus_path = os.path.join(ROOT, "data", "fusions.json")
    recipes = json.load(open(fus_path, encoding="utf-8"))
    recipes.update(fusions)
    json.dump(recipes, open(fus_path, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    print("%s: %d added, %d updated, %d skipped; cards.json now has %d cards; fusion recipes: %s"
          % (code, added, updated, skipped, len(cards) - 1, fusions))


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "fetch":
        fetch(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 3 and sys.argv[1] == "build":
        build(sys.argv[2])
    else:
        print(__doc__)
