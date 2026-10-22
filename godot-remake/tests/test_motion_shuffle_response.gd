extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event
func current_dialog(b: DuelBoard) -> DuelDialog:
	for child in b.get_children():
		if child is DuelDialog and not child.done: return child
	return null
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.side(0).hand.clear()
	var monster := d.debug_give(0, idx(db, "Axe Raider"))
	b._sync(false)
	var start: Vector2 = b.views[monster.uid].position
	b.fx_enabled = true
	b._card_action(monster)
	check(b.anim_busy and b.views[monster.uid].position.is_equal_approx(start), "summon starts at hand without teleporting")
	await process_frame
	await process_frame
	var destination := b._zone_pos(0, false, 0)
	check(not b.views[monster.uid].position.is_equal_approx(start) and not b.views[monster.uid].position.is_equal_approx(destination), "monster travels through intermediate position: start=%s now=%s dest=%s" % [start, b.views[monster.uid].position, destination])
	await create_timer(1.65).timeout
	check(b.views[monster.uid].position.is_equal_approx(destination) and not b.anim_busy, "summon completes in field zone before input resumes")
	var mst := d.debug_give(0, idx(db, "Mystical Space Typhoon"))
	b._sync(false)
	start = b.views[mst.uid].position
	b.hand_set_pref = true
	b._card_action(mst)
	check(b.views[mst.uid].position.is_equal_approx(start), "Set Spell starts from hand")
	await create_timer(1.1).timeout
	check(b.views[mst.uid].position.is_equal_approx(b._zone_pos(0, true, 0)) and not mst.face_up, "Set Spell slides to field face down")
	mst.summon_turn = -1
	var target := d.debug_place_spell(1, idx(db, "Trap Hole"), 0, false)
	b._sync(false)
	d.fx.interactive_selections = true
	d.fx.window("attack_declared", {"player": 1})
	b._check_decision()
	check(current_dialog(b) != null, "response first asks whether to activate")
	if current_dialog(b) != null: current_dialog(b)._finish(true)
	check(b._response_pick_active() and not mst.face_up and not b.decision_popup.visible, "YES does not activate even the sole available Set card")
	check(b._hover_cursor(mst) == "act" and b._hover_cursor(target) == "off", "only offered own card shows Activate cursor")
	b._on_card_input(click(), b.views[mst.uid])
	check(mst.face_up and d.fx.pending.get("type", "") == "select", "clicking offered card flips it and starts effect targeting")
	while b.anim_busy: await process_frame
	if current_dialog(b) != null: current_dialog(b)._finish(true)
	b.fx_enabled = false
	b._decision_toggle(target)
	check(d.side(1).grave.has(target), "selected response resolves after target click")
	# Original shuffle frame cycle and cleanup; presentation does not change RNG or deck order.
	var frames: Array = []
	b.fx.shuffle_frame_shown.connect(func(frame, tick): frames.append([frame, tick]))
	var before: Array = d.side(0).deck.duplicate()
	var state := d.rng.state
	await b.fx.shuffle_deck(b._pile_pos("p0_deck") + b.CARD / 2)
	check(frames.size() == 41 and frames[0] == [1, 0] and frames[40] == [1, 320], "native 8-tick counter and full frame cycle")
	check(frames[1][0] == 2 and frames[4][0] == 5 and frames[5][0] == 1, "shuffle repeats original frames 1 through 5")
	check(d.side(0).deck == before and d.rng.state == state, "shuffle presentation never reshuffles or consumes RNG")
	check(b.fx.get_child_count() == 0, "shuffle panel removed on completion")
	d.fx.presentation_enabled = true
	var ctx := {"src": monster, "controller": 0, "vars": {}, "event": {}, "effect": {}}
	var hand_before: int = d.side(0).hand.size()
	d.fx.push_script([{ "op": "shuffle", "who": "self"}, {"op": "draw", "who": "self", "n": 1}], ctx)
	d.fx.pump()
	check(d.fx.pending.get("type", "") == "presentation" and d.side(0).hand.size() == hand_before, "shuffle blocks following draws until animation acknowledgement")
	d.respond(true)
	check(d.side(0).hand.size() == hand_before + 1, "draw continues after shuffle finishes")
	b.queue_free()
	await process_frame
	print("motion/shuffle/response tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
