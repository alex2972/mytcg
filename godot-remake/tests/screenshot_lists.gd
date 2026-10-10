extends SceneTree
func _init() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var cl := Control.new()
	cl.set_script(load("res://ui/card_list.gd"))
	root.add_child(cl)
	await create_timer(0.8).timeout
	cl._on_slot_enter(33)
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/card_list.png")
	cl.queue_free()
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	root.add_child(ed)
	await create_timer(0.8).timeout
	ed._show_detail(ed.deck.main[ed.deck.main.size() - 1])
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out + "/deck2.png")
	quit()
