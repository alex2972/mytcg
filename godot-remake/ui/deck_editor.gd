extends Control
## Deck Construction screen, laid out like the original (800x600): info panel left (217px), deck area centre,
## card collection strip right. Click a collection card to add it; click a deck card to remove it.
## Right-click anywhere for load / save / presets. Assets: j/deck_c/kabegami/*, j/deck_c/font/*.

signal back

const DECK_TEXTURES := preload("res://ui/deck_textures.gd")

const THUMB := Vector2(50, 72)
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
var working_path := Deck.active_working_path()
var online := false                 # signed in: the deck lives on the server
var _save_pending := false
var _saving := false
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
var detail_index := -1
var d_icons := Control.new()
var d_stats := Label.new()
var back_button := TextureButton.new()
var d_name := Label.new()
var d_attr := Label.new()
var d_text := Label.new()
var d_text_box := Control.new()
var text_scroll := 0.0
var text_scroll_handle := TextureRect.new()
var status := Label.new()
var menu := PopupMenu.new()
var file_dialog := FileDialog.new()
var filter_panel := PopupPanel.new()
var expanded := false
var expansion := 0.0
var panel_tween: Tween
var collection_panel := Control.new()
var panel_back: NinePatchRect
var filter_controls := Control.new()
var filter_caption := TextureRect.new()
var sort_button := TextureButton.new()
var group_filter := ""
var sort_mode := 0
const SORT_LABELS := ["Name", "Attack", "Defense", "Monster type", "Attribute", "Level"]
var saving := false
var tex_cache := {}

func _ready() -> void:
	# Native interface pixels stay crisp; card artwork opts into smooth filtering.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	db = CardDB.load_default()
	var session := get_node_or_null("/root/Session")
	online = session != null and session.is_online()
	presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	if session != null:
		collection = await session.load_collection()
		deck = await session.load_deck(working_path)
	else:
		collection = Collection.load_default(db)
		deck = Deck.load_working(db, working_path)
	_build()
	_sort_deck()
	_refresh_pool()
	_refresh_deck()
	if not collection.can_build_deck():
		DuelDialog.notice(self, DuelDialog.SHOP_NOTICE)

func _tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[path]

func _img(rel: String) -> Texture2D:
	return DECK_TEXTURES.get_texture("res://assets/j/deck_c/%s.png" % rel)

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

	_put("kabegami/right", Vector2(767, 0))
	var center_back := NinePatchRect.new()
	center_back.texture = _img("kabegami/kabegami_c")
	center_back.position = Vector2(217, 0)
	center_back.size = Vector2(458, 600)
	center_back.patch_margin_left = 51
	center_back.patch_margin_right = 12
	center_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_back)
	center_back.name = "DeckBackground"
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
	d_art.position = Vector2(7, 89)
	d_art.size = Vector2(200, 290)
	d_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	d_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d_art.stretch_mode = TextureRect.STRETCH_SCALE
	d_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_art.texture = _tex("res://assets/ui/card_back.png")
	add_child(d_art)
	d_name = _label(self, Vector2(16, 390), Vector2(184, 18), 11, Color(0.05, 0.1, 0.45))
	d_text_box.position = Vector2(16, 408)
	d_text_box.size = Vector2(176, 105)
	d_text_box.clip_contents = true
	d_text_box.mouse_filter = Control.MOUSE_FILTER_STOP
	d_text_box.gui_input.connect(_on_text_input)
	add_child(d_text_box)
	d_attr = _label(d_text_box, Vector2(0, 0), Vector2(180, 16), 11, Color(0.6, 0.15, 0.05))
	d_text = _label(d_text_box, Vector2(0, 18), Vector2(158, 400), 11, Color(0.12, 0.08, 0.05))
	d_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_text.add_theme_constant_override("line_spacing", 5)
	var detail_font := SystemFont.new()
	detail_font.font_names = PackedStringArray(["Arial"])
	d_text.add_theme_font_override("font", detail_font)
	d_text.add_theme_font_size_override("font_size", 11)
	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["Arial"])
	title_font.font_weight = 700
	d_name.add_theme_font_override("font", title_font)
	d_icons.position = Vector2(15, 523)
	d_icons.size = Vector2(180, 16)
	d_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_icons.draw.connect(_draw_detail_strip)
	add_child(d_icons)
	d_stats = _label(self, Vector2(53, 521), Vector2(140, 16), 10, Color.BLACK)
	var stats_font := SystemFont.new()
	stats_font.font_names = PackedStringArray(["Arial Black", "Arial"])
	stats_font.font_weight = 900
	stats_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	stats_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	d_stats.add_theme_font_override("font", stats_font)
	d_stats.scale.x = 1.1
	text_scroll_handle.texture = _img("kabegami/bar")
	text_scroll_handle.position = Vector2(191, 410)
	text_scroll_handle.visible = false
	text_scroll_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_scroll_handle)
	d_text.minimum_size_changed.connect(func(): _scroll_text(0))
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
	pool.position = Vector2(4, 37)
	pool.size = Vector2(86, 560)
	pool.picked.connect(_add_card)
	pool.hovered.connect(_show_detail)
	pool.scrolled.connect(_on_pool_scrolled)
	collection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(collection_panel)
	panel_back = NinePatchRect.new()
	panel_back.texture = _img("kabegami/kaban")
	panel_back.patch_margin_left = 43
	panel_back.patch_margin_right = 5
	panel_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	collection_panel.add_child(panel_back)
	panel_back.size = Vector2(92, 600)
	collection_panel.add_child(pool)
	_build_collection_header()
	_apply_expansion(0.0)
	# red double-arrow scroll thumb + the two arrow buttons baked into right.png
	thumb = TextureRect.new()
	thumb.texture = _img("kabegami/kaban_bar")
	thumb.position = Vector2(775, TRACK_TOP)
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
	back_button.texture_normal = _atlas(_img("kabegami/kabegami_l_e"), Rect2(62, 549, 93, 43))
	back_button.texture_hover = _img("kabegami/back_2_e")
	back_button.position = Vector2(62, 549)
	back_button.pressed.connect(func(): back.emit())
	back_button.mouse_entered.connect(func(): CursorUtil.set_state("on"))
	back_button.mouse_exited.connect(func(): CursorUtil.set_state("off"))
	add_child(back_button)
	var custom := Button.new()
	custom.text = "..."
	custom.tooltip_text = "Search, language and debug options"
	custom.position = Vector2(770, 4)
	custom.size = Vector2(26, 26)
	custom.pressed.connect(func(): filter_panel.popup(Rect2i(520, 35, 275, 160)))
	add_child(custom)
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
	var display_size := OptionButton.new()
	display_size.add_item("Window: 800 x 600 (1x)")
	display_size.add_item("Window: 1600 x 1200 (2x)")
	display_size.selected = 1 if get_window().size == Vector2i(1600, 1200) else 0
	var usable := DisplayServer.screen_get_usable_rect(get_window().current_screen).size
	if usable.x < 1600 or usable.y < 1200:
		display_size.set_item_disabled(1, true)
		display_size.set_item_tooltip(1, "A 1600 x 1200 window needs a larger screen.")
	display_size.item_selected.connect(func(i):
		get_window().size = Vector2i(800, 600) * (i + 1))
	box.add_child(display_size)
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
	all.disabled = online           # the server owns online collections
	all.toggled.connect(func(on):
		if on and not online:
			collection.unlock_all()
			_refresh_pool()
			_refresh_deck())
	box.add_child(all)
	add_child(filter_panel)

# --- detail text scrolling -------------------------------------------------------------

func _scroll_text(delta: float) -> void:
	var max_scroll: float = maxf(0.0, d_text.get_minimum_size().y + 18.0 - d_text_box.size.y)
	text_scroll = clampf(text_scroll + delta, 0.0, max_scroll)
	d_attr.position.y = -text_scroll
	d_text.position.y = 18.0 - text_scroll
	text_scroll_handle.visible = max_scroll > 0.0
	var ratio := text_scroll / max_scroll if max_scroll > 0.0 else 0.0
	text_scroll_handle.position.y = lerpf(410.0, 481.0, ratio)

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
	if online:
		_queue_online_save()
	else:
		var save_error := deck.save_working(db, working_path)
		if save_error != OK:
			push_error("Could not save the working deck: %s" % error_string(save_error))
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
			t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_SCALE
			t.size = THUMB
			t.position = SECTIONS[sec] + Vector2((i % COLUMNS) * lerpf(STEP_X, 25.2, expansion), (i / COLUMNS) * step_y)
			t.mouse_filter = Control.MOUSE_FILTER_STOP
			t.gui_input.connect(_on_thumb_input.bind(sec, i))
			t.mouse_entered.connect(func():
				_show_detail(cards[i])
				CursorUtil.set_state("on"))
			t.mouse_exited.connect(func(): CursorUtil.set_state("off"))
			# Brighten the artwork in place; preserve overlap and deck ordering.
			t.mouse_entered.connect(func(): t.modulate = Color(1.3, 1.3, 1.3))
			t.mouse_exited.connect(func(): t.modulate = Color.WHITE)
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
	if group_filter != "":
		pool_rows = pool_rows.filter(func(i): return _group(i) == group_filter)
	pool_rows.sort_custom(_pool_less)
	pool.lang = lang
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
	detail_index = idx
	var path := db.art_path(idx)
	d_art.texture = _tex(path) if path != "" and _tex(path) != null else _tex("res://assets/ui/card_back.png")
	var c := db.card(idx)
	d_name.text = db.card_name(idx, lang)
	d_attr.text = "[%s]" % CardDB.RACES[int(c.kind)] if db.is_monster(idx) and int(c.kind) < CardDB.RACES.size() else "[%s]" % db.kind_label(idx)
	d_text.text = db.card_desc(idx, lang)
	d_stats.text = "ATK/%d  DEF/%d" % [int(c.atk), int(c.def)] if db.is_monster(idx) else ""
	d_icons.queue_redraw()
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

# Smooth drawer; the original assets supply the two button states and filter icons.
func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var out := AtlasTexture.new()
	out.atlas = texture
	out.region = region
	return out

func _build_collection_header() -> void:
	var toggle := TextureButton.new()
	toggle.texture_normal = _atlas(_img("kabegami/kaban"), Rect2(8, 7, 31, 24))
	toggle.texture_hover = _img("kabegami/yajirusi_1")
	toggle.position = Vector2(8, 7)
	toggle.tooltip_text = "Expand / collapse collection"
	toggle.pressed.connect(_toggle_collection)
	collection_panel.add_child(toggle)
	filter_controls.position = Vector2(43, 0)
	filter_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	collection_panel.add_child(filter_controls)
	var filter_frame := TextureRect.new()
	filter_frame.texture = _atlas(_img("kabegami/filter_mini"), Rect2(0, 5, 145, 33))
	filter_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_controls.add_child(filter_frame)
	var groups := ["", "normal", "effect", "fusion", "spell", "trap", "ritual"]
	var assets := ["all", "nor", "eff", "fus", "mag", "tra", "rit"]
	var positions := [Vector2(8, 4), Vector2(33, 4), Vector2(58, 4), Vector2(83, 4), Vector2(33, 16), Vector2(58, 16), Vector2(83, 16)]
	for i in groups.size():
		var button := TextureButton.new()
		# Normal pixels already exist in filter_mini; only hover replaces them.
		button.texture_normal = _atlas(_img("kabegami/filter_mini"), Rect2(positions[i] + Vector2(0, 5), _img("kabegami/f_%s_1" % assets[i]).get_size()))
		button.texture_hover = _img("kabegami/f_%s_2" % assets[i])
		button.position = positions[i]
		button.tooltip_text = "All cards" if i == 0 else groups[i].capitalize()
		button.pressed.connect(_set_group.bind(groups[i]))
		filter_controls.add_child(button)
	filter_caption.position = Vector2(11, 7)
	filter_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_controls.add_child(filter_caption)
	sort_button.position = Vector2(112, 4)
	sort_button.pressed.connect(_cycle_sort)
	filter_controls.add_child(sort_button)
	_update_header()

func _process(_delta: float) -> void:
	var reveal := Rect2(43, 3, 105, 31).has_point(collection_panel.get_local_mouse_position())
	filter_caption.visible = not reveal
	for child in filter_controls.get_children():
		if child is TextureButton and child != sort_button:
			child.visible = reveal

func _update_header() -> void:
	var caption_index := ["", "normal", "effect", "fusion", "spell", "trap", "ritual"].find(group_filter)
	filter_caption.texture = _atlas(_img("icon/icon_syurui_e"), Rect2(caption_index * 89, 0, 89, 14))
	sort_button.texture_normal = _atlas(_img("icon/icon_sort"), Rect2(sort_mode * 22, 0, 22, 21))
	sort_button.tooltip_text = "Sort: " + SORT_LABELS[sort_mode]

func _set_group(value: String) -> void:
	group_filter = value
	_update_header()
	_refresh_pool()

func _cycle_sort() -> void:
	sort_mode = (sort_mode + 1) % SORT_LABELS.size()
	_update_header()
	_refresh_pool()

func _pool_less(a: int, b: int) -> bool:
	var key: String = ["", "atk", "def", "kind", "attribute", "level"][sort_mode]
	if key != "":
		var av := int(db.card(a).get(key, 0))
		var bv := int(db.card(b).get(key, 0))
		if db.is_monster(a) != db.is_monster(b):
			return db.is_monster(a)
		if av != bv:
			return av > bv if sort_mode in [1, 2, 5] else av < bv
	var an := db.card_name(a, lang).to_lower()
	var bn := db.card_name(b, lang).to_lower()
	return a < b if an == bn else an < bn

func _toggle_collection() -> void:
	expanded = not expanded
	if panel_tween != null:
		panel_tween.kill()
	panel_tween = create_tween()
	panel_tween.tween_method(_apply_expansion, expansion, 1.0 if expanded else 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_expansion(value: float) -> void:
	expansion = value
	collection_panel.position.x = lerpf(675, 575, value)
	panel_back.size.x = lerpf(92, 192, value)
	pool.size.x = lerpf(88, 188, value)
	pool.expansion = value
	pool.queue_redraw()
	filter_controls.visible = value > 0.98
	get_node("DeckBackground").size.x = collection_panel.position.x - 217
	for sec in grids:
		for i in grids[sec].get_child_count():
			grids[sec].get_child(i).position.x = SECTIONS[sec].x + (i % COLUMNS) * lerpf(STEP_X, 25.2, value)

func _draw_detail_strip() -> void:
	if detail_index < 0:
		return
	d_icons.draw_line(Vector2(0, -6), Vector2(178, -6), Color.BLACK, 1.0)
	var data := db.card(detail_index)
	if not db.is_monster(detail_index):
		return
	var attribute := int(data.attribute)
	var attr_icon: int = {1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 9}.get(attribute, -1)
	if attr_icon >= 0:
		var texture := DECK_TEXTURES.get_texture("res://assets/j/duel/card/icon_zokusei.png")
		d_icons.draw_texture_rect_region(texture, Rect2(0, 0, 16, 16), Rect2(attr_icon * 16, 0, 16, 16))
	var race := int(data.kind)
	if race >= 1 and race <= 20:
		var texture := DECK_TEXTURES.get_texture("res://assets/j/duel/card/icon_syuzoku.png")
		d_icons.draw_texture_rect_region(texture, Rect2(17, 0, 16, 16), Rect2((race - 1) * 16, 0, 16, 16))

## Online autosave: at most one save in flight, the latest deck wins (1 s debounce).
func _queue_online_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	await get_tree().create_timer(1.0).timeout
	while _saving:
		await get_tree().process_frame
	_save_pending = false
	_saving = true
	var r: Dictionary = await get_node("/root/Session").save_deck(deck)
	_saving = false
	if not r.get("ok", false) and is_instance_valid(status):
		status.text = "Not saved: " + str(r.get("reason", r.get("error", "")))
