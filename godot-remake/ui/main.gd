extends Control
## Game shell: owns the current screen and the transitions between screens.

var current: Control
var back_button := Button.new()

func _ready() -> void:
	back_button.text = "< Back"
	back_button.pressed.connect(show_title)
	back_button.z_index = 50
	back_button.position = Vector2(700, 4)
	add_child(back_button)
	show_title()

func _set_screen(screen: Control, with_back := false, music := "") -> void:
	if music != "":
		AudioUtil.music(music)
	AudioUtil.sfx("scene_change")
	if current != null:
		current.queue_free()
	current = screen
	add_child(screen)
	move_child(screen, 0)
	back_button.visible = with_back
	CursorUtil.set_state("off")

func show_title() -> void:
	var t: Control = load("res://ui/title_screen.gd").new()
	t.action.connect(_on_title_action)
	_set_screen(t, false, "m_title")

func _page(script_path: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.set_script(load(script_path))
	return c

func _on_title_action(action: String) -> void:
	match action:
		"deck":
			var editor := _page("res://ui/deck_editor.gd")
			editor.back.connect(show_title)
			_set_screen(editor, false, "m_kaban")
		"cards":
			var list := _page("res://ui/card_list.gd")
			list.back.connect(show_title)
			_set_screen(list, false, "m_kaban")
		"single_duel", "match_duel": _set_screen(_page("res://ui/duel_setup.gd"), true, "m_menu")
		"quit": get_tree().quit()
		_: pass   # options / replay: not built yet
