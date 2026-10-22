extends RefCounted
## Native deck sprites use 85,255,0 as a transparency key, even inside atlases.
static var cache := {}

static func get_texture(path: String) -> Texture2D:
	if not cache.has(path):
		var source := load(path) as Texture2D
		if source == null:
			return null
		var image := source.get_image()
		image.convert(Image.FORMAT_RGBA8)
		var bytes := image.get_data()
		var changed := false
		for i in range(0, bytes.size(), 4):
			if bytes[i] == 85 and bytes[i + 1] == 255 and bytes[i + 2] == 0:
				bytes[i] = 0
				bytes[i + 1] = 0
				bytes[i + 3] = 0
				changed = true
		cache[path] = ImageTexture.create_from_image(Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, bytes)) if changed else source
	return cache[path]
