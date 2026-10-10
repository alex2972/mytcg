extends SceneTree
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	root.add_child(ed)
	await create_timer(0.8).timeout
	ed._show_detail(ed.deck.main[3])
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/deck.png")
	quit()
