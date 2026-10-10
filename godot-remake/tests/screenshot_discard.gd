extends SceneTree
## Capture the instruction panel while the player chooses a hand-limit discard.
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
	var d := b.duel
	var chosen: DCard
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Summoned Skull":
			chosen = d.debug_give(0, i)
	b._show_card_detail(chosen)
	await create_timer(0.4).timeout
	b._sync(false)
	b._update_ui()
	b._try_end_turn()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("discard_open.png"))
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	b._on_card_input(e, b.views[chosen.uid])
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("discard_complete.png"))
	b.queue_free()
	await process_frame
	quit()
