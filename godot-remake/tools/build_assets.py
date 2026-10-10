"""Convert original BMP art to PNG for the Godot project.
usage: build_assets.py <extracted/data dir> <godot project dir>"""
import os, sys, json
from PIL import Image
src, proj = sys.argv[1], sys.argv[2]
cards = json.load(open(os.path.join(proj, "data", "cards.json"), encoding="utf-8"))["cards"]
n = 0
for sub, key in (("card", "art"), ("mini", "mini")):
    out = os.path.join(proj, "assets", {"card": "cards", "mini": "mini"}[sub]); os.makedirs(out, exist_ok=True)
    for name in sorted({c[key] for c in cards if key in c}):
        s, d = os.path.join(src, sub, name + ".bmp"), os.path.join(out, name + ".png")
        if os.path.exists(s) and (not os.path.exists(d) or os.path.getmtime(d) < os.path.getmtime(s)):
            Image.open(s).convert("RGB").save(d, optimize=True); n += 1
print("converted", n)

# --- duel UI assets (M4) ---
ui = os.path.join(proj, "assets", "ui"); os.makedirs(ui, exist_ok=True)
D = os.path.join(src, "j", "duel")
extra = {
    "field_normal": os.path.join(D, "field", "fie_normal.bmp"),
    "card_back": os.path.join(src, "card", "card_ura.bmp"),
    "card_back_mini": os.path.join(src, "mini", "card_ura.bmp"),
    "deck": os.path.join(D, "card", "deck.bmp"),
    "grave": os.path.join(D, "card", "grave.bmp"),
}
for name, path in extra.items():
    if os.path.exists(path):
        Image.open(path).convert("RGB").save(os.path.join(ui, name + ".png"), optimize=True)
print("ui assets", len(os.listdir(ui)))
