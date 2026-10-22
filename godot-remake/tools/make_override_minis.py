"""Make the 50x72 small icons for the replacement card art in assets/art_override.

The original small icons are the full card scaled down with a bicubic filter (measured on 60 cards: this recipe matches them best,
edge sharpness 55.5 vs 54.9 for the originals). If they still look too crisp next to the originals in the game, raise BLUR (0.3-0.8).
Run after adding or changing images:  python tools/make_override_minis.py
"""
import glob
import os
from PIL import Image, ImageFilter

BLUR = 0.0

os.makedirs("assets/art_override_mini", exist_ok=True)
custom = set()                                      # miniatures made by the card builder (tools/link_builder_cards.py): keep them
if os.path.exists("assets/art_override_mini/custom.txt"):
    custom = set(open("assets/art_override_mini/custom.txt").read().split())
for f in glob.glob("assets/art_override/*.png"):
    name = os.path.basename(f)
    if name[:-4] in custom:
        continue
    mini = Image.open(f).convert("RGB").resize((50, 72), Image.BICUBIC)
    if BLUR > 0:
        mini = mini.filter(ImageFilter.GaussianBlur(BLUR))
    mini.save("assets/art_override_mini/" + name)
    print("mini for", name)
