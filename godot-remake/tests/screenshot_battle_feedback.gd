extends SceneTree
var frames: Array[Image] = []
var labels: Array = []
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1,db.cards.size()):
		if db.card_name(i)==card_name:return i
	return 0
func record(stem: String, seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start < seconds*1000:
		await RenderingServer.frame_post_draw
		frames.append(root.get_texture().get_image())
		labels.append([stem,(Time.get_ticks_msec()-start)/1000.0])
		await create_timer(0.04).timeout
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
	d.phase = "main1"
	d.no_first_turn_attack = false
	var a := d.debug_place(0,idx(db,"Summoned Skull"),0)
	var other := d.debug_place(0,idx(db,"Axe Raider"),1)
	a.summon_turn = -1
	other.summon_turn = -1
	var target := d.debug_place(1,idx(db,"Armored Starfish"),0,true,"def")
	for i in 2:
		var grave_card := d.debug_give(1,idx(db,"Pot of Greed"))
		d.send_to_grave(grave_card,"fixture")
	b._sync(false)
	b._update_ui()
	d.drain_events()
	b.fx_enabled = true
	await create_timer(0.2).timeout
	var latency := {}
	var summoned := d.debug_give(0,idx(db,"Sangan"))
	b._sync(false)
	d.drain_events()
	var started := Time.get_ticks_usec()
	b._card_action(summoned)
	latency["summon_ms"] = (Time.get_ticks_usec()-started)/1000.0
	await record("summon",1.7)
	while b.anim_busy: await process_frame
	started = Time.get_ticks_usec()
	b._do(d.to_battle(0))
	latency["enter_battle_ms"] = (Time.get_ticks_usec()-started)/1000.0
	await record("phase",1.5)
	started = Time.get_ticks_usec()
	b._card_action(a)
	latency["pick_attacker_ms"] = (Time.get_ticks_usec()-started)/1000.0
	b._on_card_enter(b.views[target.uid])
	await record("hover",0.15)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	started = Time.get_ticks_usec()
	b._on_card_input(click,b.views[target.uid])
	latency["launch_attack_ms"] = (Time.get_ticks_usec()-started)/1000.0
	await record("attack",3.5)
	while b.anim_busy: await process_frame
	d.turn_player = 1
	d.phase = "draw"
	b._play_events([{"type":"turn","turn":2,"player":1}])
	await record("turn",1.4)
	for i in frames.size():frames[i].save_png("Z:/process/scratch/battle-feedback-preview/frame_%03d.png"%i)
	var manifest := FileAccess.open("Z:/process/scratch/battle-feedback-preview/manifest.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"frames":labels,"latency":latency}))
	b.queue_free()
	await process_frame
	quit()
