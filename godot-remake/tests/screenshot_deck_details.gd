extends SceneTree
func _init() -> void:
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	ed.working_path = "user://deck_detail_preview.ydc"
	root.add_child(ed)
	await process_frame
	var axe: int = ed.db.search("Buster Blader")[0]
	ed._show_detail(axe)
	var card: TextureRect = ed.grids["main"].get_child(22)
	card.mouse_entered.emit()
	ed._show_detail(axe)
	root.warp_mouse(Vector2(220, 0))
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-details.png")
	root.warp_mouse(Vector2(100, 568))
	await create_timer(0.15).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-details-back-hover.png")
	ed.queue_free()
	await process_frame
	quit()
