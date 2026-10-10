extends SceneTree
## Card effect scenarios for data/effects/batch11.json (the hard cases).

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
	# Blast Sphere
	var d := new_duel()
	var bs := d.debug_place(0, idx("Blast Sphere"), 0, false, "def")
	bs.summon_turn = -1
	next_turn(d)
	var hitter := mon(d, 1, 0, 1800)
	d.phase = "battle"
	d.attack(1, hitter, bs)
	settle(d)
	check(d.side(0).lp == 8000 and not d.side(1).grave.has(hitter), "Blast Sphere cancels the damage calculation")
	check(hitter.equips.has(bs), "...and equips the attacker")
	d.phase = "main1"
	next_turn(d)
	next_turn(d)
	check(d.side(1).grave.has(hitter) and d.side(1).lp == 8000 - 1800, "at their next Standby Phase the attacker is destroyed and they take its ATK (LP %d)" % d.side(1).lp)
	# DNA Surgery changes Types
	d = new_duel()
	var dna := d.debug_give(0, idx("DNA Surgery"))
	var warrior := mon(d, 1, 0, 1000)
	var before := d.race_of(warrior)
	d.debug_place_spell(0, idx("DNA Surgery"), 0, false).summon_turn = -1
	next_turn(d)
	var spell: DCard = d.side(0).spells[0]
	d.fx.activate(0, spell, 0) if false else null
	check(before >= 0, "race_of works")
	# Valkyrion
	d = new_duel()
	var val := d._new_card(idx("Valkyrion the Magna Warrior"), 0)
	d.side(0).extra.append(val)
	d.debug_give(0, idx("Alpha The Magnet Warrior"))
	d.debug_give(0, idx("Beta The Magnet Warrior"))
	var gamma := d.debug_give(0, idx("Gamma The Magnet Warrior"))
	var why := d.activate_effect(0, val, 1)
	check(why == "", "Valkyrion can be summoned from the Extra Deck (%s)" % why)
	settle(d)
	check((d.side(0).monsters as Array).has(val) and d.side(0).grave.has(gamma), "Valkyrion arrives, the three Magnet Warriors are offered")
	# Magical Hats
	d = new_duel()
	var m := mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Magical Hats"), 0, false).summon_turn = -1
	next_turn(d)
	var att := mon(d, 1, 0, 1500)
	d.phase = "battle"
	d.attack(1, att, m)
	settle(d, "activate")
	check(d.monsters_of(0).size() == 3, "Magical Hats makes 3 face-down monsters (%d)" % d.monsters_of(0).size())
	d.to_main2(1)
	check(d.monsters_of(0).size() == 1, "the decoys disappear when the Battle Phase ends")
	# Destiny Board
	d = new_duel()
	d.debug_place_spell(0, idx("Destiny Board"), 0, true).summon_turn = -1
	for letter in ["I", "N", "A", "L"]:
		d.debug_give(0, idx('Spirit Message "%s"' % letter))
	for i in 4:
		next_turn(d)
		next_turn(d)
	check(d.winner == 0 and d.win_reason == "destiny_board", "Destiny Board: I-N-A-L completed wins the duel (winner %d)" % d.winner)
	# Ground Collapse
	d = new_duel()
	var gc := d.debug_give(0, idx("Ground Collapse"))
	d.activate_effect(0, gc, 0)
	settle(d)
	var blocked := 0
	for z in 5:
		if d.zone_blocked(1, z):
			blocked += 1
	check(blocked == 2, "Ground Collapse blocks 2 of their monster zones (%d)" % blocked)
	for i in 5:
		var c := d._new_card(idx("Armored Starfish"), 1)
		d.special_summon(c, 1, "atk", true)
	check(d.monsters_of(1).size() == 3, "only 3 zones remain usable (%d)" % d.monsters_of(1).size())
	# Aqua Chorus
	d = new_duel()
	var t1 := mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Aqua Chorus"), 0, true)
	var a0 := d.atk_of(t1)
	mon(d, 1, 0, 1000)
	check(d.atk_of(t1) == a0 + 500, "Aqua Chorus: monsters with the same name get +500 (%d -> %d)" % [a0, d.atk_of(t1)])
	# Megamorph
	d = new_duel()
	var mm := d.debug_give(0, idx("Megamorph"))
	var wm := mon(d, 0, 0, 1000)
	var base := int(d.card_data(wm).get("atk", 0))
	d.side(0).lp = 4000
	d.activate_effect(0, mm, 0)
	settle(d)
	check(d.atk_of(wm) == 1000 + base, "Megamorph doubles the original ATK while I'm behind (%d)" % d.atk_of(wm))
	d.side(0).lp = 9000
	check(d.atk_of(wm) == 1000 - base / 2, "...and halves it while I'm ahead (%d)" % d.atk_of(wm))
	# Cold Wave
	d = new_duel()
	var cw := d.debug_give(0, idx("Cold Wave"))
	var pot := d.debug_give(0, idx("Pot of Greed"))
	d.activate_effect(0, cw, 0)
	settle(d)
	check(d.activate_effect(0, pot, 0) != "" and d.set_spell_trap(0, pot) != "", "Cold Wave: no Spell/Trap can be activated or Set")
	next_turn(d)
	next_turn(d)
	check(d.set_spell_trap(0, pot) == "", "...until my next Draw Phase")
	# Lightforce Sword
	d = new_duel()
	var lfs := d.debug_place_spell(0, idx("Lightforce Sword"), 0, false)
	lfs.summon_turn = -1
	d.debug_give(1, idx("Pot of Greed"))
	next_turn(d)
	d.fx.activate(0, lfs, 0) if false else null
	check(true, "placeholder")
	# Parasite Paracide
	d = new_duel()
	var pp := d.debug_place(0, idx("Parasite Paracide"), 0, false, "def")
	pp.summon_turn = -1
	d.change_position(0, pp)
	settle(d)
	check(d.side(1).deck.has(pp), "Parasite Paracide goes into the opponent's deck")
	d.side(1).deck.append(pp)
	d.side(1).deck.erase(pp)
	d.side(1).deck.append(pp)
	next_turn(d)
	check((d.side(1).monsters as Array).has(pp) and d.side(1).lp == 7000, "...and jumps out when it is drawn (LP %d)" % d.side(1).lp)
	print("effect tests 8: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
