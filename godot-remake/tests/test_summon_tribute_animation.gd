extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(db: CardDB, card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	# Opponent summon: hidden hand -> midpoint flip -> landed card -> cropped rainbow.
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.turn_player = 1
	d.phase = "main1"
	d.side(1).hand.clear()
	var card := d.debug_give(1, idx(db,"Zombyra the Dark"))
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	var frames: Array = []
	b.fx.summon_frame_shown.connect(func(tick: float):
		var layer := b.fx.get_node("SummonRainbow")
		var ghost: TextureRect = layer.get_node("CardGhost")
		var rainbow: TextureRect = layer.get_node("RainbowCrop")
		var shader_material: ShaderMaterial = rainbow.material
		frames.append({"tick": tick, "ghost": ghost.visible, "rainbow": rainbow.visible, "scale": ghost.scale.x,
			"strength": shader_material.get_shader_parameter("strength"), "offset": shader_material.get_shader_parameter("offset_px"),
			"crop": shader_material.get_shader_parameter("crop_size"), "sheet": shader_material.get_shader_parameter("sheet_size")})
		check(b.views[card.uid].shown_face_up and b.views[card.uid].position.is_equal_approx(b._zone_pos(1,false,0)), "rainbow follows the face-up landed card")
		check(b.anim_busy, "input remains locked throughout summon effect"))
	b._do(d.summon(1,card))
	check(not b.views[card.uid].shown_face_up, "opponent card starts hidden during travel")
	await create_timer(1.65).timeout
	check(not b.anim_busy and b.fx.get_child_count() == 0, "normal summon finishes and removes all temporary art")
	check(frames.size() > 5, "summon renderer animates over multiple frames")
	if not frames.is_empty():
		check(frames.front()["ghost"] and frames.front()["scale"] == 0.5, "native prefix is a growing fading card miniature")
		check(frames.all(func(frame): return frame["rainbow"] == (frame["tick"] > 64)), "rainbow begins after the native prefix")
		check(frames.front()["crop"] == b.CARD and frames.front()["sheet"] == Vector2(100,94), "rainbow crops native pixels rather than shrinking the whole texture")
		check(frames.back()["offset"] == 160.0, "native tick*5/8 rainbow scrolling reaches 160 pixels")
		check(frames.any(func(frame): return frame["strength"] > 0.74), "rainbow uses original cosine opacity peak")
	b.queue_free()
	await process_frame
	# One and two Tributes: Graveyard handoff occurs while field afterimages continue.
	for count in [1,2]:
		b = DuelBoard.new(db,deck,deck,3)
		b.ai_delay = 0.0
		b.ai_running = true
		root.add_child(b)
		await process_frame
		d = b.duel
		d.side(0).hand.clear()
		var tributes: Array = []
		for zone in count: tributes.append(d.debug_place(0,idx(db,"Axe Raider"),zone))
		var summoned := d.debug_give(0,idx(db,"Summoned Skull" if count == 1 else "Blue-Eyes White Dragon"))
		var spare := d.debug_give(0,idx(db,"Armored Starfish"))
		b._sync(false)
		d.drain_events()
		var stages: Array = []
		b.fx.animation_stage.connect(func(kind, stage): stages.append([kind,stage]))
		b.fx_enabled = true
		var rng_state := d.rng.state
		b._do(d.summon(0,summoned,tributes))
		await create_timer(0.55).timeout
		check(b.views[tributes[0].uid].position.is_equal_approx(b._zone_pos(0,false,0)), "tribute remains at its former field position during gold ring/white buildup")
		await create_timer(0.3).timeout
		check(b.views[tributes[0].uid].position.is_equal_approx(b._pile_pos("p0_grave") + Vector2(6,0)) and b.fx.active_tributes > 0, "Graveyard updates before field afterimage finishes, without an intact-card flight")
		for i in 40:
			b._on_card_enter(b.views[spare.uid])
			b._on_card_exit(b.views[spare.uid])
			await create_timer(0.08).timeout
			if not b.anim_busy: break
		check(not b.anim_busy and b._can_act(), "Tribute Summon remains playable after hover during animation")
		check(stages.count(["tribute","ring"]) == count and stages.count(["tribute","white_card"]) == count, "each tribute plays gold ring then white-card afterimage exactly once")
		check(stages.count(["summon","rainbow"]) == 1, "new monster gets one normal summon rainbow")
		check(d.side(0).grave.size() == count and d.side(0).monsters[0] == summoned, "tributes enter Graveyard once and new monster occupies first vacated zone")
		check(b.fx.active_tributes == 0 and b.fx.get_child_count() == 0, "all overlapping afterimages finish before input resumes")
		check(d.rng.state == rng_state, "summon and tribute visuals leave duel RNG unchanged")
		b.queue_free()
		await process_frame
	print("summon/Tribute animation tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
