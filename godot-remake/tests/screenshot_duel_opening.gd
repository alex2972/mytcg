extends SceneTree
func _init() -> void:
	await process_frame
	var setup = load("res://ui/duel_setup.gd").new()
	root.add_child(setup)
	await process_frame
	setup.start(3,"cpu_000","cpu_010")
	var j: JankenScreen
	for child in setup.get_children():
		if child is JankenScreen: j = child
	j.human_won = true
	j._show_order()
	j._choose_order(1,false)
	# Capture the chosen order crate, transition, title and complete deal.
	var images: Array[Image] = []
	var times: Array = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec()-started < 10000:
		await RenderingServer.frame_post_draw
		images.append(root.get_texture().get_image())
		times.append((Time.get_ticks_msec()-started)/1000.0)
		if setup.board != null: setup.board.ai_running = true
		await create_timer(0.05).timeout
	# Disk encoding occurs after animation, never inside the playback loop.
	for i in images.size():
		images[i].save_png("Z:/process/scratch/duel-opening-preview/frame_%03d.png"%i)
	var manifest := FileAccess.open("Z:/process/scratch/duel-opening-preview/times.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify(times))
	setup.queue_free()
	await process_frame
	quit()
