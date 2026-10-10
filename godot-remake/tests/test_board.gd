extends SceneTree
## Drives the duel board through the same handlers real clicks reach.

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
	var mon: DCard = null
	for c in d.side(0).hand:
		if d.is_monster(c) and d.tributes_required(c) == 0 and d.fx.effects_of(c).is_empty():
			mon = c
	check(mon != null, "monster in hand")
	check(board._hover_cursor(mon) == "summon", "hover cursor on a hand monster says Summon")
	board.hand_set_pref = true
	check(board._hover_cursor(mon) == "set", "right-click toggle switches it to Set")
	board.hand_set_pref = false
	board._card_action(mon)
	check((d.side(0).monsters as Array).has(mon) and mon.face_up, "left-click summons")
	check(board._hover_cursor(mon) == "over", "a monster summoned this turn cannot change position")
	check(board._phase_click_ok(3) and board._phase_click_ok(5) and not board._phase_click_ok(4), "phase icons: Battle and End are clickable in Main 1")
	board._on_phase_icon(_click(), 3)
	check(d.phase == "battle", "BP icon enters the battle phase")
	check(board._hover_cursor(mon) == "atk", "hover cursor on an attacker says Attack")
	board._card_action(mon)
	check(d.side(1).lp < 8000, "attack hits directly (opponent has no monsters)")
	board._on_phase_icon(_click(), 4)
	check(d.phase == "main2", "M2 icon proceeds to main phase 2")
	board._try_end_turn()
	await create_timer(0.3).timeout
	check(d.turn >= 3 or d.winner != -1, "opponent turn ran and control returned (turn %d)" % d.turn)
	check(d.turn_player == 0 and board.mode == DuelBoard.Mode.IDLE, "back to the human with the board idle")
	print("board tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e
