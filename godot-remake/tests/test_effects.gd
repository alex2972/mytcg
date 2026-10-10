extends SceneTree
## Card effect scenarios: each card from data/effects/*.json behaves like its text says.

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

## Answer pending decisions with simple defaults until none are left.
func settle(d: Duel, chain_choice := "pass", pick_last := false) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 50:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"select":
				var c: Array = p["candidates"]
				d.respond(c.slice(c.size() - p["max"]) if pick_last else c.slice(0, p["max"]))
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

func next_turn(d: Duel) -> void:
	d.end_turn(d.turn_player)
	settle(d)

func _init() -> void:
	db = CardDB.load_default()
	test_burn_and_draw()
	test_mass_removal()
	test_targeting_spells()
	test_equips_and_fields()
	test_traps()
	test_monsters()
	test_continuous()
	print("effect tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_burn_and_draw() -> void:
	var d := new_duel()
	var h := d.debug_give(0, idx("Hinotama"))
	check(d.activate_effect(0, h, 0) == "", "Hinotama activates")
	settle(d)
	check(d.side(1).lp == 7500, "Hinotama deals 500 (lp %d)" % d.side(1).lp)
	check(d.side(0).grave.has(h) and d.fx.chain.is_empty(), "Hinotama goes to the graveyard after resolving")
	d = new_duel()
	var p := d.debug_give(0, idx("Pot of Greed"))
	var deck_before: int = d.side(0).deck.size()
	d.activate_effect(0, p, 0)
	settle(d)
	check(d.side(0).hand.size() == 2 and d.side(0).deck.size() == deck_before - 2, "Pot of Greed draws 2")
	d = new_duel()
	d.side(0).lp = 3000
	var k := d.debug_give(0, idx("Dian Keto the Cure Master"))
	d.activate_effect(0, k, 0)
	settle(d)
	check(d.side(0).lp == 4000, "Dian Keto heals 1000")

func test_mass_removal() -> void:
	var d := new_duel()
	mon(d, 0, 0, 1000)
	var b := mon(d, 1, 0, 1000)
	var dh := d.debug_give(0, idx("Dark Hole"))
	d.activate_effect(0, dh, 0)
	settle(d)
	check(d.monsters_of(0).is_empty() and d.monsters_of(1).is_empty() and d.side(1).grave.has(b), "Dark Hole destroys all monsters")
	d = new_duel()
	mon(d, 0, 0, 1000)
	mon(d, 1, 0, 1000)
	var r := d.debug_give(0, idx("Raigeki"))
	d.activate_effect(0, r, 0)
	settle(d)
	check(d.monsters_of(0).size() == 1 and d.monsters_of(1).is_empty(), "Raigeki destroys only the opponent's monsters")
	d = new_duel()
	var t1 := d.debug_place_spell(1, idx("Trap Hole"), 0)
	var t2 := d.debug_place_spell(0, idx("Mirror Force"), 0)
	var hs := d.debug_give(0, idx("Heavy Storm"))
	d.activate_effect(0, hs, 0)
	settle(d)
	check(d.side(1).grave.has(t1) and d.side(0).grave.has(t2) and d.side(0).grave.has(hs), "Heavy Storm destroys all other Spell/Trap cards")
	d = new_duel()
	t1 = d.debug_place_spell(1, idx("Trap Hole"), 0)
	t2 = d.debug_place_spell(0, idx("Mirror Force"), 0)
	var hf := d.debug_give(0, idx("Harpie's Feather Duster"))
	d.activate_effect(0, hf, 0)
	settle(d)
	check(d.side(1).grave.has(t1) and (d.side(0).spells as Array).has(t2), "Harpie's Feather Duster only hits the opponent's Spells/Traps")

func test_targeting_spells() -> void:
	var d := new_duel()
	var low := mon(d, 1, 0, 1000)
	var high := mon(d, 1, 1, 1800)
	var f := d.debug_give(0, idx("Fissure"))
	d.activate_effect(0, f, 0)
	settle(d)
	check(d.side(1).grave.has(low) and not d.side(1).grave.has(high), "Fissure destroys the lowest-ATK monster")
	d = new_duel()
	var dead := d.debug_give(0, idx("Armored Lizard"))
	d.side(0).hand.erase(dead)
	d.side(0).grave.append(dead)
	var mr := d.debug_give(0, idx("Monster Reborn"))
	check(d.activate_effect(0, mr, 0) == "", "Monster Reborn activates with a target in the graveyard")
	settle(d)
	check((d.side(0).monsters as Array).has(dead) and dead.face_up, "Monster Reborn revives it face-up")
	d = new_duel()
	var victim := mon(d, 1, 0, 2500)
	var coh := d.debug_give(0, idx("Change of Heart"))
	d.activate_effect(0, coh, 0)
	settle(d)
	check((d.side(0).monsters as Array).has(victim) and victim.controller == 0, "Change of Heart takes control")
	d.end_turn(0)
	settle(d)
	check((d.side(1).monsters as Array).has(victim) and victim.controller == 1, "...and gives it back at the end of the turn")
	d = new_duel()
	victim = mon(d, 1, 0, 2500)
	var junk := d.debug_give(0, idx("Armored Lizard"))
	var td := d.debug_give(0, idx("Tribute to The Doomed"))
	d.activate_effect(0, td, 0)
	settle(d)
	check(d.side(0).grave.has(junk) and d.side(1).grave.has(victim), "Tribute to The Doomed discards 1 card and destroys a monster")
	d = new_duel()
	var lonely := d.debug_give(0, idx("Tribute to The Doomed"))
	check(d.activate_effect(0, lonely, 0) != "", "Tribute to The Doomed cannot be activated with no card to discard / no target")

func test_equips_and_fields() -> void:
	var d := new_duel()
	var m := mon(d, 0, 0, 1000)
	var ax := d.debug_give(0, idx("Axe of Despair"))
	d.activate_effect(0, ax, 0)
	settle(d)
	check(d.atk_of(m) == 2000 and ax.equipped_to == m, "Axe of Despair gives +1000 ATK")
	check((d.side(0).spells as Array).has(ax), "the equip card stays on the field")
	d.destroy_card(m, "test")
	settle(d)
	check(d.side(0).grave.has(ax), "equip cards go to the graveyard with their monster")
	d = new_duel()
	var fish := mon(d, 0, 0, 1000, 1000, true, "atk", "Amphibian Beast")
	var umi := d.debug_give(0, idx("Umi"))
	var base_atk := d.atk_of(fish)
	d.activate_effect(0, umi, 0)
	settle(d)
	check(d.side(0).field_spell == umi and d.atk_of(fish) == base_atk + 200, "Umi boosts Fish (+200) (%d vs %d)" % [d.atk_of(fish), base_atk])
	var dragon := mon(d, 1, 0, 1500, 1000, true, "atk", "Darkfire Dragon")
	check(d.atk_of(dragon) == 1500, "Umi does not affect Dragons")
	var umi2 := d.debug_give(0, idx("Umiiruka"))
	d.activate_effect(0, umi2, 0)
	settle(d)
	check(d.side(0).grave.has(umi) and d.side(0).field_spell == umi2, "a new Field Spell replaces the old one")

func test_traps() -> void:
	# Trap Hole vs an opponent's Normal Summon
	var d := new_duel()
	var th := d.debug_place_spell(0, idx("Trap Hole"), 0)
	next_turn(d)
	var big := d.debug_give(1, idx("Armored Lizard"))
	big.atk_bonus = 1500 - d.atk_of(big)
	check(d.summon(1, big) == "", "opponent summons")
	check(d.fx.pending.get("type", "") == "chain" and d.fx.pending["player"] == 0, "the trap owner is offered a chain response")
	settle(d, "activate")
	check(d.side(1).grave.has(big) and d.side(0).grave.has(th), "Trap Hole destroys the summoned monster (>=1000 ATK)")
	# ...but not a weak one
	d = new_duel()
	th = d.debug_place_spell(0, idx("Trap Hole"), 0)
	next_turn(d)
	var weak := d.debug_give(1, idx("Armored Lizard"))
	weak.atk_bonus = 500 - d.atk_of(weak)
	d.summon(1, weak)
	check(d.fx.pending.is_empty() and (d.side(1).monsters as Array).has(weak), "Trap Hole is not offered for a monster below 1000 ATK")
	# Mirror Force
	d = new_duel()
	d.debug_place_spell(0, idx("Mirror Force"), 0)
	var mine := mon(d, 0, 0, 1000)
	next_turn(d)
	var a1 := mon(d, 1, 0, 2000)
	var a2 := mon(d, 1, 1, 1500)
	d.to_battle(1)
	d.attack(1, a1, mine)
	check(d.fx.pending.get("type", "") == "chain", "Mirror Force is offered on an attack")
	settle(d, "activate")
	check(d.side(1).grave.has(a1) and d.side(1).grave.has(a2) and d.side(0).lp == 8000 and d.monsters_of(0).size() == 1, "Mirror Force negates the attack and destroys all attack-position monsters")
	# Magic Cylinder
	d = new_duel()
	d.debug_place_spell(0, idx("Magic Cylinder"), 0)
	mine = mon(d, 0, 0, 1000)
	next_turn(d)
	a1 = mon(d, 1, 0, 1700)
	d.to_battle(1)
	d.attack(1, a1, mine)
	settle(d, "activate")
	check(d.side(1).lp == 8000 - 1700 and d.side(0).lp == 8000, "Magic Cylinder reflects the attacker's ATK")
	# Negate Attack (counter trap) ends the battle phase
	d = new_duel()
	d.debug_place_spell(0, idx("Negate Attack"), 0)
	mine = mon(d, 0, 0, 1000)
	next_turn(d)
	a1 = mon(d, 1, 0, 1700)
	d.to_battle(1)
	d.attack(1, a1, mine)
	settle(d, "activate")
	check(d.side(0).lp == 8000 and d.phase == "main2", "Negate Attack negates and skips the rest of the Battle Phase (phase %s)" % d.phase)
	# Waboku
	d = new_duel()
	d.debug_place_spell(0, idx("Waboku"), 0)
	next_turn(d)
	a1 = mon(d, 1, 0, 1700)
	d.to_battle(1)
	d.attack(1, a1, null)
	settle(d, "activate")
	check(d.side(0).lp == 8000, "Waboku: no battle damage this turn")
	# Solemn Judgment negates a summon
	d = new_duel()
	d.debug_place_spell(0, idx("Solemn Judgment"), 0)
	next_turn(d)
	var s := d.debug_give(1, idx("Armored Lizard"))
	d.summon(1, s)
	settle(d, "activate")
	check(d.side(1).grave.has(s) and d.side(0).lp == 4000, "Solemn Judgment: pay half LP, the summoned monster is destroyed")
	# Solemn Judgment negates a spell
	d = new_duel()
	d.debug_place_spell(0, idx("Solemn Judgment"), 0)
	next_turn(d)
	var dk := d.debug_give(1, idx("Dark Hole"))
	mine = mon(d, 0, 0, 1000)
	d.activate_effect(1, dk, 0)
	check(d.fx.pending.get("type", "") == "chain" and d.fx.pending["player"] == 0, "Solemn Judgment is offered against a Spell")
	settle(d, "activate")
	check((d.side(0).monsters as Array).has(mine) and d.side(1).grave.has(dk), "the negated Spell does nothing")

func test_monsters() -> void:
	var d := new_duel()
	var bug := d.debug_place(0, idx("Man-Eater Bug"), 0, false, "def")
	var foe := mon(d, 1, 0, 2000)
	d.change_position(0, bug)
	settle(d, "pass", true)
	check(d.side(1).grave.has(foe) or d.side(0).grave.has(bug), "Man-Eater Bug's FLIP effect destroys a monster")
	d = new_duel()
	var sangan := mon(d, 0, 0, 1000, 1000, true, "atk", "Sangan")
	d.destroy_card(sangan, "test")
	settle(d)
	var found := false
	for c in d.side(0).hand:
		if d.is_monster(c) and d.atk_of(c) <= 1500:
			found = true
	check(d.side(0).grave.has(sangan) and found and d.side(0).hand.size() == 1, "Sangan searches a monster (ATK<=1500) when sent to the graveyard")

func test_continuous() -> void:
	var d := new_duel()
	var sw := d.debug_give(0, idx("Swords of Revealing Light"))
	var fd := mon(d, 1, 0, 1000, 1000, false, "def")
	d.activate_effect(0, sw, 0)
	settle(d)
	check(fd.face_up and fd.pos == "def", "Swords of Revealing Light flips face-down monsters (they stay in Defense)")
	next_turn(d)   # opponent's turn 1 of 3
	var a := mon(d, 1, 1, 1500)
	d.to_battle(1)
	check(d.attack(1, a, null) != "", "the opponent cannot attack while Swords of Revealing Light is active")
	d.end_turn(1)
	settle(d)
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	d.end_turn(0)
	settle(d)
	check(not d.side(0).grave.has(sw), "Swords of Revealing Light is still active after the opponent's 2nd turn")
	d.end_turn(1)
	settle(d)
	check(d.side(0).grave.has(sw), "Swords of Revealing Light is destroyed after the opponent's 3rd turn")
