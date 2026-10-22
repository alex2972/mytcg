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
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	for p in 2:
		d.side(p).deck.clear()
		d.side(p).hand.clear()
	d.phase = "main1"
	var jar := d.debug_place(0, idx(db, "Morphing Jar #2"), 0, false, "def")
	jar.summon_turn = -1
	var high := d.debug_place(1, idx(db, "Blue-Eyes White Dragon"), 0)
	b._sync(false)
	d.drain_events()
	b.fx_enabled = true
	d.fx.presentation_enabled = true
	var stages: Array = []
	var reveal_count := 0
	b.fx.animation_stage.connect(func(kind, stage):
		stages.append([kind, stage])
		if kind == "excavate" and stage == "reveal":
			check(b.anim_busy, "excavation preview blocks input")
			var uid: int = d.fx.pending._task.ctx.vars.jar2.top.uid
			check(b.views[uid].shown_face_up and d.side(d.fx.pending.player).deck.has(d.card_by_uid(uid)), "card is revealed before removal from deck"))
	var why := d.change_position(0, jar)
	check(why == "", "actual Flip Summon activates Jar")
	b._do(why)
	var deadline := Time.get_ticks_msec() + 16000
	while b.anim_busy and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not b.anim_busy and d.fx.pending.is_empty(), "effect presentation finishes and releases input")
	for stage in stages:
		if stage == ["excavate", "reveal"]: reveal_count += 1
	check(reveal_count == 2, "both players see exactly one excavation")
	check(d.side(0).monsters.has(jar) and not jar.face_up and jar.pos == "def", "excavated Jar returns face-down without triggering another Flip")
	check(d.side(1).grave == [high] and d.monsters_of(1).is_empty(), "opponent's high-Level monster goes to Graveyard")
	check(stages.has(["set_monster", "ring"]), "face-down Special Summon uses yellow Set animation")
	check(not b.views[jar.uid].shown_face_up and is_equal_approx(b.views[jar.uid].rotation_degrees, 90.0), "final Jar view is hidden in Defense")
	check(b.fx.get_child_count() == 0, "presentation leaves no effect nodes behind")
	b.queue_free()
	await process_frame
	print("Morphing Jar #2 UI: ", "OK" if fails == 0 else str(fails) + " FAILED")
	quit(0 if fails == 0 else 1)
