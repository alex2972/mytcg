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
	board._show_card_detail(mon)
	check(board.d_name.get_theme_color("font_color") == Color.BLACK and board.d_name.get_theme_font("font").font_weight == 700, "detail name uses dark bold lettering")
	check(board.d_stats.get_theme_color("font_color") == Color.BLACK and board.d_stats.get_theme_font("font").font_weight == 900, "detail stats use heavy black lettering")
	var icon_image := board._ui("card/icon_syuzoku").get_image()
	var green_pixels := 0
	for y in icon_image.get_height():
		for x in icon_image.get_width():
			var pixel := icon_image.get_pixel(x, y)
			if pixel.a > 0 and pixel.r8 == 85 and pixel.g8 == 255 and pixel.b8 == 0:
				green_pixels += 1
	check(green_pixels == 0, "duel type-icon atlas has no opaque green transparency pixels")

	# Inspection remains available on the opponent's first turn, even during playback.
	var hand_view: DuelBoard.CardView = board.views[mon.uid]
	var resting_position: Vector2 = board._layout(mon)["pos"]
	d.turn_player = 1
	board.mode = DuelBoard.Mode.AI
	board.anim_busy = true
	board._on_card_enter(hand_view)
	await create_timer(board.MOVE_TIME + 0.05).timeout
	check(hand_view.position.y == 466, "own hand card rises during opponent animation")
	check(board.detail_card == mon and board._hover_cursor(mon) == "off", "opponent-turn hover inspects without offering a summon")
	check(d.side(0).hand.has(mon) and not board._can_act(), "inspection does not enable playing cards on opponent turn")
	board._on_card_exit(hand_view)
	await create_timer(board.MOVE_TIME + 0.05).timeout
	check(hand_view.position.is_equal_approx(resting_position), "card lowers after opponent-turn hover exit")
	board.anim_busy = false
	board.mode = DuelBoard.Mode.IDLE
	d.turn_player = 0
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
