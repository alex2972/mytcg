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
func click(double := false) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.double_click = double
	return e
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
	d.side(0).hand.clear()
	var first := d.debug_place(0, idx(db, "Armored Starfish"), 0, true)
	var second := d.debug_place(0, idx(db, "Axe Raider"), 1, true)
	var boss := d.debug_give(0, idx(db, "Blue-Eyes White Dragon"))
	check(b._tribute_instruction(2).contains("2 monsters"), "two-tribute instruction names two monsters")
	check(d.summon(0, boss, [second, first]) == "", "two tribute summon succeeds in reverse selection order")
	check(d.side(0).monsters[0] == boss and d.side(0).monsters[2] == null, "summon reuses leftmost tribute zone")
	b._sync(false)
	check(b._stat_texture(boss, "atk").resource_path.ends_with("duel_fontm.png"), "base ATK uses neutral digits")
	boss.atk_bonus = 500
	check(b._stat_texture(boss, "atk").resource_path.ends_with("duel_fontm_b.png"), "boosted ATK uses blue digits")
	boss.def_bonus = -500
	check(b._stat_texture(boss, "def").resource_path.ends_with("duel_fontm_r.png"), "reduced DEF uses red digits independently")
	check(b._frame_for(boss) == null, "unavailable position action has no red frame")
	var target := d.debug_place_spell(1, idx(db, "Trap Hole"), 0, false)
	var mst := d.debug_give(0, idx(db, "Mystical Space Typhoon"))
	d.fx.push_script([{ "op": "select", "as": "t", "from": "opp.spells", "n": 1, "auto": false}], {"src": mst, "controller": 0, "vars": {}, "event": {}, "effect": {}})
	d.fx.pump()
	b._sync(false)
	check(b._hover_cursor(target) == "on", "opponent target uses selection cursor")
	check(b._frame_for(target) == b._ui("card/card_waku#s"), "target has neutral selection frame")
	d.respond([target.uid])
	d.fx.push_script([{ "op": "select", "as": "t", "from": "self.hand", "n": 1, "auto": false, "cost": true}], {"src": mst, "controller": 0, "vars": {}, "event": {}, "effect": {}})
	d.fx.pump()
	check(b._hover_cursor(mst) == "on", "cost selection never offers Activate")
	d.respond([mst.uid])
	for player in 2:
		for kind in ["grave", "extra"]:
			var contents: Array = d.side(player).get(kind)
			contents.clear()
			for i in 7:
				var c := d.debug_give(player, idx(db, "Axe Raider"))
				d.side(player).hand.erase(c)
				contents.append(c)
			var original: Array = contents.duplicate()
			b._on_pile_input(click(), player, kind)
			check(b.pile_browser == null, "single click does not open pile")
			b._on_pile_input(click(true), player, kind)
			check(b.pile_browser != null and b.modal_depth == 1, "double-click opens pile for either side")
			check(b.pile_cards[0] == contents.back() and b.pile_cards.back() == contents[0], "pile shows top to bottom in order")
			b._pile_move(1)
			check(b.pile_page == 1, "pile can browse beyond five cards")
			b._show_card_detail(b.pile_cards[0])
			check(b.detail_card == b.pile_cards[0], "pile hover shows full details including opponent Extra Deck")
			b._close_pile()
			check(contents == original and b.modal_depth == 0, "closing browser preserves pile and unblocks play")
	# Refresh while a sword flies cannot recreate the idle sword.
	d.phase = "battle"
	d.normal_summoned = false
	boss.summon_turn = -1
	d.no_first_turn_attack = false
	b.mode = DuelBoard.Mode.IDLE
	b.anim_busy = false
	b._sync(false)
	b._refresh_swords()
	check(b.idle_swords.has(boss.uid), "attackable monster has an idle sword")
	b._take_sword(boss)
	b.mode = DuelBoard.Mode.ATTACK_TARGET
	b.anim_busy = true
	b._refresh_swords()
	check(not b.idle_swords.has(boss.uid), "sword is not recreated during flight")
	b.anim_busy = false
	boss.attacked = true
	b._cancel_mode()
	check(not b.idle_swords.has(boss.uid), "spent attack has no respawned sword")
	# Banners await the previous sprite's removal before starting the next.
	var completed: Array = []
	b.fx.banner_finished.connect(func(): completed.append(b.fx.get_child_count()))
	b.fx.banner(["phase_name/e_m2_b"], 0.0, 0.02)
	await b.fx.banner(["phase_name/e_en_b"], 0.0, 0.02)
	await process_frame
	check(completed == [0, 0] and not b.fx.running, "queued banners finish with no overlapping sprites: %s running=%s" % [completed, b.fx.running])
	var audio := root.get_node("Audio")
	audio.music("m_win")
	check(not audio.music_player.stream.loop, "victory music never loops")
	audio.music("m_lose")
	check(not audio.music_player.stream.loop, "defeat music never loops")
	audio.music("m_duel1")
	check(audio.music_player.stream.loop, "duel background music still loops")
	b.queue_free()
	await process_frame
	print("UI parity tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
