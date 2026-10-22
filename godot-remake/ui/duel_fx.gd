class_name DuelFx
extends Control
## Duel animations drawn above the board: phase / turn banners, explosions, attack flashes, card lunges.
## All art is the original's (j/duel/phase_name, j/duel/effect). Everything here is purely visual.

signal shuffle_frame_shown(frame: int, tick: int)

signal set_frame_shown(yellow: bool, tick: float)

signal summon_frame_shown(tick: float)
signal tribute_frame_shown(tick: float)
signal phase_frame_shown(phase: String, progress: float)
signal explosion_frame_shown(tick: float)
signal opening_frame_shown(tick: float)
signal opening_wipe(progress: float)

const SUMMON_DURATION := 1.0
const TRIBUTE_DURATION := 1.2
const TRIBUTE_READY_TICK := 248.0

const SET_DURATION := 256.0 / (12.0 * 30.0)
const ACTIVATION_DURATION := 0.6
const SELECTION_DURATION := 0.4
const SHATTER_DURATION := 0.75
const BATTLE_TIMING := preload("res://ui/battle_timing.gd")

signal turn_wipe(progress: float)

signal animation_stage(kind: String, stage: String)

signal banner_finished

signal result_shown(kind: String, results: Array)

const FRAME_BLEND_SHADER := preload("res://ui/shaders/frame_blend.gdshader")

const SUMMON_SHADER := preload("res://ui/shaders/summon_rainbow.gdshader")
const OPENING_STRIPS_SHADER := preload("res://ui/shaders/opening_strips.gdshader")

const CENTER := Vector2(515, 292)

var queue: Array = []
var running := false
var tex_cache := {}
var active_tributes := 0

## Draw tiny card fragments as one batch instead of hundreds of animated Controls.
class EffectFragments:
	extends Node2D
	var artwork: Texture2D
	var card_size := Vector2(50,72)
	var progress := 0.0
	func _draw() -> void:
		if artwork == null: return
		var grid := Vector2i(ceil(card_size.x/2),ceil(card_size.y/2))
		var cell := card_size/Vector2(grid)
		var source_cell := artwork.get_size()/Vector2(grid)
		var opacity := 1.0-smoothstep(0.2,1.0,progress)
		for y in grid.y:
			for x in grid.x:
				var direction := Vector2.from_angle((x*17+y*11)*0.73)
				var origin := Vector2(x,y)*cell-card_size/2
				var offset := direction*(30+(x+y)%4*13)*progress
				draw_texture_rect_region(artwork,Rect2(origin+offset,cell),Rect2(Vector2(x,y)*source_cell,source_cell),Color(1,1,1,opacity))

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

# --- banners (queued; callers may await completion) ---------------------------------------------

func banner(frames: Array, frame_time := 0.06, hold := 0.5, yaw := false, phase := "") -> void:
	var request := {"frames": frames, "ft": frame_time, "hold": hold, "done": false, "yaw": yaw, "phase": phase}
	queue.append(request)
	if not running:
		_run_queue()
	while not request["done"]:
		await banner_finished

func _run_queue() -> void:
	running = true
	while not queue.is_empty():
		var b: Dictionary = queue.pop_front()
		var names: Array = b["frames"]
		if b["phase"] != "":
			await _phase_presentation(names, str(b["phase"]))
			b["done"] = true
			banner_finished.emit()
			continue
		var r := _sprite(names[0], CENTER)
		if r.texture == null:
			remove_child(r)
			r.queue_free()
			b["done"] = true
			banner_finished.emit()
			continue
		r.pivot_offset = r.size / 2
		if b["yaw"]:
			r.scale = Vector2(0.05, 1.5)
			var enter := create_tween().set_parallel(true)
			enter.tween_property(r, "scale", Vector2.ONE, 0.22)
			await enter.finished
		r.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(r, "modulate:a", 1.0, 0.1)
		if b["yaw"]:
			turn_wipe.emit(0.0)
			var wipe := create_tween()
			wipe.tween_method(func(progress: float): turn_wipe.emit(progress),0.0,1.0,b["ft"]*names.size())
		for frame in names.size():
			var n: String = names[frame]
			var t := tex(n)
			if t != null:
				r.texture = t
				r.size = t.get_size()
				r.position = CENTER - r.size / 2
			await _wait(b["ft"])
		await _wait(b["hold"])
		var out := create_tween()
		out.tween_property(r, "modulate:a", 0.0, 0.2)
		if b["yaw"]:
			out.parallel().tween_property(r, "scale", Vector2(0.02, 1.5), 0.2)
		await out.finished
		remove_child(r)
		r.queue_free()
		b["done"] = true
		banner_finished.emit()
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
		await banner(frames, 0.0, 0.0, false, phase)
	else:
		await banner([base], 0.0, 0.0, false, phase)

func turn_banner(mine: bool, lang := "e") -> void:
	var c := "b" if mine else "r"
	var frames := []
	for i in range(8, 0, -1):
		frames.append("phase_name/nex_%s_%s%d" % [lang, c, i])
	frames.append("phase_name/nex_%s_%s" % [lang, c])
	await banner(frames, 0.065, 0.4, true)

# --- one-shot effects (awaitable) -------------------------------------------------------------

## Interpolate the extracted sprite frames at render rate instead of stopping on each frame.
func _frame_blend_material() -> ShaderMaterial:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = FRAME_BLEND_SHADER
	return shader_material

func _blend_frames(sprite: TextureRect, frames: Array, index: float) -> void:
	var first := clampi(int(floor(index)), 0, frames.size() - 1)
	var second := mini(first + 1, frames.size() - 1)
	sprite.texture = tex(frames[first])
	sprite.size = sprite.texture.get_size().lerp(tex(frames[second]).get_size(),clampf(index-first,0.0,1.0))
	sprite.pivot_offset = sprite.size / 2
	var shader_material: ShaderMaterial = sprite.material
	shader_material.set_shader_parameter("next_frame", tex(frames[second]))
	shader_material.set_shader_parameter("blend_amount", clampf(index - first, 0.0, 1.0))

func _phase_presentation(frames: Array, phase: String) -> void:
	var layer := Control.new()
	layer.name = "PhaseBanner"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var center := Vector2(525, 300) # Native DAT_005db570 and phase renderer y=300.
	var title := _sprite(frames[0], center)
	title.reparent(layer)
	title.pivot_offset = title.size / 2
	title.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title.material = _frame_blend_material()
	var echoes: Array[TextureRect] = []
	for i in 2:
		var echo := _sprite(frames[0], center)
		echo.reparent(layer)
		echo.pivot_offset = echo.size / 2
		echo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		echoes.append(echo)
	var streak := ColorRect.new()
	streak.size = Vector2(550, 10)
	streak.position = center - streak.size / 2
	streak.pivot_offset = streak.size / 2
	streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float a = sin(UV.x * 3.14159265) * exp(-pow((UV.y - 0.5)*8.0,2.0)); COLOR = vec4(1.0,0.85,0.95,a) * COLOR; }"
	var streak_material := ShaderMaterial.new()
	streak_material.shader = shader
	streak.material = streak_material
	layer.add_child(streak)
	var state := {"title": false, "fade": false}
	animation_stage.emit(phase, "intro")
	var duration: float = BATTLE_TIMING.PHASE_ENTRY_DURATION if phase == "battle" else BATTLE_TIMING.OTHER_PHASE_DURATION
	_update_phase_frame(0.0, phase, title, echoes, streak, frames, state)
	var animation := create_tween()
	animation.tween_method(_update_phase_frame.bind(phase, title, echoes, streak, frames, state), 0.0, 1.0, duration)
	await animation.finished
	remove_child(layer)
	layer.queue_free()
	animation_stage.emit(phase, "complete")

func _update_phase_frame(progress: float, phase: String, title: TextureRect, echoes: Array[TextureRect], streak: ColorRect, frames: Array, state: Dictionary) -> void:
	var intro := 0.18 if phase == "battle" else 0.25
	var fade_start := 0.55 if phase == "battle" else 0.5
	var entry := clampf(progress / intro, 0.0, 1.0)
	var pulse := clampf((progress - intro) / (fade_start - intro), 0.0, 1.0)
	var fade := clampf((progress - fade_start) / (1.0 - fade_start), 0.0, 1.0)
	title.visible = progress >= intro
	_blend_frames(title, frames, pulse * (frames.size() - 1))
	title.modulate.a = cos(fade * PI / 2)
	for i in echoes.size():
		var echo := echoes[i]
		echo.visible = progress < intro
		echo.position.x = 525 - echo.size.x / 2 + (-1 if i == 0 else 1) * 64 * cos(entry * PI / 2)
		echo.scale.y = maxf(0.04, sin(entry * PI / 2))
		echo.modulate.a = sin(entry * PI / 2) * 0.65
	streak.visible = progress < intro
	streak.scale.x = 0.1 + sin(entry * PI / 2) * 0.9
	streak.modulate.a = sin(entry * PI)
	if progress >= intro and not state["title"]:
		state["title"] = true
		animation_stage.emit(phase, "title")
	if progress >= fade_start and not state["fade"]:
		state["fade"] = true
		animation_stage.emit(phase, "fade")
	phase_frame_shown.emit(phase, progress)

## Native explosion layers overlap: growing spokes, bright core, then orange puffs.
func battle_shake(view: Control, duration: float = BATTLE_TIMING.SHAKE_DURATION) -> void:
	animation_stage.emit("battle_destroy", "shake")
	var origin := view.position
	var shake := create_tween()
	shake.tween_method(func(progress: float): view.position = origin+Vector2(sin(progress*TAU*3)*3.0*(1.0-progress),0),0.0,1.0,duration)
	await shake.finished
	view.position = origin
	animation_stage.emit("battle_destroy", "shake_complete")

func explosion(center: Vector2, completion: Dictionary = {}) -> void:
	var layer := Control.new()
	layer.name = "BattleExplosion"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var sprites: Array[TextureRect] = []
	for rel in ["effect/expl1", "effect/expl2", "effect/expl3"]:
		var r := _sprite(rel, center)
		r.reparent(layer)
		r.pivot_offset = r.size / 2
		r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprites.append(r)
	sprites[2].material = _frame_blend_material()
	var state := {"core": false, "puffs": false, "completion": completion}
	animation_stage.emit("battle_destroy", "spokes")
	_update_explosion_frame(0.0, sprites, center, state)
	var animation := create_tween()
	animation.tween_method(_update_explosion_frame.bind(sprites, center, state), 0.0, 208.0, BATTLE_TIMING.DESTRUCTION_DURATION)
	await animation.finished
	remove_child(layer)
	layer.queue_free()
	animation_stage.emit("battle_destroy", "complete")

func _update_explosion_frame(tick: float, sprites: Array[TextureRect], center: Vector2, state: Dictionary) -> void:
	var spokes := sprites[0]
	spokes.visible = tick < 128.0
	spokes.scale = Vector2.ONE * ((tick + 128.0) / 256.0)
	spokes.rotation = tick * TAU / 512.0
	spokes.modulate.a = maxf(0.0, cos((tick - 64.0) * TAU / 512.0))
	var core := sprites[1]
	core.visible = tick > 32.0 and tick < 144.0
	core.scale = Vector2.ONE * ((tick + 96.0) / 256.0)
	core.modulate.a = clampf((tick + 96.0) / 255.0, 0.0, 1.0)
	var puffs := sprites[2]
	puffs.visible = tick >= 128.0
	_blend_frames(puffs, ["effect/expl3","effect/expl4","effect/expl5","effect/expl6","effect/expl7"], maxf(0.0,(tick-128.0)*5.0/64.0))
	puffs.position = center - puffs.size / 2
	puffs.modulate.a = 1.0 - smoothstep(184.0,208.0,tick)
	if core.visible and not state["core"]:
		state["core"] = true
		animation_stage.emit("battle_destroy", "core")
	if puffs.visible and not state["puffs"]:
		state["puffs"] = true
		state["completion"]["grave_ready"] = true
		animation_stage.emit("battle_destroy", "puffs")
	explosion_frame_shown.emit(tick)

func attack_confirmation(view: Control) -> void:
	animation_stage.emit("attack", "target")
	var r := _sprite("card/card_waku#s", view.position + view.size / 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = view.size + Vector2(8,8)
	r.position = view.position - Vector2(4,4)
	r.pivot_offset = r.size / 2
	r.rotation = view.rotation
	var pulse := create_tween()
	pulse.tween_method(func(t: float): r.modulate.a = 0.65 + 0.35 * sin(t * PI),0.0,1.0,0.7)
	await pulse.finished
	remove_child(r)
	r.queue_free()

func damage_calculation(view: Control) -> void:
	animation_stage.emit("attack", "calculation")
	if view == null:
		return
	animation_stage.emit("attack", "survival_shine")
	var clip := Control.new()
	clip.name = "DamageCalculation"
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.size = Vector2(view.size.y,view.size.x) if absf(sin(view.rotation)) > 0.5 else view.size
	clip.position = view.position + view.size / 2 - clip.size / 2
	clip.clip_contents = true
	add_child(clip)
	var sheen := _sprite("effect/dmg_ref", Vector2.ZERO, true)
	sheen.reparent(clip)
	sheen.position = Vector2(-sheen.size.x, (clip.size.y-sheen.size.y)/2)
	var sweep := create_tween()
	sweep.tween_property(sheen,"position:x",clip.size.x,BATTLE_TIMING.SURVIVAL_SHINE_DURATION)
	await sweep.finished
	remove_child(clip)
	clip.queue_free()

func burst(center: Vector2) -> void:
	animation_stage.emit("attack", "impact")
	var r := _sprite("effect/atk_eff", center)
	r.pivot_offset = r.size / 2
	var animation := create_tween()
	animation.tween_method(func(progress: float):
		r.scale = Vector2.ONE * progress * 2
		r.modulate.a = minf(1.0,2 * (1.0-progress)),0.0,1.0,BATTLE_TIMING.IMPACT_DURATION)
	await animation.finished
	remove_child(r)
	r.queue_free()

func sparkle(center: Vector2) -> void:
	var r := _sprite("effect/card_pika_h", center, true)
	r.modulate.a = 0.9
	var tw := create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector2(1.6, 1.6), 0.3)
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	r.pivot_offset = r.size / 2
	await tw.finished
	remove_child(r)
	r.queue_free()

## Reference presentations use their own extracted art rather than a shared halo.
func reveal_board(outgoing: Texture2D) -> void:
	var strips := TextureRect.new()
	strips.name = "OpeningStrips"
	strips.texture = outgoing
	strips.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strips.stretch_mode = TextureRect.STRETCH_SCALE
	strips.size = size
	strips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip_material := ShaderMaterial.new()
	strip_material.shader = OPENING_STRIPS_SHADER
	strips.material = strip_material
	add_child(strips)
	# Give the outgoing viewport a frame to render before opening the strips.
	await get_tree().process_frame
	animation_stage.emit("opening", "wipe")
	opening_wipe.emit(0.0)
	var wipe := create_tween()
	wipe.tween_method(func(progress: float):
		strip_material.set_shader_parameter("progress", progress)
		opening_wipe.emit(progress),0.0,1.0,0.45)
	await wipe.finished
	remove_child(strips)
	strips.queue_free()
	animation_stage.emit("opening", "board")

func start_duel(lang := "e") -> void:
	await _wait(0.2)
	var shade := ColorRect.new()
	shade.name = "StartShade"
	shade.color = Color(0, 0, 0, 0)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var dark := create_tween()
	dark.tween_property(shade, "color:a", 0.45, 0.12)
	await dark.finished
	animation_stage.emit("start", "title")
	AudioUtil.sfx("start")
	var title := _sprite("effect/duel_start_%s" % lang, Vector2(400, 300))
	title.name = "StartTitle"
	title.pivot_offset = title.size / 2
	title.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_update_start_frame(0.0,title)
	var presentation := create_tween()
	presentation.tween_method(_update_start_frame.bind(title),0.0,320.0,4.0/3.0)
	await presentation.finished
	remove_child(title)
	title.queue_free()
	var brighten := create_tween()
	brighten.tween_property(shade, "color:a", 0.0, 0.12)
	await brighten.finished
	remove_child(shade)
	shade.queue_free()
	await _wait(0.25)
	animation_stage.emit("start", "complete")

## Native 00451980: scale 1.5 -> 1 through tick 64, hold to 256, fade to 320.
func _update_start_frame(tick: float, title: TextureRect) -> void:
	title.scale = Vector2.ONE * (1.0 + 0.5 * cos(tick * PI / 128.0)) if tick < 64.0 else Vector2.ONE
	title.modulate.a = sin(tick * PI / 128.0) if tick < 64.0 else (cos((tick-256.0)*PI/128.0) if tick > 256.0 else 1.0)
	opening_frame_shown.emit(tick)

func battle_sweep() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.75, 0.9, 0.85)
	flash.size = Vector2(12, 3)
	flash.position = CENTER - flash.size / 2
	flash.pivot_offset = flash.size / 2
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var spread := create_tween().set_parallel(true)
	spread.tween_property(flash, "scale", Vector2(42, 2), 0.12)
	spread.tween_property(flash, "modulate:a", 0.0, 0.2)
	await spread.finished
	remove_child(flash)
	flash.queue_free()

func selection_flash(view: Control) -> void:
	animation_stage.emit("selection", "flash")
	var r := _sprite("effect/card_pika_h", view.position + view.size / 2, true)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = view.size + Vector2(8, 8)
	r.position = view.position - Vector2(4, 4)
	r.pivot_offset = r.size / 2
	r.rotation = view.rotation
	r.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_method(func(progress: float): r.modulate.a = sin(progress * PI), 0.0, 1.0, SELECTION_DURATION)
	await fade.finished
	remove_child(r)
	r.queue_free()
	animation_stage.emit("selection", "complete")

## Native 0044fa10: first a fading miniature of the card, then a pixel-sized
## rainbow crop scrolling vertically with wrap. Do not stretch the whole 100x94 sheet.
func summon_rainbow(view: Control) -> void:
	var layer := Control.new()
	layer.name = "SummonRainbow"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var center := view.position + view.size / 2
	var ghost := TextureRect.new()
	ghost.name = "CardGhost"
	ghost.texture = (view as TextureRect).texture
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_SCALE
	ghost.size = view.size
	ghost.position = view.position
	ghost.pivot_offset = view.size / 2
	ghost.rotation = view.rotation
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ghost)
	var rainbow := _sprite("effect/eff_rainbow", center)
	rainbow.name = "RainbowCrop"
	rainbow.reparent(layer)
	rainbow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rainbow.stretch_mode = TextureRect.STRETCH_SCALE
	rainbow.size = Vector2(view.size.y, view.size.x) if absf(sin(view.rotation)) > 0.5 else view.size
	rainbow.position = center - rainbow.size / 2
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SUMMON_SHADER
	shader_material.set_shader_parameter("rainbow_sheet", rainbow.texture)
	shader_material.set_shader_parameter("crop_size", rainbow.size)
	shader_material.set_shader_parameter("sheet_size", rainbow.texture.get_size())
	rainbow.material = shader_material
	var state := {"rainbow_started": false}
	_update_summon_frame(0.0, ghost, rainbow, shader_material, state)
	var animation := create_tween()
	animation.tween_method(_update_summon_frame.bind(ghost, rainbow, shader_material, state), 0.0, 256.0, SUMMON_DURATION)
	await animation.finished
	remove_child(layer)
	layer.queue_free()

func _update_summon_frame(tick: float, ghost: TextureRect, rainbow: TextureRect, shader_material: ShaderMaterial, state: Dictionary) -> void:
	var reveal := smoothstep(64.0,80.0,tick)
	ghost.visible = tick < 80.0
	ghost.scale = Vector2.ONE * minf(1.0,(tick + 64.0) / 128.0)
	ghost.modulate.a = maxf(0.0,cos((minf(tick,64.0)+56.0)*TAU/512.0)) * (1.0-reveal)
	rainbow.visible = tick > 64.0
	if rainbow.visible and not state["rainbow_started"]:
		state["rainbow_started"] = true
		animation_stage.emit("summon", "rainbow")
	shader_material.set_shader_parameter("offset_px", tick * 5.0 / 8.0)
	shader_material.set_shader_parameter("strength", clampf(cos((tick - 160.0) * TAU / 512.0) * 192.0 / 255.0, 0.0, 1.0) * reveal * (1.0-smoothstep(240.0,256.0,tick)))
	summon_frame_shown.emit(tick)

## Native Set renderer: 0044f370 advances by 12 ticks; 0044f390 draws through tick 256.
## A Set monster uses the same renderer with yellow art, independently of Tribute effects.
func set_card(center: Vector2, yellow := false) -> void:
	animation_stage.emit("set_monster" if yellow else "set", "ring")
	var layer := Control.new()
	layer.name = "SetCircle"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var color_key := "y" if yellow else "b"
	var ring := _sprite("effect/eff_set_%s" % color_key, center)
	ring.reparent(layer)
	ring.pivot_offset = ring.size / 2
	var stars: Array[TextureRect] = []
	var origins: Array[Vector2] = []
	var visual_rng := RandomNumberGenerator.new()
	visual_rng.seed = hash(center) # Native radius range 16..47, without sampling game RNG.
	for i in 8:
		var radius := visual_rng.randi_range(16, 47)
		var origin := center + Vector2.from_angle(i * TAU / 8) * radius
		var star := _sprite("effect/eff_star0_%s" % color_key, origin)
		star.reparent(layer)
		stars.append(star)
		origins.append(origin)
	_update_set_frame(0.0, ring, stars, origins, yellow)
	var animation := create_tween()
	animation.tween_method(_update_set_frame.bind(ring, stars, origins, yellow), 0.0, 256.0, SET_DURATION)
	await animation.finished
	remove_child(layer)
	layer.queue_free()

func _update_set_frame(tick: float, ring: TextureRect, stars: Array[TextureRect], origins: Array[Vector2], yellow: bool) -> void:
	var opacity := sin(tick * PI / 256.0) * (176.0 / 255.0)
	ring.rotation = -PI * cos(tick * PI / 512.0)
	ring.scale = Vector2.ONE * maxf(1.0, tick / 128.0)
	ring.modulate.a = opacity
	var color_key := "y" if yellow else "b"
	for i in stars.size():
		var age := (tick - i * 16.0) / 8.0
		var star := stars[i]
		star.visible = age >= 0.0
		if not star.visible:
			continue
		star.texture = tex("effect/eff_star%d_%s" % [int(age) & 1, color_key])
		star.size = star.texture.get_size()
		star.position = origins[i] - star.size / 2 - Vector2(0, age * age / 16.0)
		star.modulate.a = opacity
	set_frame_shown.emit(yellow, tick)

func rune_circle(center: Vector2, tribute := false) -> void:
	if tribute:
		await tribute_glow(center)
	else:
		await set_card(center)

## Native 004870b0: gold ring grows before the white-card layer appears. At tick 248
## the old card may enter the Graveyard; the rotating afterimage continues to tick 384.
func tribute_glow(center: Vector2, card_angle := 0.0, completion: Dictionary = {}) -> void:
	active_tributes += 1
	completion["ready"] = false
	completion["done"] = false
	completion["white_started"] = false
	animation_stage.emit("tribute", "ring")
	var layer := Control.new()
	layer.name = "TributeGlow"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var secondary := _sprite("effect/card_pika_h", center)
	secondary.name = "WhiteAfterimage"
	secondary.reparent(layer)
	secondary.pivot_offset = secondary.size / 2
	var white := _sprite("effect/card_pika_h", center)
	white.name = "WhiteCard"
	white.reparent(layer)
	white.pivot_offset = white.size / 2
	var ring := _sprite("effect/eff_set_y", center)
	ring.name = "GoldRing"
	ring.reparent(layer)
	ring.pivot_offset = ring.size / 2
	var stars: Array[TextureRect] = []
	var origins: Array[Vector2] = []
	var visual_rng := RandomNumberGenerator.new()
	visual_rng.seed = hash(center)
	for i in 8:
		var origin := center + Vector2.from_angle(i * TAU / 8) * visual_rng.randi_range(16, 47)
		var star := _sprite("effect/eff_star0_y", origin)
		star.reparent(layer)
		stars.append(star)
		origins.append(origin)
	_update_tribute_frame(0.0, ring, white, secondary, stars, origins, card_angle, completion)
	var animation := create_tween()
	animation.tween_method(_update_tribute_frame.bind(ring, white, secondary, stars, origins, card_angle, completion), 0.0, 384.0, TRIBUTE_DURATION)
	await animation.finished
	remove_child(layer)
	layer.queue_free()
	completion["done"] = true
	active_tributes -= 1

func wait_for_tributes() -> void:
	while active_tributes > 0:
		await get_tree().process_frame

func _tribute_ring_angle(tick: float) -> float:
	var angle := 0.0
	var step := 8.0
	while step <= tick:
		angle += floorf(4.0 * sin(step * PI / 256.0)) if step < 128.0 else (4.0 if step == 128.0 else floorf(4.0 + 4.0 * sin((step - 128.0) * PI / 512.0)))
		step += 8.0
	var increment := floorf(4.0 * sin(step * PI / 256.0)) if step < 128.0 else (4.0 if step == 128.0 else floorf(4.0 + 4.0 * sin((step - 128.0) * PI / 512.0)))
	return -(angle + increment * (tick - step + 8.0) / 8.0) * TAU / 512.0

func _update_tribute_frame(tick: float, ring: TextureRect, white: TextureRect, secondary: TextureRect, stars: Array[TextureRect], origins: Array[Vector2], card_angle: float, completion: Dictionary) -> void:
	var age := tick - 128.0
	ring.scale = Vector2.ONE * (tick / 128.0 if tick < 128.0 else maxf(1.0, age / 128.0))
	ring.rotation = _tribute_ring_angle(tick)
	ring.modulate.a = maxf(0.0, (sin(tick * PI / 256.0) * 128.0 if tick <= 128.0 else cos(age * PI / 512.0) * 176.0) / 255.0)
	white.visible = tick > 128.0
	secondary.visible = tick >= 256.0
	white.modulate.a = maxf(0.0, sin(age * PI / 256.0))
	white.scale = Vector2.ONE * (1.0 if tick < 256.0 else (512.0 - tick) / 256.0)
	white.rotation = card_angle + (0.0 if tick < 256.0 else (tick - 256.0) * 3.0 * TAU / 512.0)
	secondary.scale = white.scale
	secondary.modulate.a = white.modulate.a / 2
	secondary.rotation = white.rotation - (tick - 256.0) * TAU / 1024.0
	if tick > 128.0 and not completion["white_started"]:
		completion["white_started"] = true
		animation_stage.emit("tribute", "white_card")
		AudioUtil.sfx("ikenie")
	for i in stars.size():
		var star_age := (age - i * 16.0) / 8.0
		var star := stars[i]
		star.visible = star_age >= 0
		if star.visible:
			star.texture = tex("effect/eff_star%d_y" % [int(star_age) & 1])
			star.size = star.texture.get_size()
			star.position = origins[i] - star.size / 2 - Vector2(0, star_age * star_age / 16.0)
			star.modulate.a = white.modulate.a
	if tick >= TRIBUTE_READY_TICK:
		completion["ready"] = true
	tribute_frame_shown.emit(tick)

func activation(center: Vector2, white := false) -> void:
	animation_stage.emit("activation", "flare")
	var layers: Array[TextureRect] = []
	for asset_name in ["kouka_sita_b", "kouka_ue_b"]:
		var r := _sprite("effect/" + asset_name, center, true)
		if white:
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; render_mode blend_add; void fragment(){ vec4 t = texture(TEXTURE, UV); COLOR = vec4(vec3(max(max(t.r,t.g),t.b)), t.a); }"
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			r.material = shader_material
		r.pivot_offset = r.size / 2
		r.scale = Vector2(0.08, 0.08)
		layers.append(r)
	var pulse := create_tween()
	pulse.tween_method(func(progress: float):
		for i in layers.size():
			layers[i].scale = Vector2.ONE * maxf(0.0,sin(progress*PI))
			layers[i].rotation = progress*PI*(0.5 if i == 0 else -1.0)
			layers[i].modulate.a = sin(progress*PI),0.0,1.0,ACTIVATION_DURATION)
	await pulse.finished
	for r in layers:
		remove_child(r)
		r.queue_free()
	animation_stage.emit("activation", "complete")

func shatter(view: TextureRect) -> void:
	animation_stage.emit("effect_destroy", "fragments")
	var center := view.position + view.size / 2
	var pieces := EffectFragments.new()
	pieces.artwork = view.texture
	pieces.card_size = view.size
	pieces.position = center
	pieces.rotation = view.rotation
	add_child(pieces)
	var scatter := create_tween().set_parallel(true)
	scatter.tween_method(func(progress: float):
		pieces.progress = progress
		pieces.queue_redraw(),0.0,1.0,SHATTER_DURATION)
	view.hide()
	# The white core belongs to destruction, never a second activation coroutine.
	var cores: Array[TextureRect] = []
	for i in 5:
		var core := _sprite("effect/shine",center,true)
		cores.append(core)
	scatter.tween_method(func(progress: float):
		# Native 00450fd0 draws five shines at radius tick/8, alpha 255-tick.
		for i in cores.size():
			cores[i].position = center-cores[i].size/2+Vector2.from_angle(i*TAU/5)*32*progress
			cores[i].modulate.a = 1.0-progress,0.0,1.0,SHATTER_DURATION)
	await scatter.finished
	for core in cores:
		remove_child(core)
		core.queue_free()
	remove_child(pieces)
	pieces.queue_free()
	animation_stage.emit("effect_destroy", "complete")

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


## Native shuffle: counter += 8 until 0x144, frame ((counter >> 3) % 5) + 1.
## 00453560 moves the window from Deck to (525,300), holds it for ticks 72..256, then returns it.
func shuffle_deck(deck_center: Vector2, lang := "e") -> void:
	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 110
	add_child(panel)
	var border := TextureRect.new()
	border.texture = tex("effect/deck_shuf_waku_" + lang)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.position = -border.texture.get_size() / 2
	panel.add_child(border)
	var cards := TextureRect.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cards)
	for step in 41:
		var tick := step * 8
		var frame := (tick >> 3) % 5 + 1
		cards.texture = tex("effect/deck_shuf%d" % frame)
		cards.position = Vector2(0, 26) - cards.texture.get_size() / 2
		var travel: float = clampf(tick / 64.0, 0.0, 1.0) if tick <= 256 else clampf((320 - tick) / 64.0, 0.0, 1.0)
		panel.position = deck_center.lerp(Vector2(525, 300), travel)
		panel.scale = Vector2.ONE * lerpf(0.5, 1.0, travel)
		if tick in [128, 192, 256]:
			AudioUtil.sfx("card_move")
		shuffle_frame_shown.emit(frame, tick)
		await _wait(1.0 / 60.0)
	remove_child(panel)
	panel.queue_free()
