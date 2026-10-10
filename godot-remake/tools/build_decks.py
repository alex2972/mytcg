"""Export the original preset/AI decks (data/j/file/*.ydc) and the in-game dialog strings.
usage: build_decks.py <extracted/data dir> <out data dir>"""
import glob, json, os, struct, sys
src, out = sys.argv[1], sys.argv[2]
cards = json.load(open(os.path.join(out, "cards.json"), encoding="utf-8"))["cards"]
by_number = {c["number"]: c["index"] for c in cards[1:]}

def parse(path):
    v = struct.unpack(f"<{os.path.getsize(path)//2}H", open(path, "rb").read())
    pos, secs = 4, []
    for _ in range(3):
        if pos >= len(v): secs.append([]); continue
        n = v[pos]; pos += 1
        secs.append([by_number.get(x, -1) for x in v[pos:pos+n]]); pos += n
    return {"main": secs[0], "extra": secs[1], "side": secs[2], "header": list(v[:4])}

decks = {os.path.splitext(os.path.basename(p))[0]: parse(p) for p in sorted(glob.glob(os.path.join(src, "j", "file", "*.ydc")))}
json.dump(decks, open(os.path.join(out, "decks.json"), "w"), separators=(",", ":"))
print("decks", len(decks), "unknown card refs", sum(x == -1 for d in decks.values() for s in (d["main"], d["extra"], d["side"]) for x in s))

LANGS = {"eng": "latin-1", "fra": "latin-1", "ger": "latin-1", "ita": "latin-1", "spa": "latin-1", "jpn": "cp932"}
strings = {}
for lang, enc in LANGS.items():
    d = open(os.path.join(src, "bin#", f"dlg_text{lang}.bin"), "rb").read()
    b = open(os.path.join(src, "bin#", f"dlg_indx{lang}.bin"), "rb").read()
    ix = struct.unpack(f"<{len(b)//4}I", b)
    strings[lang] = [d[ix[i]:ix[i+1] if i + 1 < len(ix) else len(d)].split(b"\0")[0].decode(enc, "replace").replace("\r\n", "\n") for i in range(len(ix))]
json.dump(strings, open(os.path.join(out, "strings.json"), "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print("strings per language", len(strings["eng"]))
