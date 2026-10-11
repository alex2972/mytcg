extends SceneTree
## Cards of data/effects/batch17.json: negate-for-the-turn traps and cards that react to who destroyed what.

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

func place(d: Duel, p: int, zone: int, name: String, face_up := true, pos := "atk") -> DCard:
	return d.debug_place(p, idx(name), zone, face_up, pos)

func trap(d: Duel, p: int, zone: int, name: String) -> DCard:
	var c := d.debug_place_spell(p, idx(name), zone, false)
	c.summon_turn = -1
	return c

## Open the End Phase response window and let the first available response (a set trap) be chained.

func in_zone(d: Duel, p: int, zone: String, c: DCard) -> bool:
	return (d.side(p).get(zone) as Array).has(c)

func _init() -> void:
	db = CardDB.load_default()
	test_bait()
	print("effect tests 13: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_bait() -> void:
	var d := new_duel()
	var target := trap(d, 1, 0, "Trap Hole")
	var bait := d.debug_give(0, idx("Bait Doll"))
	check(d.activate_effect(0, bait) == "", "Bait Doll activates")
	d.respond([target.uid])
	settle(d)
	check(d.side(1).grave.has(target), "wrong timing Trap is destroyed")
	check(d.side(0).deck.has(bait) and not d.side(0).grave.has(bait), "Bait Doll shuffles itself into Deck")
	d = new_duel()
	target = trap(d, 1, 0, "Pot of Greed")
	bait = d.debug_give(0, idx("Bait Doll"))
	d.activate_effect(0, bait)
	d.respond([target.uid])
	settle(d)
	check(d.side(1).spells.has(target) and not target.face_up, "non Trap stays face down")
	d = new_duel()
	target = trap(d, 1, 0, "Waboku")
	target.summon_turn = -1
	bait = d.debug_give(0, idx("Bait Doll"))
	d.activate_effect(0, bait)
	d.respond([target.uid])
	settle(d)
	check(d.side(1).grave.has(target) and d.has_turn_rule("no_battle_damage", 1), "legal Trap forced without a response chain")

	# Bait Doll cannot be countered by the Trap that it itself forces to resolve.
	d = new_duel()
	target = trap(d, 1, 0, "Magic Jammer")
	var cost_card := d.debug_give(1, idx("Axe Raider"))
	bait = d.debug_give(0, idx("Bait Doll"))
	d.activate_effect(0, bait)
	d.respond([target.uid])
	settle(d)
	check(d.side(1).grave.has(target) and d.side(1).grave.has(cost_card) and d.side(0).deck.has(bait), "forced counter pays cost but cannot negate resolving Bait Doll")
	d = new_duel()
	d.debug_place(0, idx("Jinzo"), 0, true)
	target = trap(d, 1, 0, "Gravity Bind")
	bait = d.debug_give(0, idx("Bait Doll"))
	d.activate_effect(0, bait)
	d.respond([target.uid])
	settle(d)
	check(target.face_up and d.is_on_field(target) and d.fx.effects_of(target).is_empty(), "Jinzo leaves forced Continuous Trap face-up and negated")
	d.destroy_card(d.side(0).monsters[0], "effect")
	settle(d)
	check(not d.fx.effects_of(target).is_empty(), "Continuous Trap resumes after Jinzo leaves")
	d = new_duel()
	target = trap(d, 1, 0, "Waboku")
	target.summon_turn = d.turn
	bait = d.debug_give(0, idx("Bait Doll"))
	d.activate_effect(0, bait)
	d.respond([target.uid])
	settle(d)
	check(d.side(1).grave.has(target) and not d.has_turn_rule("no_battle_damage", 1), "Trap Set this turn has incorrect activation timing")
