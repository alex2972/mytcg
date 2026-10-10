extends SceneTree
## Card effect scenarios for data/effects/batch2.json.

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
	while not d.fx.pending.is_empty() and guard < 50:
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

func play(d: Duel, name: String, p := 0) -> DCard:
	var c := d.debug_give(p, idx(name))
	var why := d.activate_effect(p, c, 0)
	if why != "":
		print("   (activation of ", name, " refused: ", why, ")")
	settle(d)
	return c

func _init() -> void:
	db = CardDB.load_default()
	test_equips()
	test_spells()
	test_continuous()
	print("effect tests 2: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_equips() -> void:
	var d := new_duel()
	var light := mon(d, 0, 0, 1000, 1000, true, "atk", "Alligator's Sword")   # a DARK monster in this game; check attribute below
	var attr := int(d.card_data(light).get("attribute", 0))
	var target := mon(d, 0, 1, 1000, 1000, true, "atk", "Mystical Elf")      # LIGHT
	var base := d.atk_of(target)
	var el := d.debug_give(0, idx("Elf's Light"))
	check(d.activate_effect(0, el, 0) == "", "Elf's Light activates with a LIGHT monster")
	settle(d)
	check(d.atk_of(target) == base + 400 and d.def_of(target) == 1000 - 200 + (d.def_of(target) - (1000 - 200)), "Elf's Light: +400 ATK (%d vs %d)" % [d.atk_of(target), base])
	d = new_duel()
	var lb := d.debug_give(0, idx("Lightning Blade"))
	mon(d, 0, 0, 1000, 1000, true, "atk", "Mystical Elf")
	check(d.activate_effect(0, lb, 0) != "", "Lightning Blade needs a Warrior")
	d = new_duel()
	var m := mon(d, 0, 0, 1000, 1000, true, "atk", "Armaill")      # Warrior
	var w := d.debug_give(0, idx("Lightning Blade"))
	var water := mon(d, 1, 0, 1500, 1000, true, "atk", "Armored Starfish")   # Aqua / WATER
	var water_before := d.atk_of(water)
	d.activate_effect(0, w, 0)
	settle(d)
	check(d.atk_of(m) == 1800 and d.atk_of(water) == water_before - 500, "Lightning Blade: +800 for the Warrior, -500 for every WATER monster")
	# Horn of the Unicorn returns to the top of the Deck
	d = new_duel()
	m = mon(d, 0, 0, 1000)
	var horn := d.debug_give(0, idx("Horn of the Unicorn"))
	d.activate_effect(0, horn, 0)
	settle(d)
	check(d.atk_of(m) == 1700, "Horn of the Unicorn +700")
	d.destroy_card(m, "test")
	settle(d)
	check(d.side(0).deck.back() == horn, "Horn of the Unicorn goes back on top of the Deck")
	# United We Stand
	d = new_duel()
	m = mon(d, 0, 0, 1000)
	mon(d, 0, 1, 1000)
	var uws := d.debug_give(0, idx("United We Stand"))
	d.activate_effect(0, uws, 0)
	settle(d)
	check(d.atk_of(m) == 1000 + 1600, "United We Stand: +800 per face-up monster (%d)" % d.atk_of(m))
	mon(d, 0, 2, 500)
	check(d.atk_of(m) == 1000 + 2400, "...and it grows with the field")
	# Mask of Brutality upkeep
	d = new_duel()
	m = mon(d, 0, 0, 1000)
	var mb := d.debug_give(0, idx("Mask of Brutality"))
	d.activate_effect(0, mb, 0)
	settle(d)
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	check(d.side(0).lp == 7000, "Mask of Brutality: pay 1000 LP in your Standby Phase (lp %d)" % d.side(0).lp)
	d.side(0).lp = 500
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	check(d.side(0).grave.has(mb), "Mask of Brutality is destroyed when you cannot pay")

func test_spells() -> void:
	var d := new_duel()
	var fiend := mon(d, 1, 0, 1000, 1000, true, "atk", "Earthbound Spirit")   # Fiend? kind 3
	var warrior := mon(d, 1, 1, 1000, 1000, true, "atk", "Armaill")
	play(d, "Exile of the Wicked")
	check(d.side(1).grave.has(fiend) and not d.side(1).grave.has(warrior), "Exile of the Wicked destroys only Fiends")
	d = new_duel()
	play(d, "Tremendous Fire")
	check(d.side(1).lp == 7000 and d.side(0).lp == 7500, "Tremendous Fire: 1000 to them, 500 to you")
	d = new_duel()
	d.debug_give(0, idx("Armored Lizard"))
	d.debug_give(0, idx("Armored Lizard"))
	for i in 3:
		d.debug_give(1, idx("Armored Lizard"))
	play(d, "Card Destruction")
	check(d.side(0).hand.size() == 2 and d.side(1).hand.size() == 3 and d.side(0).grave.size() == 3, "Card Destruction: both discard and redraw the same number")
	d = new_duel()
	play(d, "Painful Choice")
	check(d.side(0).hand.size() == 1 and d.side(0).grave.size() == 5, "Painful Choice: 1 card to hand, the other 4 to the graveyard (+ itself)")
	d = new_duel()
	var foe := mon(d, 1, 0, 2000)
	var mine := mon(d, 0, 0, 1500)
	play(d, "Mystic Box")
	check(d.side(1).grave.has(foe) and (d.side(1).monsters as Array).has(mine) and mine.controller == 1, "Mystic Box destroys theirs and gives yours away")
	d = new_duel()
	for i in 5:
		d.debug_give(0, idx("Armored Lizard"))
	mon(d, 0, 0, 1000)
	mon(d, 1, 0, 1000)
	play(d, "Final Destiny")
	check(d.monsters_of(0).is_empty() and d.monsters_of(1).is_empty() and d.side(0).hand.is_empty(), "Final Destiny: discard 5, destroy everything")
	d = new_duel()
	var four := 0
	for i in 4:
		d.debug_give(0, idx("Armored Lizard"))
	var fd := d.debug_give(0, idx("Final Destiny"))
	check(d.activate_effect(0, fd, 0) != "", "Final Destiny needs 5 other cards in hand")
	# Sebek's Blessing after a direct attack
	d = new_duel()
	var sb := d.debug_place_spell(0, idx("Sebek's Blessing"), 0)
	var a := mon(d, 0, 0, 1000)
	d.to_battle(0)
	d.attack(0, a, null)
	check(d.fx.pending.get("type", "") == "chain", "Sebek's Blessing is offered after direct damage")
	settle(d, "activate")
	check(d.side(0).lp == 9000 and d.side(1).lp == 7000, "Sebek's Blessing heals the damage dealt")

func test_continuous() -> void:
	var d := new_duel()
	mon(d, 0, 0, 1000)
	mon(d, 0, 1, 1000)
	play(d, "The Dark Door")
	d.to_battle(0)
	var a1: DCard = d.monsters_of(0)[0]
	var a2: DCard = d.monsters_of(0)[1]
	check(d.attack(0, a1, null) == "" , "first attack goes through")
	check(d.attack(0, a2, null) != "", "The Dark Door: only 1 attacker per Battle Phase")
	# Card of Safe Return
	d = new_duel()
	play(d, "Card of Safe Return")
	var dead := d.debug_give(0, idx("Armored Lizard"))
	d.side(0).hand.erase(dead)
	d.side(0).grave.append(dead)
	var hand_before: int = d.side(0).hand.size()
	var reborn := d.debug_give(0, idx("Monster Reborn"))
	hand_before = d.side(0).hand.size() - 1
	d.activate_effect(0, reborn, 0)
	settle(d, "activate")
	check(d.side(0).hand.size() == hand_before + 1, "Card of Safe Return: draw 1 when a monster is Special Summoned from your Graveyard (hand %d)" % d.side(0).hand.size())
	# Vengeful Bog Spirit
	d = new_duel()
	play(d, "Vengeful Bog Spirit")
	var fresh := d.debug_give(0, idx("Armored Lizard"))
	d.summon(0, fresh)
	d.to_battle(0)
	check(d.attack(0, fresh, null) != "", "Vengeful Bog Spirit: a monster cannot attack the turn it was summoned")
