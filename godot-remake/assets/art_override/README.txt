Drop PNGs here named <konami card number>.png (the "no." shown in the card panel, second column of docs/TOKEN_ART_CARDS.txt) to replace the placeholder art.
The game's own card images are COMPLETE card faces (frame, name, type line, art, text box, copyright line), 200 x 290 pixels. A replacement should be a complete card
image with the same ratio (about 0.69, e.g. 200x290, 400x580 or 600x870). Larger is fine and sharper: the game scales it. The same image is also used, scaled down, for
the small card icons on the field and in the lists.
If you only have the artwork (the square picture), tell me: I can build a tool that places it onto a card frame with the name and text from the game's database.

After adding or changing images run:  python tools/make_override_minis.py  (it makes the matching 50x72 icons in assets/art_override_mini).
