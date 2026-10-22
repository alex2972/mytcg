extends SceneTree
## Windowed helper: renders the Shop, then the pack opening as a frame sequence (every 0.2 s) to PNGs
## in the folder given after "--". Uses a throwaway account folder (user://shot_accounts).
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	root.size = Vector2i(800, 600)
	root.get_node("Session").use_root("user://shot_accounts")
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	shell.current.action.emit("shop")
	for i in 5: await process_frame
	var shop = shell.current
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/shop.png")
	shop.buy(int(args[1]) if args.size() > 1 else 0)
	var start := Time.get_ticks_msec()
	var n := 0
	while n < 60:
		await RenderingServer.frame_post_draw
		if Time.get_ticks_msec() - start >= n * 200:
			root.get_texture().get_image().save_png(out + "/reveal_%02d.png" % n)
			n += 1
		if shop.reveal != null and shop.reveal.done and Time.get_ticks_msec() - start > n * 200 + 1500:
			break
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/reveal.png")
	quit()
