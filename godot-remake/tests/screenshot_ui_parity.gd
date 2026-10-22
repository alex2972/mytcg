extends SceneTree
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	for name in ["Axe Raider", "Armored Starfish", "Blue-Eyes White Dragon", "Summoned Skull", "Dark Magician", "Man-Eater Bug", "Big Eye"]:
		var c := b.duel.debug_give(0, idx(db, name))
		b.duel.side(0).hand.erase(c)
		b.duel.side(0).grave.append(c)
	var m := b.duel.debug_place(0, idx(db, "Axe Raider"), 0, true)
	m.atk_bonus = 500
	m.def_bonus = -500
	b._sync(false)
	b._show_pile(0, "grave")
	await save("grave_browser")
	b._pile_move(1)
	await save("grave_browser_page2")
	b._close_pile()
	b._show_pile(1, "extra")
	await save("extra_browser")
	b._close_pile()
	await save("stat_colors")
	b.queue_free()
	await process_frame
	quit()
