extends SceneTree
var visual_ticks := {"normal": -1.0, "tribute": -1.0}
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func record(stem: String, count: int) -> void:
	var timestamps: Array = []
	var images: Array[Image] = []
	var ticks: Array = []
	var began := Time.get_ticks_msec()
	for i in count:
		await RenderingServer.frame_post_draw
		timestamps.append((Time.get_ticks_msec() - began) / 1000.0)
		ticks.append(visual_ticks[stem])
		images.append(root.get_texture().get_image())
		await create_timer(0.05).timeout
	# Encode after playback, so PNG writes cannot disturb the animation clock.
	for i in images.size():
		images[i].save_png("Z:/process/scratch/summon-reference-preview/%s_%03d.png" % [stem, i])
	var manifest := FileAccess.open("Z:/process/scratch/summon-reference-preview/" + stem + "_times.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify(timestamps))
	var tick_file := FileAccess.open("Z:/process/scratch/summon-reference-preview/" + stem + "_ticks.json", FileAccess.WRITE)
	tick_file.store_string(JSON.stringify(ticks))
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.turn_player = 1
	d.phase = "main1"
	d.side(1).hand.clear()
	var monster := d.debug_give(1, idx(db,"Zombyra the Dark"))
	for i in 4: d.debug_give(1, idx(db,"Axe Raider"))
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.fx.summon_frame_shown.connect(func(tick): visual_ticks["normal"] = tick)
	b.fx.tribute_frame_shown.connect(func(tick): visual_ticks["tribute"] = tick)
	await create_timer(0.2).timeout
	b._do(d.summon(1, monster))
	await record("normal", 35)
	var summoned := d.debug_give(1, idx(db,"Summoned Skull"))
	d.normal_summoned = false
	b._sync(false)
	d.drain_events()
	await create_timer(0.2).timeout
	b._do(d.summon(1, summoned, [monster]))
	await record("tribute", 53)
	b.queue_free()
	await process_frame
	quit()
