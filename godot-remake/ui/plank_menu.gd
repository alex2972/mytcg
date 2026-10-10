class_name PlankMenu
extends Control
## One of the original's wooden-plank menus. The artwork is a 400x250 image with five 50px planks;
## frames 0..6 fade the plank text in (0 = idle, 6 = fully highlighted). Hovering a plank plays that animation.

signal chosen(index: int)

const ROW_H := 50
const FRAME_SPEED := 22.0

var frames: Array[Texture2D] = []
var rows := 5
var enabled: Array = [true, true, true, true, true]
var level: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var hover := -1

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
		if new_hover != hover and new_hover != -1:
			AudioUtil.sfx("cursor")
		hover = new_hover
		_cursor()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover != -1:
			AudioUtil.sfx("decide")
			chosen.emit(hover)

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
	if changed:
		queue_redraw()

func _draw() -> void:
	for i in rows:
		var f: Texture2D = frames[int(round(level[i]))]
		draw_texture_rect_region(f, Rect2(0, i * ROW_H, 400, ROW_H), Rect2(0, i * ROW_H, 400, ROW_H))
