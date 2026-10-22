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
	var target := d.debug_place(1, idx(db, "Axe Raider"), 0, false)
	var spell := d.debug_give(0, idx(db, "Soul Exchange"))
	d.activate_effect(0, spell)
	b._sync(false)
	b._show_card_detail(spell)
	b.fx_enabled = true
	b._check_decision()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/soul_exchange_prompt.png")
	for child in b.get_children():
		if child is DuelDialog: child._finish(true)
	d.respond([target.uid])
	while d.fx.pending.get("type", "") == "chain": d.respond("pass")
	var robo := d.debug_place(0, idx(db, "Patrol Robo"), 0, true)
	d.phase = "standby"
	d.fx.window("standby_phase", {"player": 0})
	d.respond({"uid": robo.uid, "idx": 0})
	b.presented_decision = {}
	b._sync(false)
	b._show_card_detail(robo)
	b._check_decision()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/patrol_robo_prompt.png")
	b.queue_free()
	await process_frame
	quit()
