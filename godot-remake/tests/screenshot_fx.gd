extends SceneTree
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	setup.start(7, "cpu_000", "cpu_010", true)
	await create_timer(0.35).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/fx_banner.png")
	await create_timer(1.5).timeout
	var b: DuelBoard = setup.board
	var d := b.duel
	var db := b.db
	var idx := 0
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Armored Starfish": idx = i
	var a := d.debug_place(0, idx, 1)
	var t := d.debug_place(1, idx, 2)
	a.atk_bonus = 3000
	b._sync(false)
	d.to_battle(0)
	await b._after_action()
	d.attack(0, a, t)
	b._after_action()
	await create_timer(0.62).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/fx_explosion.png")
	quit()
