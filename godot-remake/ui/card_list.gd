extends Control
## Card List screen (original layout, 800x600): the 350-card pool, 10x5 per page, 7 pages. Cards you do not own show
## as card backs. Top right: owned/350, click it for the percentage. Positions come from j/list/list_scene.txt.

signal back

const COLS := 10
const ROWS := 5
const PER_PAGE := COLS * ROWS
const GRID_ORIGIN := Vector2(226, 114)       # first card (frame is 4px bigger on every side)
const GRID_STEP := Vector2(55, 87)

var db: CardDB
var collection: Collection
var lang := "eng"
var pool: Array = []
var page := 0
var pages := 1
var percent_mode := false
var hover_slot := -1
var selected_card := -1
var tex_cache := {}

var title := TextureRect.new()
var back_btn := TextureRect.new()
var back_hover := false
var art := TextureRect.new()
var d_name := Label.new()
var d_text := Label.new()
var text_box := Control.new()
var text_scroll := 0.0
var slots := Control.new()
var overlay := Control.new()       # frame, counters, page numbers (custom drawn)
var flicker_time := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	db = CardDB.load_default()
	collection = Collection.load_default(db)
	pool = collection.pool()
	pages = int(ceil(float(pool.size()) / PER_PAGE))
	_build()
	_show_page(0)

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func _img(name: String) -> Texture2D:
	return _tex("res://assets/j/list/%s.png" % name)

func _add_img(name: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _img(name)
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t

func _build() -> void:
	_add_img("list_bg", Vector2.ZERO)
	title.texture = _img("e_cardlistmoji2")
	title.position = Vector2(205, 0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	back_btn.texture = _img("e_back1")
	back_btn.position = Vector2(692, 0)
	back_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back_btn)
	art.position = Vector2(6, 87)
	art.size = Vector2(200, 290)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _tex("res://assets/ui/card_back.png")
	add_child(art)
	d_name.position = Vector2(16, 395)
	d_name.size = Vector2(170, 18)
	d_name.add_theme_font_size_override("font_size", 13)
	d_name.add_theme_color_override("font_color", Color(0.1, 0.1, 0.2))
	d_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d_name)
	text_box.position = Vector2(16, 414)
	text_box.size = Vector2(166, 176)
	text_box.clip_contents = true
	text_box.gui_input.connect(_on_text_input)
	add_child(text_box)
	d_text.size = Vector2(164, 400)
	d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_text.add_theme_font_size_override("font_size", 11)
	d_text.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
	d_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(d_text)
	slots.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(slots)
	overlay.size = size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	gui_input.connect(_on_input)
	set_process(true)

# --- page -----------------------------------------------------------------------------------

func _show_page(p: int) -> void:
	if p != page:
		AudioUtil.sfx("cursor")
	page = clampi(p, 0, pages - 1)
	for ch in slots.get_children():
		ch.queue_free()
	var start := page * PER_PAGE
	for s in PER_PAGE:
		var n := start + s
		if n >= pool.size():
			break
		var card: int = pool[n]
		var t := TextureRect.new()
		var owned := collection.owned(card) > 0
		var path := db.art_path(card, true)
		t.texture = (_tex(path) if path != "" else null) if owned else _tex("res://assets/ui/card_back_mini.png")
		if t.texture == null:
			t.texture = _tex("res://assets/ui/card_back_mini.png")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = Vector2(50, 72)
		t.position = GRID_ORIGIN + Vector2((s % COLS) * GRID_STEP.x, (s / COLS) * GRID_STEP.y)
		t.mouse_filter = Control.MOUSE_FILTER_STOP
		t.mouse_entered.connect(_on_slot_enter.bind(s))
		t.mouse_exited.connect(_on_slot_exit.bind(s))
		t.gui_input.connect(_on_slot_input.bind(s))
		slots.add_child(t)
	hover_slot = -1
	overlay.queue_redraw()

func _slot_card(s: int) -> int:
	var n := page * PER_PAGE + s
	return pool[n] if n < pool.size() else -1

func _on_slot_enter(s: int) -> void:
	hover_slot = s
	AudioUtil.sfx("cursor")
	CursorUtil.set_state("on")
	var card := _slot_card(s)
	if card != -1:
		_show_detail(card)
	overlay.queue_redraw()

func _on_slot_exit(s: int) -> void:
	if hover_slot == s:
		hover_slot = -1
	CursorUtil.set_state("off")
	overlay.queue_redraw()

func _on_slot_input(event: InputEvent, s: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_card = _slot_card(s)
		overlay.queue_redraw()

func _show_detail(card: int) -> void:
	if collection.owned(card) <= 0:
		art.texture = _tex("res://assets/ui/card_back.png")
		d_name.text = ""
		d_text.text = ""
		return
	var path := db.art_path(card)
	art.texture = _tex(path) if path != "" and _tex(path) != null else _tex("res://assets/ui/card_back.png")
	d_name.text = db.card_name(card, lang)
	d_text.text = db.card_desc(card, lang)
	text_scroll = 0.0
	d_text.position.y = 0

func _on_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var max_scroll: float = maxf(0.0, d_text.get_minimum_size().y - text_box.size.y)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			text_scroll = minf(max_scroll, text_scroll + 24)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			text_scroll = maxf(0.0, text_scroll - 24)
		d_text.position.y = -text_scroll

# --- input ------------------------------------------------------------------------------------

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var over := Rect2(692, 0, 108, 93).has_point(event.position)
		if over != back_hover:
			back_hover = over
			back_btn.texture = _img("e_back2" if over else "e_back1")
			CursorUtil.set_state("on" if over else "off")
		var arrows := Rect2(408, 565, 49, 23).has_point(event.position) or Rect2(549, 565, 49, 23).has_point(event.position) or Rect2(585, 18, 105, 32).has_point(event.position)
		if arrows:
			CursorUtil.set_state("on")
		elif not over and hover_slot == -1:
			CursorUtil.set_state("off")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Rect2(692, 0, 108, 93).has_point(event.position):
				AudioUtil.sfx("decide")
				back.emit()
			elif Rect2(408, 565, 49, 23).has_point(event.position):
				_show_page((page - 1 + pages) % pages)
			elif Rect2(549, 565, 49, 23).has_point(event.position):
				_show_page((page + 1) % pages)
			elif Rect2(585, 18, 105, 32).has_point(event.position):
				percent_mode = not percent_mode
				overlay.queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_show_page(page - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_show_page(page + 1)

func _process(delta: float) -> void:
	flicker_time += delta
	var frames := ["e_cardlistmoji2", "e_cardlistmoji2", "e_cardlistmoji2", "e_cardlistmoji1", "e_cardlistmoji3", "e_cardlistmoji2"]
	var i := int(flicker_time / 0.16) % frames.size()
	title.texture = _img(frames[i])

# --- custom drawing: selection frame, counters, page numbers -------------------------------

func _draw_overlay() -> void:
	# selection frame under the cursor
	if hover_slot != -1 and _slot_card(hover_slot) != -1:
		var p := GRID_ORIGIN + Vector2((hover_slot % COLS) * GRID_STEP.x, (hover_slot / COLS) * GRID_STEP.y) - Vector2(4, 4)
		overlay.draw_texture(_img("card_waku_s"), p)
	# page numbers  "<  1 / 7  >"
	var digits := _img("page_font")
	DigitFont.draw_number(overlay, digits, str(page + 1), Vector2(476, 576), 12, 21)
	DigitFont.draw_number(overlay, digits, str(pages), Vector2(530, 576), 12, 21)
	# owned/total or percentage, right aligned
	var got := collection.owned_in_pool()
	var total := pool.size()
	var text := ""
	if percent_mode:
		var pct: float = floor(float(got) / float(maxi(1, total)) * 1000.0) / 10.0
		text = "%.1f%%" % pct
	else:
		text = "%d/%d" % [got, total]
	var font := _img("get_font")
	var sym := _img("get_symbol")
	var x := 684.0
	for k in range(text.length() - 1, -1, -1):
		var ch := text[k]
		if ch in "0123456789":
			x -= 14
			overlay.draw_texture_rect_region(font, Rect2(x, 22, 14, 26), Rect2("0123456789".find(ch) * 14, 0, 14, 26))
		else:
			var idx := "/.%".find(ch)
			var w: int = 13 if idx != 1 else 12
			var sx: int = [0, 13, 25][idx]
			x -= w
			overlay.draw_texture_rect_region(sym, Rect2(x, 22, w, 26), Rect2(sx, 0, w, 26))
