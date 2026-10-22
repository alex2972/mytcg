extends SceneTree
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.02
	b.ai_running = true
	root.add_child(b)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/opening_first_draw.png")
	await create_timer(1.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/opening_deal.png")
	while b.anim_busy: await process_frame
	var dialog := DuelDialog.new()
	dialog.setup("Activate the effect of a card?", "yesno")
	b.add_child(dialog)
	var cursor := root.get_node("GameCursor")
	cursor.set_process(false)
	cursor.rect.position = dialog.panel.position + dialog._buttons()["yes"]
	cursor.set_state("on")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/cursor_above_dialog.png")
	b.queue_free()
	await process_frame
	quit()
