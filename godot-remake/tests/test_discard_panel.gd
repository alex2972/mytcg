extends SceneTree
## Discard instructions must stay visible while hand cards remain clickable.
var fails := 0
var db: CardDB
var deck: Deck

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func idx(name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	return 0

func new_board() -> DuelBoard:
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true # Keep assertions independent of the next opponent turn.
	root.add_child(b)
	return b

func click(button := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	return e

func _init() -> void:
	await process_frame
	db = CardDB.load_default()
	deck = Deck.load_file("res://data/default_deck.ydc", db)
	var b := new_board()
	await process_frame
	var d := b.duel
	d.side(0).hand.clear()
	for i in 7:
		d.debug_give(0, idx("Armored Starfish"))
	var field := d.debug_place(0, idx("Armored Lizard"), 0)
	b._sync(false)
	b._try_end_turn()
	check(is_instance_valid(b.discard_dialog) and b.discard_dialog.visible, "hand limit displays persistent discard panel")
	check(b.discard_dialog.message == "Discard from your hand." and b.discard_dialog._buttons().is_empty(), "original instruction has no OK button")
	check(b.discard_dialog.mouse_filter == Control.MOUSE_FILTER_IGNORE and b.modal_depth == 0, "panel does not intercept hand clicks")
	check(not b._can_act(), "unrelated duel actions disabled during discard")
	b._on_board_input(click(MOUSE_BUTTON_RIGHT))
	b._on_card_input(click(MOUSE_BUTTON_RIGHT), b.views[field.uid])
	check(b.mode == DuelBoard.Mode.DISCARD and is_instance_valid(b.discard_dialog), "right click cannot dismiss required discard")
	b._on_card_input(click(), b.views[field.uid])
	check(d.side(0).monsters.has(field) and b.selected.is_empty(), "field cards cannot be discarded")
	var chosen: DCard = d.side(0).hand[0]
	b._on_card_input(click(), b.views[chosen.uid])
	check(d.side(0).grave.has(chosen), "hand click discards the card")
	check(b.discard_dialog == null, "panel disappears once discard is complete")
	check(d.turn_player == 1, "turn resumes after discard")
	b.queue_free()
	await process_frame

	b = new_board()
	await process_frame
	d = b.duel
	d.side(0).hand.clear()
	for i in 8:
		d.debug_give(0, idx("Armored Starfish"))
	b._sync(false)
	b._try_end_turn()
	chosen = d.side(0).hand[0]
	var second: DCard = d.side(0).hand[1]
	b._on_card_input(click(), b.views[chosen.uid])
	check(is_instance_valid(b.discard_dialog) and d.turn_player == 0, "multiple discards keep the panel open until enough are chosen")
	b._on_card_input(click(), b.views[second.uid])
	check(d.side(0).grave.has(chosen) and d.side(0).grave.has(second) and b.discard_dialog == null, "remaining selection completes multiple discards")
	b.queue_free()
	await process_frame

	# An effect discard uses the same panel, never a modal OK or the opponent's hand.
	b = new_board()
	await process_frame
	d = b.duel
	d.side(0).hand.clear()
	chosen = d.debug_give(0, idx("Armored Starfish"))
	d.debug_give(0, idx("Armored Lizard"))
	var spell := d.debug_give(0, idx("Tribute to The Doomed"))
	d.debug_place(1, idx("Armored Starfish"), 0)
	check(d.activate_effect(0, spell, 0) == "", "discard-cost spell activates")
	b._sync(false)
	b._check_decision()
	check(d.fx.pending.get("discard", false) and is_instance_valid(b.discard_dialog), "effect discard displays the persistent panel")
	for uid in d.fx.pending["candidates"]:
		check(d.side(0).hand.has(d.card_by_uid(uid)), "effect candidates belong to discarding player's hand")
	check(not b.decision_busy and b._decision_select_active(), "no acknowledgement blocks the discard selection")
	var panel := b.discard_dialog
	b._check_decision()
	check(is_same(panel, b.discard_dialog), "refresh does not replace the open panel")
	b._on_card_input(click(), b.views[chosen.uid])
	check(d.side(0).grave.has(chosen) and b.discard_dialog == null, "effect hand click discards and closes panel")
	check(d.fx.pending.is_empty(), "effect continues after discard")
	b.queue_free()
	await process_frame

	# Even the only remaining hand card waits for the player's click.
	b = new_board()
	await process_frame
	d = b.duel
	d.side(0).hand.clear()
	chosen = d.debug_give(0, idx("Armored Starfish"))
	spell = d.debug_give(0, idx("Tribute to The Doomed"))
	d.debug_place(1, idx("Armored Starfish"), 0)
	d.activate_effect(0, spell, 0)
	b._sync(false)
	b._check_decision()
	check(is_instance_valid(b.discard_dialog) and d.side(0).hand.has(chosen), "single eligible card still waits for a click")
	b._on_card_input(click(), b.views[chosen.uid])
	check(d.side(0).grave.has(chosen) and b.discard_dialog == null, "single-card discard completes normally")
	b.queue_free()
	await process_frame
	print("discard panel tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
