class_name PackContents
extends Control
## "What's in this pack": every card a product can give, grouped by rarity (rarest first) with the
## chance per card, as small card images in a scrolling grid. Hovering a card shows it large on the left.
## Opened from the Shop's CARD LIST button; Back / Escape emits `closed`. Data comes from
## backend.get_product_contents, so the list always matches what the backend can roll.

signal closed

const ART := "res://assets/ui/shop/"
const MINI := Vector2(50, 72)
const COLUMNS := 9
const GAP := Vector2(9, 12)
const GRID := Rect2(238, 104, 540, 418)
const GOLD := Color(1.0, 0.8, 0.3)
const WHITE := Color("f3f4f5")
const RED := Color("790d08")

var db: CardDB
var owned := {}                      # card index -> copies the account owns
var sections: Array = []
var slots: Array[Control] = []       # one per card shown, in order
var scroll: ScrollContainer
var preview: TextureRect
var preview_name: Label
var preview_info: Label
var back_button: TextureButton
var font: Font = preload("res://assets/ui/shop/shop_font.tres")
var _tex := {}

## `contents` is the backend's get_product_contents result.
func show_contents(contents: Dictionary, card_db: CardDB, owned_counts: Dictionary) -> void:
	db = card_db
	owned = owned_counts
	sections = contents.get("sections", [])
	name = "PackContents"
	size = Vector2(800, 600)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_image(self, "background", Rect2(0, 0, 800, 600))
	_image(self, "header_reference", Rect2(0, 0, 800, 65.2))
	_image(self, "balance_panel", Rect2(554, 10, 211, 43))
	var title := _label(self, str(contents.get("name", "")), Rect2(566, 12, 190, 38), 24, WHITE)
	title.name = "PackName"
	var total := 0
	for s: Dictionary in sections:
		total += (s["cards"] as Array).size()
	_label(self, "CARD LIST  ·  %d CARDS" % total, Rect2(238, 70, 540, 30), 22, WHITE).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_build_preview()
	_build_grid()
	_image(self, "footer_strip", Rect2(0, 526, 800, 74))
	back_button = TextureButton.new()
	back_button.name = "BackButton"
	back_button.position = Vector2(22, 529)
	back_button.size = Vector2(129, 59)
	back_button.ignore_texture_size = true
	back_button.stretch_mode = TextureButton.STRETCH_SCALE
	back_button.texture_normal = _texture("back_normal")
	back_button.texture_hover = _texture("back_hover")
	back_button.texture_pressed = _texture("back_pressed")
	back_button.pressed.connect(close)
	back_button.mouse_entered.connect(func(): AudioUtil.sfx("cursor"))
	add_child(back_button)
	_label(back_button, "BACK", Rect2(Vector2.ZERO, back_button.size), 32, RED)
	var hint := _label(self, "Hover a card to see it. Cards you own 3 of no longer drop.", Rect2(174, 543, 600, 38), 16, WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not slots.is_empty():
		_show_card(int(slots[0].get_meta("card")))

func close() -> void:
	AudioUtil.sfx("decide")
	closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _build_preview() -> void:
	var frame := ColorRect.new()
	frame.color = Color(0.04, 0.06, 0.09, 0.75)
	frame.position = Vector2(12, 74)
	frame.size = Vector2(214, 446)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	preview = TextureRect.new()
	preview.name = "Preview"
	preview.position = Vector2(19, 80)
	preview.size = Vector2(200, 290)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	preview_name = _label(self, "", Rect2(16, 374, 206, 50), 18, WHITE)
	preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_info = _label(self, "", Rect2(16, 424, 206, 92), 15, Color("c9d2dc"))
	preview_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	preview_info.add_theme_font_override("font", _plain_font())

func _build_grid() -> void:
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.position = GRID.position
	scroll.size = GRID.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var bar := scroll.get_v_scroll_bar()
	var track := StyleBoxTexture.new()
	track.texture = _texture("scroll_track")
	var thumb := StyleBoxTexture.new()
	thumb.texture = _texture("scroll_thumb")
	bar.add_theme_stylebox_override("scroll", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(state, thumb)
	bar.custom_minimum_size.x = 16
	add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	for s: Dictionary in sections:
		column.add_child(_section_header(s))
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", int(GAP.x))
		grid.add_theme_constant_override("v_separation", int(GAP.y))
		column.add_child(grid)
		var cards: Array = (s["cards"] as Array).duplicate()
		if not s.get("ordered", false):          # sets keep their order (Fusion, its materials, ...)
			cards.sort_custom(func(a, b): return db.card_name(int(a)) < db.card_name(int(b)))
		for card in cards:
			grid.add_child(_slot(int(card), bool(s.get("rare", false)), str(s.get("label", ""))))
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 6)
		column.add_child(spacer)

func _section_header(s: Dictionary) -> Control:
	var rare := bool(s.get("rare", false))
	var row := Control.new()
	row.custom_minimum_size = Vector2(GRID.size.x - 20, 34)
	var bar := ColorRect.new()
	bar.color = Color(0.45, 0.32, 0.05, 0.85) if rare else Color(0.12, 0.16, 0.22, 0.85)
	bar.position = Vector2(0, 3)
	bar.size = Vector2(GRID.size.x - 20, 28)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	var label := _label(row, str(s.get("label", "")), Rect2(10, 2, 300, 30), 22, GOLD if rare else WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.name = "SectionTitle"
	var chance := float(s.get("chance", 0.0))
	var chance_text := ("%d%%" % roundi(chance)) if absf(chance - roundf(chance)) < 0.05 else ("%.1f%%" % chance)
	var caption := str(s["caption"]) if s.has("caption") else "%s chance per card  ·  %d cards" % [chance_text, (s["cards"] as Array).size()]
	var info := _label(row, caption, Rect2(200, 2, GRID.size.x - 232, 30), 16, GOLD if rare else Color("c9d2dc"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_theme_font_override("font", _plain_font())
	return row

func _slot(card: int, rare: bool, rarity_label: String) -> Control:
	var slot := Control.new()
	slot.name = "Card%d" % card
	slot.custom_minimum_size = MINI
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.set_meta("card", card)
	slot.set_meta("rarity", rarity_label)
	var art := TextureRect.new()
	var path := db.art_path(card, true)
	art.texture = _load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = MINI
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(art)
	if rare:
		var frame := _GoldEdge.new()
		frame.size = MINI + Vector2(6, 6)
		frame.position = Vector2(-3, -3)
		slot.add_child(frame)
	var count := int(owned.get(card, 0))
	if count > 0:
		var badge := _label(slot, "x%d" % count, Rect2(MINI.x - 24, MINI.y - 18, 26, 18), 14, Color("ffd51a") if count >= Collection.MAX_OWNED else WHITE)
		badge.name = "Owned"
		badge.add_theme_constant_override("outline_size", 4)
	slot.mouse_entered.connect(func():
		_show_card(card)
		slot.modulate = Color(1.25, 1.25, 1.25))
	slot.mouse_exited.connect(func(): slot.modulate = Color.WHITE)
	slots.append(slot)
	return slot

func _show_card(card: int) -> void:
	preview.texture = _load(db.art_path(card))
	preview_name.text = db.card_name(card)
	var c := db.card(card)
	var info := ""
	for slot in slots:
		if int(slot.get_meta("card")) == card:
			info = str(slot.get_meta("rarity")) + "\n"
			break
	info += db.kind_label(card)
	if db.is_monster(card):
		info += "\nLevel %d   ATK %d / DEF %d" % [int(c.get("level", 0)), int(c.get("atk", 0)), int(c.get("def", 0))]
	info += "\nOwned: %d / %d" % [int(owned.get(card, 0)), Collection.MAX_OWNED]
	preview_info.text = info

func _load(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]

func _texture(key: String) -> Texture2D:
	return _load(ART + key + ".png")

func _image(parent: Node, key: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture(key)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.position = rect.position
	image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

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
	label.add_theme_constant_override("outline_size", 1)
	parent.add_child(label)
	return label

static func _plain_font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial"])
	f.font_weight = 700
	return f

## Thin glowing gold outline for ultra rare thumbnails.
class _GoldEdge extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(1.0, 0.8, 0.3, 0.35), false, 3.0)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(1.0, 0.85, 0.35), false, 1.5)
