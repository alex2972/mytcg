class_name JankenScreen
extends Control
## Rock-paper-scissors to decide who goes first, then the "First / Second to Go" crates.
## Assets and coordinates come from the original's janken.txt; crate frames: 1 idle, 2 lit (hover), 3 chosen.

signal finished(human_first: bool)
signal picked(hand: int)                ## online: my pick for the server (0 rock, 1 paper, 2 scissors)
signal order_picked(first: bool)        ## online: my first/second choice for the server

enum Phase { SELECT, RESULT, ORDER, DONE }

const HANDS := ["gu", "cyo", "pa"]          # repeating conveyor order: rock, scissors, paper
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
const ROW_SPEED := 60.0
var top_offset := 0.0
var bottom_offset := 0.0
var hovered := -1
var order_busy := false
var row_top: Control
var row_bottom: Control
var belt_time := 0.0
var belts: Array[TextureRect] = []
## Online: the server decides. My pick is sent with `picked`, the reveal waits for remote_result(),
## and when the opponent chooses the order the screen waits for remote_order().
var remote := false
var _remote_picks: Array = []
var _remote_order := -1
const SERVER_HAND := {"gu": 0, "pa": 1, "cyo": 2}
const HAND_OF_SERVER := ["gu", "pa", "cyo"]

func remote_result(mine: int, theirs: int) -> void:
	_remote_picks = [mine, theirs]

func remote_order(human_first: bool) -> void:
	_remote_order = 1 if human_first else 0

func _process(delta: float) -> void:
	if phase != Phase.SELECT:
		return
	top_offset = fposmod(top_offset + ROW_SPEED * delta, CRATE.x * 3)
	if hovered < 0:
		bottom_offset = fposmod(bottom_offset - ROW_SPEED * delta, CRATE.x * 3)
	_layout_rows()
	belt_time += delta
	for belt in belts:
		belt.texture = _t("belt%d" % (1 + int(belt_time * 30) % 6))

func _layout_rows() -> void:
	for i in top.size():
		top[i].position.x = fposmod(i * CRATE.x + top_offset, CRATE.x * 6) - CRATE.x * 3
	for i in bottom.size():
		bottom[i].position.x = fposmod(i * CRATE.x + bottom_offset, CRATE.x * 6) - CRATE.x * 3

func _row_hover(point: Vector2, entered := true) -> void:
	if phase != Phase.SELECT:
		return
	var pick := -1
	if entered:
		for i in bottom.size():
			if Rect2(bottom[i].position, CRATE).has_point(point):
				pick = i
				break
	if pick == hovered:
		return
	hovered = pick
	for i in bottom.size():
		bottom[i].texture = _t("jya_%s_%d" % [HANDS[i % 3], 2 if i == hovered else 1])
	CursorUtil.set_state("on" if hovered >= 0 else "off")

func _row_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_row_hover(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_row_hover(event.position)
		if hovered >= 0:
			_choose(HANDS[hovered % 3])


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
		layer.remove_child(c)
		c.queue_free()
	belts.clear()
	bottom.clear()
	top.clear()
	order_crates.clear()

func _frame() -> void:
	# steel frame pieces at the positions given in janken.txt
	_tex_rect("bg_top", Vector2(106, 0), layer)
	_tex_rect("bg_bot", Vector2(219, 550), layer)
	_tex_rect("bg_mid_l", Vector2(106, 269), layer)
	_tex_rect("bg_mid_r", Vector2(620, 269), layer)

func _mechanism() -> void:
	for y in [0.0, 250.0, 300.0, 550.0]:
		for x in range(100, 701, 200):
			belts.append(_tex_rect("belt1", Vector2(x, y), layer))

func _order_walls() -> void:
	for y in [TOP_Y, BOT_Y]:
		_tex_rect("bg_kabe_l", Vector2(-9, y), layer)
		_tex_rect("bg_kabe_r", Vector2(600, y), layer)
		for x in [250.0, 600.0]:
			var belt := _tex_rect("belt1", Vector2(x, y), layer)
			belt.rotation_degrees = 90
			belts.append(belt)

func _foreground() -> void:
	_tex_rect("bg_l1", Vector2(0, 0), layer)
	_tex_rect("bg_r1", Vector2(710, 0), layer)
	_tex_rect("bg_l2", Vector2(107, 444), layer)
	_tex_rect("bg_r2", Vector2(579, 0), layer)

# --- phase 1: pick a hand --------------------------------------------------------

func _show_select() -> void:
	phase = Phase.SELECT
	_clear()
	hovered = -1
	top_offset = 0.0
	bottom_offset = 0.0
	_mechanism()
	_frame()
	row_top = Control.new()
	row_top.position = Vector2(91, TOP_Y)
	row_top.size = Vector2(618, 200)
	row_top.clip_contents = true
	row_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(row_top)
	row_bottom = Control.new()
	row_bottom.position = Vector2(91, BOT_Y)
	row_bottom.size = Vector2(618, 200)
	row_bottom.clip_contents = true
	row_bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(row_bottom)
	row_bottom.gui_input.connect(_row_input)
	row_bottom.mouse_entered.connect(func(): _row_hover(row_bottom.get_local_mouse_position()))
	row_bottom.mouse_exited.connect(func(): _row_hover(Vector2.ZERO, false))
	for i in 6:
		top.append(_tex_rect("jya_eye_1", Vector2.ZERO, row_top))
		bottom.append(_tex_rect("jya_%s_1" % HANDS[i % 3], Vector2.ZERO, row_bottom))
	_layout_rows()
	banner = _tex_rect("bg_mid_m2_%s" % lang, Vector2(200, 250), layer)
	_foreground()

func _on_hand_hover(i: int, entered: bool) -> void:
	_row_hover(bottom[i].position + CRATE / 2, entered)

func _on_hand_input(event: InputEvent, i: int) -> void:
	if phase == Phase.SELECT and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hovered = i
		_choose(HANDS[i % 3])

func _choose(hand: String) -> void:
	if phase != Phase.SELECT:
		return
	phase = Phase.RESULT
	AudioUtil.sfx("decide")
	CursorUtil.set_state("off")
	my_pick = hand
	if remote:
		picked.emit(int(SERVER_HAND[hand]))
		while _remote_picks.is_empty():
			await get_tree().process_frame
		cpu_pick = HAND_OF_SERVER[clampi(int(_remote_picks[1]), 0, 2)]
		_remote_picks = []
	else:
		cpu_pick = HANDS[rng.randi_range(0, 2)]
	banner.texture = _t("bg_mid_m1")
	var chosen := hovered
	if chosen < 0:
		for i in bottom.size():
			if HANDS[i % 3] == hand and bottom[i].position.x >= 0 and bottom[i].position.x < 618:
				chosen = i
				break
	var eye := 0
	for i in top.size():
		if absf(top[i].position.x - 206) < absf(top[eye].position.x - 206):
			eye = i
	bottom[chosen].texture = _t("jya_%s_3" % hand)
	top[eye].texture = _t("jya_eye_3")
	var settle := create_tween().set_parallel(true)
	var bottom_shift: float = 206.0 - bottom[chosen].position.x
	var top_shift: float = 206.0 - top[eye].position.x
	for tile in bottom:
		settle.tween_property(tile, "position:x", tile.position.x + bottom_shift, 0.35)
	for tile in top:
		settle.tween_property(tile, "position:x", tile.position.x + top_shift, 0.35)
	await settle.finished
	await get_tree().create_timer(0.35).timeout
	await _show_result()

func _show_result() -> void:
	# Side crates remain visible while the middle of the mechanism opens.
	var opening := ColorRect.new()
	opening.color = Color.BLACK
	opening.position = Vector2(195, TOP_Y)
	opening.size = Vector2(410, 502)
	opening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(opening)
	var open := create_tween().set_parallel(true)
	for tile in top + bottom:
		if tile.position.x < 200:
			open.tween_property(tile, "position:x", tile.position.x - 100, 0.2)
		elif tile.position.x > 212:
			open.tween_property(tile, "position:x", tile.position.x + 100, 0.2)
	await open.finished
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var mine := _tex_rect("jya_%s_4" % my_pick, Vector2.ZERO, layer)
	mine.material = additive
	mine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mine.size = mine.texture.get_size() * 0.85
	mine.position = Vector2(400 - mine.size.x / 2.0, 600)
	var theirs := _tex_rect("jya_%s_4" % cpu_pick, Vector2.ZERO, layer)
	theirs.material = additive
	theirs.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	theirs.size = theirs.texture.get_size() * 0.85
	theirs.pivot_offset = theirs.size / 2
	theirs.rotation_degrees = 180
	theirs.position = Vector2(400 - theirs.size.x / 2.0, -theirs.size.y)
	_foreground()
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(mine, "position:y", 550 - mine.size.y, 0.35)
	reveal.tween_property(theirs, "position:y", TOP_Y, 0.35)
	await reveal.finished
	await get_tree().create_timer(0.25).timeout
	human_won = BEATS[my_pick] == cpu_pick
	if my_pick != cpu_pick:
		var winner := mine if human_won else theirs
		var loser := theirs if human_won else mine
		winner.texture = _t("jya_%s_5" % (my_pick if human_won else cpu_pick))
		winner.size = winner.texture.get_size() * 0.85
		winner.pivot_offset = winner.size / 2
		winner.position.x = 400 - winner.size.x / 2
		winner.position.y = 550 - winner.size.y if human_won else TOP_Y
		loser.modulate = Color(0.45, 0.45, 0.45)
		var win := _tex_rect("jya_win_%s" % lang, Vector2.ZERO, layer)
		win.position = Vector2(400 - win.texture.get_width() / 2.0, 400 if human_won else 110)
	else:
		mine.modulate = Color(0.45, 0.45, 0.45)
		theirs.modulate = mine.modulate
	await get_tree().create_timer(0.9 if my_pick != cpu_pick else 0.4).timeout
	var withdraw := create_tween().set_parallel(true)
	withdraw.tween_property(mine, "position:y", 600.0, 0.2)
	withdraw.tween_property(theirs, "position:y", -theirs.size.y, 0.2)
	await withdraw.finished
	if my_pick == cpu_pick:
		_show_select()
	else:
		_show_order()

# --- phase 3: first / second to go ---------------------------------------------------

func _show_order() -> void:
	phase = Phase.ORDER
	order_busy = false
	_clear()
	_mechanism()
	_frame()
	_order_walls()
	banner = _tex_rect("bg_mid_m1", Vector2(200, 250), layer)
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
		if remote:
			while _remote_order < 0:
				await get_tree().process_frame
			first = 1 if _remote_order == 1 else 0
		await get_tree().create_timer(0.8).timeout
		(order_crates[first] as TextureRect).texture = _t("start_%s_%s2" % [kinds[first], lang])
		await _choose_order(first, first == 1)

func _on_order_hover(i: int, entered: bool) -> void:
	if phase != Phase.ORDER or order_busy:
		return
	var kinds := ["first", "second"]
	(order_crates[i] as TextureRect).texture = _t("start_%s_%s%d" % [kinds[i], lang, 2 if entered else 1])
	if entered:
		AudioUtil.sfx("cursor")
	CursorUtil.set_state("on" if entered else "off")

func _on_order_input(event: InputEvent, i: int) -> void:
	if phase == Phase.ORDER and not order_busy and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choose_order(i, i == 0)

func _choose_order(i: int, human_first: bool) -> void:
	order_busy = true
	if remote and human_won:
		order_picked.emit(human_first)
	CursorUtil.set_state("off")
	AudioUtil.sfx("decide")
	var other: TextureRect = order_crates[1 - i]
	var chosen: TextureRect = order_crates[i]
	chosen.texture = _t("start_%s_%s2" % ["first" if i == 0 else "second", lang])
	var void_panel := ColorRect.new()
	void_panel.color = Color.BLACK
	void_panel.position = Vector2(250, TOP_Y)
	void_panel.size = Vector2(300, 502)
	void_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(void_panel)
	layer.move_child(void_panel, mini(chosen.get_index(), other.get_index()))
	var dim := create_tween()
	dim.tween_property(other, "modulate", Color.BLACK, 0.3)
	await dim.finished
	other.hide()
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(chosen, "position:y", 200.0, 0.45)
	await travel.finished
	await get_tree().create_timer(0.15).timeout
	_done(human_first)

func _done(human_first: bool) -> void:
	if phase == Phase.DONE:
		return
	phase = Phase.DONE
	CursorUtil.set_state("off")
	finished.emit(human_first)
