extends SceneTree
## Windowed helper: starts a duel, plays a few actions and saves screenshots. Run: Godot --path . -s tests/screenshot.gd -- <dir>

func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	setup.start(7, "cpu_000", "cpu_010", true)
	await create_timer(1.2).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/duel_start.png")
	var b: DuelBoard = setup.board
	for c in b.duel.side(0).hand:
		if b.duel.is_monster(c) and b.duel.tributes_required(c) == 0:
			b.duel.summon(0, c)
			b.hovered = b.duel.side(0).hand[0]
			b._show_card_detail(b.hovered)
			break
	b._after_action()
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/duel_battle.png")
	quit()
