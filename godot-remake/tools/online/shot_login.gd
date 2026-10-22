extends SceneTree
## Windowed helper: renders the title screen and the online sign-in screen. godot --path . -s tools/online/shot_login.gd -- <folder>
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	root.size = Vector2i(800, 600)
	root.get_node("Session").use_root("user://shot_accounts")
	root.get_node("Session").online_cfg_path = "user://shot_accounts/online.cfg"
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/title.png")
	shell.current.action.emit("online")
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/login.png")
	quit()
