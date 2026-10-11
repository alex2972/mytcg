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
	test_all()
	print("effect tests 12: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	test_negation_traps()
	test_destruction_reactions()

func test_negation_traps() -> void:
	# Metal Detector: a Continuous Trap activated by the opponent is negated for the whole turn
	var d := new_duel()
	var md := trap(d, 0, 0, "Metal Detector")
	var def_mon := mon(d, 0, 0, 1000, 1000, true, "def")
	var mw := trap(d, 1, 0, "Mirror Wall")
	next_turn(d)
	var raider := mon(d, 1, 0, 2000)
	d.phase = "battle"
	d.attack(1, raider, def_mon)
	settle(d, "use")
	check(d.side(0).grave.has(md), "Metal Detector responds to the activation of a Continuous Trap")
	check(d.fx.effects_of(mw).is_empty() and d.atk_of(raider) == 2000, "...and its effects are off for the turn (ATK %d)" % d.atk_of(raider))
	# Mystic Probe
	d = new_duel()
	var mp := trap(d, 0, 0, "Mystic Probe")
	next_turn(d)
	var big := mon(d, 1, 0, 1800)
	var mop := d.debug_give(1, idx("Messenger of Peace"))
	d.activate_effect(1, mop, 0)
	settle(d, "use")
	d.phase = "battle"
	check(d.side(0).grave.has(mp) and d.can_attack(1, big) == "", "Mystic Probe negates a Continuous Spell (Messenger of Peace does not stop the attack)")
	# World Suppression
	d = new_duel()
	var ws := trap(d, 0, 0, "World Suppression")
	next_turn(d)
	var fish := mon(d, 1, 0, 1000, 1000, true, "atk", "Armored Starfish")
	var base: int = d.atk_of(fish)
	var umi := d.debug_give(1, idx("Umi"))
	d.activate_effect(1, umi, 0)
	settle(d, "use")
	check(d.side(0).grave.has(ws) and d.atk_of(fish) == base, "World Suppression: the Field Spell does nothing this turn (ATK %d / %d)" % [d.atk_of(fish), base])
	# Armored Glass
	d = new_duel()
	var ag := trap(d, 0, 0, "Armored Glass")
	next_turn(d)
	var lady := place(d, 1, 0, "Harpie Lady")
	base = d.atk_of(lady)
	var fan := d.debug_give(1, idx("Gust Fan"))
	d.activate_effect(1, fan, 0)
	settle(d, "use")
	check(d.side(0).grave.has(ag) and d.atk_of(lady) == base, "Armored Glass: Equip Cards do nothing this turn (ATK %d / %d)" % [d.atk_of(lady), base])
	# Anti-Spell Fragrance
	d = new_duel()
	var asf := d.debug_place_spell(0, idx("Anti-Spell Fragrance"), 0, true)
	asf.summon_turn = -1
	var pot := d.debug_give(0, idx("Pot of Greed"))
	check(d.activate_effect(0, pot, 0) != "", "Anti-Spell Fragrance: a Spell cannot be played from the hand")
	check(d.set_spell_trap(0, pot) == "", "...it has to be Set")
	check(d.activate_effect(0, pot, 0) != "", "...and cannot be activated the turn it was Set")
	next_turn(d)
	next_turn(d)
	check(d.activate_effect(0, pot, 0) == "", "...but can on my next turn")
	# Riryoku Field
	d = new_duel()
	var rf := trap(d, 0, 0, "Riryoku Field")
	var mine := mon(d, 0, 0, 1000)
	next_turn(d)
	var coh := d.debug_give(1, idx("Change of Heart"))
	d.activate_effect(1, coh, 0)
	settle(d, "use")
	check(d.side(0).monsters.has(mine) and d.side(1).grave.has(coh) and d.side(0).grave.has(rf), "Riryoku Field negates and destroys a Spell that targets 1 monster")
	d = new_duel()
	rf = trap(d, 0, 0, "Riryoku Field")
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Raimei")), 0)
	settle(d, "use")
	check(d.side(0).spells.has(rf) and d.side(0).lp == 7700, "...but not one that targets nothing")
	# Big Shield Gardna: a Spell that targets it face-down is negated
	d = new_duel()
	var gardna := d.debug_place(0, idx("Big Shield Gardna"), 0, false, "def")
	next_turn(d)
	coh = d.debug_give(1, idx("Change of Heart"))
	d.activate_effect(1, coh, 0)
	settle(d, "use")
	check(gardna.face_up and gardna.pos == "def" and d.side(0).monsters.has(gardna), "Big Shield Gardna negates a Spell that targets it face-down and turns face-up in Defense Position")

func test_destruction_reactions() -> void:
	# Driving Snow
	var d := new_duel()
	var bait := trap(d, 0, 0, "Mirror Force")
	var ds := trap(d, 0, 1, "Driving Snow")
	next_turn(d)
	var theirs := trap(d, 1, 0, "Trap Hole")
	var msp := d.debug_give(1, idx("Mystical Space Typhoon"))
	d.activate_effect(1, msp, 0)
	settle(d, "use")
	check(d.side(0).grave.has(bait) and d.side(0).grave.has(ds) and d.side(1).grave.has(theirs), "Driving Snow answers the destruction of my Trap by the opponent's effect")
	# Gust only answers the opponent's effect
	d = new_duel()
	var gust := trap(d, 0, 3, "Gust")
	var spell := d.debug_place_spell(0, idx("Infinite Cards"), 1, true)
	spell.summon_turn = -1
	d.debug_place_spell(1, idx("Infinite Cards"), 0, true)
	var own_msp := d.debug_give(0, idx("Mystical Space Typhoon"))
	d.activate_effect(0, own_msp, 0)
	d.respond([spell.uid]) if not d.fx.pending.is_empty() and d.fx.pending.get("type", "") == "select" else null
	settle(d, "use")
	check(d.side(0).spells.has(gust), "Gust does not answer the destruction of my own Spell by my own effect")
	d = new_duel()
	gust = trap(d, 0, 3, "Gust")
	spell = d.debug_place_spell(0, idx("Infinite Cards"), 0, true)
	spell.summon_turn = -1
	var foe_spell := d.debug_place_spell(1, idx("Infinite Cards"), 0, true)
	foe_spell.summon_turn = -1
	next_turn(d)
	var foe_msp := d.debug_give(1, idx("Mystical Space Typhoon"))
	d.activate_effect(1, foe_msp, 0)
	settle(d, "use")
	check(d.side(0).grave.has(gust) and d.side(0).grave.has(spell), "...but answers the opponent's")
	# Fairy Guardian
	d = new_duel()
	var fg := place(d, 0, 0, "Fairy Guardian")
	var ic := d.debug_place_spell(0, idx("Infinite Cards"), 0, true)
	ic.summon_turn = -1
	var set_msp := d.debug_place_spell(1, idx("Mystical Space Typhoon"), 0, false)
	set_msp.summon_turn = -1
	var sm := d.debug_give(0, idx("Armored Starfish"))
	d.summon(0, sm)
	settle(d, "use")
	check(d.side(0).grave.has(ic), "(the opponent destroyed my Spell during my turn)")
	check(d.activate_effect(0, fg, 0) == "", "Fairy Guardian can be offered")
	settle(d)
	check(d.side(0).deck.front() == ic and d.side(0).grave.has(fg), "...and returns that Spell to the bottom of my Deck")
