extends Control
## Title screen + Duel Mode submenu, laid out from the original's title.txt (positions are x,y in 800x600).

signal action(name: String)

var main_menu: PlankMenu
var duel_menu: PlankMenu

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/j/title/title_1_e.png")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/j/title/joey_logo.png")
	logo.position = Vector2(120, 10)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	main_menu = PlankMenu.new("menu_e_ani")
	main_menu.position = Vector2(200, 320)
	main_menu.chosen.connect(_on_main)
	add_child(main_menu)
	duel_menu = PlankMenu.new("menu_e_d_ani", [true, true, false, true, false])
	duel_menu.position = Vector2(200, 320)
	duel_menu.chosen.connect(_on_duel)
	duel_menu.visible = false
	add_child(duel_menu)

func _on_main(i: int) -> void:
	match i:
		0:
			main_menu.visible = false
			duel_menu.visible = true
			CursorUtil.set_state("off")
		1: action.emit("deck")
		2: action.emit("cards")
		3: action.emit("options")
		4: action.emit("quit")

func _on_duel(i: int) -> void:
	match i:
		0: action.emit("single_duel")
		1: action.emit("match_duel")
		3: action.emit("replay")

func _unhandled_input(event: InputEvent) -> void:
	if duel_menu.visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		duel_menu.visible = false
		main_menu.visible = true
		CursorUtil.set_state("off")
