extends SceneTree
var frame := 0
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func capture(b: DuelBoard, yellow: bool, tick: float) -> void:
	if tick >= frame * 48 and frame < 6:
		var sequence := frame
		frame += 1
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("Z:/process/scratch/video-references/set_%s_%d.png" % ["yellow" if yellow else "blue", sequence])
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	for yellow in [false, true]:
		frame = 0
		var card := b.duel.debug_place_spell(1, idx(db,"Trap Hole"), 0, false) if not yellow else b.duel.debug_place(1, idx(db,"Axe Raider"), 0, false, "def")
		b._sync(false)
		var capture_frame := func(color: bool, tick: float): capture(b, color, tick)
		b.fx.set_frame_shown.connect(capture_frame)
		await b.fx.set_card(b._view_center(card.uid), yellow)
		b.fx.set_frame_shown.disconnect(capture_frame)
	await process_frame
	b.queue_free()
	await process_frame
	quit()
