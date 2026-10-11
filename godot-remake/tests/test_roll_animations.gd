extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 4)
	board.ai_delay = 0.0
	board.ai_running = true
	root.add_child(board)
	await process_frame
	board.fx_enabled = true
	board.duel.fx.presentation_enabled = true
	var d: Duel = board.duel
	var source: DCard = d.side(0).hand[0]
	for op in ["dice", "coin", "coins"]:
		var before := d.side(1).lp
		var ctx := {"src": source, "controller": 0, "vars": {}, "event": {}}
		d.fx.push_script([{"op": op, "n": 3, "heads": [{"op": "damage", "amount": 75}], "tails": [{"op": "damage", "amount": 75}]}, {"op": "damage", "amount": 100}], ctx)
		d.fx.pump()
		check(d.fx.pending.get("type", "") == "presentation", "roll pauses subsequent effect operations")
		check(d.side(1).lp == before, "damage waits for the displayed roll")
		check(d.respond(false) != "", "premature animation acknowledgement rejected")
		if op == "coins":
			var event: Dictionary = d.events.back()
			check(event["outcomes"].size() == 3, "all three coin faces recorded")
			check(event["outcomes"].count(true) == int(event["heads"]), "visual coin faces match effect's success count")
		var displayed := []
		var observer := func(kind: String, results: Array):
			displayed.append({"kind": kind, "results": results})
			check(d.side(1).lp == before, "effect is still paused when final face is revealed")
		board.fx.result_shown.connect(observer)
		await board._after_action()
		board.fx.result_shown.disconnect(observer)
		check(displayed.size() == 1, "one result reveal per roll operation")
		check(d.fx.pending.is_empty(), "board resumes effect after animation")
		check(d.side(1).lp == before - (175 if op == "coin" else 100), "effect resolves exactly once")
		await process_frame
		check(board.fx.get_node_or_null("CoinToss") == null and board.fx.get_node_or_null("DiceRoll") == null, "roll sprites cleaned up")
	for face in range(1, 7):
		var texture := board.fx.tex("effect/dice_decide%d" % face)
		check(texture != null and texture.get_size() == Vector2(32, 35), "original dice face %d loads" % face)
	check(board.fx.coin_face(true).region.position.x != board.fx.coin_face(false).region.position.x, "coin outcomes use distinct atlas faces")
	# Animation skipping also releases a barrier without changing the sampled result.
	board.fx_enabled = false
	d.fx.push_script([{"op": "dice"}, {"op": "damage", "amount": 10}], {"src": source, "controller": 1, "vars": {}, "event": {}})
	d.fx.pump()
	await board._after_action()
	check(d.fx.pending.is_empty(), "AI-owned roll barrier also resumes with animations disabled")
	board.queue_free()
	await process_frame
	print("roll animation tests: ", "OK" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures else 0)
