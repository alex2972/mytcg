extends SceneTree
## Windowed helper: the shop notice and the 40-card refusal on the Duel screen. godot --path . -s tools/shot_notice.gd -- <folder>
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	root.size = Vector2i(800, 600)
	root.get_node("Session").use_root("user://shot_notice_accounts")
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/notice_shop.png")
	quit()
