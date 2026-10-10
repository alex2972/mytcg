extends SceneTree
## Card effect scenarios for data/effects/batch7.json.

var db: CardDB
var fails := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func idx(name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	push_error("no card " + name)
	return 0

func new_duel(seed_value := 1) -> Duel:
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var du := Duel.create(db, d, d, seed_value, 0)
	du.side(0).hand.clear()
	du.side(1).hand.clear()
	return du

func settle(d: Duel, chain_choice := "pass") -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 60:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"select":
				var c: Array = p["candidates"]
				d.respond(c.slice(0, p["max"]))
			"yesno": d.respond(true)
			"choice": d.respond(0)
			"chain":
				if chain_choice == "pass":
					d.respond("pass")
				else:
					var o: Dictionary = p["options"][0]
					d.respond({"uid": o["uid"], "idx": o["idx"]})

func next_turn(d: Duel) -> void:
	d.end_turn(d.turn_player)
	settle(d)

func mon(d: Duel, p: int, zone: int, atk: int, def := 1000, face_up := true, pos := "atk", base := "Armored Starfish") -> DCard:
	var c := d.debug_place(p, idx(base), zone, face_up, pos)
	c.atk_bonus = atk - d.atk_of(c)
	c.def_bonus = def - d.def_of(c)
	return c

func _init() -> void:
	db = CardDB.load_default()
	var d := new_duel()
	var bls := d.debug_give(0, idx("Black Luster Soldier"))
	var r := d.debug_give(0, idx("Black Luster Ritual"))
	check(d.fx.activation_problem(0, r, 0, "", {}) != "", "the ritual needs enough Levels")
	var a := d.debug_give(0, idx("Armored Starfish"))
	var b := d.debug_give(0, idx("Armored Lizard"))
	var lvs := d.level_of(a) + d.level_of(b)
	var ok := d.activate_effect(0, r, 0)
	check((lvs >= 8) == (ok == ""), "Black Luster Ritual activates only with total Level >= 8 (levels %d)" % lvs)
	if ok == "":
		settle(d)
		check((d.side(0).monsters as Array).has(bls) and bls.face_up, "Black Luster Soldier is Ritual Summoned")
		check(d.side(0).grave.has(a) or d.side(0).grave.has(b), "tributes went to the graveyard")
	d = new_duel()
	var m := d.debug_give(0, idx("Hungry Burger"))
	check(d.summon(0, m) != "", "a Ritual Monster cannot be Normal Summoned")
	d = new_duel()
	var hb := d.debug_give(0, idx("Hungry Burger"))
	var rr := d.debug_give(0, idx("Hamburger Recipe"))
	var big := d.debug_give(0, idx("Blue-Eyes White Dragon"))
	var f1 := d.debug_place(0, idx("Armored Starfish"), 0, true, "atk")
	var why := d.activate_effect(0, rr, 0)
	check(why == "", "Hamburger Recipe with field + hand monsters (%s)" % why)
	settle(d)
	check((d.side(0).monsters as Array).has(hb), "Hungry Burger arrives")
	test_misc()
	print("effect tests 6: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_misc() -> void:
	var d := new_duel()
	for n in ["Exodia the Forbidden One", "Left Leg of the Forbidden One", "Right Leg of the Forbidden One", "Left Arm of the Forbidden One"]:
		d.debug_give(0, idx(n))
	check(d.winner == -1, "four Exodia pieces do not win yet")
	d.side(0).deck.append(d._new_card(idx("Right Arm of the Forbidden One"), 0))
	d.draw_cards(0, 1)
	check(d.winner == 0 and d.win_reason == "exodia", "all five Exodia pieces in hand win the duel")
	d = new_duel()
	var asd := d.debug_place(0, idx("Alligator's Sword Dragon"), 0, true, "atk")
	asd.summon_turn = -1
	var earth := d.debug_place(1, idx("Armored Starfish"), 0, true, "atk")
	d.phase = "battle"
	var ok_attr := int(d.card_data(earth).get("attribute", 0)) in [5, 3, 4]
	check((d.attack(0, asd, null) == "") == ok_attr, "Alligator's Sword Dragon attacks directly only against EARTH/WATER/FIRE")
	d = new_duel()
	var jar := d.debug_place(0, idx("Cyber Jar"), 0, false, "def")
	jar.summon_turn = -1
	mon(d, 1, 0, 1000, 1000)
	d.change_position(0, jar)
	settle(d)
	check(d.side(0).grave.has(jar) and d.side(1).grave.size() >= 1, "Cyber Jar destroys everything")
	d = new_duel()
	var fish := d.debug_place(1, idx("The Legendary Fisherman"), 0, true, "atk")
	var att := mon(d, 0, 0, 2000, 1000)
	att.summon_turn = -1
	d.phase = "battle"
	check(d.attack(0, att, fish) == "", "the Fisherman can be attacked without Umi")
	settle(d)
