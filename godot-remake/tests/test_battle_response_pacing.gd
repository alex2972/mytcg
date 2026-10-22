extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(db: CardDB, card_name: String) -> int:
	return int(db.search(card_name).filter(func(i): return db.card_name(i) == card_name)[0])
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var b := DuelBoard.new(db, deck, deck, 7)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.phase = "battle"
	d.no_first_turn_attack = false
	var attacker := d.debug_place(0, idx(db, "Summoned Skull"), 0)
	attacker.summon_turn = -1
	var defender := d.debug_place(1, idx(db, "Axe Raider"), 0, true, "def")
	var dice := d.debug_place_spell(1, idx(db, "Graceful Dice"), 0, false)
	dice.summon_turn = -1
	b._sync(false)
	d.drain_events()
	check(d.attack(0, attacker, defender) == "", "attack starts")
	check(not d.fx.pending.is_empty() and d.fx.pending["player"] == 1, "opponent receives real battle response")
	await b._after_action()
	# Isolate response scheduling from visual durations. A deliberately long
	# ordinary AI delay must never become a pause inside this attack.
	b.ai_delay = 2.0
	b.ai_running = false
	var started := Time.get_ticks_msec()
	await b._maybe_ai()
	check(Time.get_ticks_msec() - started < 500, "battle responses bypass normal AI thinking delay")
	check(d.current_attack.is_empty() and d.fx.pending.is_empty(), "response and battle finish cleanly")
	check(not b.anim_busy, "input lock releases after battle")
	b.queue_free()
	await process_frame
	print("battle response pacing tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
