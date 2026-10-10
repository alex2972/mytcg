extends Control
## Deck Construction screen, laid out like the original (800x600): info panel left (217px), deck area centre,
## card collection strip right. Click a collection card to add it; click a deck card to remove it.
## Right-click anywhere for load / save / presets. Assets: j/deck_c/kabegami/*, j/deck_c/font/*.

signal back

const THUMB := Vector2(40, 58)
const STEP_X := 35.2
const COLUMNS := 11
const SECTIONS := {
	"main": Vector2(268, 30),
	"side": Vector2(268, 418),
	"extra": Vector2(268, 520),
}
const SECTION_HEIGHT := {"main": 340.0, "side": 62.0, "extra": 62.0}
const GROUP_ORDER := ["normal", "effect", "ritual", "fusion", "spell", "trap"]
# centres of the capsule plates baked into kabegami_c
const COUNTER_Y := {"normal": 86, "effect": 133, "spell": 180, "trap": 227, "ritual": 274, "total": 361, "side": 467, "extra": 573}
const TRACK_TOP := 72.0          # red double-arrow scroll thumb travels between these y values
const TRACK_BOTTOM := 536.0

var db: CardDB
var collection: Collection
var lang := "eng"
var deck := Deck.new()
var presets := {}
var grids := {}                 # section -> Control holding thumbs
var counters := {}              # name -> DigitFont.Counter
var pool: PoolList
var thumb: TextureRect
var dragging_thumb := false
var drag_dy := 0.0
var pool_rows: Array = []
var search_text := ""
var type_filter := ""
var d_art := TextureRect.new()
var d_name := Label.new()
var d_attr := Label.new()
var d_text := Label.new()
var d_text_box := Control.new()
var text_scroll := 0.0
var status := Label.new()
var menu := PopupMenu.new()
var file_dialog := FileDialog.new()
var filter_panel := PopupPanel.new()
var saving := false
var tex_cache := {}

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	db = CardDB.load_default()
	collection = Collection.load_default(db)
	presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	deck = Deck.load_file("res://data/default_deck.ydc", db)
	_build()
	_sort_deck()
	_refresh_pool()
	_refresh_deck()

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func _img(rel: String) -> Texture2D:
	return _tex("res://assets/j/deck_c/%s.png" % rel)

func _put(rel: String, pos: Vector2, parent: Node = self) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _img(rel)
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func _label(parent: Node, pos: Vector2, size_: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size_
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _build() -> void:
	_put("kabegami/kaban", Vector2(608, 0))
	_put("kabegami/right", Vector2(767, 0))
	_put("kabegami/kabegami_c", Vector2(217, 0))
	_put("kabegami/kabegami_l_e", Vector2.ZERO)
	for sec in SECTIONS:
		var g := Control.new()
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(g)
		grids[sec] = g
	# counters on the capsule plates
	for k in COUNTER_Y:
		var c := DigitFont.Counter.new()
		c.tex = _img("font/font_big")
		c.position = Vector2(235 - 20, COUNTER_Y[k] - 8)
		c.size = Vector2(40, 17)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		counters[k] = c
	# detail panel
	d_art.position = Vector2(14, 90)
	d_art.size = Vector2(190, 276)
	d_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d_art.stretch_mode = TextureRect.STRETCH_SCALE
	d_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_art.texture = _tex("res://assets/ui/card_back.png")
	add_child(d_art)
	d_name = _label(self, Vector2(14, 382), Vector2(184, 18), 12, Color(0.05, 0.1, 0.45))
	d_text_box.position = Vector2(14, 400)
	d_text_box.size = Vector2(182, 138)
	d_text_box.clip_contents = true
	d_text_box.mouse_filter = Control.MOUSE_FILTER_STOP
	d_text_box.gui_input.connect(_on_text_input)
	add_child(d_text_box)
	d_attr = _label(d_text_box, Vector2(0, 0), Vector2(180, 16), 11, Color(0.6, 0.15, 0.05))
	d_text = _label(d_text_box, Vector2(0, 16), Vector2(180, 400), 11, Color(0.12, 0.08, 0.05))
	d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hotspot(Rect2(196, 386, 14, 28), func(): _scroll_text(-30))
	_hotspot(Rect2(196, 514, 14, 28), func(): _scroll_text(30))
	status.position = Vector2(222, 2)
	status.size = Vector2(380, 18)
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)
	# collection list
	pool = PoolList.new()
	pool.db = db
	pool.position = Vector2(681, 37)
	pool.size = Vector2(86, 560)
	pool.picked.connect(_add_card)
	pool.hovered.connect(_show_detail)
	pool.scrolled.connect(_on_pool_scrolled)
	add_child(pool)
	# red double-arrow scroll thumb + the two arrow buttons baked into right.png
	thumb = TextureRect.new()
	thumb.texture = _img("kabegami/kaban_bar")
	thumb.position = Vector2(773, TRACK_TOP)
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.gui_input.connect(_on_thumb_drag)
	thumb.mouse_entered.connect(func(): CursorUtil.set_state("on"))
	thumb.mouse_exited.connect(func(): CursorUtil.set_state("off"))
	add_child(thumb)
	_hotspot(Rect2(770, 44, 26, 26), func(): pool.scroll_by_pixels(-110))
	_hotspot(Rect2(770, 538, 26, 26), func(): pool.scroll_by_pixels(110))
	# invisible buttons over the baked-in EXPORT / IMPORT / BACK artwork
	_hotspot(Rect2(14, 60, 94, 26), func(): _open_dialog(true))
	_hotspot(Rect2(114, 60, 92, 26), func(): _open_dialog(false))
	_hotspot(Rect2(62, 549, 93, 43), func(): back.emit())
	var filter_btn := _put("kabegami/filter_mini", Vector2(618, 1))
	filter_btn.scale = Vector2(0.55, 0.55)
	_hotspot(Rect2(618, 1, 80, 22), func(): filter_panel.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i(260, 140))))
	_build_filter_panel()
	menu.id_pressed.connect(_on_menu)
	add_child(menu)
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.ydc", "Deck files")
	file_dialog.file_selected.connect(_on_file)
	file_dialog.size = Vector2i(560, 380)
	add_child(file_dialog)
	gui_input.connect(_on_input)

func _hotspot(rect: Rect2, handler: Callable) -> void:
	var c := Control.new()
	c.position = rect.position
	c.size = rect.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			handler.call())
	c.mouse_entered.connect(func(): CursorUtil.set_state("on"))
	c.mouse_exited.connect(func(): CursorUtil.set_state("off"))
	add_child(c)

func _build_filter_panel() -> void:
	var box := VBoxContainer.new()
	filter_panel.add_child(box)
	var search := LineEdit.new()
	search.placeholder_text = "Search name or text..."
	search.text_changed.connect(func(t):
		search_text = t
		_refresh_pool())
	box.add_child(search)
	var types := OptionButton.new()
	for t in ["All", "Monster", "Spell", "Trap"]:
		types.add_item(t)
	types.item_selected.connect(func(i):
		type_filter = "" if i == 0 else types.get_item_text(i).to_lower()
		_refresh_pool())
	box.add_child(types)
	var langs := OptionButton.new()
	for l in CardDB.LANGS:
		langs.add_item(l)
	langs.item_selected.connect(func(i):
		lang = CardDB.LANGS[i]
		_refresh_pool()
		_refresh_deck())
	box.add_child(langs)
	var all := CheckBox.new()
	all.text = "Debug: unlock every card"
	all.toggled.connect(func(on):
		if on:
			collection.unlock_all()
			_refresh_pool()
			_refresh_deck())
	box.add_child(all)
	add_child(filter_panel)

# --- detail text scrolling -------------------------------------------------------------

func _scroll_text(delta: float) -> void:
	var max_scroll: float = maxf(0.0, d_text.get_minimum_size().y + 16.0 - d_text_box.size.y)
	text_scroll = clampf(text_scroll + delta, 0.0, max_scroll)
	d_attr.position.y = -text_scroll
	d_text.position.y = 16.0 - text_scroll

func _on_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_text(24)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_text(-24)

# --- deck display -----------------------------------------------------------------

func _group(idx: int) -> String:
	var c := db.card(idx)
	match c.get("type", ""):
		"spell": return "spell"
		"trap": return "trap"
	return ["normal", "effect", "fusion", "ritual"][int(c.get("category", 0))]

func _sort_deck() -> void:
	var key := func(a: int, b: int) -> bool:
		var ga := GROUP_ORDER.find(_group(a))
		var gb := GROUP_ORDER.find(_group(b))
		return ga < gb or (ga == gb and a < b)
	deck.main.sort_custom(key)
	deck.extra.sort_custom(key)
	deck.side.sort_custom(key)

func _refresh_deck() -> void:
	for sec in SECTIONS:
		var g: Control = grids[sec]
		for ch in g.get_children():
			ch.queue_free()
		var cards := DeckRules.section_of(deck, sec)
		var rows := int(ceil(float(cards.size()) / COLUMNS))
		var avail: float = SECTION_HEIGHT[sec]
		var step_y := 92.0
		if rows > 1:
			step_y = minf(92.0, (avail - THUMB.y) / float(rows - 1))
		for i in cards.size():
			var t := TextureRect.new()
			var path := db.art_path(cards[i], true)
			t.texture = _tex(path) if path != "" else _tex("res://assets/ui/card_back_mini.png")
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_SCALE
			t.size = THUMB
			t.position = SECTIONS[sec] + Vector2((i % COLUMNS) * STEP_X, (i / COLUMNS) * step_y)
			t.mouse_filter = Control.MOUSE_FILTER_STOP
			t.gui_input.connect(_on_thumb_input.bind(sec, i))
			t.mouse_entered.connect(func():
				_show_detail(cards[i])
				CursorUtil.set_state("on"))
			t.mouse_exited.connect(func(): CursorUtil.set_state("off"))
			g.add_child(t)
	var n := {"normal": 0, "effect": 0, "spell": 0, "trap": 0, "ritual": 0}
	for idx in deck.main:
		var gname := _group(idx)
		if n.has(gname):
			n[gname] += 1
	for k in n:
		counters[k].set_value(n[k])
	var total: DigitFont.Counter = counters["total"]
	total.tex = _img("font/font_big_red") if deck.main.size() < DeckRules.MIN_MAIN else _img("font/font_big")
	total.set_value(deck.main.size())
	counters["side"].set_value(deck.side.size())
	counters["extra"].set_value(deck.extra.size())
	var probs := DeckRules.problems(deck, db)
	status.text = "" if probs.is_empty() else probs[0]
	status.add_theme_color_override("font_color", Color.SALMON)
	_refresh_pool_counts()

func _on_thumb_input(event: InputEvent, sec: String, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		DeckRules.section_of(deck, sec).remove_at(i)
		AudioUtil.sfx("cursor")
		CursorUtil.set_state("off")
		_refresh_deck()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var card: int = DeckRules.section_of(deck, sec)[i]
		if sec == "main" and deck.side.size() < DeckRules.MAX_SIDE:
			DeckRules.section_of(deck, sec).remove_at(i)
			deck.side.append(card)
			_sort_deck()
			_refresh_deck()
		elif sec == "side":
			DeckRules.section_of(deck, sec).remove_at(i)
			deck.main.append(card)
			_sort_deck()
			_refresh_deck()

# --- collection list ------------------------------------------------------------------

func _refresh_pool() -> void:
	pool_rows = db.search(search_text, type_filter, lang).filter(func(i): return collection.owned(i) > 0)
	pool_rows.sort_custom(func(a, b): return db.card_name(a, lang).to_lower() < db.card_name(b, lang).to_lower())
	pool.set_rows(pool_rows)
	_refresh_pool_counts()

func _refresh_pool_counts() -> void:
	var used := {}
	for i in deck.main + deck.extra + deck.side:
		used[i] = used.get(i, 0) + 1
	pool.set_counts(collection.counts, used)

func _on_pool_scrolled(r: float) -> void:
	if thumb != null and not dragging_thumb:
		thumb.position.y = TRACK_TOP + r * (TRACK_BOTTOM - TRACK_TOP - 60.0)

func _on_thumb_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_thumb = event.pressed
		drag_dy = event.position.y
	elif event is InputEventMouseMotion and dragging_thumb:
		var y: float = clampf(thumb.position.y + event.position.y - drag_dy, TRACK_TOP, TRACK_BOTTOM - 60.0)
		thumb.position.y = y
		pool.set_ratio((y - TRACK_TOP) / (TRACK_BOTTOM - TRACK_TOP - 60.0))

func _add_card(card: int) -> void:
	var reason := DeckRules.add(deck, db, card, "", collection.owned(card))
	if reason != "":
		status.text = reason
		AudioUtil.sfx("unable")
		return
	AudioUtil.sfx("decide")
	_sort_deck()
	_refresh_deck()

# --- detail ------------------------------------------------------------------------------

func _show_detail(idx: int) -> void:
	var path := db.art_path(idx)
	d_art.texture = _tex(path) if path != "" and _tex(path) != null else _tex("res://assets/ui/card_back.png")
	var c := db.card(idx)
	d_name.text = db.card_name(idx, lang)
	d_attr.text = "[%s]" % CardDB.RACES[int(c.kind)] if db.is_monster(idx) and int(c.kind) < CardDB.RACES.size() else "[%s]" % db.kind_label(idx)
	d_text.text = db.card_desc(idx, lang)
	text_scroll = 0.0
	_scroll_text(0)

# --- menu / files -------------------------------------------------------------------------

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		menu.clear()
		menu.add_item("Open deck (.ydc)...", 1)
		menu.add_item("Save deck (.ydc)...", 2)
		menu.add_item("Clear deck", 3)
		menu.add_separator()
		var i := 10
		for k in presets.keys():
			if k.begins_with("cpu_0") or k.begins_with("ful_0"):
				menu.add_item("Preset: " + k, i)
			i += 1
		menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i(0, 0)))

func _on_menu(id: int) -> void:
	match id:
		1: _open_dialog(false)
		2: _open_dialog(true)
		3:
			deck = Deck.new()
			_refresh_deck()
		_:
			var names: Array = presets.keys()
			if id >= 10 and id - 10 < names.size():
				_load_preset(names[id - 10])

func _load_preset(preset_name: String) -> void:
	var p: Dictionary = presets[preset_name]
	deck = Deck.new()
	deck.main = p["main"].map(func(x): return int(x))
	deck.extra = p["extra"].map(func(x): return int(x))
	deck.side = p["side"].map(func(x): return int(x))
	deck.header = p["header"].map(func(x): return int(x))
	_sort_deck()
	_refresh_deck()

func _open_dialog(save: bool) -> void:
	saving = save
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func _on_file(path: String) -> void:
	if saving:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_buffer(deck.to_bytes(db))
	else:
		var d := Deck.load_file(path, db)
		if d != null:
			deck = d
			_sort_deck()
			_refresh_deck()
