extends SceneTree
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func record(stem: String, count: int) -> void:
	var images: Array[Image] = []
	var times: Array = []
	var began := Time.get_ticks_msec()
	for i in count:
		await RenderingServer.frame_post_draw
		times.append((Time.get_ticks_msec()-began)/1000.0)
		images.append(root.get_texture().get_image())
		await create_timer(0.05).timeout
	for i in images.size():
		images[i].save_png("Z:/process/scratch/battle-reference-preview/%s_%03d.png" % [stem,i])
	var manifest := FileAccess.open("Z:/process/scratch/battle-reference-preview/"+stem+"_times.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify(times))
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc",db)
	var b := DuelBoard.new(db,deck,deck,3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.turn_player = 1
	d.phase = "main1"
	d.no_first_turn_attack = false
	var actor := d.debug_place(1,idx(db,"Summoned Skull"),2)
	var defender := d.debug_place(0,idx(db,"Axe Raider"),2,true,"def")
	actor.summon_turn = -1
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	await create_timer(0.2).timeout
	b._do(d.to_battle(1))
	await record("phase",30)
	while b.anim_busy: await process_frame
	b._do(d.attack(1,actor,defender))
	await record("attack",65)
	while b.anim_busy: await process_frame
	b._do(d.to_main2(1))
	await record("main2",20)
	b.queue_free()
	await process_frame
	quit()
