extends SceneTree
func _init() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 1200)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	ed.working_path = "user://deck_filter_preview.ydc"
	viewport.add_child(ed)
	await process_frame
	viewport.canvas_transform = Transform2D(0, Vector2.ZERO).scaled(Vector2(2, 2))
	ed._show_detail(ed.db.search("Buster Blader")[0])
	for mode in ["before", "after"]:
		ed.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if mode == "before" else CanvasItem.TEXTURE_FILTER_NEAREST
		ed.pool.texture_filter = ed.texture_filter
		await create_timer(0.2).timeout
		viewport.get_texture().get_image().save_png("Z:/process/scratch/deck-crisp-" + mode + "-1600.png")
	viewport.queue_free()
	await process_frame
	quit()
