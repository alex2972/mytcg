extends SceneTree
## Card effect scenarios for data/effects/batch5.json.

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
	test_spells()
	test_monsters()
	test_continuous()
	print("effect tests 4: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_spells() -> void:
	var d := new_duel()
	var h := d.side(0).hand.size()
	play(d, "Graceful Charity")
	check(d.side(0).hand.size() == h + 1 and d.side(0).grave.size() >= 2, "Graceful Charity: draw 3, discard 2 (hand %d)" % d.side(0).hand.size())
	d = new_duel()
	play(d, "Rain of Mercy")
	check(d.side(0).lp == 9000 and d.side(1).lp == 9000, "Rain of Mercy heals both players")
	d = new_duel()
	var tv2 := d.debug_place_spell(1, idx("Mirror Force"), 0, false)
	play(d, "Spiritualism")
	check(d.side(1).hand.has(tv2), "Spiritualism returns a Spell/Trap to its owner's hand")
	d = new_duel()
	var fd := mon(d, 1, 0, 1000, 1000, false, "def")
	play(d, "Nobleman of Crossout")
	check(d.side(1).banished.has(fd), "Nobleman of Crossout banishes a face-down monster")

func test_monsters() -> void:
	var d := new_duel()
	for i in 6:
		d.side(1).deck.append(d._new_card(idx("Armored Starfish"), 1))
	var deck_before := d.side(1).deck.size()
	var nw := d.debug_place(0, idx("Needle Worm"), 0, false, "def")
	d.change_position(0, nw)
	settle(d)
	check(d.side(1).deck.size() == deck_before - 5, "Needle Worm mills 5 cards")
	d = new_duel()
	var pw := d.debug_place(0, idx("Panther Warrior"), 0, true, "atk")
	pw.summon_turn = -1
	d.phase = "battle"
	check(d.attack(0, pw, null) != "", "Panther Warrior cannot attack alone")
	var fodder := mon(d, 0, 1, 500, 500)
	var tgt := mon(d, 1, 0, 500, 500)
	check(d.attack(0, pw, tgt) == "", "Panther Warrior attacks once it can offer a monster")
	settle(d)
	check(d.side(0).grave.has(fodder) and d.side(1).grave.has(tgt), "...it tributed its own monster and destroyed the target")
	d = new_duel()
	var rw := d.debug_place(0, idx("Rocket Warrior"), 0, true, "atk")
	rw.summon_turn = -1
	var big := mon(d, 1, 0, 3000, 3000)
	d.phase = "battle"
	d.attack(0, rw, big)
	settle(d)
	check(d.side(0).lp == 8000 and d.side(0).grave.has(rw), "Rocket Warrior: no battle damage taken")
	d = new_duel()
	var g := d.side(0).grave
	g.append(d._new_card(idx("Alligator's Sword"), 0))
	var asp := d.debug_give(0, idx("Aqua Spirit"))
	check(d.summon(0, asp) != "", "Aqua Spirit cannot be Normal Summoned")
	d = new_duel()
	var water := d._new_card(idx("Jellyfish"), 0)
	d.side(0).grave.append(water)
	var spirit := d.debug_give(0, idx("Aqua Spirit"))
	var why := d.activate_effect(0, spirit, 1)
	settle(d)
	check(why == "" and (d.side(0).monsters as Array).has(spirit) and d.side(0).banished.has(water), "Aqua Spirit special summons itself by banishing a WATER monster (%s)" % why)
	d = new_duel()
	var tsk := d.debug_give(0, idx("Toon Summoned Skull"))
	tsk.atk_bonus = 0
	var lv := d.level_of(tsk)
	check(d.summon(0, tsk, [mon(d, 0, 0, 100)] if lv >= 5 else []) != "", "Toon Summoned Skull needs Toon World")
	d = new_duel()
	var iq := mon(d, 0, 0, 100, 100, true, "atk", "Insect Queen")
	var before := d.atk_of(iq)
	mon(d, 0, 1, 100, 100, true, "atk", "Man-Eater Bug")
	check(d.atk_of(iq) == before + 200, "Insect Queen: +200 per Insect on the field (%d -> %d)" % [before, d.atk_of(iq)])

func test_continuous() -> void:
	var d := new_duel()
	d.debug_place_spell(0, idx("Solemn Wishes"), 0, true)
	d.draw_cards(0, 2)
	settle(d)
	check(d.side(0).lp == 9000, "Solemn Wishes: +500 LP per drawn card (%d)" % d.side(0).lp)
	d = new_duel()
	d.debug_place_spell(0, idx("Forced Requisition"), 0, true)
	d.debug_give(1, idx("Pot of Greed"))
	d.debug_give(1, idx("Pot of Greed"))
	var dis := d.debug_give(0, idx("Pot of Greed"))
	d.send_to_grave(dis, "discard")
	settle(d)
	check(d.side(1).hand.size() == 1, "Forced Requisition: the opponent discards too (%d)" % d.side(1).hand.size())
	d = new_duel()
	var eq := d.debug_give(0, idx("Fairy Meteor Crush"))
	var atk := mon(d, 0, 0, 2000, 1000)
	d.activate_effect(0, eq, 0)
	settle(d)
	var defm := mon(d, 1, 0, 500, 800, true, "def")
	atk.summon_turn = -1
	d.phase = "battle"
	d.attack(0, atk, defm)
	settle(d)
	check(d.side(1).lp == 8000 - (2000 - 800), "Fairy Meteor Crush: piercing damage to a defender (LP %d)" % d.side(1).lp)

func play(d: Duel, name: String, p := 0) -> DCard:
	var c := d.debug_give(p, idx(name))
	var why := d.activate_effect(p, c, 0)
	if why != "":
		print("   (activation of ", name, " refused: ", why, ")")
	settle(d)
	return c
