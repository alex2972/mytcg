extends Control
## Title screen + Duel Mode submenu, laid out from the original's title.txt (positions are x,y in 800x600).

signal action(name: String)

var main_menu: PlankMenu
var duel_menu: PlankMenu
var options_button: TextureButton
var account_button: Button
var online_button: Button
var account_panel: PanelContainer
var account_list: VBoxContainer
var new_account_name: LineEdit

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
	main_menu.set_custom_row(3, "SHOP")
	main_menu.position = Vector2(200, 320)
	main_menu.chosen.connect(_on_main)
	add_child(main_menu)
	duel_menu = PlankMenu.new("menu_e_d_ani", [true, true, true, false, true])
	# Reuse the original yellow rows; omit the Duelist LV strip entirely.
	duel_menu.source_rows = [0, 1, 3, 4, 0]
	duel_menu.set_custom_row(4, "BACK", true)
	duel_menu.position = Vector2(200, 320)
	duel_menu.chosen.connect(_on_duel)
	duel_menu.visible = false
	add_child(duel_menu)
	options_button = TextureButton.new()
	options_button.name = "OptionsButton"
	options_button.texture_normal = load("res://assets/ui/title_menu/options_gear.png")
	options_button.ignore_texture_size = true
	options_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	options_button.position = Vector2(16, 16)
	options_button.size = Vector2(38, 38)
	options_button.tooltip_text = "Options"
	options_button.mouse_entered.connect(func():
		options_button.modulate = Color(1.25, 1.25, 1.25)
		CursorUtil.set_state("on"))
	options_button.mouse_exited.connect(func():
		options_button.modulate = Color.WHITE
		CursorUtil.set_state("off"))
	options_button.pressed.connect(func(): action.emit("options"))
	add_child(options_button)
	# Temporary account switcher (accounts become online logins later).
	account_button = Button.new()
	account_button.name = "AccountButton"
	account_button.position = Vector2(24, 534)
	account_button.size = Vector2(180, 36)
	account_button.clip_text = true
	account_button.pressed.connect(func():
		if _session() != null and _session().is_online():
			action.emit("online")
		else:
			toggle_accounts())
	add_child(account_button)
	# Temporary entry to online play (sign in, ranked/casual).
	online_button = Button.new()
	online_button.name = "OnlineButton"
	online_button.position = Vector2(596, 534)
	online_button.size = Vector2(180, 36)
	online_button.pressed.connect(func(): action.emit("online"))
	add_child(online_button)
	_build_account_panel()
	_update_account_button()

func _session() -> Node:
	return get_node_or_null("/root/Session")

func _update_account_button() -> void:
	var session := _session()
	account_button.visible = session != null and main_menu.visible
	online_button.visible = account_button.visible
	if session == null:
		return
	if session.is_online():
		account_button.text = "Online: " + str(session.display_name())
		online_button.text = "Play Online"
		return
	online_button.text = "Online"
	var current: String = session.account_id()
	for a in session.accounts():
		if a["id"] == current:
			account_button.text = "Account: " + str(a["name"])

func _build_account_panel() -> void:
	account_panel = PanelContainer.new()
	account_panel.name = "AccountPanel"
	account_panel.position = Vector2(24, 300)
	account_panel.custom_minimum_size = Vector2(240, 0)
	account_panel.visible = false
	add_child(account_panel)
	var box := VBoxContainer.new()
	account_panel.add_child(box)
	var title := Label.new()
	title.text = "Choose an account"
	box.add_child(title)
	account_list = VBoxContainer.new()
	box.add_child(account_list)
	var row := HBoxContainer.new()
	box.add_child(row)
	new_account_name = LineEdit.new()
	new_account_name.placeholder_text = "New account name"
	new_account_name.max_length = 16
	new_account_name.custom_minimum_size = Vector2(150, 0)
	new_account_name.text_submitted.connect(func(_t): create_account())
	row.add_child(new_account_name)
	var create := Button.new()
	create.text = "Create"
	create.pressed.connect(create_account)
	row.add_child(create)

func toggle_accounts() -> void:
	account_panel.visible = not account_panel.visible
	if not account_panel.visible:
		return
	for child in account_list.get_children():
		account_list.remove_child(child)
		child.queue_free()
	var session := _session()
	for a in session.accounts():
		var b := Button.new()
		b.text = str(a["name"]) + ("  (current)" if a["id"] == session.account_id() else "")
		b.pressed.connect(choose_account.bind(str(a["id"])))
		account_list.add_child(b)
	# The panel grows downwards; keep it above the bottom buttons.
	account_panel.reset_size()
	account_panel.position.y = 526 - account_panel.get_combined_minimum_size().y

func choose_account(id: String) -> void:
	_session().switch_account(id)
	account_panel.visible = false
	_update_account_button()

func create_account() -> void:
	var id: String = _session().create_account(new_account_name.text)
	if id == "":
		return
	new_account_name.text = ""
	account_panel.visible = false
	_update_account_button()

func _on_main(i: int) -> void:
	match i:
		0:
			main_menu.visible = false
			options_button.visible = false
			account_button.visible = false
			online_button.visible = false
			account_panel.visible = false
			duel_menu.visible = true
			CursorUtil.set_state("off")
		1: action.emit("deck")
		2: action.emit("cards")
		3: action.emit("shop")
		4: action.emit("quit")

func _on_duel(i: int) -> void:
	match i:
		0: action.emit("single_duel")
		1: action.emit("match_duel")
		2: action.emit("replay")
		4: _back_to_main()

func _back_to_main() -> void:
	duel_menu.visible = false
	main_menu.visible = true
	options_button.visible = true
	_update_account_button()
	CursorUtil.set_state("off")

func _unhandled_input(event: InputEvent) -> void:
	if duel_menu.visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_back_to_main()
	elif duel_menu.visible and event.is_action_pressed("ui_cancel"):
		_back_to_main()
		get_viewport().set_input_as_handled()
