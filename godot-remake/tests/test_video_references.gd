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
func _init() -> void:
	await process_frame
	var j := JankenScreen.new(11)
	root.add_child(j)
	j.set_process(false)
	var before := j.bottom_offset
	j._process(0.2)
	check(j.top_offset > 0 and j.bottom_offset > before, "rows advance in opposite directions with wrapped offsets")
	var visible := -1
	for i in j.bottom.size():
		if j.bottom[i].position.x > 0 and j.bottom[i].position.x < 412: visible = i
	j._row_hover(j.bottom[visible].position + j.CRATE / 2)
	before = j.bottom_offset
	var top_before := j.top_offset
	j._process(0.4)
	check(j.bottom_offset == before and j.top_offset != top_before, "hover freezes only the player's conveyor")
	check(j.bottom[j.hovered].texture == j._t("jya_%s_2" % j.HANDS[j.hovered % 3]), "hover lights the actual moving crate")
	j._row_hover(Vector2.ZERO, false)
	j._process(0.2)
	check(j.bottom_offset != before, "leaving the row resumes movement")
	for i in 1000: j._process(0.017)
	for x in [10.0, 100.0, 300.0, 610.0]:
		j._row_hover(Vector2(x, 100))
		check(j.hovered >= 0, "conveyor remains filled after many wraps")
	var hovered_hand: String = j.HANDS[j.hovered % 3]
	var event := InputEventMouseButton.new()
	event.position = j.bottom[j.hovered].position + j.CRATE / 2
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	j._row_input(event)
	check(j.phase == JankenScreen.Phase.RESULT and j.my_pick == hovered_hand, "click chooses the hand on the moving crate, rather than a fixed column")
	while j.phase == JankenScreen.Phase.RESULT:
		await process_frame
	j.human_won = true
	j._show_order()
	var completed: Array = []
	j.finished.connect(func(first): completed.append(first))
	j._on_order_input(event, 1)
	check(j.order_busy and completed.is_empty(), "turn-order choice waits for its departure animation")
	await create_timer(1.0).timeout
	check(completed == [false], "Second-to-Go completes exactly once after crate travel")
	j.queue_free()
	await process_frame
	var fx := DuelFx.new()
	root.add_child(fx)
	var stages: Array = []
	fx.animation_stage.connect(func(kind, stage): stages.append([kind, stage]))
	await fx.start_duel()
	check(stages == [["start", "title"],["start","complete"]] and fx.get_child_count() == 0, "start title finishes and releases dim overlay before dealing")
	var wipe: Array = []
	fx.turn_wipe.connect(func(progress): wipe.append(progress))
	await fx.turn_banner(true)
	check(wipe.size() > 20 and wipe[0] == 0.0 and wipe.back() == 1.0, "turn flip progresses continuously from outgoing to incoming")
	await fx.activation(Vector2(400, 300))
	check(fx.get_child_count() == 0, "activation flare is removed before resolution continues")
	await fx.tribute_glow(Vector2(400, 300))
	check(stages.has(["tribute", "ring"]) and stages.has(["tribute", "white_card"]), "tribute ring precedes rotating white card")
	await process_frame
	check(fx.get_child_count() == 0, "tribute particles and glow cleaned up")
	fx.queue_free()
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	var card: DCard = d.debug_place(1, idx(db, "Axe Raider"), 0, true, "atk")
	b._sync(false)
	b.fx_enabled = true
	var trap := d.debug_place_spell(0, idx(db, "Trap Hole"), 0, false)
	b._sync(false)
	trap.face_up = true
	var flip_checks: Array = []
	var inspect := func(kind, stage):
		if kind == "activation" and stage == "flare":
			flip_checks.append(b.views[trap.uid].shown_face_up)
	b.fx.animation_stage.connect(inspect)
	await b._play_events([{"type": "card_activated", "uid": trap.uid, "kind": "trap"}])
	b.fx.animation_stage.disconnect(inspect)
	check(flip_checks == [true], "Set card is visibly face-up before activation flare and effect resolution")
	var rng_state := d.rng.state
	await b.fx.summon_rainbow(b.views[card.uid])
	check(b.fx.get_child_count() == 0 and d.rng.state == rng_state, "rainbow completes without affecting game RNG")
	d.drain_events()
	d.send_to_grave(card, "destroyed:effect")
	var old_position: Vector2 = b.views[card.uid].position
	var complete: Array = []
	b.fx.animation_stage.connect(func(kind, stage): complete.append([kind, stage]))
	b._play_events(d.drain_events())
	check(not b.views[card.uid].visible and b.views[card.uid].position == old_position, "effect-destroyed card shatters at former zone")
	await create_timer(0.3).timeout
	check(b.views[card.uid].visible and b.views[card.uid].position.is_equal_approx(b._pile_pos("p1_grave") + Vector2(6,0)), "graveyard updates during destruction, without intact field flight")
	await create_timer(0.55).timeout
	check(complete.count(["effect_destroy", "fragments"]) == 1 and b.fx.get_child_count() == 0, "paired destroy/to-grave produces one effect and cleans up")
	b.queue_free()
	await process_frame
	print("video reference tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)


