extends SceneTree
## The board shows effect decisions to the human and routes the answers back to the engine.

var fails := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	return 0

func _init() -> void:
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.duel.no_first_turn_attack = false
	root.add_child(board)
	await process_frame
	var d := board.duel
	# 1) the human sets a trap, the opponent summons -> a chain prompt appears and Trap Hole works
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	var trap := d.debug_place_spell(0, idx(db, "Trap Hole"), 0)
	d.end_turn(0)
	var big := d.debug_give(1, idx(db, "Armored Lizard"))
	big.atk_bonus = 1500 - d.atk_of(big)
	d.summon(1, big)
	board._after_action()
	check(d.fx.pending.get("type", "") == "chain" and board.decision_popup.visible, "chain prompt shown to the human")
	check(board._hover_cursor(trap) == "off", "no hover action while a decision is pending")
	board._answer({"uid": trap.uid, "idx": 0})
	check(d.side(1).grave.has(big) and d.side(0).grave.has(trap) and d.fx.pending.is_empty(), "answering the prompt resolves the chain")
	# 2) a spell in hand shows the Activate cursor and activating it resolves
	await create_timer(0.2).timeout
	while d.turn_player != 0 or board.ai_running:
		if d.fx.pending.is_empty() and d.turn_player == 1:
			SimpleAI.step(d, 1)
		else:
			await create_timer(0.05).timeout
		if d.fx.pending.get("player", -1) == 0:
			board._answer("pass")
	var spell := d.debug_give(0, idx(db, "Pot of Greed"))
	board._after_action()
	check(board._hover_cursor(spell) == "act", "a playable Spell in hand shows the Activate cursor")
	var hand_before: int = d.side(0).hand.size()
	board._card_action(spell)
	check(d.side(0).grave.has(spell) and d.side(0).hand.size() == hand_before - 1 + 2, "clicking it activates Pot of Greed")
	board.hand_set_pref = true
	var spell2 := d.debug_give(0, idx(db, "Hinotama"))
	check(board._hover_cursor(spell2) == "set", "right-click toggle makes it Set instead")
	board.hand_set_pref = false
	# 3) a target selection from the field (Fissure picks among equal-ATK monsters)
	d.debug_place(1, idx(db, "Armored Starfish"), 0)
	d.debug_place(1, idx(db, "Armored Starfish"), 1)
	var f := d.debug_give(0, idx(db, "Fissure"))
	board._card_action(f)
	check(d.fx.pending.get("type", "") == "select" and board._decision_select_active(), "target selection is shown on the field")
	var cands: Array = d.fx.pending["candidates"]
	board._decision_toggle(d.card_by_uid(cands[0]))
	check(d.fx.pending.is_empty() and d.side(1).grave.size() >= 1, "clicking a candidate answers the prompt")
	print("board effects tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
