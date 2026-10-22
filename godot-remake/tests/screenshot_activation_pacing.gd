extends SceneTree
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1,db.cards.size()):
		if db.card_name(i)==card_name:return i
	return 0
func sequence(b: DuelBoard, mst: DCard) -> void:
	b.duel.activate_effect(1,mst)
	await b._after_action()
	var pending: Dictionary = b.duel.fx.pending
	var choices: Array[int] = []
	for uid in pending.get("candidates",[]): choices.append(int(uid))
	await create_timer(0.3).timeout
	JoeyAI.step(b.duel,1)
	await b._present_ai_target_choice(pending,choices)
	await b._after_action()
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
	d.phase = "end"
	d.debug_place_spell(0,idx(db,"Call Of The Haunted"),0,true)
	d.debug_place_spell(0,idx(db,"Trap Hole"),1,false)
	var mst := d.debug_place_spell(1,idx(db,"Mystical Space Typhoon"),0,false)
	d.debug_place(0,idx(db,"Axe Raider"),0)
	d.debug_place(1,idx(db,"Summoned Skull"),0)
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	b.decision_busy = true
	d.phase = "main1"
	await create_timer(0.2).timeout
	sequence(b,mst)
	var images: Array[Image] = []
	var times: Array = []
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start < 3500:
		await RenderingServer.frame_post_draw
		images.append(root.get_texture().get_image())
		times.append((Time.get_ticks_msec()-start)/1000.0)
		await create_timer(0.04).timeout
	for i in images.size():images[i].save_png("Z:/process/scratch/activation-preview/frame_%03d.png"%i)
	var manifest := FileAccess.open("Z:/process/scratch/activation-preview/times.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify(times))
	b.queue_free()
	await process_frame
	quit()
