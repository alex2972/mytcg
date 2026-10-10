"""Convert every UI image of the original (data/j/**, data/cursor/**) to PNG under assets/j and assets/cursor.
- .yga : decoded with yga.py (real alpha)
- .bmp : if the top-left pixel is pure green or magenta it is the colour key -> transparent
usage: build_ui_assets.py <extracted/data dir> <godot project dir>"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import yga

KEYS = {(0, 255, 0), (255, 0, 255), (141, 179, 40)}   # green, magenta, olive (duel digit fonts)

def bmp(path):
    im = Image.open(path).convert("RGB")
    key = im.getpixel((0, 0))
    keyed = key in KEYS
    if not keyed and im.width * im.height < 60000:
        # small sprites/fonts use their corner colour as the colour key (e.g. black, red, light blue)
        px = im.getdata()
        share = sum(1 for p in px if p == key) / float(len(px))
        w, h = im.size
        corners = [im.getpixel(c) for c in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
        keyed = share >= 0.3 or (share >= 0.1 and all(c == key for c in corners))
    if keyed:
        rgba = im.convert("RGBA")
        px = rgba.load()
        w, h = rgba.size
        for y in range(h):
            for x in range(w):
                if px[x, y][:3] == key:
                    px[x, y] = (0, 0, 0, 0)
        return rgba
    return im

src, proj = sys.argv[1], sys.argv[2]
n = 0
for sub in ("j", "cursor"):
    for root, _, files in os.walk(os.path.join(src, sub)):
        for f in files:
            low = f.lower()
            if not low.endswith((".bmp", ".yga")):
                continue
            p = os.path.join(root, f)
            rel = os.path.relpath(p, src)
            dst = os.path.join(proj, "assets", os.path.splitext(rel)[0] + ".png")
            if "--force" not in sys.argv and os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(p):
                continue
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            im = yga.load(p)[0] if low.endswith(".yga") else bmp(p)
            im.save(dst)
            n += 1
print("converted", n)
