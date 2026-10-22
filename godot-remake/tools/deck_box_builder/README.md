# Deck Box Studio

Open `index.html` in a browser. This is a self-contained offline editor; no installation, server, or network connection is required. The supplied transparent Yu-Gi-Oh! logo is embedded in the HTML; `logo.webp` preserves the original source.

1. Choose, drop, or paste flat artwork (PNG, JPEG, WebP, or another browser-supported image).
2. Adjust zoom and crop, box depth, logo size and position. The hanging tab and ground shadow are optional.
3. Export a transparent PNG at 600 × 900, 1200 × 1800, or 2400 × 3600. The filename is asset metadata and is never printed on the box.
4. Save a project to retain the embedded artwork and appearance settings; Open project restores them.

The default abstract pattern is a placeholder. The front uses your artwork. The spine, top and hanging tab use a shared subtle diamond pattern tinted from dominant colors sampled around the original image perimeter. This approximates background colors without subject detection; crop changes do not change the palette. Transparent, almost-black and almost-white pixels are excluded, with a slate fallback for images without usable edge colors. All faces use fixed affine projections. Lighting and edge highlights provide depth without a 3D engine. No publisher labels, edition text, deck titles, or age labels are added. Text already present in uploaded artwork or the supplied logo remains part of that image.

Copy exported PNGs into `godot-remake/assets/deck_boxes/` when registering deck assets. They can be used as Texture2D resources in a TextureRect or Sprite2D. Keep the image aspect ratio when displaying. All exports share a 2:3 canvas for consistent shop alignment. The supplied 250 × 87 logo is raster artwork, so high-resolution exports cannot add detail beyond that source.

This tool produces reusable packaging assets. Deck lists, prices, currency deductions and ownership/shop UI are separate game features and are not implemented by the builder.

Optional local preview server, from this directory:

```powershell
python -m http.server 8766 --bind 127.0.0.1
```

Then open http://127.0.0.1:8766.
