extends SceneTree
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func _init() -> void:
	await process_frame
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	for first in 2:
		var d := Duel.create(db, deck, deck, 3, first, null, true)
		d.fx.presentation_enabled = true
		check(d.side(0).hand.is_empty() and d.side(1).hand.is_empty(), "opening starts with empty hands")
		d.start_opening_deal()
		for i in 10:
			var player: int = 1 - first if i < 5 else first
			var count: int = i % 5 + 1
			check(d.fx.pending.get("type", "") == "presentation", "each opening draw pauses for its presentation")
			check(d.side(player).hand.size() == count, "second player deals first, one card per acknowledgement")
			var events: Array = d.drain_events()
			check(events.size() == 1 and events[0]["type"] == "draw", "opening draw events do not overlap phases")
			d.respond(true)
		check(d.side(first).hand.size() == 5, "first player still has five before turn draw")
		d.respond(true) # next-turn barrier
		d.respond(true) # draw phase barrier
		check(d.side(first).hand.size() == 6 and d.side(1-first).hand.size() == 5, "first player draws for turn after both opening hands")
	var b := DuelBoard.new(db, deck, deck, 3)
	b.ai_delay = 0.0
	b.ai_running = true
	root.add_child(b)
	await process_frame
	var d := b.duel
	d.side(0).hand.clear()
	var a := d.debug_give(0, idx(db, "Axe Raider"))
	var other := d.debug_give(0, idx(db, "Armored Starfish"))
	b._sync(false)
	b._on_card_enter(b.views[a.uid])
	b.hand_set_pref = true
	b._on_card_enter(b.views[other.uid])
	check(not b.hand_set_pref and b._hover_cursor(other) == "summon", "hovering a different hand card resets Set preference")
	var hidden := d.debug_place_spell(0, idx(db, "Trap Hole"), 0, false)
	b._sync(false)
	b.modal_depth = 1
	b._preview_set_cards(b.views[hidden.uid].position + b.CARD / 2)
	check(b.detail_card == hidden, "own Set card can be inspected while modal response question is open")
	b.modal_depth = 0
	b.mode = DuelBoard.Mode.TRIBUTE
	b.pending_card = a
	b._highlight()
	check(b.views[hidden.uid].modulate == Color.WHITE, "selection does not tint card artwork")
	b._cancel_mode()
	var dialog := DuelDialog.new()
	dialog.setup("Activate?", "yesno")
	b.add_child(dialog)
	var answer: Array = []
	dialog.answered.connect(func(value): answer.append(value))
	var audio := root.get_node("Audio")
	var streams: Array = audio.players.map(func(player): return player.stream)
	var hover := InputEventMouseMotion.new()
	hover.position = dialog.panel.position + dialog._buttons()["yes"]
	dialog._on_input(hover)
	check(audio.players.map(func(player): return player.stream) == streams, "decision button hover plays no sound")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	dialog._on_input(right)
	check(answer == [false], "right-click answers No")
	b.fx_enabled = true
	var tribute_monster := d.debug_give(0, idx(db, "Summoned Skull"))
	b._card_action(tribute_monster)
	for child in b.get_children():
		if child is DuelDialog and not child.done: child._on_input(right)
	check(d.side(0).hand.has(tribute_monster) and b.mode == DuelBoard.Mode.IDLE and b.pending_card == null, "right-click cancels tribute setup before selection")
	b.fx_enabled = false
	check(root.get_node("GameCursor").layer > 1024, "custom cursor draws above embedded popup layer")
	# Isolated autosave path: never change the user's working deck in tests.
	var path := "res://tests/persistence_probe.ydc"
	check(deck.save_working(db, path) == OK, "working deck saves atomically")
	deck.side.append(idx(db, "Axe Raider"))
	check(deck.save_working(db, path) == OK, "autosave replaces an earlier save")
	var restored := Deck.load_working(db, path)
	check(restored.main == deck.main and restored.extra == deck.extra and restored.side == deck.side, "fresh load restores every deck section")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Choosing an attacker preserves other idle swords while keeping artwork untinted.
	d.no_first_turn_attack = false
	d.phase = "battle"
	var attacker := d.debug_place(0, idx(db, "Axe Raider"), 0, true)
	var second_attacker := d.debug_place(0, idx(db, "Armored Starfish"), 1, true)
	b._sync(false)
	b._update_ui()
	check(b.idle_swords.size() == 2, "both available attackers have idle swords")
	b._take_sword(attacker)
	b.mode = DuelBoard.Mode.ATTACK_TARGET
	b._update_ui()
	check(b.idle_swords.has(second_attacker.uid) and not b.idle_swords.has(attacker.uid) and b.active_sword != null, "other valid attackers keep their transparent swords while one is selected")
	check(b.views[second_attacker.uid].modulate == Color.WHITE, "attack selection preserves card colors")
	b._cancel_mode()
	# Activation barrier precedes dice; dice barrier precedes stat application.
	var dice := d.debug_place_spell(1, idx(db, "Graceful Dice"), 0, false)
	dice.summon_turn = -1
	var boosted := d.debug_place(1, idx(db, "Armored Starfish"), 0, true)
	d.phase = "battle"
	d.fx.presentation_enabled = true
	d.drain_events()
	var atk: int = d.atk_of(boosted)
	d.fx.window("attack_declared", {"player": 0})
	check(d.fx.pending.get("type", "") == "chain", "opponent Quick-Play response offered")
	d.respond({"uid": dice.uid, "idx": 0})
	var events: Array = d.drain_events()
	check(d.fx.pending.get("type", "") == "presentation" and events.filter(func(e): return e["type"] == "dice").is_empty(), "card activation presentation precedes rolling")
	check(events.filter(func(e): return e["type"] == "card_activated").size() == 1, "one activation event per card")
	d.respond(true)
	while d.fx.pending.get("type", "") == "chain": d.respond("pass")
	events = d.drain_events()
	check(d.fx.pending.get("type", "") == "presentation" and events.filter(func(e): return e["type"] == "dice").size() == 1, "dice presentation follows activation")
	check(d.atk_of(boosted) == atk, "stats remain unchanged while result animation runs")
	d.respond(true)
	check(d.atk_of(boosted) > atk, "stats apply only after dice animation acknowledgement")
	b.queue_free()
	await process_frame
	print("opening/UI/persistence tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
