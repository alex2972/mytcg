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
	var eye := d.debug_place(0, idx(db, "Big Eye"), 0, true)
	var ctx := {"src": eye, "controller": 0, "vars": {}, "event": {}, "effect": {}}
	var before: Array = d.side(0).deck.duplicate()
	d.fx.push_script([{ "op": "order_deck"}], ctx)
	d.fx.pump()
	check(d.fx.pending.get("order_deck", false), "Big Eye asks for deck ordering")
	var top: Array = d.fx.pending["candidates"].duplicate()
	check(top.size() == 5 and top[0] == before.back().uid, "first displayed card is next draw")
	check(d.respond([top[0], top[0], top[2], top[3], top[4]]) != "", "duplicate order rejected")
	check(d.side(0).deck == before, "invalid order leaves deck untouched")
	b._check_decision()
	check(b.order_panel != null and b.order_panel.size == Vector2(451, 191), "original size ordering panel")
	b._order_pick(int(top[2]))
	check(b.order_ranks[top[2]].text == "1", "first click labels rank one")
	b._order_pick(int(top[2]))
	check(b.decision_selected.size() == 1, "clicking a ranked card again does not duplicate it")
	b._order_pick(int(top[0]))
	b._order_pick(int(top[4]))
	b._order_pick(int(top[1]))
	b._order_pick(int(top[3]))
	check(d.side(0).deck.back().uid == top[2], "first click is next draw")
	check(d.side(0).deck[-2].uid == top[0] and d.side(0).deck[-5].uid == top[3], "all ordered cards preserved")
	check(d.side(0).deck.slice(0, -5) == before.slice(0, -5), "rest of deck unchanged")
	check(b.order_panel == null, "ordering panel closes after completion")
	# Fewer than five cards: reorder all remaining cards.
	d.side(0).deck = d.side(0).deck.slice(-2)
	d.fx.push_script([{ "op": "order_deck"}], ctx)
	d.fx.pump()
	check(d.fx.pending["max"] == 2, "short deck requests two cards")
	d.respond(d.fx.pending["candidates"])
	var mystic := d.debug_place(0, idx(db, "The Stern Mystic"), 1, true)
	var hidden := d.debug_place(1, idx(db, "Man-Eater Bug"), 0, false)
	var trap := d.debug_place_spell(0, idx(db, "Trap Hole"), 0, false)
	d.drain_events()
	d.fx.presentation_enabled = true
	ctx["src"] = mystic
	d.fx.push_script(d.fx.effects_of(mystic)[0]["do"], ctx)
	d.fx.pump()
	var events: Array = d.drain_events()
	check(events.size() == 1 and events[0]["type"] == "reveal_cards", "Stern Mystic emits only a visual reveal")
	check(events[0]["cards"].has(hidden.uid) and events[0]["cards"].has(trap.uid), "both sides' Set field cards revealed")
	check(not events[0]["cards"].has(eye.uid), "face-up cards excluded")
	check(events[0]["seconds"] == 4 and events[0]["sequential"], "sequential reveal with four second hold")
	check(d.fx.pending["type"] == "presentation", "duel paused until reveal completes")
	b._sync(false)
	b._set_revealed(hidden.uid, true)
	check(b.views[hidden.uid].shown_face_up and not hidden.face_up, "field reveal changes display only")
	b._set_revealed(hidden.uid, false)
	check(not b.views[hidden.uid].shown_face_up, "field concealment restored")
	d.respond(true)
	check(not hidden.face_up and not trap.face_up and d.fx.pending.is_empty(), "no Flip activation after reveal")
	d.fx.presentation_enabled = false
	var spy := d.debug_give(0, idx(db, "The Inexperienced Spy"))
	var secret := d.debug_give(1, idx(db, "Axe Raider"))
	d.drain_events()
	ctx["src"] = spy
	d.fx.push_script(d.fx.effects_of(spy)[0]["do"], ctx)
	d.fx.pump()
	check(d.fx.pending.get("hidden_pick", false), "Spy waits for click even with only one hand card")
	check(not b._uses_list(d.fx.pending), "hidden hand selection does not expose list of names")
	b._sync(false)
	b.presented_decision = {}
	b._check_decision()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	b._on_card_input(click, b.views[secret.uid])
	check(not d.fx.pending.get("hidden_pick", false), "click on opponent hand answers the peek selection")
	# The board drains and displays the reveal event during its action.
	check(not b.views[secret.uid].shown_face_up, "peek automatically restores hand back")
	d.fx.push_script([{ "op": "reveal", "what": "$peek"}], ctx)
	d.fx.pump()
	events = d.drain_events()
	check(events.size() == 1 and events[0]["cards"] == [secret.uid], "Spy reveals selected hand card")
	check(d.side(1).hand.has(secret) and not secret.face_up, "hand reveal preserves card and hidden state")
	b.fx_enabled = true
	b._present_reveal({"cards": [hidden.uid, trap.uid], "public": true, "seconds": 0.1, "sequential": true})
	await create_timer(0.34).timeout
	check(b.revealed_cards.has(hidden.uid) and b.revealed_cards.has(trap.uid), "sequential field cards remain revealed together")
	await create_timer(0.45).timeout
	check(b.revealed_cards.is_empty() and not hidden.face_up and not trap.face_up, "timed reveal automatically conceals every card")
	b.queue_free()
	await process_frame
	print("reveal and ordering tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
