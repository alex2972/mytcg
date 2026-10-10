class_name JankenScreen
extends Control
## Rock-paper-scissors to decide who goes first, then the "First / Second to Go" crates.
## Assets and coordinates come from the original's janken.txt; crate frames: 1 idle, 2 lit (hover), 3 chosen.

signal finished(human_first: bool)

enum Phase { SELECT, RESULT, ORDER, DONE }

const HANDS := ["pa", "gu", "cyo"]          # left-to-right crates (paper, rock, scissors), as on the original screen
const BEATS := {"gu": "cyo", "cyo": "pa", "pa": "gu"}
const CRATE := Vector2(206, 200)
const CRATE_X := [91.0, 297.0, 503.0]
const TOP_Y := 48.0
const BOT_Y := 350.0

var phase := Phase.SELECT
var rng := RandomNumberGenerator.new()
var lang := "e"
var my_pick := ""
var cpu_pick := ""
var human_won := false
var bottom: Array = []         # TextureRects of my crates
var top: Array = []            # TextureRects of the opponent's crates
var order_crates: Array = []   # [first, second]
var banner := TextureRect.new()
var layer := Control.new()
var tex_cache := {}

func _init(seed_value := 0) -> void:
	rng.seed = seed_value if seed_value != 0 else randi()
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)

func _t(tex_name: String) -> Texture2D:
	if not tex_cache.has(tex_name):
		tex_cache[tex_name] = load("res://assets/j/janken/%s.png" % tex_name)
	return tex_cache[tex_name]

func _tex_rect(name: String, pos: Vector2, parent: Node = self) -> TextureRect:
	var r := TextureRect.new()
	r.texture = _t(name)
	r.position = pos
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _ready() -> void:
	var base := ColorRect.new()
	base.color = Color(0.36, 0.14, 0.17)
	base.size = size
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	add_child(layer)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_select()

func _clear() -> void:
	for c in layer.get_children():
		c.queue_free()
	bottom.clear()
	top.clear()
	order_crates.clear()

func _frame() -> void:
	# steel frame pieces at the positions given in janken.txt
	_tex_rect("bg_top", Vector2(106, 0), layer)
	_tex_rect("bg_bot", Vector2(219, 550), layer)
	_tex_rect("bg_mid_l", Vector2(106, 269), layer)
	_tex_rect("bg_mid_r", Vector2(620, 269), layer)

func _foreground() -> void:
	_tex_rect("bg_l1", Vector2(0, 0), layer)
	_tex_rect("bg_r1", Vector2(710, 0), layer)
	_tex_rect("bg_l2", Vector2(107, 444), layer)
	_tex_rect("bg_r2", Vector2(579, 0), layer)

# --- phase 1: pick a hand --------------------------------------------------------

func _show_select() -> void:
	phase = Phase.SELECT
	_clear()
	_frame()
	for i in 3:
		top.append(_tex_rect("jya_eye_1", Vector2(CRATE_X[i], TOP_Y), layer))
	banner = _tex_rect("bg_mid_m2_%s" % lang, Vector2(200, 250), layer)
	for i in 3:
		var r := _tex_rect("jya_%s_1" % HANDS[i], Vector2(CRATE_X[i], BOT_Y), layer)
		r.mouse_filter = Control.MOUSE_FILTER_STOP
		r.gui_input.connect(_on_hand_input.bind(i))
		r.mouse_entered.connect(_on_hand_hover.bind(i, true))
		r.mouse_exited.connect(_on_hand_hover.bind(i, false))
		bottom.append(r)
	_foreground()

func _on_hand_hover(i: int, entered: bool) -> void:
	if phase != Phase.SELECT:
		return
	(bottom[i] as TextureRect).texture = _t("jya_%s_%d" % [HANDS[i], 2 if entered else 1])
	if entered:
		AudioUtil.sfx("cursor")
	CursorUtil.set_state("on" if entered else "off")

func _on_hand_input(event: InputEvent, i: int) -> void:
	if phase == Phase.SELECT and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choose(HANDS[i])

func _choose(hand: String) -> void:
	phase = Phase.RESULT
	AudioUtil.sfx("decide")
	CursorUtil.set_state("off")
	my_pick = hand
	cpu_pick = HANDS[rng.randi_range(0, 2)]
	for i in 3:
		(bottom[i] as TextureRect).texture = _t("jya_%s_%d" % [HANDS[i], 3 if HANDS[i] == hand else 1])
	await get_tree().create_timer(0.5).timeout
	_show_result()

# --- phase 2: show both hands ------------------------------------------------------

func _show_result() -> void:
	_clear()
	_frame()
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.position = Vector2(195, 45)
	black.size = Vector2(410, 500)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var additive := CanvasItemMaterial.new()    # the hand photos have opaque black backgrounds
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var mine := _tex_rect("jya_%s_5" % my_pick, Vector2.ZERO, layer)
	mine.material = additive
	mine.position = Vector2(400 - mine.texture.get_width() / 2.0, 545 - mine.texture.get_height())
	var theirs := _tex_rect("jya_%s_5" % cpu_pick, Vector2.ZERO, layer)
	theirs.material = additive
	theirs.pivot_offset = theirs.texture.get_size() / 2
	theirs.rotation_degrees = 180
	theirs.position = Vector2(400 - theirs.texture.get_width() / 2.0, 45)
	human_won = BEATS[my_pick] == cpu_pick
	if human_won:
		var win := _tex_rect("jya_win_%s" % lang, Vector2.ZERO, layer)
		win.position = Vector2(400 - win.texture.get_width() / 2.0, 330)
	_foreground()
	await get_tree().create_timer(1.4).timeout
	if my_pick == cpu_pick:
		_show_select()          # draw: throw again
	else:
		_show_order()

# --- phase 3: first / second to go ---------------------------------------------------

func _show_order() -> void:
	phase = Phase.ORDER
	_clear()
	_frame()
	banner = _tex_rect("bg_mid_m1", Vector2(200, 250), layer)
	for y in [TOP_Y, TOP_Y + 100.0, BOT_Y, BOT_Y + 100.0]:
		_tex_rect("bg_plus1", Vector2(200, y), layer)
		_tex_rect("bg_plus2", Vector2(550, y), layer)
	var kinds := ["first", "second"]
	for i in 2:
		var r := _tex_rect("start_%s_%s1" % [kinds[i], lang], Vector2(250, TOP_Y if i == 0 else BOT_Y), layer)
		if human_won:
			r.mouse_filter = Control.MOUSE_FILTER_STOP
			r.gui_input.connect(_on_order_input.bind(i))
			r.mouse_entered.connect(_on_order_hover.bind(i, true))
			r.mouse_exited.connect(_on_order_hover.bind(i, false))
		order_crates.append(r)
	_foreground()
	if not human_won:
		# the opponent decides (original shows its choice lit up)
		var first := rng.randi_range(0, 1)       # 0 = the opponent chose FIRST, so the human goes second
		await get_tree().create_timer(0.8).timeout
		(order_crates[first] as TextureRect).texture = _t("start_%s_%s2" % [kinds[first], lang])
		await get_tree().create_timer(1.0).timeout
		_done(first == 1)

func _on_order_hover(i: int, entered: bool) -> void:
	if phase != Phase.ORDER:
		return
	var kinds := ["first", "second"]
	(order_crates[i] as TextureRect).texture = _t("start_%s_%s%d" % [kinds[i], lang, 2 if entered else 1])
	if entered:
		AudioUtil.sfx("cursor")
	CursorUtil.set_state("on" if entered else "off")

func _on_order_input(event: InputEvent, i: int) -> void:
	if phase == Phase.ORDER and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_done(i == 0)

func _done(human_first: bool) -> void:
	phase = Phase.DONE
	AudioUtil.sfx("decide")
	CursorUtil.set_state("off")
	finished.emit(human_first)
