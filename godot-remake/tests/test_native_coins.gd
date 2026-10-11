extends SceneTree
## Original coin call UI: FUN0058da80/005835f0/00585540/0058ed20.

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
	for call in 2:
		for seed_value in [1, 2, 3, 4]:
			var d := new_duel(seed_value)
			var goddess := place(d, 0, 0, "Goddess of Whim")
			var original := d.atk_of(goddess)
			d.activate_effect(0, goddess)
			var guard := 0
			while d.fx.pending.get("type", "") == "chain" and guard < 10:
				d.respond("pass")
				guard += 1
			check(d.fx.pending.get("labels", []) == ["Heads", "Tails"], "Goddess asks for a call before tossing")
			check(d.respond(2) != "", "invalid coin call rejected")
			d.respond(call)
			settle(d)
			var toss: Dictionary = {}
			for event in d.events:
				if event.get("type", "") == "coin": toss = event
			# log_event stores payload directly in the event record.
			check(not toss.is_empty(), "coin outcome recorded")
			if not toss.is_empty():
				var correct: bool = bool(toss["heads"]) == (call == 0)
				check(bool(toss["correct"]) == correct, "success depends on the player's call")
				check(d.atk_of(goddess) == original * 2 if correct else d.atk_of(goddess) == original / 2, "called coin selects correct ATK result")
	for name in ["Time Wizard", "Fairy Box", "Gamble"]:
		var data: Array = EffectDB.load_default(db).for_number(int(db.cards[idx(name)]["number"]))
		var found := false
		for effect in data:
			for step in effect.get("do", []):
				if step.get("op", "") == "choice" and step.get("as", "") == "coin_call": found = true
		check(found, "%s offers a coin call" % name)
	print("native coin tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
