# Card Shop UI asset kit

Implementation update: the kit is now assembled in `ui/shop.gd` and accessible through the temporary Shop button on the main menu. See `docs/SHOP.md` for behavior and validation. The asset-delivery notes below describe the original artwork package; its ZIP remains an artwork-only handoff.

Generated from the approved 4:3 shop concept. The individual PNG assets are in `res://assets/ui/shop/`. This delivery contains UI artwork and a layout reference; it does not add shop behavior or modify existing scenes. Product art is intentionally excluded.

## Files

- `background.png`: full-screen gray duel-field background; draw at 800 × 600.
- `header_strip.png`, `footer_strip.png`: independent blank chrome strips.
- `logo_yugioh.png`: isolated generated logo derived from the existing game logo; review against the original branding before a final release.
- `title_card_shop.png`: fixed silver CARD SHOP title.
- `tab_normal.png`, `tab_hover.png`, `tab_pressed.png`, `tab_selected.png`: category button surfaces. Normal is pale silver; selected is orange-red. Use normal with reduced opacity for disabled tabs.
- `price_normal.png`, `price_hover.png`, `price_disabled.png`: blank price plaques. Render prices in code. Pressed can use normal with a darker modulation.
- `balance_panel.png`: blank dark DP balance panel with silver frame.
- `back_normal.png`, `back_hover.png`, `back_pressed.png`, `back_disabled.png`: blank Back button surfaces.
- `selection_corner.png`: top-left corner marker. Mirror horizontally for top-right, vertically for bottom-left, both for bottom-right. A TextureRect supports `flip_h` and `flip_v`.
- `scroll_track.png`: empty vertical scrollbar channel. Use a NinePatchRect / StyleBoxTexture to stretch its center, retaining its end caps.
- `scroll_thumb.png`: separate orange scrollbar thumb. Its height must reflect the viewport/content ratio.
- `scroll_arrow_down.png`: separate arrow button; flip vertically if an up arrow is needed.
- `shop_font.tres`: runtime SystemFont using Impact, then Arial Narrow / Arial fallbacks. Impact is installed on this workstation. No font binary is redistributed; for another platform, supply a licensed condensed font for consistent text metrics.

All control PNGs preserve true alpha. The generated source sheets are retained in `sources/`. Controls were mechanically cropped into individual files; their pixel dimensions vary slightly between states. Render every state into the same fixed control rectangle to avoid layout movement. Do not trim and resize the live control on state changes.

## Layout at 800 × 600

Coordinates are an implementation starting point matching the approved composition. Use the full background under the fixed header/footer.

| Element | x | y | width | height |
| --- | ---: | ---: | ---: | ---: |
| Background | 0 | 0 | 800 | 600 |
| Header strip | 0 | 0 | 800 | 64 |
| Logo | 44 | 0 | 195 | 60 |
| CARD SHOP title | 247 | 8 | 200 | 44 |
| DP balance panel | 554 | 10 | 211 | 43 |
| Packs tab | 150 | 71 | 154 | 32 |
| Decks tab | 310 | 71 | 150 | 32 |
| Bundles tab | 468 | 71 | 155 | 32 |
| Catalog clip viewport | 136 | 116 | 598 | 410 |
| Scrollbar track | 760 | 108 | 16 | 378 |
| Scrollbar down arrow | 760 | 486 | 16 | 16 |
| Footer strip | 0 | 526 | 800 | 74 |
| Back button | 22 | 531 | 129 | 57 |
| Footer hint | 174 | 551 | 340 | 24 |

The three pack columns start at screen x=160, 340, 514. The first-row pack rectangles are approximately 120 × 220 at y=126. Preserve the supplied products' aspect ratios inside those rectangles. Names are centered below at y=355, prices at y=380 (80 × 25). Start the next row around y=452. Keep all catalog content inside the clip viewport. Header, tabs, scrollbar, and footer remain fixed. These are positions, not baked text/images.

Place selection markers just outside the selected pack image, around 17 × 18 each. Keep them inside the catalog so they scroll with the product.

## Text and colors

Use Labels over the blank textures: tab text 20 px, product names 19 px, prices 18 px, Back 27 px, balance 27 px, footer 16 px. Tune against actual rendered metrics at 800 × 600. White labels use a small dark outline; dark tab labels use no heavy shadow.

- White names: `#F3F4F5`, dark outline `#111923`.
- Silver tab text: `#18202B`.
- Selected tab, price, and Back text: `#790D08`, subtle pale outline if needed.
- DP suffix/accent: `#FFD51A`.

## Godot usage

Use TextureButton textures for normal/hover/pressed/disabled, with an overlaid Label using `mouse_filter = IGNORE`. For selected categories, swap to `tab_selected.png` and change the label color. Set the texture button to ignore native texture size and stretch into the fixed rectangle. Keep the selected tab visually selected during hover/press.

Use a ScrollContainer with three columns, or a custom clipped catalog. Connect the scrollbar to actual content height. The preview uses empty product footprints solely to demonstrate spacing; do not ship those placeholders. Attach real user-created packs/decks through catalog data.

Use linear texture filtering for the high-resolution textures at the 800 × 600 design size. The PNGs are source-resolution assets; the background's near-4:3 size is intentionally scaled to the exact viewport. Preserve alpha when importing. The kit does not include purchase dialogs or pack-opening visuals because they are outside the approved screen.

## Preview and provenance

Open `preview.html` for the UI composition and asset inventory. It uses the actual PNG files and browser text, with no product art. `approved_concept.png` is the user's target reference. `sprite_manifest.json` lists source extraction rectangles; `asset_manifest.json` lists final asset dimensions, alpha validation, and intended usage.

The assets have been checked for nonempty image data, transparent control corners, and complete individual output files. Integration in the running game remains separate.
