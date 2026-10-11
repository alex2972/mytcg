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
	var d := new_duel()
	var immortal := place(d, 0, 0, "The Immortal of Thunder")
	d.send_to_grave(immortal, "effect")
	settle(d)
	check(d.side(0).lp == 8000, "face-up Immortal never flipped does not lose LP")
	d = new_duel()
	immortal = place(d, 0, 0, "The Immortal of Thunder", false, "def")
	d.force_position(immortal, "atk", true)
	settle(d)
	check(d.side(0).lp == 11000, "Immortal flip gains 3000")
	d.send_to_grave(immortal, "effect")
	settle(d)
	check(d.side(0).lp == 6000, "previously flipped Immortal loses 5000 after field cleanup")
	d = new_duel()
	immortal = place(d, 0, 0, "The Immortal of Thunder", false, "def")
	d.force_position(immortal, "atk", true)
	settle(d)
	d.force_position(immortal, "def", false)
	d.send_to_grave(immortal, "effect")
	settle(d)
	check(d.side(0).lp == 11000, "setting Immortal again resets flipped history")
	d = new_duel()
	var spear := place(d, 0, 0, "Spear Cretin")
	var victim := d.debug_give(0, idx("Axe Raider"))
	d.send_to_grave(victim, "effect")
	d.send_to_grave(spear, "effect")
	check(d.fx.pending.is_empty(), "never-flipped face-up Spear Cretin cannot trigger")
	d = new_duel()
	spear = place(d, 0, 0, "Spear Cretin", false, "def")
	victim = d.debug_give(0, idx("Axe Raider"))
	d.send_to_grave(victim, "effect")
	d.force_position(spear, "atk", true)
	settle(d)
	d.send_to_grave(spear, "effect")
	check(not d.fx.pending.is_empty(), "flipped Spear offers revival after cleanup")
	settle(d)
	check(not d.monsters_of(0).is_empty(), "Spear revival resolves")
	d = new_duel()
	var riot := trap(d, 0, 0, "Major Riot")
	var borrowed := place(d, 0, 0, "Axe Raider")
	borrowed.owner = 1
	d.effect_player = 1
	d.return_to_hand(borrowed)
	check(d.fx.options_for(0, "returned_to_hand", {"player": 0, "uid": borrowed.uid, "by": 1}).any(func(o): return o["uid"] == riot.uid), "Riot responds for opponent-owned monster previously controlled by player")
	test_lightforce()
	print("native history tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_lightforce() -> void:
	for active in 2:
		var d := new_duel()
		d.turn_player = active
		var source := d.debug_give(0, idx("Lightforce Sword"))
		var captive := d.debug_give(1, idx("Axe Raider"))
		var delay := 6 if active == 1 else 7
		d.fx.ops.run({"op": "banish_random_hand", "who": "opp", "owner_turns": 4}, {"src": source, "controller": 0, "vars": {}, "event": {}})
		check(int(captive.flags.get("return_turn", -1)) == d.turn + delay, "Lightforce counts opponent's fourth turn from activation")
		for i in delay - 1:
			next_turn(d)
			check(d.side(1).banished.has(captive), "Lightforce captive remains removed before fourth opponent turn")
		next_turn(d)
		check(d.turn_player == 1 and d.side(1).hand.has(captive), "Lightforce returns captive on fourth opponent turn")
