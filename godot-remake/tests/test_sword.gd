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
	var other := d.debug_place(0, idx, 3)
	board._sync(false)
	d.to_battle(0)
	board._update_ui()
	check(board.idle_swords.has(mine.uid), "a monster that can attack carries a sword")
	check(not board.idle_swords.has(foe.uid), "the opponent's monsters do not")
	board._card_action(mine)
	check(board.active_sword != null and board.mode == DuelBoard.Mode.ATTACK_TARGET, "clicking takes the sword")
	check(board.idle_swords.has(other.uid), "other valid attackers retain idle swords during target selection")
	board.anim_busy = true
	d.fx.pending = {"type": "presentation", "player": 0}
	board._refresh_swords()
	check(board.idle_swords.has(other.uid), "other swords persist during animations and response windows")
	check(not board.idle_swords.has(mine.uid), "selected sword is not duplicated")
	d.fx.pending = {}
	board.anim_busy = false
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
	check(board.idle_swords.has(mine.uid) and board.idle_swords.has(other.uid), "cancelling restores selected idle sword and preserves the other")
	other.attacked = true
	board._refresh_swords()
	check(not board.idle_swords.has(other.uid), "spent attacker loses its sword")
	d.phase = "main2"
	board._refresh_swords()
	check(board.idle_swords.is_empty(), "swords disappear when Battle Phase ends")
	d.turn_player = 1
	d.phase = "battle"
	var foe_other := d.debug_place(1, idx, 3)
	board._sync(false)
	board._refresh_swords()
	check(board.idle_swords.has(foe.uid) and board.idle_swords.has(foe_other.uid), "opponent's eligible attackers have idle swords")
	check(not board.idle_swords.has(mine.uid), "inactive player's monsters have no idle swords")
	var foe_sword: TextureRect = board.idle_swords[foe.uid]
	check(is_equal_approx(foe_sword.modulate.a, 0.5) and is_equal_approx(foe_sword.rotation, PI), "opponent's idle sword is translucent and points down")
	check((foe_sword.position + foe_sword.size / 2).is_equal_approx(board._view_center(foe.uid)), "opponent's sword is centred on its monster")
	d.current_attack = {"attacker": foe}
	board._refresh_swords()
	check(not board.idle_swords.has(foe.uid) and board.idle_swords.has(foe_other.uid), "opponent's current attack removes only its own idle sword")
	d.current_attack = {}
	foe.attacked = true
	board._refresh_swords()
	check(not board.idle_swords.has(foe.uid), "opponent's spent attacker has no idle sword")
	d.phase = "main2"
	board._refresh_swords()
	check(board.idle_swords.is_empty(), "opponent's idle swords clear after Battle Phase")
	print("sword tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
