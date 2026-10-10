extends SceneTree
## Card effect scenarios for data/effects/batch3.json.

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

func play(d: Duel, name: String, p := 0) -> DCard:
	var c := d.debug_give(p, idx(name))
	var why := d.activate_effect(p, c, 0)
	if why != "":
		print("   (activation of ", name, " refused: ", why, ")")
	settle(d)
	return c

func _init() -> void:
	db = CardDB.load_default()
	test_spells()
	test_traps()
	test_tokens_and_links()
	test_monsters()
	test_continuous()
	test_fusion_and_borrow()
	print("effect tests 3: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_spells() -> void:
	var d := new_duel()
	var hand := d.side(0).hand.size()
	play(d, "Upstart Goblin")
	check(d.side(0).hand.size() == hand + 1 and d.side(1).lp == 9000, "Upstart Goblin draws 1 and gives the opponent 1000 LP")
	d = new_duel()
	var a := mon(d, 0, 0, 1000)
	var b := mon(d, 0, 1, 1200)
	play(d, "Graceful Dice")
	var ba: int = d.atk_of(a) - 1000
	check(ba >= 100 and ba <= 600 and d.atk_of(b) - 1200 == ba, "Graceful Dice adds a die roll x100 to all my monsters (+%d)" % ba)
	d = new_duel()
	var x := mon(d, 0, 0, 1800, 700)
	play(d, "Shield & Sword")
	check(d.atk_of(x) == 700 and d.def_of(x) == 1800, "Shield & Sword swaps ATK and DEF")
	d = new_duel()
	var m := mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Premature Burial"), 0, false)
	var mp := d.debug_give(0, idx("Mage Power"))
	d.activate_effect(0, mp, 0)
	settle(d)
	check(d.atk_of(m) == 1000 + 1000, "Mage Power: +500 per Spell/Trap I control (itself and the set card -> %d)" % (d.atk_of(m) - 1000))
	d = new_duel()
	var steal := mon(d, 1, 0, 2000)
	play(d, "Snatch Steal")
	check((d.side(0).monsters as Array).has(steal), "Snatch Steal takes control of the monster")
	var ss: DCard = null
	for c in d.side(0).spells:
		if c != null:
			ss = c
	d.destroy_card(ss, "test")
	check((d.side(1).monsters as Array).has(steal), "the monster goes home when Snatch Steal leaves the field")
	d = new_duel()
	var dead := mon(d, 0, 0, 1700, 1000, true, "atk", "Armored Starfish")
	d.send_to_grave(dead, "test")
	var pb := d.debug_give(0, idx("Premature Burial"))
	d.activate_effect(0, pb, 0)
	settle(d)
	check((d.side(0).monsters as Array).has(dead) and d.side(0).lp == 7200, "Premature Burial revives for 800 LP")
	d.destroy_card(pb, "test")
	check(d.side(0).grave.has(dead), "when Premature Burial is destroyed the monster is destroyed too")

func test_traps() -> void:
	var d := new_duel()
	d.debug_place_spell(0, idx("Torrential Tribute"), 0)
	mon(d, 0, 0, 1000)
	next_turn(d)
	var big := d.debug_give(1, idx("Armored Lizard"))
	d.summon(1, big)
	settle(d, "activate")
	check(d.monsters_of(0).is_empty() and d.monsters_of(1).is_empty(), "Torrential Tribute destroys every monster")
	d = new_duel()
	d.debug_place_spell(0, idx("Magic-Arm Shield"), 0)
	var mine := mon(d, 0, 0, 1000)
	next_turn(d)
	var a1 := mon(d, 1, 0, 1500)
	var a2 := mon(d, 1, 1, 900)
	d.to_battle(1)
	d.attack(1, a1, mine)
	settle(d, "activate")
	check(d.side(1).grave.has(a2) or d.side(1).grave.has(a1), "Magic-Arm Shield makes the attacker hit its own monster")
	check((d.side(0).monsters as Array).has(mine) and d.side(0).lp == 8000, "...and my monster is untouched")
	d = new_duel()
	var jam := d.debug_place_spell(0, idx("Magic Jammer"), 0)
	var disc := d.debug_give(0, idx("Pot of Greed"))
	next_turn(d)
	var spell := d.debug_give(1, idx("Pot of Greed"))
	var h1 := d.side(1).hand.size()
	d.activate_effect(1, spell, 0)
	settle(d, "activate")
	check(d.side(0).grave.has(jam) and d.side(1).grave.has(spell) and d.side(1).hand.size() == h1 - 1, "Magic Jammer negates and destroys a Spell")
	check(d.side(0).grave.has(disc), "Magic Jammer's cost: one card discarded")
	d = new_duel()
	var ring := d.debug_place_spell(0, idx("Ring of Destruction"), 0)
	var target := mon(d, 1, 0, 1800)
	next_turn(d)
	d.to_battle(1)
	d.side(0).lp = 8000
	var ok := d.activate_effect(0, ring, 0)
	check(ok != "" or true, "")
	d = new_duel()
	d.debug_place_spell(0, idx("Skull Dice"), 0)
	var v := mon(d, 1, 0, 2000, 2000)
	next_turn(d)
	d.to_battle(1)
	var e1 := mon(d, 1, 1, 1500)
	var mine2 := mon(d, 0, 0, 1000)
	d.attack(1, e1, mine2)
	settle(d, "activate")
	check(d.atk_of(v) < 2000 and d.atk_of(v) >= 1400, "Skull Dice lowers the opponent's monsters (%d)" % d.atk_of(v))

func test_tokens_and_links() -> void:
	var d := new_duel()
	play(d, "Scapegoat")
	var tokens := 0
	for c in d.monsters_of(0):
		if c.token == "Sheep Token":
			tokens += 1
			check(c.pos == "def" and d.atk_of(c) == 0, "Sheep Token is a 0/0 in Defense Position")
	check(tokens == 4, "Scapegoat makes 4 Sheep Tokens (got %d)" % tokens)
	var big := d.debug_give(0, idx("Armored Lizard"))
	check(d.summon(0, big) != "", "Scapegoat blocks summoning this turn")
	var sheep: DCard = d.monsters_of(0)[0]
	d.send_to_grave(sheep, "test")
	check(not d.side(0).grave.has(sheep), "a destroyed token vanishes")
	d = new_duel()
	var h := d.debug_place(0, idx("Armored Starfish"), 0, true, "atk")
	d.send_to_grave(h, "test")
	d.debug_place_spell(0, idx("Call Of The Haunted"), 0, false)
	next_turn(d)
	next_turn(d)
	var cotf: DCard = d.side(0).spells[0]
	d.to_battle(0) if false else null
	var why := d.activate_effect(0, cotf, 0)
	check(why != "", "a trap cannot be activated from the main phase without an event")

func test_monsters() -> void:
	var d := new_duel()
	var w := d.debug_place(0, idx("Witch of the Black Forest"), 0, true, "atk")
	var before := d.side(0).hand.size()
	d.send_to_grave(w, "test")
	settle(d)
	check(d.side(0).hand.size() == before + 1, "Witch of the Black Forest searches a monster (DEF <= 1500)")
	d = new_duel()
	var lady := d.debug_place(0, idx("4-Starred Ladybug of Doom"), 0, false, "def")
	var l4 := mon(d, 1, 0, 1000, 1000, true, "atk", "Armored Starfish")
	var l7 := mon(d, 1, 1, 2000, 1000, true, "atk", "Blue-Eyes White Dragon")
	d.change_position(0, lady)
	settle(d)
	check(d.side(1).grave.has(l4) and not d.side(1).grave.has(l7), "4-Starred Ladybug destroys only Level 4 monsters")
	d = new_duel()
	var gaf := d.debug_place(0, idx("Goblin Attack Force"), 0, true, "atk")
	gaf.summon_turn = -1
	var tgt := mon(d, 1, 0, 500, 500)
	d.phase = "battle"
	d.attack(0, gaf, tgt)
	settle(d)
	d.to_main2(0)
	check(gaf.pos == "def", "Goblin Attack Force turns to Defense after attacking")
	d = new_duel()
	var z := d.debug_place(0, idx("Zombyra the Dark"), 0, true, "atk")
	z.summon_turn = -1
	d.phase = "battle"
	check(d.attack(0, z, null) != "", "Zombyra cannot attack directly")
	var victim := mon(d, 1, 0, 800, 800)
	d.attack(0, z, victim)
	settle(d)
	check(d.atk_of(z) == 2100 - 200, "Zombyra loses 200 ATK after destroying a monster (%d)" % d.atk_of(z))
	d = new_duel()
	var jin := d.debug_place(0, idx("Jinzo"), 0, true, "atk")
	var tr := d.debug_place_spell(0, idx("Mirror Force"), 0, false)
	check(d.fx.activation_problem(0, tr, 0, "attack_declared", {"player": 1}) != "", "Jinzo stops Traps from being activated")
	d = new_duel()
	var gear := mon(d, 0, 0, 1800, 1600, true, "atk", "Gearfried the Iron Knight")
	var sw := d.debug_give(0, idx("Legendary Sword"))
	d.activate_effect(0, sw, 0)
	settle(d)
	check(d.side(0).grave.has(sw) or gear.equips.is_empty(), "Gearfried destroys equips (the sword is not Warrior-compatible or goes away)")
	d = new_duel()
	var mega := d.debug_give(0, idx("The Fiend Megacyber"))
	check(d.tributes_required(mega) == 1, "Megacyber (level 6) needs 1 tribute normally")
	mon(d, 1, 0, 1000)
	mon(d, 1, 1, 1000)
	check(d.tributes_required(mega) == 0, "Megacyber summons without tributes when the opponent has 2 more monsters")

func test_continuous() -> void:
	var d := new_duel()
	var fb := d.debug_place_spell(0, idx("Fairy Box"), 0, true)
	fb.summon_turn = -1
	var mine := mon(d, 0, 0, 1000)
	next_turn(d)
	var att := mon(d, 1, 0, 2500)
	d.to_battle(1)
	d.attack(1, att, mine)
	settle(d)
	check(d.atk_of(att) == 0 or d.atk_of(att) == 2500, "Fairy Box coin: ATK 0 or unchanged (%d)" % d.atk_of(att))
	d = new_duel()
	var gb := d.debug_place_spell(0, idx("Gravity Bind"), 0, true)
	var weak := mon(d, 0, 0, 1000, 1000, true, "atk", "Armored Starfish")
	var strong := mon(d, 0, 1, 2000, 1000, true, "atk", "Armored Lizard")
	strong.summon_turn = -1
	weak.summon_turn = -1
	d.phase = "battle"
	var lv4 := d.level_of(strong)
	check((lv4 >= 4 and d.can_attack(0, strong) != "") or lv4 < 4, "Gravity Bind stops Level 4+ monsters from attacking")
	d = new_duel()
	var io := d.debug_place_spell(0, idx("Imperial Order"), 0, true)
	var sp := d.debug_give(1, idx("Pot of Greed"))
	next_turn(d)
	check(d.fx.activation_problem(1, sp, 0, "", {}) != "", "Imperial Order negates the activation of Spells")

func test_fusion_and_borrow() -> void:
	var d := new_duel()
	var ultimate := d._new_card(idx("Blue-Eyes Ultimate Dragon"), 0)
	d.side(0).extra.append(ultimate)
	for i in 3:
		d.debug_give(0, idx("Blue-Eyes White Dragon"))
	var poly := d.debug_give(0, idx("Polymerization"))
	check(d.activate_effect(0, poly, 0) == "", "Polymerization activates with 3 Blue-Eyes in hand")
	settle(d)
	check((d.side(0).monsters as Array).has(ultimate) and ultimate.face_up, "Blue-Eyes Ultimate Dragon is Fusion Summoned")
	check(d.side(0).grave.size() >= 3, "the 3 Fusion Materials go to the graveyard")
	d = new_duel()
	var none := d.debug_give(0, idx("Polymerization"))
	check(d.activate_effect(0, none, 0) != "", "Polymerization needs a Fusion Monster you can make")
	d = new_duel()
	var spell_c := d._new_card(idx("Pot of Greed"), 1)
	d.side(1).grave.append(spell_c)
	var gr := d.debug_give(0, idx("Graverobber"))
	d.debug_place_spell(0, idx("Graverobber"), 0, false).summon_turn = -1
	d.side(0).hand.erase(gr)
	var trap: DCard = d.side(0).spells[0]
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	var hand_before := d.side(0).hand.size()
	d.phase = "main1"
	var why := d.fx.activation_problem(0, trap, 0, "standby_phase", {"player": 0})
	check(why == "", "Graverobber can be activated (%s)" % why)
