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
	for set_spell in [false, true]:
		var b := DuelBoard.new(db, deck, deck, 3)
		b.ai_delay = 0.0
		b.ai_running = true
		root.add_child(b)
		await process_frame
		b.duel.side(0).hand.clear()
		var played := b.duel.debug_give(0, idx(db, "Mystical Space Typhoon" if set_spell else "Axe Raider"))
		var other := b.duel.debug_give(0, idx(db, "Armored Starfish"))
		b._sync(false)
		b.duel.drain_events()
		var stages: Array = []
		b.fx.animation_stage.connect(func(kind, stage): stages.append([kind, stage]))
		b.fx_enabled = true
		b.hand_set_pref = set_spell
		b._card_action(played)
		await create_timer(0.05).timeout
		var motion: Tween = b.views[played.uid].motion
		# Real mouse enter/exit on a different hand card used to rebuild every card's layout.
		b._on_card_enter(b.views[other.uid])
		b._on_card_exit(b.views[other.uid])
		check(motion.is_valid() and motion.is_running(), "hover cannot cancel an awaited card flight")
		# A non-hover refresh must also respect the presentation's ownership of this view.
		b._sync(false)
		check(motion.is_valid() and motion.is_running(), "layout refresh preserves the in-flight event animation")
		await create_timer(1.8).timeout
		check(not b.anim_busy and b._can_act(), "input resumes after summon/Set despite hover and refresh")
		check(stages.has(["set", "ring"] if set_spell else ["summon", "rainbow"]), "arrival effect is played instead of skipped")
		check(b.views[played.uid].position.is_equal_approx(b._zone_pos(0, set_spell, 0)), "played card reaches its field zone")
		check(b.views[played.uid].scale.is_equal_approx(Vector2.ONE), "mid-flight flip completes")
		b._on_card_enter(b.views[other.uid])
		await create_timer(0.35).timeout
		check(b.views[other.uid].position.y == 466, "hand hover still raises cards after presentation")
		b.queue_free()
		await process_frame
	print("summon animation reentry tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
