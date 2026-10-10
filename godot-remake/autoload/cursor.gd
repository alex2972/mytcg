extends CanvasLayer
## The original's hand cursor. States: "off", "on" (over something clickable), or an action bubble
## ("summon", "set", "atk", "flip", "act", "over", "draw", "setatk", "setdef", "surrender").

const HOTSPOTS := {"press": Vector2(6, 11), "surrender": Vector2(43, 15), "ssummon_a": Vector2(7, 30), "ssummon_d": Vector2(7, 30)}
const DEFAULT_HOTSPOT := Vector2(7, 14)

var rect := TextureRect.new()
var textures := {}
var state := "off"
var lang := "e"
const RIPPLE_TIME := 0.4
var ripples: Array = []
var _pressed := false
var ripple_layer := Control.new()

func _ready() -> void:
	layer = 128
	ripple_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple_layer.size = Vector2(4096, 4096)
	ripple_layer.draw.connect(_draw_ripples)
	add_child(ripple_layer)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(64, 64)
	add_child(rect)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	set_state("off")

func _tex(s: String) -> Texture2D:
	if not textures.has(s):
		var path := "res://assets/cursor/cursor0%d.png" % (1 if s == "press" else 0)
		if s != "off" and s != "on" and s != "press":
			path = "res://assets/cursor/cursor_%s_%s.png" % [lang, s]
			if not ResourceLoader.exists(path):
				path = "res://assets/cursor/cursor_%s.png" % s
		textures[s] = load(path) if ResourceLoader.exists(path) else null
	return textures[s]

func set_state(s: String) -> void:
	state = s
	rect.texture = _tex("press" if _pressed and (s == "off" or s == "on") else s)
	rect.size = rect.texture.get_size() if rect.texture else Vector2(64, 64)

## The original's hand does a little "press" (cursor01) while the left button is held.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if state == "off" or state == "on":
			rect.texture = _tex("press" if event.pressed else state)
			_pressed = event.pressed
		if event.pressed:
			ripples.append({"pos": get_viewport().get_mouse_position(), "t": 0.0})

func _draw_ripples() -> void:
	for r in ripples:
		var k: float = r["t"] / RIPPLE_TIME
		var radius := 4.0 + 22.0 * k
		var a := 0.45 * (1.0 - k)
		ripple_layer.draw_circle(r["pos"], radius, Color(1, 1, 1, a * 0.35))
		ripple_layer.draw_arc(r["pos"], radius, 0.0, TAU, 32, Color(1, 1, 1, a), 2.0, true)

func _process(delta: float) -> void:
	var hot: Vector2 = HOTSPOTS.get("press" if _pressed and (state == "off" or state == "on") else state, DEFAULT_HOTSPOT)
	rect.position = get_viewport().get_mouse_position() - hot
	if not ripples.is_empty():
		for r in ripples:
			r["t"] += delta
		ripples = ripples.filter(func(r): return r["t"] < RIPPLE_TIME)
		ripple_layer.queue_redraw()
	rect.visible = DisplayServer.window_is_focused() or true
