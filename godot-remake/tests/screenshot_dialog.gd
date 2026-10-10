extends SceneTree
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	setup.start(7, "cpu_000", "cpu_010", true)
	await create_timer(2.5).timeout
	var b: DuelBoard = setup.board
	var d := b.duel
	var db := b.db
	var mf := 0
	var st := 0
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Mirror Force": mf = i
		if db.card_name(i) == "Armored Starfish": st = i
	d.debug_place_spell(0, mf, 0)
	d.debug_place(0, st, 1)
	d.end_turn(0)
	await create_timer(0.3).timeout
	var a := d.debug_place(1, st, 2)
	d.to_battle(1)
	d.attack(1, a, d.monsters_of(0)[0])
	b._after_action()
	await create_timer(1.6).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/dialog_chain.png")
	quit()
