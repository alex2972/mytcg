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
	test_chains()
	print("effect tests 14: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_chains() -> void:
	var d := new_duel()
	var wall := place(d, 0, 0, "Labyrinth Wall")
	var shadow := d._new_card(idx("Wall Shadow"), 0)
	d.side(0).deck.append(shadow)
	check(d.summon(0, d.debug_give(0, idx("Wall Shadow"))) != "", "Wall Shadow cannot Normal Summon")
	check(d.special_summon(shadow, 0) != "", "Wall Shadow rejects generic Special Summon")
	check(d.activate_effect(0, shadow, 2) != "", "Shadow needs Labyrinth equip")
	var lab := d.debug_give(0, idx("Magical Labyrinth"))
	d.activate_effect(0, lab)
	settle(d)
	check(lab.equipped_to == wall, "Labyrinth equips only Wall")
	check(d.activate_effect(0, shadow, 2) == "", "Shadow procedure is available from Deck")
	settle(d)
	check(d.side(0).grave.has(wall) and d.side(0).grave.has(lab) and d.side(0).monsters.has(shadow), "procedure Tributes Wall and Special Summons Shadow")
	check(not d.normal_summoned, "procedure preserves Normal Summon")
	d = new_duel()
	wall = place(d, 0, 0, "Labyrinth Wall")
	shadow = d._new_card(idx("Wall Shadow"), 0)
	d.side(0).deck.append(shadow)
	lab = d.debug_give(0, idx("Magical Labyrinth"))
	d.activate_effect(0, lab)
	settle(d)
	check(d.activate_effect(0, lab, 1) == "", "Labyrinth offers its equipped monster")
	settle(d)
	check(d.side(0).monsters.has(shadow), "equip's own procedure summons Shadow")
	d = new_duel()
	var petit := place(d, 0, 0, "Petit Moth")
	var moth := d.debug_give(0, idx("Perfectly Ultimate Great Moth"))
	var cocoon := d.debug_give(0, idx("Cocoon of Evolution"))
	check(d.activate_effect(0, cocoon) == "", "Cocoon can be treated as Equip from hand")
	settle(d)
	check(cocoon.equipped_to == petit and d.atk_of(petit) == 0 and d.def_of(petit) == 2000, "Cocoon gives Petit its stats")
	for i in 5:
		next_turn(d)
		next_turn(d)
	check(int(cocoon.flags.get("cocoon_turns", 0)) == 5, "counts my turns, not opponent turns")
	check(d.activate_effect(0, moth, 2) != "", "Moth cannot emerge before sixth turn")
	next_turn(d)
	next_turn(d)
	check(d.activate_effect(0, moth, 2) == "", "Moth emerges on sixth own turn")
	settle(d)
	check(d.side(0).monsters.has(moth) and d.side(0).grave.has(petit) and d.side(0).grave.has(cocoon), "proper Moth summon chain")
	d = new_duel()
	var returned := place(d, 0, 0, "Armored Starfish")
	var mine := place(d, 0, 1, "Axe Raider")
	var theirs := place(d, 1, 0, "Harpie Lady")
	var riot := trap(d, 0, 0, "Major Riot")
	d.effect_player = 1
	d.return_to_hand(returned)
	d.effect_player = -1
	check(d.fx.pending.get("event", "") == "returned_to_hand", "Major Riot uses monster return window")
	d.respond({"uid": riot.uid, "idx": 0})
	settle(d)
	check(d.monsters_of(0).size() == 1 and d.monsters_of(1).size() == 1, "both choose exact number bounced by Riot")
	for c in d.monsters_of(0) + d.monsters_of(1):
		check(not c.face_up and c.pos == "def" and c.flags.get("special_summoned", false), "Riot summons face-down Defense")
	check(d.side(0).grave.has(riot) and (d.side(0).hand.has(mine) or d.side(0).monsters.has(mine)) and d.side(1).monsters.has(theirs), "Riot resolves and keeps returned monsters in their proper sides")
	d = new_duel()
	riot = trap(d, 0, 0, "Major Riot")
	var spell := d.debug_place_spell(0, idx("Pot of Greed"), 1, true)
	d.return_to_hand(spell)
	check(d.fx.pending.is_empty(), "returning Spell does not trigger Riot")

	d = new_duel()
	riot = trap(d, 0, 0, "Major Riot")
	returned = place(d, 0, 0, "Axe Raider")
	d.return_to_hand(returned)
	check(d.fx.pending.is_empty(), "Riot does not answer own or rule-caused return")

	d = new_duel()
	var fusion := place(d, 0, 0, "Flame Swordsman")
	riot = trap(d, 0, 0, "Major Riot")
	d.effect_player = 1
	d.return_to_hand(fusion)
	d.effect_player = -1
	check(d.side(0).extra.has(fusion) and not d.side(0).hand.has(fusion) and d.fx.pending.is_empty(), "Fusion returns to Extra Deck and does not trigger Riot")

	d = new_duel()
	petit = place(d, 0, 0, "Petit Moth")
	cocoon = d.debug_give(0, idx("Cocoon of Evolution"))
	d.activate_effect(0, cocoon)
	settle(d)
	cocoon.flags["cocoon_turns"] = 6
	d.force_position(petit, "def", false)
	settle(d)
	check(d.side(0).grave.has(cocoon) and petit.equips.is_empty(), "turning Petit face-down loses Cocoon and evolution counter")
	d.force_position(petit, "atk", true)
	settle(d)
	cocoon = d.debug_give(0, idx("Cocoon of Evolution"))
	d.activate_effect(0, cocoon)
	settle(d)
	check(int(cocoon.flags.get("cocoon_turns", -1)) == 0, "new Cocoon starts six-turn wait again")
