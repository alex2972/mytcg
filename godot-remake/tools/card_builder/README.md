# Local Card Builder

Creates new card PNGs using the original game's frame pixels, symbols, and 200 × 290 layout. No source cards or game data are changed.

## Launch

From the `godot-remake` directory:

```powershell
python tools/card_builder/server.py
```

Requires Python 3.10+ and Pillow (`python -m pip install Pillow`). The editor opens at http://127.0.0.1:8765. Keep the process running while using it; Ctrl+C stops it. Use `--no-browser` to start without opening a browser.

## Use

1. Select Normal, Effect, Fusion, Ritual, Spell, or Trap. Each type has one fixed game frame.
2. Supply artwork by choosing a file or copying an image and pressing Ctrl+V in the artwork area. The Paste image from clipboard button is also available. Use zoom / horizontal / vertical sliders to crop it into the illustration window.
3. Enter the new card's text and details. Select the title color; upload a custom title TTF/OTF if desired.
4. Check the preview at game size. Brightness, contrast, and saturation affect artwork only.
5. Export. `output/card_builder/` receives the 200 × 290 PNG, a 50 × 72 miniature, and a JSON project including the uploaded artwork. Existing filenames are rejected rather than overwritten.

Save/Open project supports round trips and work across sessions. Download PNG saves the preview using your browser. Source artwork is never uploaded to a remote service.

## Accuracy and scope

The six fixed frames use MRD023, MRL010, TP3007, MRL068, SDY042, and EDS003. Fusion and Ritual use the requested Kwagar Hercules and Hungry Burger references; their empty star rows come from native one-star cards of the same types. Star backgrounds are never stretched. Printed letters are removed using small ink masks and local reconstruction, retaining the original title bevel, description borders, and divider. Untouched pixels are preserved exactly at native resolution. Italic body text is clipped inside the description box so it cannot spill onto the left border. The default title lettering comes from a glyph atlas extracted from over 3,000 letter samples in the original black card titles. White and gold names use a separate atlas extracted from over 2,000 native white title letters, retaining their stronger stroke weight. Black names use the original dark atlas. A few uncommon digits/punctuation absent from the source atlas use a fallback font, and uppercase X is reconstructed from the small-cap X. Custom title fonts remain optional.

Body text uses Arial (or Times Italic for normal monster flavor text), and stats use native lettering extracted from original game cards, rendered directly at game resolution. The stat background retains the pale highlight sampled from its original rows. Black, white, gold and custom title colors are available. Body fonts remain approximations, not identified original fonts. Layout uses a common artwork window `(28,63)–(173,207)` and 4× rendering downsampled to game resolution. There is no bottom-left passcode field; obsolete passcodes in old projects are ignored. Old frame-reference choices are also ignored in favor of the fixed type frame.

`build_title_atlas.py` regenerates `title_glyphs.json`; `--light` regenerates `title_glyphs_light.json` from the original cards and writes a visual atlas to the checks folder. Existing cards are never edited.

The builder renders card images only. It does not register missing cards, gameplay effects or fusion recipes in Godot, and does not write to `assets/cards` or `assets/art_override`. Copy an approved export into the appropriate new asset location only when adding its game data separately.

## Verification

```powershell
python tools/card_builder/check.py
```

Checks all six card types, custom metadata, text fitting, symbol handling, output dimensions and preservation of original files. Creates preview sheets under `output/card_builder_checks/`.


## Batch creation

Use `card_batches/input/cards.csv` and put artwork under `card_batches/input/artwork/`.
`example.csv` and `README.txt` in that folder explain the columns. Each row is one card;
`filename` is the export name and `artwork` selects its image. Monster rows require
attribute, level, race, atk and def. Title colors accept black, white, gold or a hex color.
Optional crop and tone values use the same settings as the editor.

```powershell
python tools/card_builder/batch.py card_batches/input/cards.csv
```

For a different folder, pass its CSV path; artwork defaults to an `artwork` folder beside it.
Use `--artwork` to select another artwork folder. Exports go to a new run folder under
`output/card_builder_batches/`. Each successful row creates a card, miniature and editor
project JSON. Preview sheets and CSV/JSON reports accompany the batch. Invalid rows are
reported while other rows continue. Repeated runs never overwrite previous exports.
Batch mode uses the renderer directly and does not require the browser server.

`build_stat_atlas.py` regenerates native ATK/DEF masks and all ten digit masks in `stat_glyphs.json`. Every value uses the same fixed labels and five-pixel digit spacing. Values from 0 to 9999 retain the same size and weight.
