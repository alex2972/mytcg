extends SceneTree
func _init() -> void:
	var ed := Control.new()
	ed.set_script(load("res://ui/deck_editor.gd"))
	ed.working_path = "user://deck_reference_preview.ydc"
	root.add_child(ed)
	await process_frame
	ed._apply_expansion(1.0)
	var names := ["Bottom Dweller", "Bubonic Vermin", "Burning Land", "Burning Spear", "Buster Blader", "Call of the Grave", "Call Of The Haunted", "Cannon Soldier", "Card Destruction", "Card of Safe Return"]
	var rows := []
	var counts := {}
	var amounts := [12, 13, 16, 19, 9, 17, 3, 10, 19, 13]
	for i in names.size():
		var matches: Array = ed.db.search(names[i]).filter(func(card): return ed.db.card_name(card).to_lower() == names[i].to_lower())
		assert(not matches.is_empty(), names[i])
		rows.append(matches[0])
		counts[matches[0]] = amounts[i]
	ed.pool.set_rows(rows)
	ed.pool.set_counts(counts, {})
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("Z:/process/scratch/deck-reference-match.png")
	ed.queue_free()
	await process_frame
	quit()
