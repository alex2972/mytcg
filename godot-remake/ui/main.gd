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
	_set_screen(t, false, "m_menu")

## Sign-in screen, or the online lobby when already signed in.
func show_online(force_login := false) -> void:
	var session := get_node_or_null("/root/Session")
	if session != null and session.is_online() and not force_login and ResourceLoader.exists("res://client/online_lobby.gd"):
		var lobby := _page("res://client/online_lobby.gd")
		lobby.back.connect(show_title)
		lobby.connect("account", func(): show_online(true))
		lobby.connect("start_duel", _on_online_duel)
		_set_screen(lobby, false, "m_menu")
		return
	var login := _page("res://client/login_screen.gd")
	login.back.connect(show_title)
	login.play_online.connect(func(): show_online())
	_set_screen(login, false, "m_menu")

## The lobby found a match: the online duel screen takes over until the duel ends.
func _on_online_duel(room: Dictionary) -> void:
	var screen := _page("res://client/online_duel_screen.gd")
	screen.set("room", room)
	screen.connect("finished", func(): show_online())
	_set_screen(screen, false, "")

func _page(script_path: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.set_script(load(script_path))
	return c

func _on_title_action(action: String) -> void:
	match action:
		"shop":
			var shop := _page("res://ui/shop.gd")
			shop.back.connect(show_title)
			_set_screen(shop, false, "m_kaban")
		"deck":
			var editor := _page("res://ui/deck_editor.gd")
			editor.back.connect(show_title)
			_set_screen(editor, false, "m_kaban")
		"cards":
			var list := _page("res://ui/card_list.gd")
			list.back.connect(show_title)
			_set_screen(list, false, "m_kaban")
		"single_duel", "match_duel":
			var setup := _page("res://ui/duel_setup.gd")
			setup.set("match_mode", action == "match_duel")
			_set_screen(setup, true, "m_menu")
		"online":
			show_online()
		"quit": get_tree().quit()
		_: pass   # options / replay: not built yet
