extends SceneTree
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var board := DuelBoard.new(db,deck,deck,3)
	board.ai_delay = 0.0
	board.ai_running = true
	root.add_child(board)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	screenshot.save_png("Z:/process/scratch/opponent-deck-board.png")
	var crop := screenshot.get_region(Rect2i(248,94,66,96))
	crop.resize(264,384,Image.INTERPOLATE_NEAREST)
	crop.save_png("Z:/process/scratch/opponent-deck-detail.png")
	board.queue_free()
	await process_frame
	quit()
