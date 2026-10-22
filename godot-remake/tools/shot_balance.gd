extends SceneTree
## Windowed helper: renders the Shop header with a few balances. godot --path . -s tools/shot_balance.gd -- <folder>
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	root.size = Vector2i(800, 600)
	root.get_node("Session").use_root("user://shot_accounts")
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	shell.current.action.emit("shop")
	for i in 5: await process_frame
	var shop = shell.current
	for v in [2450, 1000000, 999999, 12]:
		shop.set_balance(v)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().get_region(Rect2i(540, 0, 260, 66)).save_png("%s/bal_%d.png" % [out, v])
	quit()
