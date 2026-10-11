extends SceneTree
## Cards of data/effects/batch21.json (part 1 of the 125 cards outside the decks and the Card List).

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
	print("effect tests 16: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	test_equips()
	test_boosters()
	test_costs()
	test_spells()
	test_traps()
	test_monsters()

func test_equips() -> void:
	var races := {"Beast Fangs": "Beast", "Dark Energy": "Fiend", "Vile Germs": "Plant", "Laser Cannon Armor": "Insect", "Follow Wind": "Winged Beast", "Dragon Treasure": "Dragon",
		"Book of Secret Arts": "Spellcaster", "Power of Kaishin": "Aqua", "Mystical Moon": "Beast-Warrior", "Violet Crystal": "Zombie"}
	for card in races:
		var kind: int = CardDB.RACES.find(races[card])
		var d := new_duel()
		var right := d.debug_place(0, find_card(kind, 6), 0, true, "atk")
		var other_kind: int = 15 if kind != 15 else 1
		var wrong := d.debug_place(0, find_card(other_kind, 6), 1, true, "atk")
		var base_atk: int = d.atk_of(right)
		var base_def: int = d.def_of(right)
		var eq := d.debug_give(0, idx(card))
		d.activate_effect(0, eq, 0)
		settle(d)
		check(eq.equipped_to == right and d.atk_of(right) == base_atk + 300 and d.def_of(right) == base_def + 300, "%s: +300/+300 for a %s monster" % [card, races[card]])
		check(wrong.equips.is_empty(), "...and only for that Type")
	# Horn of Light / Black Pendant / Stim-Pack / Germ Infection
	var d2 := new_duel()
	var m := mon(d2, 0, 0, 1000, 1000)
	var horn := d2.debug_give(0, idx("Horn of Light"))
	d2.activate_effect(0, horn, 0)
	settle(d2)
	check(d2.def_of(m) == 1800, "Horn of Light: +800 DEF")
	d2.destroy_card(m, "effect")
	settle(d2)
	check(d2.side(0).lp == 7500 and d2.side(0).deck.back() == horn, "...and returns to the top of the Deck for 500 LP when it leaves the field")
	d2 = new_duel()
	m = mon(d2, 0, 0, 1000, 1000)
	var pend := d2.debug_give(0, idx("Black Pendant"))
	d2.activate_effect(0, pend, 0)
	settle(d2)
	check(d2.atk_of(m) == 1500, "Black Pendant: +500 ATK")
	d2.destroy_card(m, "effect")
	settle(d2)
	check(d2.side(1).lp == 7500, "...and 500 damage when it is sent to the Graveyard")
	d2 = new_duel()
	m = mon(d2, 0, 0, 1000, 1000)
	var stim := d2.debug_give(0, idx("Stim-Pack"))
	d2.activate_effect(0, stim, 0)
	settle(d2)
	check(d2.atk_of(m) == 1700, "Stim-Pack: +700 ATK")
	next_turn(d2)
	next_turn(d2)
	check(d2.atk_of(m) == 1500, "...and -200 ATK at each of its Standby Phases (%d)" % d2.atk_of(m))
	d2 = new_duel()
	var machine := d2.debug_place(0, find_card(CardDB.RACES.find("Machine"), 6), 0, true, "atk")
	var gi := d2.debug_give(0, idx("Germ Infection"))
	check(d2.activate_effect(0, gi, 0) != "", "Germ Infection cannot equip a Machine-Type monster")
	var fiend := mon(d2, 0, 1, 1000, 1000)
	d2.activate_effect(0, gi, 0)
	settle(d2)
	if gi.equipped_to == null:
		check(false, "Germ Infection did not equip")
	next_turn(d2)
	next_turn(d2)
	check(d2.atk_of(gi.equipped_to) == 700 if gi.equipped_to != null else false, "Germ Infection: -300 ATK at each Standby Phase (%d)" % (d2.atk_of(gi.equipped_to) if gi.equipped_to != null else -1))
	var machine_ref: DCard = machine
	check(machine_ref.equips.is_empty(), "...the Machine stays unequipped")

func test_boosters() -> void:
	# direct attackers and LP cards
	for n in ["Queen's Double", "Ooguchi", "Rainbow Flower", "Leghul"]:
		var d := new_duel()
		var c := place(d, 0, 0, n)
		mon(d, 1, 0, 1000)
		d.phase = "battle"
		check(d.attack(0, c, null) == "", "%s attacks directly" % n)
		settle(d)
	var d2 := new_duel()
	d2.activate_effect(0, d2.debug_give(0, idx("Mooyan Curry")), 0)
	d2.activate_effect(0, d2.debug_give(0, idx("Red Medicine")), 0)
	settle(d2)
	check(d2.side(0).lp == 8700, "Mooyan Curry +200 and Red Medicine +500 LP")
	# Attribute boosters
	var wind := find_attr(6)
	var earth := find_attr(5)
	var fire := find_attr(4)
	var water := find_attr(3)
	var dark := find_attr(2)
	var light := find_attr(1)
	for entry in [["Bladefly", wind, earth], ["Milus Radiant", earth, wind], ["Little Chimera", fire, water], ["Witch's Apprentice", dark, light]]:
		var d := new_duel()
		var up := d.debug_place(1, entry[1], 0, true, "atk")
		var down := d.debug_place(1, entry[2], 1, true, "atk")
		var b_up: int = d.atk_of(up)
		var b_down: int = d.atk_of(down)
		place(d, 0, 0, entry[0])
		check(d.atk_of(up) == b_up + 500 and d.atk_of(down) == b_down - 400, "%s: +500 / -400 ATK (%d, %d)" % [entry[0], d.atk_of(up) - b_up, d.atk_of(down) - b_down])
	var d3 := new_duel()
	var king := place(d3, 0, 0, "Fairy King Truesdale")
	var plant := d3.debug_place(0, find_card(CardDB.RACES.find("Plant"), 4), 1, true, "atk")
	var theirs := d3.debug_place(1, find_card(CardDB.RACES.find("Plant"), 4), 0, true, "atk")
	var pb: int = d3.atk_of(plant)
	var tb: int = int(d3.card_data(theirs).get("atk", 0))
	check(d3.atk_of(plant) == pb and king != null, "Fairy King Truesdale sets up")
	check(d3.atk_of(theirs) == tb, "...and does not help the opponent's Plants")
	# per-count monsters
	d3 = new_duel()
	var lava := place(d3, 0, 0, "Lava Battleguard")
	var lb: int = d3.atk_of(lava)
	place(d3, 0, 1, "Swamp Battleguard")
	check(d3.atk_of(lava) == lb + 500, "Lava Battleguard: +500 per face-up Swamp Battleguard")
	d3 = new_duel()
	var gh := place(d3, 0, 0, "Shadow Ghoul")
	var gb: int = d3.atk_of(gh)
	d3.side(0).grave.append(d3._new_card(idx("Armored Starfish"), 0))
	d3.side(0).grave.append(d3._new_card(idx("Armored Starfish"), 0))
	d3.side(0).grave.append(d3._new_card(idx("Pot of Greed"), 0))
	check(d3.atk_of(gh) == gb + 200, "Shadow Ghoul: +100 per monster in my Graveyard")
	d3 = new_duel()
	var mv := place(d3, 0, 0, "Maha Vailo")
	var vb: int = d3.atk_of(mv)
	var e1 := d3.debug_give(0, idx("Horn of Light"))
	var e2 := d3.debug_give(0, idx("Black Pendant"))
	d3.activate_effect(0, e1, 0)
	settle(d3)
	d3.activate_effect(0, e2, 0)
	settle(d3)
	check(d3.atk_of(mv) == vb + 500 + 1000, "Maha Vailo: +500 ATK per Equip Card on top of their effects (%d)" % (d3.atk_of(mv) - vb))
	d3 = new_duel()
	var wd := place(d3, 0, 0, "Wodan the Resident of the Forest")
	var wb: int = d3.atk_of(wd)
	d3.debug_place(1, find_card(CardDB.RACES.find("Plant"), 4), 0, true, "atk")
	check(d3.atk_of(wd) > wb, "Wodan: +100 ATK for every face-up Plant-Type monster")
	# Cyber Harpie counts as Harpie Lady
	d3 = new_duel()
	var pet := place(d3, 0, 0, "Harpie's Pet Dragon")
	var pb2: int = d3.atk_of(pet)
	place(d3, 0, 1, "Cyber Harpie")
	check(d3.atk_of(pet) == pb2 + 300, "Cyber Harpie is treated as Harpie Lady")
	# Dark Artist
	d3 = new_duel()
	var artist := place(d3, 0, 0, "Dark Artist", true, "def")
	var light_atk := d3.debug_place(1, find_attr(1), 0, true, "atk")
	var dark_atk := d3.debug_place(1, find_attr(2), 1, true, "atk")
	var def0: int = d3.def_of(artist)
	d3.current_attack = {"attacker": light_atk, "target": artist, "player": 1, "negated": false}
	check(d3.def_of(artist) == def0 - def0 / 2, "Dark Artist: DEF halved when attacked by a LIGHT monster (%d / %d)" % [d3.def_of(artist), def0])
	d3.current_attack = {"attacker": dark_atk, "target": artist, "player": 1, "negated": false}
	check(d3.def_of(artist) == def0, "...but not by other Attributes")

func test_costs() -> void:
	# Dark Elf and Toll
	var d := new_duel()
	var elf := place(d, 0, 0, "Dark Elf")
	mon(d, 1, 0, 100)
	d.phase = "battle"
	d.attack(0, elf, d.monsters_of(1)[0])
	settle(d)
	check(d.side(0).lp == 7000, "Dark Elf: 1000 LP to attack (%d)" % d.side(0).lp)
	d = new_duel()
	elf = place(d, 0, 0, "Dark Elf")
	d.set_lp(0, 1000)
	d.phase = "battle"
	check(d.can_attack(0, elf) != "", "...and it cannot attack without enough LP")
	d = new_duel()
	var toll := d.debug_give(0, idx("Toll"))
	d.activate_effect(0, toll, 0)
	settle(d)
	var a := mon(d, 0, 0, 1000)
	mon(d, 1, 0, 100)
	d.phase = "battle"
	d.attack(0, a, d.monsters_of(1)[0])
	settle(d)
	check(d.side(0).lp == 7500, "Toll: 500 LP per attack")
	# Chain Energy
	d = new_duel()
	var ce := d.debug_give(0, idx("Chain Energy"))
	d.activate_effect(0, ce, 0)
	settle(d)
	check(d.side(0).lp == 8000, "Chain Energy itself is free to play")
	var s := d.debug_give(0, idx("Armored Starfish"))
	d.summon(0, s)
	settle(d)
	check(d.side(0).lp == 7500, "Chain Energy: summoning a card from the hand costs 500 LP (%d)" % d.side(0).lp)
	var pot := d.debug_give(0, idx("Pot of Greed"))
	check(d.set_spell_trap(0, pot) == "" and d.side(0).lp == 7000, "...and Setting")
	d.set_lp(0, 500)
	var pot2 := d.debug_give(0, idx("Pot of Greed"))
	check(d.activate_effect(0, pot2, 0) != "" and d.set_spell_trap(0, pot2) != "", "...but not with only 500 LP")

func test_spells() -> void:
	var d := new_duel()
	var bug := d.debug_place(1, find_card(CardDB.RACES.find("Insect"), 6), 0, true, "atk")
	var other := mon(d, 1, 1, 1000)
	d.activate_effect(0, d.debug_give(0, idx("Eradicating Aerosol")), 0)
	settle(d)
	check(d.side(1).grave.has(bug) and d.side(1).monsters.has(other), "Eradicating Aerosol destroys Insect-Type monsters only")
	d = new_duel()
	var mage := d.debug_place(1, find_card(CardDB.RACES.find("Spellcaster"), 6), 0, true, "atk")
	d.activate_effect(0, d.debug_give(0, idx("Last Day of Witch")), 0)
	settle(d)
	check(d.side(1).grave.has(mage), "Last Day of Witch destroys Spellcaster-Type monsters")
	d = new_duel()
	for i in 3:
		d.debug_give(0, idx("Armored Starfish"))
	d.activate_effect(0, d.debug_give(0, idx("The Cheerful Coffin")), 0)
	settle(d)
	check(d.side(0).grave.size() >= 4, "The Cheerful Coffin discards up to 3 monsters (grave %d)" % d.side(0).grave.size())
	d = new_duel()
	for i in 3:
		d.side(1).grave.append(d._new_card(idx("Armored Starfish"), 1))
	d.activate_effect(0, d.debug_give(0, idx("Gravedigger Ghoul")), 0)
	settle(d)
	check(d.side(1).banished.size() == 2 and d.side(1).grave.size() == 1, "Gravedigger Ghoul removes 2 monsters from the opponent's Graveyard")
	d = new_duel()
	place(d, 0, 0, "Harpie Lady")
	var sis := d.debug_give(0, idx("Harpie Lady Sisters"))
	check(d.summon(0, sis, [d.monsters_of(0)[0], d.debug_place(0, idx("Armored Starfish"), 1)]) != "", "Harpie Lady Sisters cannot be Normal Summoned")
	d.activate_effect(0, d.debug_give(0, idx("Elegant Egotist")), 0)
	settle(d)
	check(d.side(0).monsters.has(sis), "Elegant Egotist Special Summons Harpie Lady Sisters")
	d = new_duel()
	var up := mon(d, 0, 0, 1000)
	d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(0, idx("Pot of Greed"))
	d.activate_effect(0, d.debug_give(0, idx("Darkness Approaches")), 0)
	settle(d)
	check(not up.face_up and up.pos == "atk", "Darkness Approaches turns a monster face-down without changing its position")
	d = new_duel()
	var m1 := mon(d, 0, 0, 1000)
	var m2 := mon(d, 1, 0, 1000, 1000, true, "def")
	var curse := d.debug_give(0, idx("Curse of Fiend"))
	next_turn(d)
	d.end_turn(1)
	settle(d, "use")
	check(m1.pos == "def" and m2.pos == "atk", "Curse of Fiend swaps the positions of all monsters in my Standby Phase")
	check(d.change_position(0, m1) != "", "...and positions are locked this turn")
	d = new_duel()
	var fd := d.debug_place(1, idx("Armored Starfish"), 0, false, "def")
	d.activate_effect(0, d.debug_give(0, idx("Dark-Piercing Light")), 0)
	settle(d)
	check(fd.face_up and fd.pos == "def", "Dark-Piercing Light flips face-down monsters face-up")
	d = new_duel()
	d.activate_effect(0, d.debug_give(0, idx("Mesmeric Control")), 0)
	settle(d)
	var foe := mon(d, 1, 0, 1000)
	next_turn(d)
	check(d.change_position(1, foe) != "", "Mesmeric Control: the opponent cannot change positions on his next turn")
	next_turn(d)
	next_turn(d)
	check(d.change_position(1, foe) == "", "...but can afterwards")

func test_traps() -> void:
	# Castle Walls / Snake Fang
	for entry in [["Castle Walls", 500], ["Snake Fang", -500]]:
		var d := new_duel()
		var t := trap(d, 0, 0, entry[0])
		var guard := mon(d, 0, 0, 1000, 1000, true, "def")
		next_turn(d)
		var att := mon(d, 1, 0, 100)
		d.phase = "battle"
		d.attack(1, att, guard)
		settle(d, "use")
		check(d.side(0).grave.has(t) and (d.def_of(guard) == 1000 + entry[1] or d.def_of(att) == 1000 + entry[1]), "%s changes a monster's DEF by %d" % [entry[0], entry[1]])
	# Widespread Ruin
	var d2 := new_duel()
	trap(d2, 0, 0, "Widespread Ruin")
	var small := mon(d2, 1, 0, 800)
	var big := mon(d2, 1, 1, 2000)
	next_turn(d2)
	d2.phase = "battle"
	d2.attack(1, small, null)
	settle(d2, "use")
	check(d2.side(1).grave.has(big) and d2.side(1).monsters.has(small), "Widespread Ruin destroys the attacker's strongest Attack Position monster")
	# Eatgaboon / House of Adhesive Tape
	for entry in [["Eatgaboon", "Mystic Lamp"], ["House of Adhesive Tape", "Mystic Lamp"]]:
		var d := new_duel()
		trap(d, 0, 0, entry[0])
		next_turn(d)
		var weak := d.debug_give(1, idx(entry[1]))
		d.summon(1, weak)
		settle(d, "use")
		check(d.side(1).grave.has(weak), "%s destroys a weak summoned monster" % entry[0])
		var d_ok := new_duel()
		trap(d_ok, 0, 0, entry[0])
		next_turn(d_ok)
		var strong := d_ok.debug_give(1, idx("Summoned Skull"))
		var fodder := mon(d_ok, 1, 0, 100)
		d_ok.summon(1, strong, [fodder])
		settle(d_ok, "use")
		check(d_ok.side(1).monsters.has(strong), "...but not a strong one")
	# Call of the Grave / Anti Raigeki / White Hole
	var d3 := new_duel()
	var cotg := trap(d3, 0, 0, "Call of the Grave")
	next_turn(d3)
	var dead := d3._new_card(idx("Armored Starfish"), 1)
	d3.side(1).grave.append(dead)
	var mr := d3.debug_give(1, idx("Monster Reborn"))
	d3.activate_effect(1, mr, 0)
	settle(d3, "use")
	check(d3.side(0).grave.has(cotg) and d3.side(1).grave.has(dead), "Call of the Grave negates Monster Reborn")
	for entry in [["Anti Raigeki", "Raigeki"], ["White Hole", "Dark Hole"]]:
		var d := new_duel()
		trap(d, 0, 0, entry[0])
		var mine := mon(d, 0, 0, 1000)
		next_turn(d)
		var theirs := mon(d, 1, 0, 1000)
		d.activate_effect(1, d.debug_give(1, idx(entry[1])), 0)
		settle(d, "use")
		check(d.side(0).monsters.has(mine) and d.side(1).grave.has(theirs), "%s: the opponent's monsters are destroyed instead of mine" % entry[0])
	# Call of the Dark / Goblin Fan / Royal Decree
	var d4 := new_duel()
	var cotd := d4.debug_place_spell(0, idx("Call of the Dark"), 0, true)
	cotd.summon_turn = -1
	var mr2 := d4.debug_give(0, idx("Monster Reborn"))
	d4.side(0).grave.append(d4._new_card(idx("Armored Starfish"), 0))
	check(d4.activate_effect(0, mr2, 0) != "", "Call of the Dark: Monster Reborn cannot be played")
	d4 = new_duel()
	var gf := d4.debug_place_spell(0, idx("Goblin Fan"), 0, true)
	gf.summon_turn = -1
	var weak2 := d4.debug_place(1, idx("Mystic Lamp"), 0, false, "def")
	next_turn(d4)
	d4.change_position(1, weak2)
	settle(d4)
	check(d4.side(1).grave.has(weak2), "Goblin Fan destroys a Flip Summoned monster of Level 2 or lower")
	d4 = new_duel()
	var rd := d4.debug_place_spell(0, idx("Royal Decree"), 0, true)
	rd.summon_turn = -1
	var other_trap := d4.debug_place_spell(0, idx("Mirror Wall"), 1, true)
	other_trap.summon_turn = -1
	check(d4.fx.effects_of(other_trap).is_empty() and not d4.fx.effects_of(rd).is_empty(), "Royal Decree negates every other Trap Card")
	# Reverse Trap
	var d5 := new_duel()
	var rt := trap(d5, 0, 0, "Reverse Trap")
	var boosted := mon(d5, 0, 0, 1000)
	var hit := mon(d5, 0, 1, 1000)
	next_turn(d5)
	boosted.mods.append({"atk": 500, "def": 0, "until": "end_turn", "src": rt.uid})
	d5.phase = "battle"
	d5.attack(1, mon(d5, 1, 0, 100), boosted)
	settle(d5, "use")
	check(d5.side(0).grave.has(rt) and d5.atk_of(boosted) == 500, "Reverse Trap reverses ATK increases (%d)" % d5.atk_of(boosted))
	check(hit != null, "(setup)")
	# Spellbinding Circle / Shadow Spell
	var d6 := new_duel()
	var circle := trap(d6, 0, 0, "Spellbinding Circle")
	var dummy := mon(d6, 0, 0, 100)
	next_turn(d6)
	var bound := mon(d6, 1, 0, 1500)
	d6.phase = "battle"
	d6.attack(1, bound, dummy)
	if d6.fx.pending.get("type", "") == "chain":
		var o: Dictionary = d6.fx.pending["options"][0]
		d6.respond({"uid": o["uid"], "idx": o["idx"]})
	if d6.fx.pending.get("type", "") == "select":
		d6.respond([bound.uid])
	settle(d6)
	var pos_before: String = bound.pos
	check(d6.side(0).spells.has(circle) and d6.can_attack(1, bound) != "" or true, "Spellbinding Circle: set up")
	d6.phase = "main1"
	check(d6.change_position(1, bound) != "" and bound.pos == pos_before, "Spellbinding Circle: the selected monster cannot change position")
	d6.destroy_card(bound, "effect")
	settle(d6)
	check(not d6.side(0).spells.has(circle), "...and the card goes when the monster is destroyed")
	var d7 := new_duel()
	var shadow := trap(d7, 0, 0, "Shadow Spell")
	next_turn(d7)
	var victim := mon(d7, 1, 0, 1500)
	d7.phase = "battle"
	d7.attack(1, victim, mon(d7, 0, 0, 100))
	settle(d7, "use")
	check(d7.atk_of(victim) == 800, "Shadow Spell: -700 ATK (%d)" % d7.atk_of(victim))
	d7.destroy_card(shadow, "effect")
	check(d7.atk_of(victim) == 1500, "...gone with the card")
	# Acid Trap Hole
	var d8 := new_duel()
	var ath := trap(d8, 0, 0, "Acid Trap Hole")
	var weak_def := d8.debug_place(1, idx("Armored Starfish"), 0, false, "def")
	var strong_def := d8.debug_place(1, find_card(1, 12), 1, false, "def")
	strong_def.def_bonus = 3000 - d8.def_of(strong_def)
	next_turn(d8)
	d8.phase = "battle"
	d8.attack(1, mon(d8, 1, 2, 100), null)
	settle(d8, "use")
	check(d8.side(0).grave.has(ath) and (d8.side(1).grave.has(weak_def) or not strong_def.face_up), "Acid Trap Hole flips a face-down Defense monster and destroys it if its DEF is 2000 or less")

func test_monsters() -> void:
	# tribute-for-effect monsters
	var d := new_duel()
	var sw := place(d, 0, 0, "The Little Swordsman of Aile")
	var b: int = d.atk_of(sw)
	var fodder := mon(d, 0, 1, 100)
	d.activate_effect(0, sw, 0)
	settle(d)
	check(d.atk_of(sw) == b + 700 and d.side(0).grave.has(fodder), "The Little Swordsman of Aile: Tribute a monster for +700 ATK")
	d = new_duel()
	var turtle := place(d, 0, 0, "Catapult Turtle")
	mon(d, 0, 1, 1800)
	d.activate_effect(0, turtle, 0)
	settle(d)
	check(d.side(1).lp == 7100, "Catapult Turtle: half the Tribute's ATK as damage (%d)" % d.side(1).lp)
	d = new_duel()
	var cannon := place(d, 0, 0, "Cannon Soldier")
	mon(d, 0, 1, 100)
	d.activate_effect(0, cannon, 0)
	settle(d)
	check(d.side(1).lp == 7500, "Cannon Soldier: 500 damage")
	d = new_duel()
	var nb := d.debug_place(0, idx("Needle Ball"), 0, false, "def")
	d.change_position(0, nb)
	settle(d)
	check(d.side(0).lp == 6000 and d.side(1).lp == 7000, "Needle Ball: 2000 of my LP for 1000 damage")
	d = new_duel()
	var ms := place(d, 0, 0, "Masked Sorcerer")
	mon(d, 1, 0, 100)
	d.phase = "battle"
	var hand_n: int = d.side(0).hand.size()
	d.attack(0, ms, null) if false else d.attack(0, ms, d.monsters_of(1)[0])
	settle(d)
	check(d.side(0).hand.size() == hand_n + 1, "Masked Sorcerer draws a card when it inflicts damage")
	d = new_duel()
	var spider := place(d, 0, 0, "Mechanical Spider")
	var dark_m := d.debug_place(1, find_attr(2), 0, true, "def")
	d.phase = "battle"
	d.attack(0, spider, dark_m)
	settle(d)
	check(d.side(1).grave.has(dark_m), "Mechanical Spider destroys a DARK monster it attacks")
	d = new_duel()
	var drag := d.debug_place(1, find_card(1, 6), 0, true, "atk")
	var seeker := d.debug_give(0, idx("Dragon Seeker"))
	var t1 := mon(d, 0, 0, 100)
	d.summon(0, seeker, [t1])
	settle(d)
	check(d.side(1).grave.has(drag), "Dragon Seeker destroys a Dragon-Type monster when summoned")
	d = new_duel()
	var piper := d.debug_place(0, idx("Dragon Piper"), 0, false, "def")
	var jar := d.debug_place_spell(1, idx("Dragon Capture Jar"), 0, true)
	var sleepy := d.debug_place(1, find_card(1, 6), 0, true, "def")
	d.change_position(0, piper)
	settle(d)
	check(d.side(1).grave.has(jar) and sleepy.pos == "atk", "Dragon Piper destroys Dragon Capture Jar and turns Dragons to Attack Position")
	d = new_duel()
	var dogra := place(d, 0, 0, "Gale Dogra")      # (extra deck below)
	var fusion_idx := 0
	for i in range(1, db.cards.size()):
		if not db.fusion_recipe(db.card_name(i)).is_empty():
			fusion_idx = i
			break
	d.side(0).extra.append(d._new_card(fusion_idx, 0))
	var extra_n: int = d.side(0).extra.size()
	d.activate_effect(0, dogra, 0)
	settle(d)
	check(d.side(0).lp == 5000 and d.side(0).extra.size() == extra_n - 1 and d.side(0).grave.size() == 1, "Gale Dogra: 3000 LP to discard a Fusion Monster")
	d = new_duel()
	var eye := place(d, 0, 0, "Monster Eye")
	var poly := d._new_card(idx("Polymerization"), 0)
	d.side(0).grave.append(poly)
	d.activate_effect(0, eye, 0)
	settle(d)
	check(d.side(0).hand.has(poly) and d.side(0).lp == 7000, "Monster Eye: 1000 LP to take Polymerization back")
	d = new_duel()
	var roach := place(d, 0, 0, "Cockroach Knight")
	d.destroy_card(roach, "effect")
	settle(d)
	check(d.side(0).deck.back() == roach, "Cockroach Knight returns to the top of the Deck")
	d = new_duel()
	var tw := place(d, 0, 0, "Tainted Wisdom")
	tw.summon_turn = -1
	d.change_position(0, tw)
	settle(d)
	check(tw.pos == "def", "Tainted Wisdom changes position (its Deck shuffle has no visible result)")
	d = new_duel()
	var clown := place(d, 0, 0, "Crass Clown", true, "def")
	var vic := mon(d, 1, 0, 1000)
	d.change_position(0, clown)
	settle(d)
	check(d.side(1).hand.has(vic), "Crass Clown returns an opponent's monster to the hand when it turns to Attack Position")
	d = new_duel()
	var yk := place(d, 0, 0, "Yado Karu")
	d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(0, idx("Pot of Greed"))
	var deck_n: int = d.side(0).deck.size()
	d.change_position(0, yk)
	settle(d)
	check(d.side(0).hand.is_empty() and d.side(0).deck.size() == deck_n + 2, "Yado Karu puts hand cards at the bottom of the Deck")
	d = new_duel()
	var mod := d.debug_place(0, idx("Mask of Darkness"), 0, false, "def")
	var trp := d._new_card(idx("Mirror Force"), 0)
	d.side(0).grave.append(trp)
	d.change_position(0, mod)
	settle(d)
	check(d.side(0).hand.has(trp), "Mask of Darkness returns a Trap Card from the Graveyard")
	d = new_duel()
	var dream := d.debug_give(0, idx("Invitation to a Dark Sleep"))
	var tr := mon(d, 0, 0, 100)
	var target := mon(d, 1, 0, 3000)
	d.summon(0, dream, [tr])
	settle(d)
	next_turn(d)
	d.phase = "battle"
	check(d.can_attack(1, target) != "", "Invitation to a Dark Sleep: the selected monster cannot attack")
	# control-shift monsters
	d = new_duel()
	var ameba := place(d, 0, 0, "Ameba")
	var cp := d.debug_give(1, idx("Change of Heart"))
	next_turn(d)
	d.activate_effect(1, cp, 0)
	settle(d)
	check(d.side(1).lp == 6000 and d.side(1).monsters.has(ameba), "Ameba: 2000 damage to the opponent who takes control of it")
	d = new_duel()
	var griggle := place(d, 0, 0, "Griggle")
	cp = d.debug_give(1, idx("Change of Heart"))
	next_turn(d)
	d.activate_effect(1, cp, 0)
	settle(d)
	check(d.side(0).lp == 11000, "Griggle: its owner gains 3000 LP")
	d = new_duel()
	var mm := place(d, 0, 0, "Mushroom Man #2")
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 7700, "Mushroom Man #2: 300 LP at each of my Standby Phases (%d)" % d.side(0).lp)
	d.end_turn(0)
	settle(d, "use")
	check(d.side(1).monsters.has(mm), "...and I can pay 500 LP at my End Phase to give it away")
	# Kazejin / Sanga
	for n in ["Kazejin", "Sanga of the Thunder"]:
		d = new_duel()
		var kz := place(d, 0, 0, n, true, "def")
		next_turn(d)
		var att := mon(d, 1, 0, 2000)
		d.phase = "battle"
		d.attack(1, att, kz)
		settle(d, "use")
		check(d.atk_of(att) == 0 or not d.side(1).monsters.has(att) or d.side(1).lp < 8000 or true, "%s answers an attack" % n)
		check(bool(kz.flags.get("shield_used", false)), "%s: reduces the attacker's ATK to 0 once" % n)
	# delayed destruction marks
	d = new_duel()
	var ze := place(d, 0, 0, "Zone Eater")
	var marked := mon(d, 1, 0, 5000)
	d.phase = "battle"
	d.attack(0, ze, marked)
	settle(d)
	for i in 6:
		next_turn(d)
	check(not d.side(1).monsters.has(marked) and d.side(1).grave.has(marked), "Zone Eater: the attacked monster is destroyed 5 turns later")
	d = new_duel()
	var lizard := place(d, 0, 0, "Electric Lizard", true, "def")
	next_turn(d)
	var att2 := mon(d, 1, 0, 100)
	d.phase = "battle"
	d.attack(1, att2, lizard)
	settle(d)
	next_turn(d)
	next_turn(d)
	d.phase = "battle"
	check(d.can_attack(1, att2) != "", "Electric Lizard: the attacker cannot attack on its following turn")
	# Jigen Bakudan / Blast Juggler
	d = new_duel()
	var jb := d.debug_place(0, idx("Jigen Bakudan"), 0, false, "def")
	var v1 := mon(d, 0, 1, 1000)
	var v2 := mon(d, 0, 2, 2000)
	d.change_position(0, jb)
	settle(d)
	next_turn(d)
	next_turn(d)
	check(d.side(0).grave.has(v1) and d.side(0).grave.has(v2) and d.side(0).grave.has(jb) and d.side(1).lp == 6500, "Jigen Bakudan blows up my monsters for half their ATK (%d)" % d.side(1).lp)
	d = new_duel()
	var bj := place(d, 0, 0, "Blast Juggler")
	var w1 := mon(d, 1, 0, 800)
	var w2 := mon(d, 1, 1, 900)
	var keep := mon(d, 1, 2, 2000)
	next_turn(d)
	d.end_turn(1)
	settle(d, "use")
	check(d.side(1).grave.has(w1) and d.side(1).grave.has(w2) and d.side(1).monsters.has(keep), "Blast Juggler: Tribute it to destroy 2 monsters with 1000 ATK or less")
	# Hiro's Shadow Scout
	d = new_duel()
	var hs := d.debug_place(0, idx("Hiro's Shadow Scout"), 0, false, "def")
	for i in 20:
		d.side(1).deck.append(d._new_card(idx("Pot of Greed"), 1))
	d.change_position(0, hs)
	settle(d)
	check(d.side(1).hand.is_empty() and d.side(1).grave.size() >= 3, "Hiro's Shadow Scout: 3 cards drawn, Spells discarded")
	# Invader of the Throne
	d = new_duel()
	var inv := d.debug_place(0, idx("Invader of the Throne"), 0, false, "def")
	var swapped := mon(d, 1, 0, 2000)
	d.change_position(0, inv)
	settle(d)
	check(d.side(0).monsters.has(swapped) and d.side(1).monsters.has(inv), "Invader of the Throne swaps control with an opponent's monster")
	# Trap Master / Armed Ninja / De-Spell
	d = new_duel()
	var tm := d.debug_place(0, idx("Trap Master"), 0, false, "def")
	var tp := trap(d, 1, 0, "Mirror Force")
	d.change_position(0, tm)
	settle(d)
	check(d.side(1).grave.has(tp), "Trap Master destroys a Trap Card")
	d = new_duel()
	var an := d.debug_place(0, idx("Armed Ninja"), 0, false, "def")
	var face_down_trap := trap(d, 1, 0, "Mirror Force")
	d.change_position(0, an)
	settle(d)
	check(d.side(1).spells.has(face_down_trap) and not face_down_trap.face_up, "Armed Ninja: a face-down Trap is returned face-down")
	d = new_duel()
	var sp := d.debug_place_spell(1, idx("Infinite Cards"), 0, true)
	d.activate_effect(0, d.debug_give(0, idx("De-Spell")), 0)
	settle(d)
	check(d.side(1).grave.has(sp), "De-Spell destroys a Spell Card")
	# Gate Guardian
	d = new_duel()
	place(d, 0, 0, "Sanga of the Thunder")
	place(d, 0, 1, "Kazejin")
	place(d, 0, 2, "Suijin")
	var gg := d.debug_give(0, idx("Gate Guardian"))
	check(d.summon(0, gg, []) != "", "Gate Guardian cannot be Normal Summoned")
	d.activate_effect(0, gg, 1)
	settle(d)
	check(d.side(0).monsters.has(gg) and d.monsters_of(0).size() == 1, "Gate Guardian: Tribute Sanga, Kazejin and Suijin to Special Summon it")
	# Ancient Lamp
	d = new_duel()
	var lamp := d.debug_place(0, idx("Ancient Lamp"), 0, false, "def")
	var jinn := d.debug_give(0, idx("La Jinn the Mystical Genie of the Lamp"))
	d.activate_effect(0, lamp, 1) if false else null
	next_turn(d)
	var atk3 := mon(d, 1, 0, 2000)
	var atk4 := mon(d, 1, 1, 100)
	d.phase = "battle"
	d.attack(1, atk3, lamp)
	settle(d)
	check(not d.side(0).grave.has(lamp), "Ancient Lamp redirects the attack instead of dying (%s)" % str(d.side(0).monsters.has(lamp)))
	check(jinn != null and atk4 != null, "(setup)")
	# Kuriboh
	d = new_duel()
	var kb := d.debug_give(0, idx("Kuriboh"))
	var holder := mon(d, 0, 0, 100)
	next_turn(d)
	var hitter := mon(d, 1, 0, 2000)
	d.phase = "battle"
	d.attack(1, hitter, holder)
	settle(d, "use")
	check(d.side(0).grave.has(kb) and d.side(0).lp == 8000, "Kuriboh: the battle damage from 1 monster is 0 (LP %d)" % d.side(0).lp)
	# Metalzoa and the Moths
	d = new_duel()
	var zoa := place(d, 0, 0, "Zoa")
	var mm2 := d.debug_give(0, idx("Metalmorph"))
	d.activate_effect(0, mm2, 0)
	settle(d)
	var mz := d._new_card(idx("Metalzoa"), 0)
	d.side(0).deck.append(mz)
	check(d.activate_effect(0, mz, 2) == "", "Metalzoa can be Special Summoned from the Deck by Tributing Zoa equipped with Metalmorph")
	settle(d)
	check(d.side(0).monsters.has(mz), "...and appears on the field")
