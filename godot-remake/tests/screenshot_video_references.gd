extends SceneTree
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("Z:/process/scratch/video-references/remake_" + name + ".png")
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func _init() -> void:
	await process_frame
	var j := JankenScreen.new(11)
	root.add_child(j)
	await create_timer(0.4).timeout
	j._row_hover(Vector2(300,100))
	await snap("rps_hover")
	j._choose(j.HANDS[j.hovered % 3])
	await create_timer(1.25).timeout
	await snap("rps_reveal")
	await create_timer(1.6).timeout
	j.human_won = true
	j._show_order()
	j._on_order_hover(1, true)
	await snap("rps_order")
	j.queue_free()
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	b.fx.start_duel()
	await create_timer(0.7).timeout
	await snap("start")
	await create_timer(1.2).timeout
	var card := b.duel.debug_place(0, idx(db, "Axe Raider"), 0)
	b._sync(false)
	b.fx.summon_rainbow(b.views[card.uid])
	await create_timer(0.7).timeout
	await snap("summon")
	await create_timer(0.7).timeout
	b.fx.rune_circle(b._view_center(card.uid))
	await create_timer(0.3).timeout
	await snap("set")
	await create_timer(0.5).timeout
	b.fx.activation(b._view_center(card.uid))
	await create_timer(0.18).timeout
	await snap("activation")
	await create_timer(0.3).timeout
	b.fx.tribute_glow(b._view_center(card.uid))
	await create_timer(0.58).timeout
	await snap("tribute")
	await create_timer(0.65).timeout
	b.fx.shatter(b.views[card.uid])
	await create_timer(0.25).timeout
	await snap("shatter")
	await create_timer(0.5).timeout
	b.queue_free()
	await process_frame
	quit()
