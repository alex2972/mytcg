extends Control
## An online duel from the player's side: the original rock-paper-scissors screen (decided by the server),
## then the duel board on a RemoteDuel, an opponent/timer strip, and the result with rating and DP.
## `room` comes from the lobby ({"room_id", "opponent", "mode"}) and `early` holds pushes that arrived
## before this screen existed.

signal finished

var room := {}
var early: Array = []
var remote: RemoteDuel
var board: DuelBoard
var janken: JankenScreen
var result := {}
var strip: Label
var _janken_done := false
var _order_known := false
var _board_left := false

func _session() -> Node:
	return get_node_or_null("/root/Session")

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	size = Vector2(800, 600)
	var session := _session()
	remote = RemoteDuel.make(session.db, session.online, str(room.get("room_id", "")))
	session.online.pushed.connect(_on_push)
	remote.result_received.connect(_on_result)
	if str(room.get("state", "janken")) == "playing" or str(room.get("state", "")) == "finished":
		# Resuming a running duel (reconnect): straight to the board.
		_order_known = true
		for p in early:
			_on_push(p[0], p[1])
		early.clear()
		_on_janken_finished(true)
		_build_strip()
		return
	AudioUtil.music("m_jyank")
	janken = JankenScreen.new(0)
	janken.remote = true
	janken.picked.connect(func(hand): remote._send("janken_pick", {"hand": hand}))
	janken.order_picked.connect(func(first): remote._send("choose_order", {"first": first}))
	janken.finished.connect(_on_janken_finished)
	add_child(janken)
	_build_strip()
	for p in early:
		_on_push(p[0], p[1])
	early.clear()

func _build_strip() -> void:
	strip = Label.new()
	strip.position = Vector2(560, 2)
	strip.size = Vector2(236, 20)
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	strip.add_theme_font_size_override("font_size", 13)
	strip.add_theme_color_override("font_color", Color(1, 1, 1))
	strip.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	strip.add_theme_constant_override("outline_size", 4)
	strip.z_index = 200
	add_child(strip)
	var opp: Dictionary = room.get("opponent", {})
	strip.text = "vs %s%s" % [opp.get("name", "?"), "" if opp.get("bot", false) else "  (%d)" % int(opp.get("rating", 0))]

func _on_push(kind: String, payload: Dictionary) -> void:
	if str(payload.get("room_id", "")) != str(room.get("room_id", "")):
		return
	match kind:
		"room_janken":
			if payload.get("tie", false) or payload.get("phase", "") == "order":
				var picks: Array = payload.get("picks", [0, 0])
				if janken != null:
					janken.remote_result(int(picks[0]), int(picks[1]))
		"room_batch":
			if not _order_known and not payload.get("state", {}).is_empty():
				_order_known = true
				if janken != null:
					janken.remote_order(int(payload["state"].get("turn_player", 0)) == 0)
			remote.receive_batch(payload)
		"room_result":
			remote.receive_result(payload)
		"room_start":
			var opp: Dictionary = payload.get("opponent", {})
			if strip != null:
				strip.text = "vs %s%s" % [opp.get("name", "?"), "" if opp.get("bot", false) else "  (%d)" % int(opp.get("rating", 0))]

func _on_janken_finished(_human_first: bool) -> void:
	_janken_done = true
	while not remote.has_state():
		await get_tree().process_frame
	if janken != null:
		janken.queue_free()
		janken = null
	board = DuelBoard.new(_session().db, Deck.new(), Deck.new(), 0, 0, remote)
	board.match_game = 1 if str(room.get("mode", "")) == "ranked" else 0
	board.left.connect(_on_board_left)
	add_child(board)
	move_child(board, 0)

func _on_board_left() -> void:
	_board_left = true
	if not result.is_empty():
		_show_result()
	elif remote.winner == -1:
		# Leaving a running duel is a surrender.
		remote.surrender(0)

func _on_result(r: Dictionary) -> void:
	result = r
	if _board_left or board == null:
		_show_result()

func _process(_delta: float) -> void:
	if remote == null or strip == null:
		return
	var opp: Dictionary = room.get("opponent", {})
	var who := ""
	if remote.has_state() and remote.winner == -1:
		who = "  ·  your move" if (remote.fx.pending.get("player", -1) == 0 or (remote.fx.pending.is_empty() and remote.turn_player == 0)) else "  ·  opponent's move"
	strip.text = "vs %s%s%s" % [opp.get("name", "?"), "" if opp.get("bot", false) else "  (%d)" % int(opp.get("rating", 0)), who]

## Win/lose, reason, rating change and DP reward, then back to the lobby.
func _show_result() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(230, 200)
	panel.custom_minimum_size = Vector2(340, 0)
	panel.z_index = 300
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	style.border_color = Color(0.75, 0.6, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "DRAW" if result.get("draw", false) else ("YOU WIN" if result.get("you_won", false) else "YOU LOSE")
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var lines := []
	lines.append("Reason: %s   Turns: %d" % [str(result.get("reason", "")).replace("_", " "), int(result.get("turns", 0))])
	if result.has("rating_after"):
		var delta := int(result.get("rating_delta", 0))
		lines.append("Rating %d -> %d (%s%d)" % [int(result.get("rating_before", 0)), int(result.get("rating_after", 0)), "+" if delta >= 0 else "", delta])
	if int(result.get("dp_reward", 0)) > 0:
		lines.append("+%d DP" % int(result.get("dp_reward", 0)))
	var info := Label.new()
	info.text = "\n".join(PackedStringArray(lines))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var ok := Button.new()
	ok.text = "Back to the lobby"
	ok.pressed.connect(func():
		await _session().refresh_online_account()
		finished.emit())
	box.add_child(ok)

func _exit_tree() -> void:
	if remote != null:
		remote.dispose()
	var session := _session()
	if session != null and session.online != null and session.online.pushed.is_connected(_on_push):
		session.online.pushed.disconnect(_on_push)
