extends SceneTree
var frames: Array[Image] = []
var labels: Array = []
func record(stem: String, duration: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start < duration*1000:
		await RenderingServer.frame_post_draw
		frames.append(root.get_texture().get_image())
		labels.append([stem,(Time.get_ticks_msec()-start)/1000.0])
		await create_timer(0.02).timeout
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var b := DuelBoard.new(db,deck,deck,3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	b.fx_enabled = true
	b.decision_busy = true
	await create_timer(0.2).timeout
	b.duel.damage_player(1,2500,"effect")
	b._after_action()
	await record("damage",1.15)
	while b.anim_busy: await process_frame
	b.duel.heal_player(1,2500)
	b._after_action()
	await record("heal",1.15)
	while b.anim_busy: await process_frame
	for i in frames.size():frames[i].save_png("Z:/process/scratch/lp-animation-preview/frame_%03d.png"%i)
	var manifest := FileAccess.open("Z:/process/scratch/lp-animation-preview/manifest.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify(labels))
	b.queue_free()
	await process_frame
	quit()
