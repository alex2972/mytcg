class_name PlankArt
extends RefCounted
## Recover the shared original wood at its native coordinates. The localized
## idle labels brighten brown wood and darken yellow wood; other copies expose
## the underlying pixels. No patches, repeated strips, or generated wood.

static var _themes: Dictionary = {}

static func theme(yellow: bool) -> Dictionary:
	if _themes.has(yellow):
		return _themes[yellow]
	var suffix := "d_" if yellow else ""
	var copies: Array[Image] = []
	for language in ["e", "f", "g", "i", "s"]:
		var atlas: Texture2D = load("res://assets/j/title/menu_%s_%sani0.png" % [language, suffix])
		var image := atlas.get_image()
		# These three rows share exactly the same wood. The other two have a
		# different grain layout and must not contribute to the reconstruction.
		for row in [0, 3, 4]:
			copies.append(image.get_region(Rect2i(0, row * 50, 400, 44)))
	var wood := copies[1].duplicate() as Image
	# Preserve the original cut edges and bevel, which already have no text.
	for y in range(4, 41):
		for x in range(4, 396):
			var background := copies[0].get_pixel(x, y)
			var score := background.r + background.g + background.b
			for candidate in copies:
				var pixel := candidate.get_pixel(x, y)
				var brightness := pixel.r + pixel.g + pixel.b
				if (yellow and brightness > score) or (not yellow and brightness < score):
					background = pixel
					score = brightness
			wood.set_pixel(x, y, background)
	var result := {"wood": ImageTexture.create_from_image(wood), "image": wood}
	if not yellow:
		result.wear = _original_ink_wear(wood, copies[1])
	_themes[yellow] = result
	return result

static func _original_ink_wear(wood: Image, idle: Image) -> ImageTexture:
	# Frame 4 has the same glyph geometry as idle, with solid ink. Comparing
	# their opaque stroke interiors recovers actual worn/clean areas from the
	# original OPTIONS label, rather than eroding every letter using grain.
	var solid_atlas: Texture2D = load("res://assets/j/title/menu_e_ani4.png")
	var solid := solid_atlas.get_image().get_region(Rect2i(0, 150, 400, 44))
	var wear := Image.create(400, 44, false, Image.FORMAT_RGBA8)
	wear.fill(Color.WHITE)
	for y in range(5, 37):
		var positions: Array[int] = []
		var values: Array[float] = []
		for x in range(80, 320):
			var base := wood.get_pixel(x, y).b
			var solid_alpha := (solid.get_pixel(x, y).b - base) / maxf(0.01, 1.0 - base)
			if solid_alpha > 0.98:
				var idle_alpha := (idle.get_pixel(x, y).b - base) / maxf(0.01, 1.0 - base)
				positions.append(x)
				values.append(clampf(idle_alpha / 0.45, 0.0, 1.0))
		if positions.is_empty():
			continue
		var nearest := 0
		for x in 400:
			while nearest + 1 < positions.size() and abs(positions[nearest + 1] - x) < abs(positions[nearest] - x):
				nearest += 1
			var strength := values[nearest] if abs(positions[nearest] - x) < 16 else 1.0
			wear.set_pixel(x, y, Color(strength, strength, strength, 1))
	return ImageTexture.create_from_image(wear)
