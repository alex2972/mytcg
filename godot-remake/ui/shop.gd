extends Control
## Card Shop screen. It only displays what the backend (Session.backend) returns and sends it
## account/product ids: prices, balances and pack contents are decided by the backend, which will
## become the authoritative server.

signal back

const ART := "res://assets/ui/shop/"
const CATEGORIES := ["packs", "decks", "bundles"]
const ROW_HEIGHT := 326.0
const VIEW_HEIGHT := 410.0
const SCROLL_TRACK := Rect2(758, 108, 20, 360)
const WHITE := Color("f3f4f5")
const INK := Color("18202b")
const RED := Color("790d08")

# Filled from the backend's catalog: category -> [{"id", "name", "price", "art", "available"}].
var catalog: Dictionary = {"packs": [], "decks": [], "bundles": []}
var dp := 0
var busy := false             # a purchase request is in flight
var price_buttons: Array[TextureButton] = []
var reveal: PackOpening       # pack opening in progress or showing its result, null when closed
var contents_button: TextureButton
var contents_view: PackContents   # card list of the selected product, null when closed
var last_result: Dictionary = {}
# Second-row visual stand-ins until more pack art exists. No purchase actions.
var show_preview_row := true
var active_category := "packs"
var selected_index := 0
var tabs: Dictionary = {}
var products: Array[TextureButton] = []
var markers: Array[Control] = []
var clip: Control
var content: Control
var scrollbar: VScrollBar
var scroll_thumb: TextureRect
var scroll_down: TextureButton
var back_button: TextureButton
var hint: Label
var balance: Label
var font: Font = preload("res://assets/ui/shop/shop_font.tres")
var _textures: Dictionary = {}
var _pack_textures: Dictionary = {}
var _dragging_scroll := false
var _scroll_drag_offset := 0.0

func _ready() -> void:
	name = "Shop"
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(800, 600)
	custom_minimum_size = size
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_image(self, "background", Rect2(0, 0, 800, 600))
	# Static branding/chrome extracted from the approved reference. The separate
	# opaque balance panel below covers its sample balance with runtime text.
	_image(self, "header_reference", Rect2(0, 0, 800, 65.2))
	_image(self, "balance_panel", Rect2(554, 10, 211, 43))
	balance = _label(self, "", Rect2(570, 12, 134, 38), 30, WHITE)
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(self, "DP", Rect2(708, 12, 34, 38), 25, Color("ffd51a"))
	for i in CATEGORIES.size():
		var category: String = CATEGORIES[i]
		var button := _button(self, "tab", category.to_upper(), Rect2(150 + i * 159, 70, 154, 33), 24, INK)
		button.name = category.capitalize() + "Tab"
		button.pressed.connect(show_category.bind(category))
		tabs[category] = button
	clip = Control.new()
	clip.name = "CatalogViewport"
	clip.position = Vector2(136, 116)
	clip.size = Vector2(598, VIEW_HEIGHT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(clip)
	content = Control.new()
	content.name = "CatalogContent"
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	clip.add_child(content)
	_image(self, "scroll_track", SCROLL_TRACK)
	scrollbar = VScrollBar.new()
	scrollbar.name = "CatalogScrollBar"
	scrollbar.position = SCROLL_TRACK.position
	scrollbar.size = SCROLL_TRACK.size
	scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrollbar.focus_mode = Control.FOCUS_NONE
	scrollbar.step = 1.0
	# Use the native range model, with the reference's compact custom handle.
	for state in ["scroll", "scroll_focus", "grabber", "grabber_highlight", "grabber_pressed"]:
		scrollbar.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	scrollbar.value_changed.connect(_scroll_changed)
	add_child(scrollbar)
	scroll_thumb = _image(self, "scroll_thumb", Rect2(761, 112, 14, 40))
	scroll_down = TextureButton.new()
	scroll_down.position = Vector2(758, 468)
	scroll_down.size = Vector2(20, 30)
	scroll_down.ignore_texture_size = true
	scroll_down.stretch_mode = TextureButton.STRETCH_SCALE
	scroll_down.texture_normal = _texture("scroll_arrow_down")
	scroll_down.pressed.connect(func(): scrollbar.value += 70)
	add_child(scroll_down)
	_image(self, "footer_strip", Rect2(0, 526, 800, 74))
	back_button = _button(self, "back", "BACK", Rect2(22, 529, 129, 59), 32, RED)
	back_button.name = "BackButton"
	back_button.pressed.connect(_go_back)
	hint = _label(self, "Select a pack", Rect2(174, 543, 360, 38), 16, WHITE)
	# Shows every card the selected product can give, by rarity.
	contents_button = _button(self, "tab", "CARD LIST", Rect2(612, 546, 154, 33), 22, INK)
	contents_button.name = "ContentsButton"
	contents_button.pressed.connect(show_contents)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var hint_font := SystemFont.new()
	hint_font.font_names = PackedStringArray(["Arial"])
	hint_font.font_weight = 700
	hint.add_theme_font_override("font", hint_font)
	await _load_from_backend()
	show_category("packs")

func _session() -> Node:
	return get_node_or_null("/root/Session")

## Catalog and balance come from the backend; nothing here is trusted for purchases.
func _load_from_backend() -> void:
	var session := _session()
	if session == null:
		return
	var result: Dictionary = await session.backend.get_catalog()
	if result.get("ok", false):
		for key in catalog:
			catalog[key] = []
		for p: Dictionary in result["products"]:
			if catalog.has(p["category"]):
				(catalog[p["category"]] as Array).append(p)
	await refresh_balance()

func refresh_balance() -> void:
	var session := _session()
	if session == null:
		return
	var result: Dictionary = await session.backend.get_profile(session.account_id())
	if result.get("ok", false):
		set_balance(int(result["account"]["dp"]))

func set_balance(value: int) -> void:
	dp = value
	balance.text = _thousands(value)
	# Seven-digit balances shrink a little so they stay inside the panel.
	balance.add_theme_font_size_override("font_size", 30 if balance.text.length() <= 7 else 26)
	_update_price_states()

static func _thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out

func _texture(key: String) -> Texture2D:
	if not _textures.has(key):
		_textures[key] = load(ART + key + ".png")
	return _textures[key]

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
	if color == WHITE:
		label.add_theme_color_override("font_outline_color", Color("111923"))
		label.add_theme_constant_override("outline_size", 1)
	parent.add_child(label)
	return label

func _button(parent: Node, prefix: String, text: String, rect: Rect2, font_size: int, color: Color) -> TextureButton:
	var button := TextureButton.new()
	button.position = rect.position
	button.size = rect.size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = _texture(prefix + "_normal")
	button.texture_hover = _texture(prefix + "_hover")
	button.texture_pressed = _texture(prefix + "_pressed")
	button.texture_focused = _texture(prefix + "_hover")
	if prefix == "back":
		button.texture_disabled = _texture("back_disabled")
	parent.add_child(button)
	var label := _label(button, text, Rect2(Vector2.ZERO, rect.size), font_size, color)
	label.name = "Caption"
	button.mouse_entered.connect(func(): AudioUtil.sfx("cursor"))
	return button

func _scroll_changed(value: float) -> void:
	content.position.y = -value
	if scroll_thumb == null:
		return
	var overflow := maxf(0.0, scrollbar.max_value - scrollbar.page)
	scroll_thumb.visible = overflow > 0.0
	scroll_down.disabled = overflow <= 0.0
	scroll_down.modulate = Color.WHITE if overflow > 0.0 else Color(0.65, 0.65, 0.65)
	scroll_thumb.size.y = 40.0
	scroll_thumb.position.y = 112.0 + 312.0 * value / maxf(1.0, overflow)

func show_category(category: String) -> void:
	if not catalog.has(category):
		return
	active_category = category
	_dragging_scroll = false
	selected_index = 0
	for key: String in tabs:
		var button: TextureButton = tabs[key]
		var selected := key == category
		button.texture_normal = _texture("tab_selected" if selected else "tab_normal")
		button.texture_hover = _texture("tab_selected" if selected else "tab_hover")
		button.texture_pressed = _texture("tab_selected" if selected else "tab_pressed")
		button.texture_focused = button.texture_hover
		button.get_node("Caption").add_theme_color_override("font_color", RED if selected else INK)
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	products.clear()
	markers.clear()
	price_buttons.clear()
	var entries: Array = catalog[category]
	for i in entries.size():
		_add_product(entries[i], i)
	var rows := ceili(entries.size() / 3.0)
	if show_preview_row and category == "packs" and entries.size() == 3:
		_add_preview_row(entries)
		rows += 1
	content.size = Vector2(598, maxf(VIEW_HEIGHT, rows * ROW_HEIGHT))
	scrollbar.max_value = content.size.y
	scrollbar.page = VIEW_HEIGHT
	scrollbar.value = 0
	content.position.y = 0
	_scroll_changed(0)
	if entries.is_empty():
		_label(content, "No " + category + " available yet", Rect2(0, 145, 598, 45), 23, WHITE)
	hint.text = "Select a " + ("bundle" if category == "bundles" else category.trim_suffix("s")) if not entries.is_empty() else "Check back soon"
	_update_selection()
	_update_contents_button()
	_update_price_states()

func _pack_texture(path: String) -> Texture2D:
	if not _pack_textures.has(path):
		var original: Texture2D = load(path)
		var cropped := AtlasTexture.new()
		cropped.atlas = original
		cropped.region = original.get_image().get_used_rect()
		_pack_textures[path] = cropped
	return _pack_textures[path]

func _add_product(entry: Dictionary, index: int) -> void:
	var column := index % 3
	var row := index / 3
	var origin := Vector2(24 + column * 177, 10 + row * ROW_HEIGHT)
	var product := TextureButton.new()
	product.name = "Product" + str(index)
	product.position = origin
	product.size = Vector2(120, 220)
	product.ignore_texture_size = true
	product.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	product.texture_normal = _pack_texture(entry.art)
	product.mouse_filter = Control.MOUSE_FILTER_PASS
	product.pressed.connect(select_product.bind(index))
	product.focus_entered.connect(select_product.bind(index))
	content.add_child(product)
	products.append(product)
	_label(content, entry.name, Rect2(origin + Vector2(-20, 228), Vector2(160, 26)), 20, WHITE)
	# The price tag is the buy button (disabled when the balance is too low).
	var price := TextureButton.new()
	price.name = "Price" + str(index)
	price.position = origin + Vector2(20, 254)
	price.size = Vector2(80, 25)
	price.ignore_texture_size = true
	price.stretch_mode = TextureButton.STRETCH_SCALE
	price.texture_normal = _texture("price_normal")
	price.texture_hover = _texture("price_hover")
	price.texture_pressed = _texture("price_hover")
	price.texture_disabled = _texture("price_disabled")
	price.tooltip_text = "Buy " + str(entry.name)
	price.pressed.connect(buy.bind(index))
	price.mouse_entered.connect(func(): AudioUtil.sfx("cursor"))
	content.add_child(price)
	price_buttons.append(price)
	var price_label := _label(price, "%s DP" % _thousands(int(entry.price)) if _available(entry) else "SOON", Rect2(Vector2.ZERO, price.size), 18, RED)
	price_label.name = "Caption"
	var corners := Control.new()
	corners.position = origin
	corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(corners)
	for i in 4:
		var right := i % 2 == 1
		var bottom := i >= 2
		var marker := _image(corners, "selection_corner", Rect2(119 if right else -18, 216 if bottom else -8, 17, 18))
		marker.flip_h = right
		marker.flip_v = bottom
	markers.append(corners)

func _add_preview_row(entries: Array) -> void:
	# These are display-only stand-ins, deliberately outside the product list.
	for i in 3:
		var origin := Vector2(24 + i * 177, 10 + ROW_HEIGHT)
		var art := TextureRect.new()
		art.name = "PreviewPack" + str(i)
		art.texture = _pack_texture(entries[i].art)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position = origin
		art.size = Vector2(120, 220)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(art)
		_label(content, "PREVIEW", Rect2(origin + Vector2(-20, 228), Vector2(160, 26)), 20, WHITE)

## Products shown in the catalog but not sold yet (backend "available": false).
static func _available(entry: Dictionary) -> bool:
	return bool(entry.get("available", true))

func select_product(index: int) -> void:
	selected_index = index
	_update_selection()
	_update_contents_button()
	# Keep keyboard-focused products visible in the scrolling catalog.
	var top := floorf(index / 3.0) * ROW_HEIGHT
	if top < scrollbar.value:
		scrollbar.value = top
	elif top + 289 > scrollbar.value + VIEW_HEIGHT:
		scrollbar.value = top + 289 - VIEW_HEIGHT

func _update_price_states() -> void:
	var entries: Array = catalog.get(active_category, [])
	for i in price_buttons.size():
		var affordable: bool = i < entries.size() and entries[i].has("id") and _available(entries[i]) and int(entries[i].price) <= dp
		price_buttons[i].disabled = busy or not affordable
		price_buttons[i].get_node("Caption").modulate = Color.WHITE if affordable else Color(0.55, 0.55, 0.55)

## Asks the backend to buy the product; on success shows the cards it rolled.
func buy(index: int) -> void:
	var entries: Array = catalog.get(active_category, [])
	var session := _session()
	if busy or session == null or index >= entries.size() or not entries[index].has("id") or not _available(entries[index]):
		return
	select_product(index)
	busy = true
	_update_price_states()
	var result: Dictionary = await session.backend.purchase(session.account_id(), str(entries[index].id))
	busy = false
	last_result = result
	if result.get("ok", false):
		AudioUtil.sfx("decide")
		set_balance(int(result["balance"]))
		_show_reveal(str(entries[index].name), result["cards"], str(entries[index].art))
	else:
		AudioUtil.sfx("cancel")
		if result.has("balance"):
			set_balance(int(result["balance"]))
		hint.text = {"not_enough_dp": "Not enough DP", "set_complete": "You already own every card in this pack"}.get(result.get("error", ""), "The purchase could not be completed")
		_update_price_states()

## CARD LIST works for products that are on sale; "coming soon" ones have no list yet.
func _update_contents_button() -> void:
	if contents_button == null:
		return
	var entries: Array = catalog.get(active_category, [])
	var ok: bool = selected_index < entries.size() and entries[selected_index].has("id") and _available(entries[selected_index])
	contents_button.disabled = not ok
	contents_button.modulate = Color.WHITE if ok else Color(0.6, 0.6, 0.6)
	if selected_index < entries.size() and not _available(entries[selected_index]):
		hint.text = "Coming soon"
	elif not entries.is_empty() and hint.text == "Coming soon":
		hint.text = "Select a " + ("bundle" if active_category == "bundles" else active_category.trim_suffix("s"))

## Card list of the selected product (ui/pack_contents.gd), from the backend.
func show_contents() -> void:
	var entries: Array = catalog.get(active_category, [])
	var session := _session()
	if session == null or selected_index >= entries.size() or not entries[selected_index].has("id") or contents_view != null:
		return
	var result: Dictionary = await session.backend.get_product_contents(str(entries[selected_index].id))
	if not result.get("ok", false):
		hint.text = "The card list is not available"
		return
	AudioUtil.sfx("decide")
	var owned := Collection.load_default(session.db).counts
	contents_view = PackContents.new()
	add_child(contents_view)
	contents_view.closed.connect(close_contents)
	contents_view.show_contents(result, session.db, owned)

func close_contents() -> void:
	if contents_view != null:
		remove_child(contents_view)
		contents_view.queue_free()
		contents_view = null

## Pack opening animation (ui/pack_opening.gd). Cards the backend marks "rare" get the golden reveal.
func _show_reveal(title: String, cards: Array, art: String) -> void:
	close_reveal()
	var pulled := []
	for i in cards.size():
		var card: Dictionary = (cards[i] as Dictionary).duplicate()
		card["rare"] = bool(card.get("rare", false))
		pulled.append(card)
	var opening := PackOpening.new()
	reveal = opening
	add_child(opening)
	opening.closed.connect(close_reveal)
	opening.play(_pack_texture(art), title, pulled, _session().db)
	hint.text = "Cards added to your collection"

func close_reveal() -> void:
	if reveal != null:
		remove_child(reveal)
		reveal.queue_free()
		reveal = null

func _update_selection() -> void:
	for i in markers.size():
		markers[i].visible = i == selected_index

func _input(event: InputEvent) -> void:
	if reveal != null or contents_view != null:
		return
	if event is InputEventMouseMotion and _dragging_scroll:
		var fraction := clampf((event.position.y - _scroll_drag_offset - 112.0) / 312.0, 0.0, 1.0)
		scrollbar.value = fraction * (scrollbar.max_value - scrollbar.page)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_dragging_scroll = false
		elif scroll_thumb.visible and SCROLL_TRACK.has_point(event.position):
			if scroll_thumb.get_global_rect().has_point(event.position):
				_dragging_scroll = true
				_scroll_drag_offset = event.position.y - scroll_thumb.position.y
			else:
				scrollbar.value += scrollbar.page * (-1 if event.position.y < scroll_thumb.position.y else 1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and clip.get_global_rect().has_point(event.position):
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scrollbar.value += 70
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scrollbar.value -= 70
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if contents_view != null:
			close_contents()
		elif reveal != null:
			if reveal.done:
				close_reveal()
			else:
				reveal.skip()
		else:
			_go_back()

func _go_back() -> void:
	AudioUtil.sfx("decide")
	back.emit()
