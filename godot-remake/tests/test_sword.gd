extends SceneTree
## The attack sword stays on its monster and turns toward the mouse; it never drifts.

var fails := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func _init() -> void:
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.duel.no_first_turn_attack = false
	root.add_child(board)
	await process_frame
	var d := board.duel
	var idx := 0
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Armored Starfish": idx = i
	var mine := d.debug_place(0, idx, 2)
	var foe := d.debug_place(1, idx, 2)
	board._sync(false)
	d.to_battle(0)
	board._update_ui()
	check(board.idle_swords.has(mine.uid), "a monster that can attack carries a sword")
	check(not board.idle_swords.has(foe.uid), "the opponent's monsters do not")
	board._card_action(mine)
	check(board.active_sword != null and board.mode == DuelBoard.Mode.ATTACK_TARGET, "clicking takes the sword")
	var anchor := board.sword_anchor
	var centre: Vector2 = board.active_sword.position + board.active_sword.size / 2.0
	check(centre.is_equal_approx(anchor), "the sword is centred on its monster")
	# point at a spot straight to the right of the anchor: the tip (which points up at rotation 0) must turn +90 degrees
	board.active_sword.rotation = ((anchor + Vector2(100, 0)) - anchor).angle() + PI / 2.0
	check(absf(board.active_sword.rotation - PI / 2.0) < 0.001, "pointing right = tip turned 90 deg clockwise from straight up (angle %f)" % board.active_sword.rotation)
	for k in 5:
		board.active_sword.rotation += 0.3
		var c2: Vector2 = board.active_sword.position + board.active_sword.size / 2.0
		check(c2.is_equal_approx(anchor), "rotating never moves the sword's centre")
	board._cancel_mode()
	check(board.active_sword == null, "right-click puts it away")
	print("sword tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
