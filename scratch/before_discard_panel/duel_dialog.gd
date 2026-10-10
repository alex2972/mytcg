class_name DuelDialog
extends Control
## The original's modal question panel (j/duel/dialog): steel frame over a city-skyline picture, message text on the
## right, brush-stroke YES / NO or OK button. While it is open nothing else can be clicked (the game "stops").
## Geometry: native 412px art; the bottom sprite overlaps the skyline by its 22px open inset.
## button centres are offsets from (dialog centre x, inner bottom y): ok (0,-21), yes (-64,-19), no (64,-22).

signal answered(value: bool)

const SCALE := 1.0
const BASE_W := 412.0
const TOP_H := 36.0
const BOTTOM_H := 63.0
const BOTTOM_INSET := 22.0
const CENTER := Vector2(524, 305)
const TEXT_X := 82.0

var message := ""
var kind := "yesno"                  # "yesno" or "ok"
var body_h := 100.0
var hover := ""                      # "yes" / "no" / "ok"
var lang := "e"
var panel := Control.new()
var label := Label.new()
var tex_cache := {}
var done := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(800, 600)
	z_index = 150

func _t(tex_name: String) -> Texture2D:
	if not tex_cache.has(tex_name):
		tex_cache[tex_name] = load("res://assets/j/duel/dialog/%s.png" % tex_name)
	return tex_cache[tex_name]

## Plain text of a game string: colour codes removed, line breaks kept.
static func clean(text: String) -> String:
	var re := RegEx.new()
	re.compile("@[0-9]")
	return re.sub(text, "", true)

func setup(text: String, dialog_kind: String) -> void:
	message = clean(text)
	kind = dialog_kind

func _ready() -> void:
	# Measure wrapped text, reserving room below it for the brush-stroke buttons.
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial"])
	font.font_weight = 700
	label.add_theme_font_override("font", font)
	var text_size := font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT,
		BASE_W - TEXT_X - 22.0, 14, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
	body_h = maxf(92.0, text_size.y + 48.0)
	panel.size = Vector2(BASE_W, TOP_H + body_h + BOTTOM_H - BOTTOM_INSET)
	panel.scale = Vector2(SCALE, SCALE)
	panel.pivot_offset = Vector2.ZERO
	panel.position = CENTER - panel.size * SCALE / 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.draw.connect(_draw_panel)
	add_child(panel)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	label.position = Vector2(TEXT_X, TOP_H + 4.0)
	label.size = Vector2(BASE_W - TEXT_X - 22.0, body_h - 40.0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	mouse_entered.connect(func(): CursorUtil.set_state("off"))
	gui_input.connect(_on_input)

func _buttons() -> Dictionary:
	var inner_bottom := TOP_H + body_h
	var out := {}
	if kind == "ok":
		out["ok"] = Vector2(BASE_W / 2.0, inner_bottom - 21.0)
	else:
		out["yes"] = Vector2(BASE_W / 2.0 - 64.0, inner_bottom - 19.0)
		out["no"] = Vector2(BASE_W / 2.0 + 64.0, inner_bottom - 22.0)
	return out

func _draw_panel() -> void:
	var base := _t("dial_base")
	var bott := _t("dial_bott")
	panel.draw_texture_rect_region(base, Rect2(0, 0, BASE_W, TOP_H + body_h), Rect2(0, 0, BASE_W, TOP_H + body_h))
	panel.draw_texture_rect(bott, Rect2(0, TOP_H + body_h - BOTTOM_INSET, BASE_W, BOTTOM_H), false)
	var b := _buttons()
	for key in b:
		var tex := _t("%s_%s_%s" % [key, lang, "over" if hover == key else "out"])
		if tex != null:
			panel.draw_texture(tex, b[key] - tex.get_size() / 2.0)

func _button_at(local: Vector2) -> String:
	var b := _buttons()
	for key in b:
		var tex := _t("%s_%s_out" % [key, lang])
		if tex != null and Rect2(b[key] - tex.get_size() / 2.0, tex.get_size()).has_point(local):
			return key
	return ""

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var key := _button_at((event.position - panel.position) / SCALE)
		if key != hover:
			hover = key
			CursorUtil.set_state("on" if key != "" else "off")
			if key != "":
				AudioUtil.sfx("cursor")
			panel.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not done:
		var key := _button_at((event.position - panel.position) / SCALE)
		if key != "":
			_finish(key != "no")

func _finish(value: bool) -> void:
	if done:
		return
	done = true
	hide()
	AudioUtil.sfx("decide")
	CursorUtil.set_state("off")
	answered.emit(value)
	queue_free()
