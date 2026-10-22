extends Control
## Online sign-in: server address, name, password (may be empty), Login / Register, or back to offline play.
## When already signed in it shows the account and offers Play Online, Logout and Back.

signal back
signal play_online

var server_field: LineEdit
var name_field: LineEdit
var password_field: LineEdit
var status: Label
var form: VBoxContainer
var signed_in: VBoxContainer
var account_label: Label
var busy := false

func _session() -> Node:
	return get_node_or_null("/root/Session")

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/j/title/title_1_e.png")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(220, 150)
	panel.custom_minimum_size = Vector2(360, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	style.border_color = Color(0.75, 0.6, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "ONLINE"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	form = VBoxContainer.new()
	box.add_child(form)
	var saved: Dictionary = _session().last_online_settings() if _session() != null else {}
	server_field = _field(form, "Server", str(saved.get("url", "")) if str(saved.get("url", "")) != "" else Protocol.DEFAULT_URL)
	name_field = _field(form, "Name (3-16 letters, digits, _ - or space)", str(saved.get("name", "")))
	password_field = _field(form, "Password (optional)", "")
	password_field.secret = true
	password_field.text_submitted.connect(func(_t): _submit(false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	form.add_child(row)
	_button(row, "Login", func(): _submit(false))
	_button(row, "Register", func(): _submit(true))
	signed_in = VBoxContainer.new()
	box.add_child(signed_in)
	account_label = Label.new()
	account_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	signed_in.add_child(account_label)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	signed_in.add_child(row2)
	_button(row2, "Play Online", func(): play_online.emit())
	_button(row2, "Logout", _logout)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(340, 40)
	status.add_theme_color_override("font_color", Color("ffd27a"))
	box.add_child(status)
	_button(box, "Back (play offline)", func(): back.emit())
	_refresh()
	if _session() != null and not _session().is_online() and str(saved.get("token", "")) != "":
		status.text = "Reconnecting..."
		busy = true
		var r: Dictionary = await _session().resume_online()
		busy = false
		status.text = "" if r.get("ok", false) else ""
		_refresh()

func _field(parent: Node, label_text: String, value: String) -> LineEdit:
	var l := Label.new()
	l.text = label_text
	parent.add_child(l)
	var e := LineEdit.new()
	e.text = value
	e.custom_minimum_size = Vector2(340, 0)
	parent.add_child(e)
	return e

func _button(parent: Node, text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

func _refresh() -> void:
	var online: bool = _session() != null and _session().is_online()
	form.visible = not online
	signed_in.visible = online
	if online:
		var a: Dictionary = _session().online_account
		account_label.text = "Signed in as %s\nRating %d   W %d / L %d   %d DP" % [a.get("name", ""), int(a.get("rating", 0)), int(a.get("wins", 0)), int(a.get("losses", 0)), int(a.get("dp", 0))]

func _submit(create: bool) -> void:
	if busy or _session() == null:
		return
	busy = true
	status.text = "Connecting..."
	var r: Dictionary = await _session().go_online(server_field.text.strip_edges(), name_field.text.strip_edges(), password_field.text, create)
	busy = false
	password_field.text = ""
	status.text = "" if r.get("ok", false) else _explain(str(r.get("error", "")), r)
	_refresh()

func _logout() -> void:
	if busy:
		return
	busy = true
	await _session().logout()
	busy = false
	status.text = "Signed out."
	_refresh()

static func _explain(code: String, r: Dictionary) -> String:
	match code:
		"not_connected": return "Could not reach the server."
		"outdated_client": return "This game version does not match the server. Update the game."
		"bad_credentials": return "Wrong name or password."
		"name_taken": return "That name is taken."
		"bad_name": return "Names need 3-16 letters, digits, spaces, _ or -."
		"bad_password": return "Passwords can have at most 64 characters."
		"rate_limited": return "Too many attempts. Wait %d s." % ceili(float(r.get("retry_after", 2)))
		"timeout": return "The server did not answer."
	return "Error: " + code

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()
