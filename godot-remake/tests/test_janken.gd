extends SceneTree
## Janken logic + flow into the duel (no mouse needed: drives the same handlers).

var fails := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func _init() -> void:
	var j := JankenScreen.new(11)
	root.add_child(j)
	await process_frame
	check(j.phase == JankenScreen.Phase.SELECT, "starts at hand selection")
	var seen := {}
	var outcome := ""
	var got_first := []
	j.finished.connect(func(h): got_first.append(h))
	# play until the flow finishes (draws repeat)
	var guard := 0
	while got_first.is_empty() and guard < 20:
		guard += 1
		if j.phase == JankenScreen.Phase.SELECT:
			j._choose("gu")
		elif j.phase == JankenScreen.Phase.ORDER and j.human_won:
			j._on_order_input(_click(), 0)
		await create_timer(0.7).timeout
		if j.phase == JankenScreen.Phase.RESULT:
			await create_timer(1.6).timeout
		if j.phase == JankenScreen.Phase.ORDER and not j.human_won:
			await create_timer(2.2).timeout
	check(got_first.size() == 1, "janken finishes exactly once (iterations %d)" % guard)
	# rule table
	for h in ["gu", "cyo", "pa"]:
		check(JankenScreen.BEATS[JankenScreen.BEATS[JankenScreen.BEATS[h]]] == h, "beats cycle for " + h)
	# duel setup flow with janken skipped
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	setup.start(3, "cpu_000", "cpu_010", true)
	check(setup.board != null and setup.board.duel.turn_player == 0, "duel starts with the human first when janken is skipped")
	setup.board.queue_free()
	var setup2 = load("res://ui/duel_setup.gd").new()
	root.add_child(setup2)
	await process_frame
	setup2._start_board(setup2._deck_from_preset("cpu_000"), setup2._deck_from_preset("cpu_010"), 3, false)
	check(setup2.board.duel.turn_player == 1, "second to go: the opponent takes turn 1")
	print("janken tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e
