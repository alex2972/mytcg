BATCH CARD INPUT

1. Put artwork images in the artwork folder.
2. Fill cards.csv: one row per card. See example.csv for two examples.
3. Tell me the batch is ready and I can run it and review the preview sheets.

filename: output name, without an extension. Letters, numbers, _ and - only.
artwork: image filename, including .png, .jpg or .webp. If blank, uses filename.png.
name: printed card name.
kind: Normal, Effect, Fusion, Ritual, Spell or Trap.
attribute: EARTH, WATER, DARK, LIGHT, FIRE or WIND (monsters only).
level, race, atk, def: required for monsters; leave empty for spells and traps.
description: printed description or effect. Use double quotes around CSV values containing commas. A spreadsheet editor handles this automatically.
code, edition: optional.
titleColor: black, white, gold or a #RRGGBB color. Defaults to black for monsters and white for spells/traps.
zoom, cropX, cropY, brightness, contrast, saturation: optional. Leave blank for defaults. Artwork fills the window with a centered crop.

The subtype column can specify normal, ritual, continuous, equip, field, quickplay or counter where appropriate. You can add titleSize and bodySize columns too.

CSV can be edited in a text editor or spreadsheet and saved as UTF-8 CSV. Comma, semicolon and tab separators are supported.

Outputs: output/card_builder_batches/<new run folder>/
Each card has a 200x290 PNG, 50x72 miniature and editable project JSON.
Preview sheets and report.csv/report.json are included. Bad rows are reported without stopping the remaining cards. Each run has a separate folder.

Existing game cards are never replaced or registered automatically.
