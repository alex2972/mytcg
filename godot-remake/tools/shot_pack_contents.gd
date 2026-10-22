extends SceneTree
## Windowed helper: saves the Shop (with the CARD LIST button) and the MONSTERS 1 card list, top and
## scrolled, to the folder given after "--". Uses a throwaway account folder (user://shot_accounts).
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
	root.get_texture().get_image().save_png(out + "/shop_button.png")
	shop.select_product(int(args[1]) if args.size() > 1 else 0)
	await shop.show_contents()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/contents_top.png")
	shop.contents_view.scroll.scroll_vertical = 420
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/contents_scrolled.png")
	quit()
