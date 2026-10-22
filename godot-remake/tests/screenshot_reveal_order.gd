extends SceneTree
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
	for name in ["Buster Blader", "Morphing Jar #2", "The Stern Mystic", "Nimble Momonga", "Magic Jammer"]:
		d.debug_give(0, idx(db, name))
	var eye := d.debug_place(0, idx(db, "Big Eye"), 0, true)
	var ctx := {"src": eye, "controller": 0, "vars": {}, "event": {}, "effect": {}}
	for name in ["Tribute to The Doomed", "Magic Jammer", "Flame Ghost", "Spellbinding Circle", "Princess of Tsurugi"]:
		var c := d.debug_give(0, idx(db, name))
		d.side(0).hand.erase(c)
		d.side(0).deck.append(c)
	d.fx.push_script([{ "op": "order_deck"}], ctx)
	d.fx.pump()
	b._sync(false)
	b._show_card_detail(eye)
	b._check_decision()
	var top: Array = d.fx.pending["candidates"].duplicate()
	b._order_pick(top[0])
	b._order_pick(top[4])
	b._order_pick(top[3])
	b._order_pick(top[1])
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/big_eye_order.png")
	b._order_pick(top[2])
	var hidden := d.debug_place(1, idx(db, "Man-Eater Bug"), 0, false)
	var trap := d.debug_place_spell(0, idx(db, "Trap Hole"), 0, false)
	b.fx_enabled = true
	b._present_reveal({"cards": [hidden.uid, trap.uid], "public": true, "seconds": 4.0, "sequential": true})
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/stern_mystic_reveal.png")
	await create_timer(4.0).timeout
	b.queue_free()
	await process_frame
	quit()
