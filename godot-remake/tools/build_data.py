"""Build data/cards.json from the unpacked original data (see unpack_dat.py).
usage: build_data.py <extracted/data dir> <out data dir>
Card property bitfields were recovered from the original exe (accessors 0x4025d0..0x402800)."""
import json, re, struct, sys, os

src, out = sys.argv[1], sys.argv[2]
B = os.path.join(src, "bin#")
LANGS = {"eng": "latin-1", "fra": "latin-1", "ger": "latin-1", "ita": "latin-1", "spa": "latin-1", "jpn": "cp932"}

def rd(name): return open(os.path.join(B, name), "rb").read()
def u16s(name): d = rd(name); return struct.unpack(f"<{len(d)//2}H", d)
def u32s(name): d = rd(name); return struct.unpack(f"<{len(d)//4}I", d)

ids = u16s("card_id.bin")          # [0] = 0xFFFF (card back), then the official card number
intid = u16s("card_intid.bin")     # internal id used by the effect code
prop = u32s("card_prop.bin")
n = len(ids)

def decode(p):
    k = p >> 20 & 0x1f
    spelltrap = 20 < k < 24
    c = {"kind": k}
    # 21 = trap, 22 = spell, 23 = a lone special spell, 24 = the three god cards (monsters)
    c["type"] = "trap" if k == 21 else "spell" if k in (22, 23) else "monster"
    c["atk"] = 4000 if k == 24 else 0 if spelltrap else (p >> 9 & 0x1ff) * 10
    c["def"] = 4000 if k == 24 else 0 if spelltrap else (p & 0x1ff) * 10
    c["level"] = 10 if k == 24 else 0 if spelltrap else p >> 25 & 0xf
    c["attribute"] = 9 if k == 21 else 8 if k == 22 else p >> 29   # 8 = spell, 9 = trap in the original
    c["category"] = p >> 18 & 3        # 0 normal, 1 effect, 2 fusion, 3 ritual (per original accessor)
    c["subtype"] = p >> 17 & 7 if 20 < k < 23 else 0
    if k == 21: c["subtype_name"] = {0: "normal", 1: "counter", 4: "continuous"}.get(c["subtype"], "?")
    if k == 22: c["subtype_name"] = {0: "normal", 2: "field", 3: "equip", 4: "continuous", 5: "quickplay", 6: "ritual"}.get(c["subtype"], "?")
    return c

cards = []
for i in range(n):
    c = {"index": i, "number": ids[i], "intid": intid[i] if i < len(intid) else 0}
    c.update(decode(prop[i]) if i < len(prop) and i > 0 else {})
    cards.append(c)

for lang, enc in LANGS.items():
    names = rd(f"card_name{lang}.bin"); descs = rd(f"card_desc{lang}.bin")
    ix = u32s(f"card_indx{lang}.bin")
    for i in range(1, n):
        cards[i].setdefault("name", {})[lang] = names[64*i:64*i+64].split(b"\0")[0].decode(enc, "replace")
        d = descs[ix[i]:ix[i+1] if i + 1 < len(ix) else len(descs)] if i < len(ix) else b""
        cards[i].setdefault("desc", {})[lang] = d.split(b"\0")[0].decode(enc, "replace").replace("\r\n", "\n")

# card art: list_card.txt maps index -> bmp file
def art(path):
    m = {}; t = open(path, encoding="latin-1").read()
    for idx, fn in re.findall(r"//\t(\d{4}):\[\d+\]\s*\n(\S+\.bmp)", t): m[int(idx)] = fn
    return m
full = art(os.path.join(src, "card", "list_card.txt")); mini = art(os.path.join(src, "mini", "list_card.txt"))
for c in cards:
    if c["index"] in full: c["art"] = os.path.splitext(full[c["index"]])[0]
    if c["index"] in mini: c["mini"] = os.path.splitext(mini[c["index"]])[0]

os.makedirs(out, exist_ok=True)
json.dump({"cards": cards}, open(os.path.join(out, "cards.json"), "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print("cards", n, "with art", sum(1 for c in cards if "art" in c))
