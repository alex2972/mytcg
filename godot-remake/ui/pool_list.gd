class_name PoolList
extends Control
## The collection strip on the right of Deck Construction, one 62px row per card you own, like the original:
##  - thumbnail (dimmed when every copy you own is already in the deck)
##  - red 1 / 2 badge top-left for Limited / Semi-Limited cards (forbidden = crossed circle)
##  - small cream number bottom-right = spare copies (owned, not in the deck)
##  - ATK over DEF in sky-blue digits to the right
## Rows are drawn on demand. `scroll` is measured in rows; the owner draws the red double-arrow scroll thumb.

signal picked(card_index: int)
signal hovered(card_index: int)
signal scrolled(ratio: float)

const ROW_H := 55.0          # the separator stripes baked into kaban.png repeat every 55px

var db: CardDB
var rows: Array = []
var used := {}                 # card index -> copies in the deck
var owned := {}                # card index -> copies owned
var scroll := 0.0              # in rows
var hover_row := -1
var thumbs := {}
var _tex_cache := {}

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_rows(r: Array) -> void:
	rows = r
	scroll = 0.0
	scrolled.emit(0.0)
	queue_redraw()

func set_counts(owned_counts: Dictionary, used_counts: Dictionary) -> void:
	owned = owned_counts
	used = used_counts
	queue_redraw()

func max_scroll() -> float:
	return maxf(0.0, rows.size() - size.y / ROW_H)

func ratio() -> float:
	var m := max_scroll()
	return 0.0 if m <= 0.0 else scroll / m

func set_ratio(r: float) -> void:
	scroll = clampf(r, 0.0, 1.0) * max_scroll()
	hover_row = -1
	queue_redraw()

func _visible_rows() -> int:
	return int(ceil(size.y / ROW_H)) + 1

func _t(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]

func _thumb(card: int) -> Texture2D:
	if not thumbs.has(card):
		var p := db.art_path(card, true)
		thumbs[card] = load(p) if p != "" and ResourceLoader.exists(p) else load("res://assets/ui/card_back_mini.png")
	return thumbs[card]

func _draw() -> void:
	var digits := _t("res://assets/j/deck_c/font/font_k_kousyu.png")
	var small := _t("res://assets/j/deck_c/font/font_small.png")
	var seigen := _t("res://assets/j/deck_c/icon/icon_seigen.png")
	var first := int(floor(scroll))
	var off := -(scroll - first) * ROW_H
	for k in _visible_rows():
		var r := first + k
		if r >= rows.size():
			break
		var card: int = rows[r]
		var y := off + k * ROW_H
		var spare: int = int(owned.get(card, 0)) - int(used.get(card, 0))
		var tint := Color.WHITE if spare > 0 else Color(0.45, 0.45, 0.5, 1.0)
		draw_texture_rect(_thumb(card), Rect2(5, y, 38, 55), false, tint)
		# limit badge
		var lim := DeckRules.copy_limit(db, card)
		if lim < DeckRules.MAX_COPIES and seigen != null:
			draw_texture_rect_region(seigen, Rect2(0, y + 2, 16, 16), Rect2(16 * (0 if lim == 0 else lim), 0, 16, 16))
		# spare copies, bottom-right of the thumbnail
		if spare > 0 and small != null:
			DigitFont.draw_number(self, small, str(spare), Vector2(46, y + 41), 9, 14, "right")
		if db.is_monster(card) and digits != null:
			var c := db.card(card)
			_draw_sky(digits, str(int(c.atk)), Vector2(84, y + 10))
			_draw_sky(digits, str(int(c.def)), Vector2(84, y + 29))
		if r == hover_row:
			draw_rect(Rect2(2, y + 1, size.x - 4, ROW_H - 2), Color(1, 1, 1, 0.14))

## Sky-blue digits: font_k_kousyu has 10 glyphs on a 6px grid (5px wide glyph + 1px gap).
func _draw_sky(tex: Texture2D, text: String, right_top: Vector2) -> void:
	var x := right_top.x - 6.0 * text.length()
	for ch in text:
		var d := "0123456789".find(ch)
		if d >= 0:
			draw_texture_rect_region(tex, Rect2(x, right_top.y, 6, 15), Rect2(6 * d, 0, 6, 15))
		x += 6.0

func _row_at(pos: Vector2) -> int:
	var r := int(floor(scroll + pos.y / ROW_H))
	return r if r >= 0 and r < rows.size() else -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var r := _row_at(event.position)
		if r != hover_row:
			hover_row = r
			CursorUtil.set_state("on" if r != -1 else "off")
			if r != -1:
				hovered.emit(rows[r])
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN: _scroll_by(3)
			MOUSE_BUTTON_WHEEL_UP: _scroll_by(-3)
			MOUSE_BUTTON_LEFT:
				var r := _row_at(event.position)
				if r != -1:
					picked.emit(rows[r])

func scroll_by_pixels(px: float) -> void:
	_scroll_by(px / ROW_H)

func _scroll_by(rows_delta: float) -> void:
	scroll = clampf(scroll + rows_delta, 0.0, max_scroll())
	hover_row = -1
	scrolled.emit(ratio())
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_row = -1
		CursorUtil.set_state("off")
		queue_redraw()
