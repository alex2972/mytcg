extends SceneTree
func _init() -> void:
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	ed.working_path = "user://deck_drawer_preview.ydc"
	root.add_child(ed)
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-collapsed.png")
	ed._toggle_collection()
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-expanded.png")
	root.warp_mouse(Vector2(660, 16))
	await create_timer(0.15).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-filters.png")
	ed.queue_free()
	await process_frame
	quit()
