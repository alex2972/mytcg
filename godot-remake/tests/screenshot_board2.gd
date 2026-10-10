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
	var idx := 0
	for i in range(1, b.db.cards.size()):
		if b.db.card_name(i) == "Panther Warrior": idx = i
	var foe := d.debug_place(1, idx, 2)
	for c in d.side(0).hand:
		if d.is_monster(c) and d.tributes_required(c) == 0:
			d.summon(0, c)
			break
	await b._after_action()
	d.to_battle(0)
	await b._after_action()
	await create_timer(1.2).timeout
	var mine: DCard = d.monsters_of(0)[0]
	b._on_card_enter(b.views[mine.uid])
	b._show_card_detail(mine)
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/board_battle.png")
	b._on_card_exit(b.views[mine.uid])
	b._card_action(mine)
	b._on_card_enter(b.views[foe.uid])
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/board_target.png")
	quit()
