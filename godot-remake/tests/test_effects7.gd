extends SceneTree
## Card effect scenarios for data/effects/batch9.json.

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

func mon(d: Duel, p: int, zone: int, atk: int, def := 1000, face_up := true, pos := "atk", base := "Armored Starfish") -> DCard:
	var c := d.debug_place(p, idx(base), zone, face_up, pos)
	c.atk_bonus = atk - d.atk_of(c)
	c.def_bonus = def - d.def_of(c)
	return c

func _init() -> void:
	db = CardDB.load_default()
	var d := new_duel()
	d.debug_place(0, idx("Alligator's Sword"), 0, true, "atk")
	var ext := d._new_card(idx("Alligator's Sword Dragon"), 0)
	d.side(0).extra.append(ext)
	d.debug_give(0, idx("Goddess with the Third Eye"))
	var poly := d.debug_give(0, idx("Polymerization"))
	var why := d.activate_effect(0, poly, 0)
	check(why == "", "Polymerization with a Third Eye substitute (%s)" % why)
	d.respond([ext.uid])
	settle(d)
	check((d.side(0).monsters as Array).has(ext), "the Fusion with a substitute material succeeded")

	d = new_duel()
	d.debug_place_spell(1, idx("Chain Destruction"), 0, false).summon_turn = -1
	var a1 := d.debug_give(0, idx("Armored Starfish"))
	d.debug_give(0, idx("Armored Starfish"))
	d.side(0).deck.append(d._new_card(idx("Armored Starfish"), 0))
	d.summon(0, a1)
	settle(d, "activate")
	var copies := 0
	for c in d.side(0).hand + d.side(0).deck:
		if db.card_name(c.idx) == "Armored Starfish":
			copies += 1
	check((d.side(0).monsters as Array).has(a1) and copies == 0, "Chain Destruction destroys the other copies in hand and deck (%d left)" % copies)

	d = new_duel()
	var doomed := mon(d, 0, 0, 500, 500)
	d.debug_place_spell(0, idx("Time Machine"), 0, false).summon_turn = -1
	var killer := mon(d, 1, 0, 2000, 1000)
	killer.summon_turn = -1
	d.end_turn(0)
	settle(d)
	d.phase = "battle"
	d.attack(1, killer, doomed)
	settle(d, "activate")
	check((d.side(0).monsters as Array).has(doomed), "Time Machine brings the destroyed monster back")

	d = new_duel()
	var dc := d.debug_place(0, idx("Dream Clown"), 0, true, "atk")
	dc.summon_turn = -1
	var foe := mon(d, 1, 0, 1000, 1000)
	d.change_position(0, dc)
	settle(d)
	check(d.side(1).grave.has(foe), "Dream Clown destroys a monster when it changes to Defense")

	d = new_duel()
	var rj := d.debug_place(0, idx("Revival Jam"), 0, true, "atk")
	rj.summon_turn = -1
	var big := mon(d, 1, 0, 3000, 3000)
	big.summon_turn = -1
	d.end_turn(0)
	settle(d)
	d.phase = "battle"
	d.attack(1, big, rj)
	settle(d)
	check(d.side(0).grave.has(rj), "Revival Jam was destroyed in battle")
	d.end_turn(1)
	settle(d)
	check((d.side(0).monsters as Array).has(rj) and d.side(0).lp == 8000 - 1500 - 1000, "Revival Jam returns at my next Standby Phase for 1000 LP (LP %d)" % d.side(0).lp)

	print("effect tests 7: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
