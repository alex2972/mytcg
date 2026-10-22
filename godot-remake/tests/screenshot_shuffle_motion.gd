extends SceneTree
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + path + ".png")
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	b.duel.side(0).hand.clear()
	var c := b.duel.debug_give(0, idx(db, "Axe Raider"))
	b._sync(false)
	b.fx_enabled = true
	b._card_action(c)
	await process_frame
	await process_frame
	await save_frame("card_moving_from_hand")
	await create_timer(0.7).timeout
	b.fx.shuffle_frame_shown.connect(func(_frame, tick):
		if tick == 128: save_frame("deck_shuffle"))
	await b.fx.shuffle_deck(b._pile_pos("p0_deck") + b.CARD / 2)
	b.queue_free()
	await process_frame
	quit()
