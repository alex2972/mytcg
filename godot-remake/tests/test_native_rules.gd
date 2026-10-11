extends SceneTree
var db: CardDB
var fails := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)
func idx(name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name: return i
	return 0
func fresh() -> Duel:
	var deck := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var d := Duel.create(db, deck, deck, 3, 0)
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	return d
func settle(d: Duel) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 100:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"chain": d.respond("pass")
			"select": d.respond((p["candidates"] as Array).slice(0, int(p["max"])))
			"choice": d.respond(0)
			"yesno": d.respond(true)
func _init() -> void:
	db = CardDB.load_default()
	test_jam()
	test_scapegoat()
	test_garuda()
	print("native rules tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
func test_jam() -> void:
	var d := fresh()
	var jam := d.debug_place_spell(0, idx("Jam Breeding Machine"), 0, true)
	var c := d.debug_give(0, idx("Armored Starfish"))
	check(d.summon(0, c) != "", "Jam blocks controller Normal Summon")
	check(d.special_summon(c, 0) != "", "Jam blocks controller Special Summon")
	check(d.summon(0, c, [], -1, true) == "", "Jam permits a monster Set")
	c.summon_turn = -1
	check(d.change_position(0, c) != "", "Jam blocks Flip Summon")
	var other := d.debug_give(1, idx("Armored Starfish"))
	check(d.special_summon(other, 1) == "", "Jam does not restrict opponent")
	settle(d)
	d.fx.window("standby_phase", {"player": 0})
	settle(d)
	check(d.monsters_of(0).filter(func(m): return m.token == "Slime Token").size() == 1, "Jam creates its Slime Token despite lock")
	d.add_turn_rule("neg_continuous_spell", 0)
	check(d.special_summon(c, 0) == "", "Negating Jam releases summon lock")
func test_scapegoat() -> void:
	var d := fresh()
	d.debug_place(0, idx("Armored Starfish"), 0)
	d.debug_place(0, idx("Armored Starfish"), 1)
	var goat := d.debug_give(0, idx("Scapegoat"))
	check(d.activate_effect(0, goat) != "", "Scapegoat requires four free zones")
	d = fresh()
	var summoned := d.debug_give(0, idx("Armored Starfish"))
	check(d.summon(0, summoned) == "", "Preparation Normal Summon")
	settle(d)
	goat = d.debug_give(0, idx("Scapegoat"))
	check(d.activate_effect(0, goat) != "", "Scapegoat cannot follow a Normal Summon")
	d = fresh()
	summoned = d.debug_give(0, idx("Armored Starfish"))
	check(d.special_summon(summoned, 0) == "", "Preparation Special Summon")
	settle(d)
	goat = d.debug_give(0, idx("Scapegoat"))
	check(d.activate_effect(0, goat) != "", "Scapegoat cannot follow a Special Summon")
	d = fresh()
	var facedown := d.debug_place(0, idx("Armored Starfish"), 0, false, "def")
	facedown.summon_turn = -1
	check(d.change_position(0, facedown) == "", "Preparation Flip Summon")
	settle(d)
	goat = d.debug_give(0, idx("Scapegoat"))
	check(d.activate_effect(0, goat) != "", "Scapegoat cannot follow a Flip Summon")
	d = fresh()
	goat = d.debug_give(0, idx("Scapegoat"))
	check(d.activate_effect(0, goat) == "", "Scapegoat activates before summons")
	settle(d)
	check(d.monsters_of(0).size() == 4, "Scapegoat creates all four tokens")
	var c := d.debug_give(0, idx("Armored Starfish"))
	check(d.summon(0, c) != "", "Scapegoat blocks later Normal Summon")
	check(d.special_summon(c, 0) != "", "Scapegoat blocks later Special Summon")
	check(d.summon(0, c, [], -1, true) == "", "Scapegoat permits monster Set")
	c.summon_turn = -1
	check(d.change_position(0, c) != "", "Scapegoat blocks later Flip Summon")

	d._end_of_turn_cleanup()
	check(d.special_summon_problem(c, 0) == "", "Scapegoat summon restriction expires at turn end")
	d = fresh()
	goat = d.debug_give(0, idx("Scapegoat"))
	var response := d.debug_place_spell(1, idx("Magic Jammer"), 0, false)
	response.summon_turn = -1
	d.debug_give(1, idx("Armored Starfish"))
	check(d.activate_effect(0, goat) == "", "Scapegoat starts with sufficient zones")
	d.debug_place(0, idx("Armored Starfish"), 0)
	d.debug_place(0, idx("Armored Starfish"), 1)
	settle(d)
	check(d.monsters_of(0).size() == 2, "Scapegoat rechecks space at resolution and produces no partial tokens")
	check(not d.has_turn_rule("no_summon", 0), "Failed Scapegoat resolution does not install summon lock")

func test_garuda() -> void:
	var d := fresh()
	d.debug_place(0, idx("Garuda the Wind Spirit"), 0, true, "atk")
	var target := d.debug_place(1, idx("Armored Starfish"), 0, true, "atk")
	d.turn_player = 1
	d.fx.window("end_phase", {"player": 1})
	check(d.fx.pending.get("type", "") == "yesno", "Garuda asks whether to use its position change")
	d.respond(false)
	settle(d)
	check(target.pos == "atk", "Declining Garuda leaves target unchanged")
	d.fx.window("end_phase", {"player": 1})
	check(d.fx.pending.get("type", "") == "yesno", "Garuda can be offered next End Phase")
	d.respond(true)
	check(d.fx.pending.get("type", "") == "select", "Accepting Garuda opens target selection")
	d.respond([target.uid])
	settle(d)
	check(target.pos == "def", "Garuda changes selected face-up opponent monster")
