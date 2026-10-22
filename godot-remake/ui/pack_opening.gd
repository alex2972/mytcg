class_name PackOpening
extends Control
## Pack opening sequence (shown by the Shop after a successful purchase):
##   1. the pack rises into a spotlight and hovers,   2. its top strip tears off with a flash,
##   3. the card backs shoot out of the pack,         4. they land in a row,
##   5. they flip one by one; rare cards get a golden build-up and burst, NEW! tags blink.
## Clicking or pressing a key while it plays fast-forwards; OK (or Escape) afterwards emits `closed`.
## Purely visual: the cards were already decided and saved by the backend.

signal finished          # every card is face up
signal closed

const ART := "res://assets/ui/shop/"
const CARD_BACK := "res://assets/ui/card_back.png"
const CARD_SIZE := Vector2(120, 174)
const ROW_GAP := 14.0
const ROW_TOP := 196.0
const PACK_HEIGHT := 300.0
const PACK_CENTER := Vector2(400, 340)
const HORIZON := 0.655                 # floor line of the backdrop (fraction of the height)
const SKIP_SPEED := 6.0
const NEW_CYCLE := 2.0                 # NEW! blinks: shown ~1.5 s, hidden ~0.5 s
const GOLD := Color(1.0, 0.78, 0.25)
# Sounds (assets/audio/sfx). Swap freely when dedicated pack sounds exist.
const SFX_RISE := "card_move"
const SFX_TEAR := "card_open"
const SFX_CARD_OUT := "card_move"
const SFX_FLIP := "card_open"
const SFX_RARE_CHARGE := "fusion1"
const SFX_RARE_BURST := "reborn"
const SFX_NEW := "life_up"

var done := false
var speed := 1.0
var cards: Array = []                  # [{"index", "name", "new", "rare"}]
var card_nodes: Array[Control] = []
var faces: Array[TextureRect] = []
var reflections: Array[TextureRect] = []
var new_tags: Array[Label] = []
var ok_button: TextureButton
var db: CardDB
var font: Font = preload("res://assets/ui/shop/shop_font.tres")
var _tweens: Array[Tween] = []
var _time := 0.0
var _backdrop: ColorRect
var _spot: Control
var _pack: Control
var _pack_top: TextureRect
var _pack_body: TextureRect
var _row: Control
var _rays: Array[Control] = []
var _back_texture: Texture2D

## `pack_art` should already be cropped to the pack (the Shop's AtlasTexture).
func play(pack_art: Texture2D, title: String, pulled: Array, card_db: CardDB) -> void:
	cards = pulled
	db = card_db
	name = "PackReveal"
	size = Vector2(800, 600)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_back_texture = load(CARD_BACK)
	_build_backdrop()
	_build_spotlight()
	_build_pack(pack_art)
	_row = Control.new()
	_row.name = "CardRow"
	_row.size = size
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	move_child(_row, _pack.get_index())       # cards come out from behind the pack
	var heading := _label(self, title, Rect2(0, 34, 800, 44), 34, Color.WHITE)
	heading.modulate.a = 0.0
	await _intro()
	await _tear()
	await _eject_cards()
	_tween().tween_property(heading, "modulate:a", 1.0, 0.4)
	await _deal_row()
	for i in cards.size():
		if cards[i].get("rare", false):
			await _flip_rare(i)
		else:
			await _flip(i)
	await _wait(0.25)
	_show_ok()
	done = true
	finished.emit()

## Fast-forward everything that is still playing (and everything that starts later).
func skip() -> void:
	speed = SKIP_SPEED
	for t in _tweens:
		if t.is_valid():
			t.set_speed_scale(speed)

func close() -> void:
	closed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not done:
		skip()
		accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if not done:
		skip()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		close()

func _process(delta: float) -> void:
	_time += delta
	for ray in _rays:
		if is_instance_valid(ray):
			ray.rotation += delta * 0.35
	# NEW! blinks: visible most of the cycle, a quick fade out/in, with a gentle pulse.
	var phase := fmod(_time, NEW_CYCLE)
	var alpha := 1.0
	if phase > 1.45:
		alpha = clampf(1.0 - (phase - 1.45) / 0.12, 0.0, 1.0) if phase < 1.75 else clampf((phase - 1.75) / 0.12, 0.0, 1.0)
	for tag in new_tags:
		if tag.has_meta("shown"):
			tag.modulate.a = alpha
			if not tag.has_meta("popping"):
				tag.scale = Vector2.ONE * (1.0 + 0.06 * sin(_time * 6.0))

# --- stages -------------------------------------------------------------------------

func _intro() -> void:
	AudioUtil.sfx(SFX_RISE)
	var t := _tween().set_parallel(true)
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.35)
	t.tween_property(_spot, "modulate:a", 1.0, 0.5).set_delay(0.15)
	t.tween_property(_pack, "position:y", _pack.position.y - 70.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_pack, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_pack, "modulate:a", 1.0, 0.3)
	await t.finished
	# A short hover before the tear.
	var hover := _tween()
	hover.tween_property(_pack, "position:y", _pack.position.y - 8.0, 0.35).set_trans(Tween.TRANS_SINE)
	hover.tween_property(_pack, "position:y", _pack.position.y, 0.35).set_trans(Tween.TRANS_SINE)
	await hover.finished

func _tear() -> void:
	AudioUtil.sfx(SFX_TEAR)
	var opening := _pack.position + Vector2(_pack.size.x / 2.0, _pack_top.size.y)
	var t := _tween().set_parallel(true)
	t.tween_property(_pack_top, "position", _pack_top.position + Vector2(150, -170), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_pack_top, "rotation", 0.9, 0.5)
	t.tween_property(_pack_top, "modulate:a", 0.0, 0.5).set_delay(0.15)
	_flash_line(opening, _pack.size.x * 1.3)
	_beam(opening, _pack.size.x)
	await _wait(0.3)

func _eject_cards() -> void:
	var opening := _pack.position + Vector2(_pack.size.x / 2.0, _pack_top.size.y + 6.0)
	for i in cards.size():
		var card := _make_card(i)
		card.position = opening - CARD_SIZE / 2.0 + Vector2(0, 40)
		card.scale = Vector2(0.55, 0.55)
		card.modulate.a = 0.0
		var spread := (i - (cards.size() - 1) / 2.0)
		var t := _tween().set_parallel(true)
		t.tween_property(card, "modulate:a", 1.0, 0.06)
		t.tween_property(card, "position", opening - CARD_SIZE / 2.0 + Vector2(spread * 50.0, -105.0 + absf(spread) * 12.0), 0.28).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "rotation", spread * 0.16, 0.28)
		t.tween_property(card, "scale", Vector2(0.7, 0.7), 0.28)
		AudioUtil.sfx(SFX_CARD_OUT)
		await _wait(0.085)
	await _wait(0.3)

func _deal_row() -> void:
	var gone := _tween().set_parallel(true)
	gone.tween_property(_pack, "position:y", _pack.position.y + 260.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	gone.tween_property(_pack, "modulate:a", 0.0, 0.4)
	gone.tween_property(_spot, "modulate:a", 0.35, 0.5)
	var left := (800.0 - cards.size() * CARD_SIZE.x - (cards.size() - 1) * ROW_GAP) / 2.0
	var last: Tween
	for i in card_nodes.size():
		var card := card_nodes[i]
		var t := _tween().set_parallel(true)
		t.tween_property(card, "position", Vector2(left + i * (CARD_SIZE.x + ROW_GAP), ROW_TOP), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "rotation", 0.0, 0.42)
		t.tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(reflections[i], "modulate:a", 0.22, 0.3).set_delay(0.3)
		last = t
		await _wait(0.05)
	await last.finished
	await _wait(0.3)

func _flip(i: int) -> void:
	AudioUtil.sfx(SFX_FLIP)
	await _turn(i, 0.11, 0.14)
	_card_flash(i, Color(1, 1, 1, 0.8))
	var pop := _tween()
	pop.tween_property(card_nodes[i], "scale", Vector2(1.07, 1.07), 0.08)
	pop.tween_property(card_nodes[i], "scale", Vector2.ONE, 0.12)
	_show_new(i)
	await _wait(0.32)

## Golden rare: glow builds behind the card while it shakes, then a burst when it turns.
func _flip_rare(i: int) -> void:
	var card := card_nodes[i]
	var center := card.position + CARD_SIZE / 2.0
	AudioUtil.sfx(SFX_RARE_CHARGE)
	var glow := _glow(center, 360.0)
	glow.modulate.a = 0.0
	var charge := _tween().set_parallel(true)
	charge.tween_property(glow, "modulate:a", 0.9, 0.9)
	charge.tween_property(glow, "scale", Vector2.ONE * 1.15, 0.9)
	var dim := _tween()
	dim.tween_property(_row, "modulate", Color(0.75, 0.75, 0.8), 0.6)
	for other in card_nodes:
		if other != card:
			_tween().tween_property(other, "modulate", Color(0.6, 0.6, 0.65), 0.6)
	await _shake(card, 0.9, 1.0, 6.0)
	AudioUtil.sfx(SFX_RARE_BURST)
	await _turn(i, 0.08, 0.1)
	# Burst
	for other in card_nodes:
		_tween().tween_property(other, "modulate", Color.WHITE, 0.4)
	_tween().tween_property(_row, "modulate", Color.WHITE, 0.4)
	_screen_flash(Color(1.0, 0.85, 0.45, 0.85))
	_rays_behind(center)
	_sparkle_burst(center)
	_sparkle_aura(center)
	_gold_frame(i)
	var pop := _tween()
	pop.tween_property(card, "scale", Vector2(1.28, 1.28), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(card, "scale", Vector2(1.1, 1.1), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var settle := _tween()
	settle.tween_property(glow, "modulate:a", 0.55, 0.6)
	_shake_screen(0.3, 6.0)
	_show_new(i)
	await _wait(0.9)

# --- pieces ---------------------------------------------------------------------------

func _build_backdrop() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.size = size
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float horizon = 0.655;
void fragment() {
	vec2 uv = UV;
	vec3 col = mix(vec3(0.03, 0.03, 0.09), vec3(0.13, 0.08, 0.27), smoothstep(0.0, horizon, uv.y));
	vec2 g = fract(uv * vec2(48.0, 36.0));
	float grid = max(step(0.95, g.x), step(0.95, g.y));
	col += vec3(0.05, 0.06, 0.14) * grid * (1.0 - uv.y);
	float line = exp(-pow((uv.y - horizon) * 90.0, 2.0)) * (1.0 - pow(abs(uv.x - 0.5) * 1.7, 2.0));
	col += vec3(0.7, 0.75, 1.0) * max(line, 0.0);
	if (uv.y > horizon) { col *= 0.35 + 0.4 * exp(-(uv.y - horizon) * 9.0); }
	COLOR = vec4(col, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("horizon", HORIZON)
	_backdrop.material = material
	_backdrop.modulate.a = 0.0
	add_child(_backdrop)

func _build_spotlight() -> void:
	_spot = _Beam.new()
	_spot.name = "Spotlight"
	_spot.size = size
	(_spot as _Beam).top = Rect2(330, -10, 140, 0)
	(_spot as _Beam).bottom = Rect2(170, 420, 460, 0)
	(_spot as _Beam).color = Color(0.75, 0.8, 1.0, 0.22)
	_spot.modulate.a = 0.0
	add_child(_spot)

func _build_pack(art: Texture2D) -> void:
	var region := Rect2(Vector2.ZERO, art.get_size())
	var atlas: Texture2D = art
	if art is AtlasTexture:
		atlas = (art as AtlasTexture).atlas
		region = (art as AtlasTexture).region
	var display := Vector2(PACK_HEIGHT * region.size.x / region.size.y, PACK_HEIGHT)
	var top_fraction := 0.12
	_pack = Control.new()
	_pack.name = "Pack"
	_pack.size = display
	_pack.pivot_offset = display / 2.0
	_pack.position = PACK_CENTER - display / 2.0 + Vector2(0, 70)
	_pack.scale = Vector2(0.6, 0.6)
	_pack.modulate.a = 0.0
	_pack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pack)
	var body_tex := AtlasTexture.new()
	body_tex.atlas = atlas
	body_tex.region = Rect2(region.position + Vector2(0, region.size.y * top_fraction), Vector2(region.size.x, region.size.y * (1.0 - top_fraction)))
	_pack_body = _rect(_pack, body_tex, Rect2(0, display.y * top_fraction, display.x, display.y * (1.0 - top_fraction)))
	var top_tex := AtlasTexture.new()
	top_tex.atlas = atlas
	top_tex.region = Rect2(region.position, Vector2(region.size.x, region.size.y * top_fraction))
	_pack_top = _rect(_pack, top_tex, Rect2(0, 0, display.x, display.y * top_fraction))
	_pack_top.pivot_offset = _pack_top.size / 2.0

func _make_card(i: int) -> Control:
	var card := Control.new()
	card.name = "RevealCard%d" % i
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(card)
	var reflection := _rect(card, _back_texture, Rect2(0, CARD_SIZE.y + 4, CARD_SIZE.x, CARD_SIZE.y))
	reflection.flip_v = true
	reflection.modulate.a = 0.0
	reflection.name = "Reflection"
	var face := _rect(card, _back_texture, Rect2(Vector2.ZERO, CARD_SIZE))
	face.name = "Face"
	card_nodes.append(card)
	faces.append(face)
	reflections.append(reflection)
	return card

## Turns card i over: shrink to an edge, swap to its face, grow back.
func _turn(i: int, close_time: float, open_time: float) -> void:
	var card := card_nodes[i]
	var t := _tween()
	t.tween_property(card, "scale:x", 0.0, close_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	var path := db.art_path(int(cards[i]["index"])) if db != null else ""
	var face: Texture2D = load(path) if path != "" and ResourceLoader.exists(path) else _back_texture
	faces[i].texture = face
	reflections[i].texture = face
	var t2 := _tween()
	t2.tween_property(card, "scale:x", card.scale.y, open_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t2.finished

func _show_new(i: int) -> void:
	if not cards[i].get("new", false):
		return
	AudioUtil.sfx(SFX_NEW)
	var card := card_nodes[i]
	var tag := _label(_row, "NEW!", Rect2(card.position + Vector2(CARD_SIZE.x - 60, -18), Vector2(64, 28)), 24, Color("ffd51a"))
	tag.name = "NewTag%d" % i
	tag.add_theme_color_override("font_outline_color", Color("6a1500"))
	tag.add_theme_constant_override("outline_size", 6)
	tag.pivot_offset = tag.size / 2.0
	tag.rotation = 0.18
	tag.scale = Vector2.ZERO
	tag.set_meta("shown", true)
	tag.set_meta("popping", true)
	new_tags.append(tag)
	var t := _tween()
	t.tween_property(tag, "scale", Vector2.ONE * 1.35, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(tag, "scale", Vector2.ONE, 0.12)
	t.tween_callback(func(): tag.remove_meta("popping"))

func _show_ok() -> void:
	ok_button = TextureButton.new()
	ok_button.name = "RevealOk"
	ok_button.position = Vector2(336, 480)
	ok_button.size = Vector2(129, 59)
	ok_button.ignore_texture_size = true
	ok_button.stretch_mode = TextureButton.STRETCH_SCALE
	ok_button.texture_normal = load(ART + "back_normal.png")
	ok_button.texture_hover = load(ART + "back_hover.png")
	ok_button.texture_pressed = load(ART + "back_pressed.png")
	ok_button.pressed.connect(close)
	ok_button.mouse_entered.connect(func(): AudioUtil.sfx("cursor"))
	add_child(ok_button)
	_label(ok_button, "OK", Rect2(Vector2.ZERO, ok_button.size), 32, Color("790d08"))
	ok_button.modulate.a = 0.0
	var t := _tween().set_parallel(true)
	t.tween_property(ok_button, "modulate:a", 1.0, 0.25)
	t.tween_property(ok_button, "position:y", 470.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- effects --------------------------------------------------------------------------

func _flash_line(center: Vector2, width: float) -> void:
	# Soft white flare along the tear (a radial glow stretched wide and flat).
	var line := _glow(center, width)
	line.reparent(self, false)
	line.modulate = Color(1, 1, 1, 1)
	line.self_modulate = Color(1.4, 1.4, 1.4)
	line.size = Vector2(width * 1.6, 60)
	line.position = center - line.size / 2.0
	line.pivot_offset = line.size / 2.0
	line.scale = Vector2(0.2, 0.6)
	var t := _tween().set_parallel(true)
	t.tween_property(line, "scale", Vector2(1.3, 1.6), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(line, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(line.queue_free)

func _beam(origin: Vector2, width: float) -> void:
	var beam := _Beam.new()
	beam.size = size
	beam.top = Rect2(origin.x - width * 1.1, -20, width * 2.2, 0)
	beam.bottom = Rect2(origin.x - width * 0.45, origin.y, width * 0.9, 0)
	beam.color = Color(1, 1, 0.95, 0.55)
	beam.modulate.a = 0.0
	add_child(beam)
	move_child(beam, _pack.get_index())
	var t := _tween()
	t.tween_property(beam, "modulate:a", 1.0, 0.12)
	t.tween_property(beam, "modulate:a", 0.0, 0.9)
	t.tween_callback(beam.queue_free)

func _card_flash(i: int, color: Color) -> void:
	var card := card_nodes[i]
	var flash := _glow_rect(Rect2(Vector2.ZERO, CARD_SIZE), color)
	flash.reparent(card, false)
	var t := _tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.25)
	t.tween_callback(flash.queue_free)

func _screen_flash(color: Color) -> void:
	var flash := _glow_rect(Rect2(Vector2.ZERO, size), color)
	var t := _tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(flash.queue_free)

func _glow(center: Vector2, diameter: float) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.55, 1.0))
	gradient.set_color(1, Color(1.0, 0.6, 0.1, 0.0))
	gradient.add_point(0.35, Color(1.0, 0.75, 0.25, 0.6))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var glow := TextureRect.new()
	glow.texture = tex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.size = Vector2(diameter, diameter)
	glow.position = center - glow.size / 2.0
	glow.pivot_offset = glow.size / 2.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.material = _additive()
	_row.add_child(glow)
	_row.move_child(glow, 0)
	return glow

func _rays_behind(center: Vector2) -> void:
	for layer in 2:
		var rays := _Rays.new()
		rays.count = 14 if layer == 0 else 9
		rays.radius = 330.0 if layer == 0 else 250.0
		rays.color = Color(1.0, 0.82, 0.35, 0.5 if layer == 0 else 0.35)
		rays.size = Vector2(rays.radius * 2.0, rays.radius * 2.0)
		rays.position = center - rays.size / 2.0
		rays.pivot_offset = rays.size / 2.0
		rays.rotation = layer * 0.4
		rays.scale = Vector2.ZERO
		rays.material = _additive()
		_row.add_child(rays)
		_row.move_child(rays, 1)
		_rays.append(rays)
		var t := _tween()
		t.tween_property(rays, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# The second layer turns the other way for a shimmering cross pattern.
	_rays[_rays.size() - 1].set_meta("reverse", true)

func _sparkle_burst(center: Vector2) -> void:
	var p := _particles(center, 90, 1.1, true)
	p.spread = 180.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 420.0
	p.damping_min = 120.0
	p.damping_max = 220.0
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.7

func _sparkle_aura(center: Vector2) -> void:
	var p := _particles(center, 26, 1.6, false)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = CARD_SIZE * 0.6
	p.spread = 180.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(0, -40)
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.4

func _particles(center: Vector2, amount: int, lifetime: float, one_shot: bool) -> CPUParticles2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var dot := GradientTexture2D.new()
	dot.gradient = gradient
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 32
	dot.height = 32
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 0.85, 1.0))
	ramp.set_color(1, Color(1.0, 0.6, 0.1, 0.0))
	ramp.add_point(0.4, GOLD)
	var p := CPUParticles2D.new()
	p.position = center
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.texture = dot
	p.color_ramp = ramp
	p.material = _additive()
	p.speed_scale = speed
	_row.add_child(p)
	p.emitting = true
	return p

func _gold_frame(i: int) -> void:
	var card := card_nodes[i]
	var frame := _Frame.new()
	frame.size = CARD_SIZE + Vector2(12, 12)
	frame.position = Vector2(-6, -6)
	frame.color = GOLD
	frame.material = _additive()
	card.add_child(frame)
	var t := _tween().set_loops()
	t.tween_property(frame, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(frame, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _shake(node: Control, duration: float, start: float, end: float) -> void:
	var origin := node.position
	var steps := maxi(1, int(duration / 0.03))
	var t := _tween()
	for s in steps:
		var amount := lerpf(start, end, float(s) / steps)
		t.tween_property(node, "position", origin + Vector2(randf_range(-amount, amount), randf_range(-amount * 0.5, amount * 0.5)), 0.03)
	t.tween_property(node, "position", origin, 0.03)
	await t.finished

func _shake_screen(duration: float, amount: float) -> void:
	var t := _tween()
	var steps := int(duration / 0.03)
	for s in steps:
		var a := amount * (1.0 - float(s) / steps)
		t.tween_property(_row, "position", Vector2(randf_range(-a, a), randf_range(-a, a)), 0.03)
	t.tween_property(_row, "position", Vector2.ZERO, 0.03)

# --- helpers --------------------------------------------------------------------------

func _tween() -> Tween:
	var t := create_tween()
	t.set_speed_scale(speed)
	_tweens = _tweens.filter(func(old): return old.is_valid())
	_tweens.append(t)
	return t

func _wait(seconds: float) -> void:
	var t := _tween()
	t.tween_interval(seconds)
	await t.finished

func _rect(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _glow_rect(rect: Rect2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = _additive()
	add_child(r)
	return r

func _label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("111923"))
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	return label

static func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

## A soft light cone between two horizontal spans (top and bottom).
class _Beam extends Control:
	var top := Rect2()
	var bottom := Rect2()
	var color := Color.WHITE
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		material = PackOpening._additive()
	func _draw() -> void:
		var clear := Color(color, 0.0)
		var points := PackedVector2Array([top.position, top.position + Vector2(top.size.x, 0), bottom.position + Vector2(bottom.size.x, 0), bottom.position])
		draw_polygon(points, PackedColorArray([clear, clear, color, color]))
		# Brighter core down the middle.
		var mid_top := top.position.x + top.size.x / 2.0
		var mid_bottom := bottom.position.x + bottom.size.x / 2.0
		var core := PackedVector2Array([Vector2(mid_top - top.size.x * 0.2, top.position.y), Vector2(mid_top + top.size.x * 0.2, top.position.y), Vector2(mid_bottom + bottom.size.x * 0.25, bottom.position.y), Vector2(mid_bottom - bottom.size.x * 0.25, bottom.position.y)])
		draw_polygon(core, PackedColorArray([clear, clear, Color(color, color.a * 0.8), Color(color, color.a * 0.8)]))

## Golden god-rays around a center.
class _Rays extends Control:
	var count := 12
	var radius := 300.0
	var color := Color.WHITE
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		if has_meta("reverse"):
			rotation -= delta * 0.7
	func _draw() -> void:
		var c := size / 2.0
		var clear := Color(color, 0.0)
		for i in count:
			var a := TAU * i / count
			var w := TAU / count * 0.28
			var p1 := c + Vector2.from_angle(a - w) * radius
			var p2 := c + Vector2.from_angle(a + w) * radius
			draw_polygon(PackedVector2Array([c, p1, p2]), PackedColorArray([color, clear, clear]))

## Glowing rectangular outline.
class _Frame extends Control:
	var color := Color.WHITE
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for w in [10.0, 6.0, 3.0]:
			var a: float = 0.25 if w > 8.0 else (0.45 if w > 4.0 else 1.0)
			draw_rect(Rect2(Vector2(w / 2.0, w / 2.0), size - Vector2(w, w)), Color(color, a), false, w)
