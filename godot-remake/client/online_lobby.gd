extends Control
## The online lobby: your rating/record/DP, Ranked / Casual / Practice vs CPU, the search status with
## Cancel, and the Top 100. A "room_start" push (a match was found, or a duel to resume after a reconnect)
## hands over to the online duel screen through `start_duel`.

signal back
signal account
signal start_duel(room: Dictionary)

var info: Label
var status: Label
var buttons: Array[Button] = []
var cancel_button: Button
var board_list: ItemList
var searching := ""
var search_started := 0.0
var _handed_over := false

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
	var left := _panel(Vector2(40, 60), Vector2(330, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	left.add_child(box)
	var title := Label.new()
	title.text = "PLAY ONLINE"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	buttons.append(_button(box, "Ranked Duel", func(): _join("ranked")))
	buttons.append(_button(box, "Casual Duel", func(): _join("casual")))
	buttons.append(_button(box, "Practice vs CPU", func(): _join("practice")))
	cancel_button = _button(box, "Cancel search", _cancel)
	cancel_button.visible = false
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(300, 48)
	status.add_theme_color_override("font_color", Color("ffd27a"))
	box.add_child(status)
	buttons.append(_button(box, "Account", func(): account.emit()))
	buttons.append(_button(box, "Back", func(): back.emit()))
	var right := _panel(Vector2(400, 60), Vector2(360, 0))
	var rbox := VBoxContainer.new()
	right.add_child(rbox)
	var lt := Label.new()
	lt.text = "TOP 100"
	lt.add_theme_font_size_override("font_size", 22)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rbox.add_child(lt)
	board_list = ItemList.new()
	board_list.custom_minimum_size = Vector2(340, 400)
	rbox.add_child(board_list)
	var session := _session()
	if session != null and session.online != null:
		session.online.pushed.connect(_on_push)
		session.online.disconnected.connect(_on_disconnected)
	_refresh_info()
	await _refresh_account()
	await _refresh_leaderboard()
	if session != null and session.is_online():
		# Back from a duel or after a reconnect: if a duel is still running, rejoin it.
		session.online.send("room_rejoin")

func _panel(pos: Vector2, min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = min_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	style.border_color = Color(0.75, 0.6, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _button(parent: Node, text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 34)
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

func _refresh_info() -> void:
	var a: Dictionary = _session().online_account if _session() != null else {}
	info.text = "%s\nRating %d   (best %d)\nW %d  /  L %d  /  D %d   ·   %d DP" % [a.get("name", ""), int(a.get("rating", 0)), int(a.get("best_rating", 0)),
		int(a.get("wins", 0)), int(a.get("losses", 0)), int(a.get("draws", 0)), int(a.get("dp", 0))]

func _refresh_account() -> void:
	if _session() == null or not _session().is_online():
		return
	await _session().refresh_online_account()
	if is_inside_tree():
		_refresh_info()
		var r: Dictionary = await _session().online.request("my_rank")
		if r.get("ok", false) and int(r.get("rank", 0)) > 0 and is_inside_tree():
			info.text += "\nRank #%d of %d" % [int(r["rank"]), int(r["total"])]

func _refresh_leaderboard() -> void:
	if _session() == null or not _session().is_online():
		return
	var r: Dictionary = await _session().online.request("leaderboard", {"limit": 100, "offset": 0})
	if not is_inside_tree():
		return
	board_list.clear()
	if not r.get("ok", false):
		board_list.add_item("(leaderboard unavailable)")
		return
	if r["rows"].is_empty():
		board_list.add_item("No ranked duels yet. Be the first!")
	for row in r["rows"]:
		board_list.add_item("#%-3d %-16s %5d   %d-%d" % [int(row["rank"]), row["name"], int(row["rating"]), int(row["wins"]), int(row["losses"])])

func _join(mode: String) -> void:
	if searching != "":
		return
	status.text = "Joining..."
	var r: Dictionary = await _session().online.request("queue_join", {"mode": mode})
	if not is_inside_tree():
		return
	if not r.get("ok", false):
		status.text = _explain(r)
		return
	if mode == "practice":
		status.text = "Starting a duel against the CPU..."
		return
	searching = mode
	search_started = Time.get_unix_time_from_system()
	_set_searching(true)

func _cancel() -> void:
	await _session().online.request("queue_leave")
	searching = ""
	if is_inside_tree():
		_set_searching(false)
		status.text = "Search cancelled."

func _set_searching(on: bool) -> void:
	for b in buttons:
		b.disabled = on and b.text != "Back" and b.text != "Account"
	cancel_button.visible = on

func _process(_delta: float) -> void:
	if searching != "":
		var waited := int(Time.get_unix_time_from_system() - search_started)
		status.text = "Searching for a %s duel...  %d:%02d" % [searching, waited / 60, waited % 60]

func _on_push(kind: String, payload: Dictionary) -> void:
	if kind == "room_start" and not _handed_over:
		_handed_over = true
		searching = ""
		start_duel.emit(payload)
	elif kind == "kicked":
		status.text = "Disconnected: %s" % payload.get("reason", "")

func _on_disconnected() -> void:
	if not is_inside_tree():
		return
	searching = ""
	_set_searching(false)
	status.text = "Connection lost. Reconnecting..."
	var r: Dictionary = await _session().resume_online()
	if is_inside_tree():
		status.text = "Reconnected." if r.get("ok", false) else "Could not reconnect: %s" % r.get("error", "")
		_refresh_info()

static func _explain(r: Dictionary) -> String:
	match str(r.get("error", "")):
		"deck_invalid": return "Your deck can't be used: %s" % r.get("reason", "")
		"already_in_duel": return "You are already in a duel."
		"in_queue": return "You are already searching."
		"not_connected", "timeout": return "The server is not answering."
	return "Error: %s" % r.get("error", "")

func _exit_tree() -> void:
	var session := _session()
	if session != null and session.online != null:
		if session.online.pushed.is_connected(_on_push):
			session.online.pushed.disconnect(_on_push)
		if session.online.disconnected.is_connected(_on_disconnected):
			session.online.disconnected.disconnect(_on_disconnected)
