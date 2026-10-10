class_name DuelFx
extends Control
## Duel animations drawn above the board: phase / turn banners, explosions, attack flashes, card lunges.
## All art is the original's (j/duel/phase_name, j/duel/effect). Everything here is purely visual.

const CENTER := Vector2(515, 292)

var queue: Array = []
var running := false
var tex_cache := {}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(800, 600)

func tex(rel: String) -> Texture2D:
	if not tex_cache.has(rel):
		var p := "res://assets/j/duel/%s.png" % rel
		tex_cache[rel] = load(p) if ResourceLoader.exists(p) else null
	return tex_cache[rel]

func _wait(t: float) -> void:
	if t > 0 and is_inside_tree():
		await get_tree().create_timer(t).timeout

func _sprite(rel: String, center: Vector2, additive := false) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(rel)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if r.texture != null:
		r.size = r.texture.get_size()
		r.position = center - r.size / 2
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		r.material = m
	add_child(r)
	return r

# --- banners (queued, they never block the game) ---------------------------------------------

func banner(frames: Array, frame_time := 0.06, hold := 0.5) -> void:
	queue.append({"frames": frames, "ft": frame_time, "hold": hold})
	if not running:
		_run_queue()

func _run_queue() -> void:
	running = true
	while not queue.is_empty():
		var b: Dictionary = queue.pop_front()
		var names: Array = b["frames"]
		var r := _sprite(names[0], CENTER)
		if r.texture == null:
			r.queue_free()
			continue
		r.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(r, "modulate:a", 1.0, 0.1)
		for n in names:
			var t := tex(n)
			if t != null:
				r.texture = t
				r.size = t.get_size()
				r.position = CENTER - r.size / 2
			await _wait(b["ft"])
		await _wait(b["hold"])
		var out := create_tween()
		out.tween_property(r, "modulate:a", 0.0, 0.15)
		await _wait(0.15)
		r.queue_free()
	running = false

func phase_banner(phase: String, mine: bool, lang := "e") -> void:
	var key: String = {"draw": "dr", "standby": "st", "main1": "m1", "battle": "ba", "main2": "m2", "end": "en"}.get(phase, "")
	if key == "":
		return
	var c := "b" if mine else "r"
	var base := "phase_name/%s_%s_%s" % [lang, key, c]
	if phase == "battle":
		var frames := []
		for i in range(1, 8):
			frames.append("phase_name/%s_ba_%s%d" % [lang, c, i])
		frames.append(base)
		banner(frames, 0.05, 0.35)
	else:
		banner([base], 0.0, 0.45)

func turn_banner(mine: bool, lang := "e") -> void:
	var c := "b" if mine else "r"
	var frames := []
	for i in range(1, 9):
		frames.append("phase_name/nex_%s_%s%d" % [lang, c, i])
	frames.append("phase_name/nex_%s_%s" % [lang, c])
	banner(frames, 0.05, 0.4)

# --- one-shot effects (awaitable) -------------------------------------------------------------

func explosion(center: Vector2) -> void:
	var r := _sprite("effect/expl1", center, true)
	for i in range(1, 8):
		var t := tex("effect/expl%d" % i)
		if t == null:
			continue
		r.texture = t
		r.size = t.get_size()
		r.position = center - r.size / 2
		await _wait(0.06)
	r.queue_free()

func burst(center: Vector2) -> void:
	var r := _sprite("effect/atk_eff", center, true)
	r.pivot_offset = r.size / 2
	r.scale = Vector2(0.4, 0.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector2(1.5, 1.5), 0.22)
	tw.tween_property(r, "modulate:a", 0.0, 0.22)
	await _wait(0.22)
	r.queue_free()

func sparkle(center: Vector2) -> void:
	var r := _sprite("effect/card_pika_h", center, true)
	r.modulate.a = 0.9
	var tw := create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector2(1.6, 1.6), 0.3)
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	r.pivot_offset = r.size / 2
	await _wait(0.3)
	r.queue_free()

## A ghost of `view` rushes to `to` and back (the real card stays put underneath).
func lunge(view: Control, to: Vector2) -> void:
	var g := TextureRect.new()
	g.texture = (view as TextureRect).texture
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.size = view.size
	g.pivot_offset = view.pivot_offset
	g.rotation_degrees = view.rotation_degrees
	g.position = view.position
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(g)
	var tw := create_tween()
	tw.tween_property(g, "position", to, 0.16).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "position", view.position, 0.14).set_ease(Tween.EASE_OUT)
	await _wait(0.32)
	g.queue_free()
