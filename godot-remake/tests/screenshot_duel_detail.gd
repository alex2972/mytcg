extends SceneTree
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	board.ai_running = true
	root.add_child(board)
	await process_frame
	var card := board.duel.debug_give(0, int(db.search("Aqua Spirit")[0]))
	board._show_card_detail(card)
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/duel-detail-fixed.png")
	board.queue_free()
	await process_frame
	quit()
