class_name DuelFx
extends Control
## Duel animations drawn above the board: phase / turn banners, explosions, attack flashes, card lunges.
## All art is the original's (j/duel/phase_name, j/duel/effect). Everything here is purely visual.

signal result_shown(kind: String, results: Array)

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


# --- original random-result sprite strips -------------------------------------------------

func strip_frame(rel: String, frame: int, columns: int) -> AtlasTexture:
	var sheet := tex(rel)
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var cell := Vector2(sheet.get_width() / float(columns), sheet.get_height())
	atlas.region = Rect2(Vector2(clampi(frame, 0, columns - 1) * cell.x, 0), cell)
	return atlas

func _roll_sprite(parent: Control, texture: Texture2D, center: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texture != null:
		sprite.size = texture.get_size()
		sprite.position = center - sprite.size / 2
	parent.add_child(sprite)
	return sprite

func coin_face(heads: bool) -> AtlasTexture:
	# The triangle face is heads; the opposite inscription is tails.
	return strip_frame("effect/coin_rotate", 0 if heads else 6, 14)

func toss_coins(outcomes: Array) -> void:
	if outcomes.is_empty():
		return
	var layer := Control.new()
	layer.name = "CoinToss"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var coins := []
	var shadows := []
	var centers := []
	for i in outcomes.size():
		var center := CENTER + Vector2((i - (outcomes.size() - 1) / 2.0) * 72.0, 0)
		centers.append(center)
		shadows.append(_roll_sprite(layer, strip_frame("effect/coin_sha", 0, 4), center + Vector2(0, 24)))
		coins.append(_roll_sprite(layer, coin_face(bool(outcomes[i])), center))
	for frame in 28:
		var progress := frame / 27.0
		for i in coins.size():
			var coin: TextureRect = coins[i]
			coin.texture = strip_frame("effect/coin_rotate", (frame + i * 3) % 14, 14)
			coin.position = centers[i] - coin.size / 2 + Vector2(0, -sin(progress * PI) * 90)
			(shadows[i] as TextureRect).modulate.a = 0.65 - sin(progress * PI) * 0.35
		await _wait(0.04)
	for i in coins.size():
		var coin: TextureRect = coins[i]
		coin.texture = coin_face(bool(outcomes[i]))
		coin.position = centers[i] - coin.size / 2
		var ripple := _roll_sprite(layer, tex("effect/coin_ripple"), centers[i])
		ripple.pivot_offset = ripple.size / 2
		var flash := create_tween().set_parallel(true)
		flash.tween_property(ripple, "scale", Vector2(1.5, 1.5), 0.25)
		flash.tween_property(ripple, "modulate:a", 0.0, 0.25)
	result_shown.emit("coins", outcomes.duplicate())
	await _wait(0.65)
	layer.queue_free()

func roll_dice(result: int) -> void:
	result = clampi(result, 1, 6)
	var layer := Control.new()
	layer.name = "DiceRoll"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var shadow := _roll_sprite(layer, strip_frame("effect/dice_shadow", 0, 6), CENTER + Vector2(0, 22))
	var die := _roll_sprite(layer, strip_frame("effect/dice_random", 0, 6), CENTER)
	for frame in 18:
		die.texture = strip_frame("effect/dice_random", frame % 6, 6)
		shadow.texture = strip_frame("effect/dice_shadow", frame % 6, 6)
		die.position = CENTER - die.size / 2 + Vector2((1.0 - frame / 18.0) * 90, -abs(sin(frame * 0.7)) * 30)
		await _wait(0.035)
	var strip := "effect/dice_ani_2453" if result in [2, 4, 5, 3] else "effect/dice_ani_5621"
	for frame in 16:
		die.texture = strip_frame(strip, frame, 16)
		die.size = die.texture.get_size()
		die.position = CENTER - die.size / 2 + Vector2(0, -abs(sin(frame / 15.0 * PI)) * 12)
		await _wait(0.035)
	die.texture = tex("effect/dice_decide%d" % result)
	die.size = die.texture.get_size()
	die.position = CENTER - die.size / 2
	shadow.texture = tex("effect/dice_dci_sha")
	shadow.size = shadow.texture.get_size()
	shadow.position = CENTER - shadow.size / 2 + Vector2(0, 5)
	result_shown.emit("dice", [result])
	await _wait(0.65)
	layer.queue_free()
