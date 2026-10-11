extends SceneTree
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func _init() -> void:
	await process_frame
	var output := OS.get_cmdline_user_args()[0]
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	b.duel.side(0).hand.clear()
	var spell := b.duel.debug_give(0, idx(db, "Prohibition"))
	b._card_action(spell)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("prohibition_picker.png"))
	b._answer((b.duel.fx.pending["labels"] as Array).find("Pot of Greed"))
	var inspection := b.duel.debug_place_spell(0, idx(db, "Inspection"), 1, true)
	b.duel.debug_give(1, idx(db, "Axe Raider"))
	b.duel.phase = "standby"
	b.duel.turn_player = 1
	b.duel.fx.window("standby_phase", {"player": 1})
	b.duel.respond({"uid": inspection.uid, "idx": 1})
	while b.duel.fx.pending.get("type", "") == "chain": b.duel.respond("pass")
	b.presented_decision = {}
	b._check_decision()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("inspection_reveal.png"))
	b.queue_free()
	await process_frame
	quit()
