class_name PlankMenu
extends Control
## One of the original's wooden-plank menus. The artwork is a 400x250 image with five 50px planks;
## frames 0..6 fade the plank text in (0 = idle, 6 = fully highlighted). Hovering a plank plays that animation.

signal chosen(index: int)

const ROW_H := 50
const FRAME_SPEED := 22.0
const LETTERING_SHADER := preload("res://ui/plank_lettering.gdshader")
const ORIGINAL_ART := preload("res://ui/plank_art.gd")
const SELECTED_PLANK_OFFSET := Vector2(0, 4)

## The board and its lettering inherit one transform, as one moving object.
class PlankBody extends Control:
	var wood: Texture2D

	func _draw() -> void:
		draw_texture(wood, Vector2.ZERO)

## Text has its own CanvasItem so the wear shader never tints the wood.
class PlankLettering extends Control:
	var text := ""
	var yellow := false
	var font: Font
	var frame := 0

	func _draw() -> void:
		var amount := clampf(float(frame) / 4.0, 0.0, 1.0)
		# The originals keep their small glyphs for frames 0..4, enlarge at 5,
		# then move the complete board and label down together in frame 6.
		var font_size := 38 if frame < 5 else 42
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var center := 20.0 if frame < 5 else 22.0
		var baseline := center + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		var pos := Vector2((400.0 - width) * 0.5, baseline)
		var idle := Color(0.37, 0.33, 0.10, 0.65) if yellow else Color(1, 1, 1, 0.45)
		var outline := Color("304b32") if yellow else Color("914600")
		outline.a = amount if yellow or frame >= 5 else 0.0
		if yellow and frame > 0:
			draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, amount * 0.7))
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 1, outline)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, idle.lerp(Color.WHITE, amount))

var frames: Array[Texture2D] = []
var rows := 5
var enabled: Array = [true, true, true, true, true]
var level: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var hover := -1
var source_rows: Array = [0, 1, 2, 3, 4]
var custom_rows: Dictionary = {}

func set_custom_row(index: int, text: String, yellow := false) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Times New Roman"] if yellow else ["Arial Black", "Arial"])
	font.font_weight = 400 if yellow else 900
	if custom_rows.has(index):
		custom_rows[index].body.queue_free()
	var art: Dictionary = ORIGINAL_ART.theme(yellow)
	var body := PlankBody.new()
	body.wood = art.wood
	body.position = Vector2(0, index * ROW_H)
	body.size = Vector2(400, 44)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lettering := PlankLettering.new()
	lettering.text = text
	lettering.yellow = yellow
	lettering.font = font
	lettering.size = Vector2(400, ROW_H)
	lettering.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ShaderMaterial.new()
	ink.shader = LETTERING_SHADER
	# The original yellow serif labels are dark ink, without the brown menu's
	# scraped white paint. Keep that distinction instead of applying wear to both.
	ink.set_shader_parameter("wear_strength", 0.0 if yellow else 1.0)
	if not yellow:
		ink.set_shader_parameter("ink_wear", art.wear)
	lettering.material = ink
	body.add_child(lettering)
	add_child(body)
	custom_rows[index] = {"text": text, "lettering": lettering, "body": body}
	queue_redraw()

func _init(prefix: String, row_enabled: Array = [true, true, true, true, true]) -> void:
	enabled = row_enabled
	for i in 7:
		frames.append(load("res://assets/j/title/%s%d.png" % [prefix, i]))
	size = Vector2(400, 250)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var i := int(event.position.y / ROW_H)
		var new_hover := i if i >= 0 and i < rows and enabled[i] else -1
		hover = new_hover
		_cursor()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var row := int(event.position.y / ROW_H)
		if row >= 0 and row < rows and enabled[row]:
			AudioUtil.sfx("decide")
			chosen.emit(row)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover = -1
		_cursor()

func _cursor() -> void:
	CursorUtil.set_state("on" if hover != -1 else "off")

func _process(delta: float) -> void:
	var changed := false
	for i in rows:
		var target := 6.0 if i == hover else 0.0
		var v: float = move_toward(level[i], target, delta * FRAME_SPEED)
		if v != level[i]:
			level[i] = v
			changed = true
			if custom_rows.has(i):
				var lettering: PlankLettering = custom_rows[i].lettering
				lettering.frame = int(round(v))
				custom_rows[i].body.position = Vector2(0, i * ROW_H) + _plank_offset(lettering.frame)
				lettering.material.set_shader_parameter("highlight", clampf(float(lettering.frame) / 4.0, 0.0, 1.0))
				lettering.queue_redraw()
	if changed:
		queue_redraw()

func _draw() -> void:
	for i in rows:
		if custom_rows.has(i):
			_draw_custom_row(i)
			continue
		var f: Texture2D = frames[int(round(level[i]))]
		draw_texture_rect_region(f, Rect2(0, i * ROW_H, 400, ROW_H), Rect2(0, int(source_rows[i]) * ROW_H, 400, ROW_H))

func _draw_custom_row(index: int) -> void:
	var frame := int(round(level[index]))
	var origin := Vector2(0, index * ROW_H)
	# Original row 3 supplies the exposed fence. The entire recovered board and
	# its lettering are drawn by one child, sharing the original translation.
	draw_texture_rect_region(frames[frame], Rect2(origin, Vector2(400, ROW_H)), Rect2(0, 150, 400, ROW_H))

static func _plank_offset(frame: int) -> Vector2:
	return SELECTED_PLANK_OFFSET if frame == 6 else Vector2.ZERO
