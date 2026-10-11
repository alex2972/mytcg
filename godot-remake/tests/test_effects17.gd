extends SceneTree
## Cards of data/effects/batch22.json (the last cards outside the decks and the Card List) and the hooks they need.

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

func find_card(kind: int, max_level := 12) -> int:
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.card(i)
		if c.get("type", "") == "monster" and int(c.get("kind", 0)) == kind and int(c.get("level", 0)) <= max_level and int(c.get("category", 0)) == 0:
			return i
	return 0

func find_attr(attr: int, max_level := 4) -> int:
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.card(i)
		if c.get("type", "") == "monster" and int(c.get("attribute", 0)) == attr and int(c.get("level", 0)) <= max_level and int(c.get("category", 0)) == 0 and int(c.get("atk", 0)) >= 500:
			return i
	return 0

func _init() -> void:
	db = CardDB.load_default()
	test_all()
	print("effect tests 17: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	test_sent_to_grave()
	test_stage_cards()
	test_traps()
	test_misc()

func test_sent_to_grave() -> void:
	# Minar / Electric Snake: sent directly from the hand to the Graveyard by the opponent's effect
	var d := new_duel()
	var minar := d.debug_give(0, idx("Minar"))
	d.effect_player = 1
	d.send_to_grave(minar, "discard")
	d.effect_player = -1
	settle(d)
	check(d.side(1).lp == 7000, "Minar: 1000 damage when the opponent's effect discards it from my hand")
	d = new_duel()
	minar = d.debug_give(0, idx("Minar"))
	d.send_to_grave(minar, "discard")
	settle(d)
	check(d.side(1).lp == 8000, "...but not when I discard it myself")
	d = new_duel()
	var m2 := place(d, 0, 0, "Minar")
	d.effect_player = 1
	d.destroy_card(m2, "effect")
	d.effect_player = -1
	settle(d)
	check(d.side(1).lp == 8000, "...nor when it was destroyed on the field")
	d = new_duel()
	var snake := d.debug_give(0, idx("Electric Snake"))
	var hand_n: int = d.side(0).hand.size()
	d.effect_player = 1
	d.send_to_grave(snake, "discard")
	d.effect_player = -1
	settle(d)
	check(d.side(0).hand.size() == hand_n - 1 + 2, "Electric Snake: draw 2 cards")
	# Penguin Knight
	d = new_duel()
	var pk := d._new_card(idx("Penguin Knight"), 0)
	d.side(0).deck.append(pk)
	for i in 3:
		d.side(0).grave.append(d._new_card(idx("Pot of Greed"), 0))
	var deck_total: int = d.side(0).deck.size() + 3
	d.effect_player = 1
	d.send_to_grave(pk, "milled")
	d.effect_player = -1
	settle(d)
	check(d.side(0).grave.size() == 0 or d.side(0).grave.size() == 1 and d.side(0).grave.has(pk) and d.side(0).deck.size() == deck_total, "Penguin Knight: the Graveyard is shuffled into the Deck (grave %d)" % d.side(0).grave.size())

func test_stage_cards() -> void:
	# Castle of Dark Illusions / Pumpking
	var d := new_duel()
	var castle := d.debug_place(0, idx("Castle of Dark Illusions"), 0, false, "def")
	var zombie := d.debug_place(0, find_card(CardDB.RACES.find("Zombie"), 4), 1, true, "atk")
	var other := mon(d, 0, 2, 1000)
	var zb: int = d.atk_of(zombie)
	d.change_position(0, castle)
	settle(d)
	check(d.atk_of(zombie) == zb + 200 and d.atk_of(other) == 1000, "Castle of Dark Illusions: Zombies get +200 ATK/DEF")
	next_turn(d)
	next_turn(d)
	check(d.atk_of(zombie) == zb + 400, "...and +200 more at each of my Standby Phases (%d)" % (d.atk_of(zombie) - zb))
	for i in 6:
		next_turn(d)
	check(d.atk_of(zombie) == zb + 800, "...up to 4 times in total (%d)" % (d.atk_of(zombie) - zb))
	d.destroy_card(castle, "effect")
	check(d.atk_of(zombie) == zb, "...and it ends with the card")
	d = new_duel()
	var pump := place(d, 0, 0, "Pumpking the King of Ghosts")
	var pb: int = d.atk_of(pump)
	var c2 := place(d, 0, 1, "Castle of Dark Illusions")
	check(d.atk_of(pump) == pb + 100, "Pumpking: +100 ATK while Castle of Dark Illusions is face-up")
	next_turn(d)
	next_turn(d)
	check(d.atk_of(pump) == pb + 200, "...and +100 more at each of my Standby Phases (%d)" % (d.atk_of(pump) - pb))
	d.destroy_card(c2, "effect")
	check(d.atk_of(pump) == pb + 100, "...(the bonus of the counter stays until the next Standby Phase)" if false else "...ends with the Castle except the counter")
	# Hourglass of Courage
	d = new_duel()
	var hg := d.debug_give(0, idx("Hourglass of Courage"))
	d.summon(0, hg)
	settle(d)
	check(d.atk_of(hg) == 550 and d.def_of(hg) == 600, "Hourglass of Courage: ATK/DEF halved after its Summon (%d/%d)" % [d.atk_of(hg), d.def_of(hg)])
	next_turn(d)
	next_turn(d)
	check(d.atk_of(hg) == 550, "...still halved on the third turn")
	next_turn(d)
	check(d.atk_of(hg) == 2200 and d.def_of(hg) == 2400, "...then doubled (%d/%d)" % [d.atk_of(hg), d.def_of(hg)])

func test_traps() -> void:
	# Mystical Refpanel
	var d := new_duel()
	var rp := trap(d, 0, 0, "Mystical Refpanel")
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Hinotama")), 0)
	settle(d, "use")
	check(d.side(0).grave.has(rp) and d.side(1).lp == 7500 and d.side(0).lp == 8000, "Mystical Refpanel transfers a Spell that targets a player to the other player (LP %d / %d)" % [d.side(0).lp, d.side(1).lp])
	# Fairy's Hand Mirror
	d = new_duel()
	var fhm := trap(d, 0, 0, "Fairy's Hand Mirror")
	var a := mon(d, 0, 0, 1000)
	var b := mon(d, 0, 1, 1000)
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Change of Heart")), 0)
	if d.fx.pending.get("type", "") == "select":
		d.respond([a.uid])
	for i in 6:
		if d.fx.pending.is_empty():
			break
		var p: Dictionary = d.fx.pending
		if p["type"] == "chain":
			var o: Dictionary = p["options"][0]
			d.respond({"uid": o["uid"], "idx": o["idx"]})
		elif p["type"] == "select":
			d.respond([b.uid])
		else:
			d.respond(0)
	settle(d)
	check(d.side(0).grave.has(fhm) and d.side(0).monsters.has(a) and d.side(1).monsters.has(b), "Fairy's Hand Mirror switches the target of Change of Heart to another monster")
	# Fake Trap
	d = new_duel()
	var real := trap(d, 0, 0, "Mirror Force")
	var fake := trap(d, 0, 1, "Fake Trap")
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Mystical Space Typhoon")), 0)
	settle(d, "use")
	check(d.side(0).spells.has(real) and d.side(0).grave.has(fake), "Fake Trap is destroyed in place of my Trap Card")

func test_misc() -> void:
	# Soul Exchange
	var d := new_duel()
	var theirs := mon(d, 1, 0, 2000)
	var se := d.debug_give(0, idx("Soul Exchange"))
	var big := d.debug_give(0, idx("Summoned Skull"))
	d.activate_effect(0, se, 0)
	settle(d)
	check(d.summon(0, big, [theirs]) == "", "Soul Exchange: an opponent's monster can be the Tribute")
	check(d.side(1).grave.has(theirs) and d.side(0).monsters.has(big), "...it goes to its owner's Graveyard")
	d.phase = "main1"
	check(d.to_battle(0) != "", "...and my Battle Phase is skipped")
	# Thousand-Eyes Restrict
	d = new_duel()
	var tr := place(d, 0, 0, "Thousand-Eyes Restrict")
	var other := mon(d, 0, 1, 1800)
	var foe := place(d, 1, 0, "Armored Starfish")
	d.phase = "battle"
	check(d.can_attack(0, other) != "", "Thousand-Eyes Restrict: other monsters cannot attack")
	d.phase = "main1"
	check(d.change_position(0, other) != "", "...or change position")
	d.activate_effect(0, tr, 2) if false else null
	var why := d.activate_effect(0, tr, d.fx.effects_of(tr).size() - 1)
	settle(d)
	check(why == "" and tr.equips.has(foe) and d.atk_of(tr) == 850 and d.def_of(tr) == 1400, "...and it takes on the ATK/DEF of an opponent's monster, which becomes its Equip Card (%d/%d)" % [d.atk_of(tr), d.def_of(tr)])
	check(d.activate_effect(0, tr, d.fx.effects_of(tr).size() - 1) != "", "...once per turn")
	# Dark Sage through Time Wizard
	var summoned := 0
	for sd in range(1, 21):
		d = new_duel(sd)
		var tw := place(d, 0, 0, "Time Wizard")
		place(d, 0, 1, "Dark Magician")
		var ds := d.debug_give(0, idx("Dark Sage"))
		mon(d, 1, 0, 1000)
		d.activate_effect(0, tw, 0)
		settle(d)
		if d.monsters_of(1).is_empty() and d.side(0).monsters.has(tw):
			check(d.side(0).monsters.has(ds) and d.side(0).grave.size() >= 1, "Dark Sage is summoned when Time Wizard's call is right (seed %d)" % sd)
			summoned += 1
			break
	check(summoned == 1, "(a seed with a right call exists)")
	var sage := d.debug_give(0, idx("Dark Sage"))
	check(d.summon(0, sage, [mon(d, 0, 2, 100), mon(d, 0, 3, 100)]) != "", "Dark Sage cannot be Normal Summoned")
