extends SceneTree
func _init() -> void:
	await process_frame
	var output := OS.get_cmdline_user_args()[0]
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.ai_running = true
	root.add_child(board)
	await process_frame
	board.fx.roll_dice(6)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("dice_tumble.png"))
	await board.fx.result_shown
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("dice_result.png"))
	await create_timer(0.7).timeout
	board.fx.toss_coins([true, false, true])
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("coins_spin.png"))
	await board.fx.result_shown
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("coins_result.png"))
	await create_timer(0.7).timeout
	board.queue_free()
	await process_frame
	quit()
