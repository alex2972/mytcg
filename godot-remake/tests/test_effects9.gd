extends SceneTree
## Card effect scenarios for data/effects/batch12.json (the hard cases).

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
	while not d.fx.pending.is_empty() and guard < 80:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"select": d.respond((p["candidates"] as Array).slice(0, p["max"]))
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
	c.summon_turn = -1
	return c

func _init() -> void:
	db = CardDB.load_default()
	test_all()
	print("effect tests 9: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	# Exchange
	var d := new_duel()
	var mine := d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(0, idx("Exchange"))
	var theirs := d.debug_give(1, idx("Dark Hole"))
	var ex: DCard = d.side(0).hand[1]
	d.activate_effect(0, ex, 0)
	settle(d)
	check(d.side(0).hand.has(theirs) and d.side(1).hand.has(mine), "Exchange swaps one card between the hands")
	d.send_to_grave(theirs, "discard")
	check(d.side(1).grave.has(theirs), "a card taken with Exchange goes to its real owner's graveyard")
	# Jowgen
	d = new_duel()
	var jw := d.debug_place(0, idx("Jowgen the Spiritualist"), 0, true, "atk")
	jw.summon_turn = -1
	var spc := mon(d, 1, 0, 1000)
	spc.flags["special_summoned"] = true
	var normal := mon(d, 1, 1, 1000)
	d.debug_give(0, idx("Pot of Greed"))
	var why := d.fx.activation_problem(0, jw, 0, "", {})
	check(why == "", "Jowgen can be activated (%s)" % why)
	d.activate_effect(0, jw, 0)
	settle(d)
	check(d.side(1).grave.has(spc) and not d.side(1).grave.has(normal), "Jowgen destroys only Special Summoned monsters")
	var extra_mon := d._new_card(idx("Armored Starfish"), 0)
	check(d.special_summon(extra_mon, 0) != "", "while Jowgen is face-up nobody can Special Summon")
	# Dark Spirit of the Silent
	d = new_duel()
	var vic := mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Dark Spirit of the Silent"), 0, false).summon_turn = -1
	next_turn(d)
	var a1 := mon(d, 1, 0, 800)
	var a2 := mon(d, 1, 1, 2400)
	d.phase = "battle"
	d.attack(1, a1, vic)
	settle(d, "activate")
	check(d.side(0).grave.has(vic) or d.side(0).lp < 8000, "Dark Spirit made another monster attack (a stronger one: LP %d)" % d.side(0).lp)
	# Ekibyo Drakmord
	d = new_duel()
	var sick := mon(d, 1, 0, 1000)
	var ek := d.debug_give(0, idx("Ekibyo Drakmord"))
	d.activate_effect(0, ek, 0)
	settle(d)
	check(sick.equips.has(ek) and d.can_attack(1, sick) != "", "Ekibyo Drakmord: the equipped monster cannot attack")
	for i in 4:
		next_turn(d)
	check(d.side(1).grave.has(sick) and d.side(0).hand.has(ek), "...it is destroyed after its controller's 2nd turn and the card returns to my hand")
