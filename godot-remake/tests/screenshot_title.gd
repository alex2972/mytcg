extends SceneTree
## Windowed helper: screenshots of the title and duel menu. Run: Godot --path . -s tests/screenshot_title.gd -- <dir>

func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var main: Control = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	var t = main.current
	t.main_menu.hover = 1
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/title.png")
	t._on_main(0)
	t.duel_menu.hover = 0
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/title_duel.png")
	quit()
