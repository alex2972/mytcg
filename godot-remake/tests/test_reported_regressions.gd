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
func settle(d: Duel) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 100:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"chain": d.respond("pass")
			"select": d.respond((p["candidates"] as Array).slice(0, p["max"]))
			"yesno": d.respond(true)
			"choice": d.respond(0)
			"presentation": d.respond(true)
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
	d.side(1).hand.clear()
	var jam := d.debug_place_spell(1, idx(db, "Magic Jammer"), 0, false)
	jam.summon_turn = -1
	var spell := d.debug_give(0, idx(db, "Pot of Greed"))
	check(d.activate_effect(0, spell) == "", "spell activates against empty-hand Magic Jammer")
	check(d.fx.pending.is_empty(), "empty-handed Magic Jammer cannot counter")
	check(not jam.face_up and d.side(0).grave.has(spell), "unpaid Jammer stays Set and spell resolves")
	var payment := d.debug_give(1, idx(db, "Axe Raider"))
	spell = d.debug_give(0, idx(db, "Pot of Greed"))
	d.activate_effect(0, spell)
	check(d.fx.pending.get("type", "") == "chain", "Jammer offered when discard is affordable")
	d.respond({"uid": jam.uid, "idx": 0})
	check(d.fx.pending.get("discard", false) and d.fx.chain.size() == 1, "counter waits for discard before entering chain")
	d.respond([payment.uid])
	check(d.side(1).grave.has(payment) and not d.side(1).hand.has(payment), "discard cost really leaves opponent hand")
	settle(d)
	check(d.side(1).grave.has(jam), "paid counter resolves")
	var target := d.debug_place_spell(1, idx(db, "Trap Hole"), 0, false)
	var mst := d.debug_give(0, idx(db, "Mystical Space Typhoon"))
	d.fx.interactive_selections = true
	d.activate_effect(0, mst)
	check(d.fx.pending.get("type", "") == "select" and d.fx.pending["candidates"] == [target.uid], "one MST target still waits for human selection")
	check(d.side(1).spells.has(target), "MST target not destroyed before click")
	# Browse both graveyards without disturbing the pending target decision.
	var pending: Dictionary = d.fx.pending
	b.anim_busy = true
	for player in 2:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.double_click = true
		click.position = b._pile_pos("p%d_grave" % player) + Vector2(20, 20)
		b._input(click)
		check(b.pile_browser != null and is_same(d.fx.pending, pending), "graveyard accessible during pending selection and animation")
		b._close_pile()
	b.anim_busy = false
	d.respond([target.uid])
	settle(d)
	check(d.side(1).grave.has(target), "MST resolves after click")
	# A previous movement toward the Graveyard must not pull a revived card back.
	var dead := d.debug_give(1, idx(db, "Armored Starfish"))
	d.send_to_grave(dead, "effect")
	b._sync(true)
	var old_motion: Tween = b.views[dead.uid].motion
	d.special_summon(dead, 0)
	settle(d)
	b._sync(true)
	check(not old_motion.is_running(), "old graveyard movement cancelled on revival")
	await create_timer(0.4).timeout
	check(not d.side(1).grave.has(dead) and d.side(0).monsters.has(dead), "revived monster belongs to only one zone")
	check(b.views[dead.uid].position.is_equal_approx(b._zone_pos(0, false, d.side(0).monsters.find(dead))), "revived view finishes in its monster zone")
	# Soul Exchange exposes the original instruction and permits the borrowed Tribute.
	var borrowed := d.debug_place(1, idx(db, "Axe Raider"), 0, true)
	var exchange := d.debug_give(0, idx(db, "Soul Exchange"))
	d.activate_effect(0, exchange)
	check(d.fx.pending.get("prompt_text", "").contains("offer as tribute"), "Soul Exchange uses original instruction")
	d.respond([borrowed.uid])
	settle(d)
	check(b._tribute_candidates().has(borrowed), "borrowed opponent monster selectable as Tribute")
	var boss := d.debug_give(0, idx(db, "Summoned Skull"))
	b._sync(false)
	b.mode = DuelBoard.Mode.TRIBUTE
	b.pending_card = boss
	var tribute_click := InputEventMouseButton.new()
	tribute_click.button_index = MOUSE_BUTTON_LEFT
	tribute_click.pressed = true
	b._on_card_input(tribute_click, b.views[borrowed.uid])
	check(d.side(0).monsters.has(boss) and d.side(1).grave.has(borrowed), "Soul Exchange tribute click summons using opponent monster")
	var robo := d.debug_place(0, idx(db, "Patrol Robo"), 2, true)
	var facedown := d.debug_place_spell(1, idx(db, "Trap Hole"), 0, false)
	d.phase = "standby"
	d.fx.window("standby_phase", {"player": 0})
	check(d.fx.pending.get("type", "") == "chain", "Patrol Robo offered in controller Standby")
	d.respond({"uid": robo.uid, "idx": 0})
	check(d.fx.pending.get("prompt_text", "").contains("facedown cards"), "Patrol Robo uses original target instruction")
	d.respond([facedown.uid])
	settle(d)
	check(not facedown.face_up, "Patrol Robo never permanently flips target")
	# End/next-turn/draw banners are engine barriers, not merely a visual queue.
	d.drain_events()
	d.phase = "main1"
	d.turn_player = 0
	d.side(0).hand.clear()
	d.fx.presentation_enabled = true
	var before: int = d.side(1).hand.size()
	d.end_turn(0)
	check(d.phase == "end" and d.turn_player == 0 and d.fx.pending["type"] == "presentation", "end banner holds before next player's turn")
	d.respond(true)
	check(d.turn_player == 1 and d.side(1).hand.size() == before, "next-turn banner holds before draw")
	d.respond(true)
	check(d.phase == "draw" and d.side(1).hand.size() == before, "draw phase banner holds before drawing")
	d.respond(true)
	check(d.phase == "standby" and d.side(1).hand.size() == before + 1, "card drawn only after draw banner completes")
	d.respond(true)
	settle(d)
	check(d.phase == "main1", "Main Phase starts after Standby banner")
	b.queue_free()
	await process_frame
	print("reported regression tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
