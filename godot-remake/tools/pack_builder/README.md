# Pack Studio

Open `index.html` in a browser. It works offline with the supplied Yu-Gi-Oh! logo embedded in the file, and does not require installation.

1. Choose, paste, or drop artwork.
2. Adjust crop and zoom. The front has a straight-on view with slightly curved edges, metallic crimped seals and adjustable foil reflections.
3. Adjust seal height, logo width and logo placement. Turn **Add Yu-Gi-Oh! logo** off when importing a finished cover that already contains a logo (such as the provided pack_tex images). Text and logos baked into artwork are not removed.
4. Export a transparent PNG at 400 × 600, 600 × 900, 1200 × 1800, or 2400 × 3600. The pack occupies a tall, narrow silhouette within the consistent 2:3 asset canvas.
5. Save/Open project preserves embedded artwork and settings in a `.pack.json` file. Deck-box projects remain separate.

The initial pattern is a placeholder. Plain artwork is best for new designs; existing finished pack textures may include their own seals or branding. No titles, publisher labels, edition labels or card counts are added by this editor. The original raster logo limits sharpness at large export sizes.

Copy exported PNGs to the game's chosen pack asset folder and use them as Texture2D resources with aspect ratio preserved. This builder does not change pack contents, prices or purchase logic.
