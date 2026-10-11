extends SceneTree
## Control effects (Change of Heart and friends) and the cards of data/effects/batch15.json.

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
	print("effect tests 11: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	test_control()
	test_monsters()
	test_spells_traps()
	test_quickplay()
	test_batch16()

func find_card(kind: int, max_level := 12) -> int:
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.card(i)
		if c.get("type", "") == "monster" and int(c.get("kind", 0)) == kind and int(c.get("level", 0)) <= max_level and int(c.get("category", 0)) == 0:
			return i
	return 0

func fire(d: Duel) -> void:
	d.end_turn(d.turn_player)
	settle(d, "use")

## Change of Heart: the monster is on my side for the turn and I can use it like any monster of mine.
func test_control() -> void:
	var d := new_duel()
	var stolen := mon(d, 1, 0, 1800, 1000)
	var foe := mon(d, 1, 1, 500, 500)
	next_turn(d)
	stolen.attacked = true          # it attacked during the opponent's own turn
	stolen.pos_changed = true
	next_turn(d)
	var coh := d.debug_give(0, idx("Change of Heart"))
	d.activate_effect(0, coh, 0)
	settle(d)
	check(d.side(0).monsters.has(stolen) and stolen.controller == 0, "Change of Heart: the monster moves to my side")
	d.phase = "battle"
	check(d.can_attack(0, stolen) == "", "...and can attack this turn even though it attacked on the opponent's turn (%s)" % d.can_attack(0, stolen))
	d.attack(0, stolen, foe)
	settle(d)
	check(d.side(1).grave.has(foe) and d.side(1).lp == 8000 - 1300, "...and its battle works (LP %d)" % d.side(1).lp)
	next_turn(d)
	check(d.side(1).monsters.has(stolen) and stolen.controller == 1, "...and goes back to its owner at the end of the turn")
	# change position and use as a Tribute
	d = new_duel()
	stolen = mon(d, 1, 0, 1800, 1000)
	next_turn(d)
	stolen.attacked = true
	stolen.pos_changed = true
	next_turn(d)
	coh = d.debug_give(0, idx("Change of Heart"))
	d.activate_effect(0, coh, 0)
	settle(d)
	check(d.change_position(0, stolen) == "" and stolen.pos == "def", "a stolen monster can change position")
	var big := d.debug_give(0, idx("Summoned Skull"))
	check(d.summon(0, big, [stolen]) == "", "...and be offered as a Tribute")
	check(d.side(1).grave.has(stolen) and not d.side(0).grave.has(stolen), "...and then goes to its owner's Graveyard")

func test_monsters() -> void:
	# Total Defense Shogun
	var d := new_duel()
	var sh := d.debug_give(0, idx("Total Defense Shogun"))
	var fodder := mon(d, 0, 1, 100)
	d.summon(0, sh, [fodder])
	settle(d)
	check(sh.pos == "def" and sh.face_up, "Total Defense Shogun is summoned in Defense Position")
	var foe := mon(d, 1, 0, 500, 500)
	d.phase = "battle"
	check(d.can_attack(0, sh) == "", "...and can attack from Defense Position (%s)" % d.can_attack(0, sh))
	d.attack(0, sh, foe)
	settle(d)
	check(d.side(1).grave.has(foe) and d.side(1).lp == 8000 - (d.atk_of(sh) - 500), "...using its ATK for the battle (LP %d)" % d.side(1).lp)
	# Boar Soldier
	d = new_duel()
	var boar := d.debug_give(0, idx("Boar Soldier"))
	d.summon(0, boar)
	settle(d)
	check(d.side(0).grave.has(boar), "Boar Soldier is destroyed when Normal Summoned")
	d = new_duel()
	boar = place(d, 0, 0, "Boar Soldier")
	var base: int = d.atk_of(boar)
	check(base == int(d.card_data(boar).get("atk", 0)), "Boar Soldier keeps its ATK while the opponent has no monsters")
	mon(d, 1, 0, 100)
	mon(d, 1, 1, 100)
	check(d.atk_of(boar) == base - 1000, "...loses 1000 ATK once, not per monster (%d)" % (d.atk_of(boar) - base))
	# Garuda the Wind Spirit
	d = new_duel()
	var wind := d._new_card(idx("Harpie Lady"), 0)
	d.side(0).grave.append(wind)
	var gar := d.debug_give(0, idx("Garuda the Wind Spirit"))
	check(d.summon(0, gar) != "", "Garuda cannot be Normal Summoned")
	check(d.activate_effect(0, gar, 1) == "", "Garuda can be Special Summoned by removing a WIND monster")
	settle(d)
	check(d.side(0).monsters.has(gar) and d.side(0).banished.has(wind), "...which is removed from play")
	var victim := mon(d, 1, 0, 1000)
	next_turn(d)
	next_turn(d)
	check(victim.pos == "def", "Garuda changes the position of an opponent's monster at his End Phase")
	# Banisher of the Light
	d = new_duel()
	place(d, 0, 0, "Banisher of the Light")
	var target := mon(d, 1, 0, 1000)
	d.destroy_card(target, "effect")
	check(d.side(1).banished.has(target) and not d.side(1).grave.has(target), "Banisher of the Light: cards that would go to the Graveyard are removed from play")
	# Infinite Cards
	d = new_duel()
	for i in 8:
		d.debug_give(0, idx("Pot of Greed"))
	check(d.hand_excess(0) == 2, "hand limit is 6 normally")
	d.debug_place_spell(0, idx("Infinite Cards"), 0, true)
	check(d.hand_excess(0) == 0 and d.hand_excess(1) == 0, "Infinite Cards: no hand limit for either player")
	# Dark-Eyes Illusionist
	d = new_duel()
	var dei := d.debug_place(0, idx("Dark-Eyes Illusionist"), 0, false, "def")
	var bound := mon(d, 1, 0, 2000)
	d.change_position(0, dei)
	if not d.fx.pending.is_empty():
		d.respond([bound.uid])
	settle(d)
	next_turn(d)
	d.phase = "battle"
	check(d.can_attack(1, bound) != "", "Dark-Eyes Illusionist: the designated monster cannot attack")
	d.destroy_card(dei, "effect")
	check(d.can_attack(1, bound) == "", "...until Dark-Eyes Illusionist leaves the field")
	# Bazoo the Soul-Eater
	d = new_duel()
	var bz := place(d, 0, 0, "Bazoo the Soul-Eater")
	for i in 4:
		d.side(0).grave.append(d._new_card(idx("Pot of Greed"), 0))
	base = d.atk_of(bz)
	check(d.activate_effect(0, bz, 0) == "", "Bazoo can be activated")
	settle(d)
	check(d.atk_of(bz) == base + 900 and d.side(0).banished.size() == 3, "Bazoo: +300 ATK per card removed (%d)" % (d.atk_of(bz) - base))
	check(d.activate_effect(0, bz, 0) != "", "...once per turn")
	next_turn(d)
	check(d.atk_of(bz) == base + 900, "...lasting through the opponent's turn")
	next_turn(d)
	check(d.atk_of(bz) == base, "...and ending after it")

func test_spells_traps() -> void:
	# Infinite Dismissal
	var d := new_duel()
	var lamp := d.debug_give(0, idx("Mystic Lamp"))
	d.summon(0, lamp)
	settle(d)
	var spec := mon(d, 0, 4, 1000)
	spec.flags["special_summoned"] = true
	spec.summon_turn = d.turn
	trap(d, 0, 0, "Infinite Dismissal")
	fire(d)
	check(d.side(0).grave.has(lamp) and d.side(0).monsters.has(spec), "Infinite Dismissal destroys Level 3 or lower monsters summoned this turn (not Special Summoned ones)")
	# Mirror Wall
	d = new_duel()
	var mw := d.debug_place_spell(0, idx("Mirror Wall"), 0, true)
	mw.summon_turn = -1
	var raider := mon(d, 1, 0, 2000)
	var own := mon(d, 0, 0, 2000)
	d.current_attack = {"attacker": raider, "target": own, "player": 1, "negated": false}
	check(d.atk_of(raider) == 1000 and d.atk_of(own) == 2000, "Mirror Wall halves the ATK of the opponent's attacking monster")
	d.current_attack = {}
	check(d.atk_of(raider) == 2000, "...only while it is attacking")
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 6000, "...and costs 2000 LP each of my Standby Phases (%d)" % d.side(0).lp)
	d.set_lp(0, 1500)
	next_turn(d)
	next_turn(d)
	check(not d.side(0).spells.has(mw), "...and is destroyed when I cannot pay")
	# Royal Command
	d = new_duel()
	var rc := d.debug_place_spell(0, idx("Royal Command"), 0, true)
	rc.summon_turn = -1
	var bs := d.debug_place(0, idx("Bite Shoes"), 0, false, "def")
	var foe := mon(d, 1, 0, 1000)
	d.change_position(0, bs)
	settle(d)
	check(foe.pos == "atk", "Royal Command negates Flip Effects")
	# Ultimate Offering
	d = new_duel()
	var uo := d.debug_place_spell(0, idx("Ultimate Offering"), 0, true)
	uo.summon_turn = -1
	var a := d.debug_give(0, idx("Armored Starfish"))
	var b := d.debug_give(0, idx("Mystic Lamp"))
	d.summon(0, a)
	settle(d)
	check(d.summon(0, b) != "", "only one Normal Summon per turn normally")
	check(d.activate_effect(0, uo, 1) == "", "Ultimate Offering can be used after a Normal Summon")
	settle(d)
	check(d.summon(0, b) == "" and d.side(0).lp == 7500, "...for 500 LP, one more Normal Summon (LP %d)" % d.side(0).lp)
	# The Eye of Truth
	d = new_duel()
	var et := d.debug_place_spell(0, idx("The Eye of Truth"), 0, true)
	et.summon_turn = -1
	d.debug_give(1, idx("Pot of Greed"))
	next_turn(d)
	check(d.side(1).lp == 9000, "The Eye of Truth: the opponent gains 1000 LP with a Spell in hand (%d)" % d.side(1).lp)
	# Equip cards
	d = new_duel()
	var warrior := d.debug_place(0, find_card(15, 4), 0, true, "atk")
	var wb: int = d.atk_of(warrior)
	var dragonic := d.debug_give(0, idx("Dragonic Attack"))
	d.activate_effect(0, dragonic, 0)
	settle(d)
	check(d.atk_of(warrior) == wb + 500 and d.race_of(warrior) == CardDB.RACES.find("Dragon"), "Dragonic Attack: +500 ATK and the monster becomes Dragon-Type")
	d.destroy_card(dragonic, "effect")
	check(d.race_of(warrior) == CardDB.RACES.find("Warrior"), "...Warrior again once the Equip Card is gone")
	d = new_duel()
	var hl := place(d, 0, 0, "Harpie Lady")
	wb = d.atk_of(hl)
	var db0: int = d.def_of(hl)
	var gf := d.debug_give(0, idx("Gust Fan"))
	d.activate_effect(0, gf, 0)
	settle(d)
	check(d.atk_of(hl) == wb + 400 and d.def_of(hl) == db0 - 200, "Gust Fan: +400 ATK, -200 DEF for a WIND monster")
	d = new_duel()
	var grad := place(d, 0, 0, "Gradius")
	wb = d.atk_of(grad)
	var cl := d.debug_give(0, idx("Cyclon Laser"))
	d.activate_effect(0, cl, 0)
	settle(d)
	check(d.atk_of(grad) == wb + 300, "Cyclon Laser: +300 ATK for Gradius")
	mon(d, 1, 0, 100, 1000, true, "def")
	d.phase = "battle"
	d.attack(0, grad, d.monsters_of(1)[0])
	settle(d)
	check(d.side(1).lp == 8000 - (wb + 300 - 1000), "...and piercing damage (LP %d)" % d.side(1).lp)
	# Attack and Receive
	d = new_duel()
	trap(d, 0, 0, "Attack and Receive")
	d.side(0).grave.append(d._new_card(idx("Attack and Receive"), 0))
	next_turn(d)
	var hin := d.debug_give(1, idx("Hinotama"))
	d.activate_effect(1, hin, 0)
	settle(d, "use")
	check(d.side(0).lp == 7500 and d.side(1).lp == 8000 - 1000, "Attack and Receive: 700 + 300 per copy in the Graveyard (LP %d)" % d.side(1).lp)
	# The Flute of Summoning Dragon
	d = new_duel()
	place(d, 0, 0, "Lord of D.")
	var dr1 := d.debug_give(0, find_card(1, 6))
	var dr2 := d.debug_give(0, find_card(1, 6))
	var flute := d.debug_give(0, idx("The Flute of Summoning Dragon"))
	d.activate_effect(0, flute, 0)
	settle(d)
	check(d.side(0).monsters.has(dr1) and d.side(0).monsters.has(dr2), "The Flute of Summoning Dragon: up to 2 Dragons from the hand")
	# Multiply
	d = new_duel()
	var kb := place(d, 0, 0, "Kuriboh")
	var mult := d.debug_give(0, idx("Multiply"))
	d.activate_effect(0, mult, 0)
	settle(d)
	var tokens := 0
	for c in d.monsters_of(0):
		if c.token == "Kuriboh Token" and c.pos == "def":
			tokens += 1
	check(tokens == 5 and d.side(0).grave.has(kb), "Multiply: a Kuriboh Token in each open Monster Card Zone (%d)" % tokens)
	var big := d.debug_give(0, idx("Summoned Skull"))
	var one: DCard = d.monsters_of(0)[0]
	d.side(0).monsters[4] = null
	check(d.summon(0, big, [one, d.monsters_of(0)[1]]) != "", "...and the tokens cannot be Tributes")
	# De-Fusion
	d = new_duel()
	var fusion_idx := 0
	var recipe: Array = []
	for i in range(1, db.cards.size()):
		var r: Array = db.fusion_recipe(db.card_name(i))
		if r.size() == 2 and idx(r[0]) != 0 and idx(r[1]) != 0 and r[0] != r[1]:
			fusion_idx = i
			recipe = r
			break
	var fm := d.debug_place(0, fusion_idx, 0, true, "atk")
	var m1 := d._new_card(idx(recipe[0]), 0)
	var m2 := d._new_card(idx(recipe[1]), 0)
	d.side(0).grave.append_array([m1, m2])
	var df := d.debug_give(0, idx("De-Fusion"))
	d.activate_effect(0, df, 0)
	settle(d)
	check(d.side(0).extra.has(fm) and d.side(0).monsters.has(m1) and d.side(0).monsters.has(m2), "De-Fusion: the Fusion Monster returns, its materials are Special Summoned from the Graveyard")

func test_quickplay() -> void:
	# every Quick-Play Spell with an effect must be declared as quickplay with timings (so it works when Set)
	var bad := []
	var eff := EffectDB.load_default(db)
	var checked := 0
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.card(i)
		if c.get("type", "") == "spell" and int(c.get("subtype", -1)) == 5:
			var effects: Array = eff.for_number(int(c.get("number", 0)))
			checked += 1 if not effects.is_empty() else 0
			for e in effects:
				if e.get("type", "") != "quickplay" or (e.get("when", []) as Array).is_empty():
					bad.append(db.card_name(i))
	check(checked >= 10, "the Quick-Play check looked at %d cards" % checked)
	check(bad.is_empty(), "all Quick-Play Spells are declared with timings: %s" % str(bad))
	# Graceful Dice, Set, played in response to an attack
	var d := new_duel()
	var gd := d.debug_place_spell(0, idx("Graceful Dice"), 0, false)
	var def_mon := mon(d, 0, 0, 1000, 1000, true, "def")
	next_turn(d)
	var att := mon(d, 1, 0, 1500, 1000)
	d.phase = "battle"
	d.attack(1, att, def_mon)
	check(d.fx.pending.get("type", "") == "chain" and int(d.fx.pending.get("player", -1)) == 0, "a Set Quick-Play Spell gets a chance to respond to an attack")
	settle(d, "use")
	check(d.side(0).grave.has(gd) and d.atk_of(def_mon) >= 1100, "...and Graceful Dice raises ATK/DEF (ATK %d)" % d.atk_of(def_mon))
	# the same from the hand on the opponent's turn is not allowed
	d = new_duel()
	var hand_gd := d.debug_give(0, idx("Graceful Dice"))
	mon(d, 0, 0, 1000)
	next_turn(d)
	check(d.fx.activation_problem(0, hand_gd, 0, "attack_declared", {}) != "", "Quick-Play Spells in the hand cannot be played on the opponent's turn")
	# Set Quick-Play: not the turn it was Set
	d = new_duel()
	var setqp := d.debug_give(0, idx("Rush Recklessly"))
	d.set_spell_trap(0, setqp)
	check(d.fx.activation_problem(0, setqp, 0, "end_phase", {}) != "", "...and a Set Quick-Play Spell waits until the next turn")
	# Rush Recklessly as a Set card in response to an attack
	d = new_duel()
	var rr := d.debug_place_spell(0, idx("Rush Recklessly"), 0, false)
	var mine := mon(d, 0, 0, 1000)
	var foe := mon(d, 1, 0, 1500)
	next_turn(d)
	d.phase = "battle"
	d.attack(1, foe, mine)
	settle(d, "use")
	check(d.side(0).grave.has(rr) and d.atk_of(mine) == 1700, "Rush Recklessly: +700 ATK when responding to an attack (ATK %d)" % d.atk_of(mine))

func test_batch16() -> void:
	# Raimei
	var d := new_duel()
	d.activate_effect(0, d.debug_give(0, idx("Raimei")), 0)
	settle(d)
	check(d.side(1).lp == 7700, "Raimei: 300 damage")
	# Tailor of the Fickle
	d = new_duel()
	var h1 := place(d, 0, 0, "Harpie Lady")
	var h2 := place(d, 0, 1, "Harpie Lady")
	var b0: int = d.atk_of(h2)
	var gf := d.debug_give(0, idx("Gust Fan"))
	d.activate_effect(0, gf, 0)
	d.respond([h1.uid]) if not d.fx.pending.is_empty() else null
	settle(d)
	check(gf.equipped_to == h1, "Gust Fan is on the first Harpie Lady")
	var tf := d.debug_give(0, idx("Tailor of the Fickle"))
	d.activate_effect(0, tf, 0)
	settle(d)
	check(gf.equipped_to == h2 and d.atk_of(h2) == b0 + 400, "Tailor of the Fickle switches the Equip Card to another monster")
	# Monster Recovery
	d = new_duel()
	var mm := mon(d, 0, 0, 1000)
	for i in 3:
		d.debug_give(0, idx("Pot of Greed"))
	var mr := d.debug_give(0, idx("Monster Recovery"))
	var deck_n: int = d.side(0).deck.size()
	d.activate_effect(0, mr, 0)
	settle(d)
	check(d.side(0).hand.size() == 3 and d.side(0).deck.has(mm) and d.side(0).deck.size() == deck_n + 1, "Monster Recovery: the monster joins the Deck, the hand is redrawn")
	# Lord of D.
	d = new_duel()
	var lord := place(d, 0, 0, "Lord of D.")
	var dragon := d.debug_place(1, find_card(1, 6), 1, true, "atk")
	var coh := d.debug_give(0, idx("Change of Heart"))
	check(d.activate_effect(0, coh, 0) != "", "Lord of D.: Dragons cannot be targeted")
	d.destroy_card(lord, "effect")
	check(d.activate_effect(0, coh, 0) == "", "...unless Lord of D. is gone")
	settle(d)
	check(dragon.controller == 0, "...and then Change of Heart takes it")
	# Lady Panther
	d = new_duel()
	var lp := place(d, 0, 1, "Lady Panther")
	var fighter := mon(d, 0, 0, 500)
	mon(d, 1, 0, 3000)
	d.phase = "battle"
	d.attack(0, fighter, d.monsters_of(1)[0])
	settle(d)
	d.to_main2(0)
	check(d.activate_effect(0, lp, 0) == "", "Lady Panther can be offered")
	settle(d)
	check(d.side(0).deck.back() == fighter and d.side(0).grave.has(lp), "...and returns the monster destroyed in battle to the top of the Deck")
	# Sword of Dragon's Soul
	d = new_duel()
	var war := d.debug_place(0, find_card(15, 4), 0, true, "atk")
	var sw := d.debug_give(0, idx("Sword of Dragon's Soul"))
	d.activate_effect(0, sw, 0)
	settle(d)
	var drg := mon(d, 1, 0, 100, 100, true, "atk", db.card_name(find_card(1, 6)))
	d.phase = "battle"
	d.attack(0, war, drg)
	settle(d)
	var war_alive: bool = d.side(0).monsters.has(war)
	d.to_main2(0)
	settle(d)
	check(war_alive and not d.side(1).monsters.has(drg), "Sword of Dragon's Soul: a Dragon battling the equipped monster is destroyed")
	# Shadow of Eyes
	d = new_duel()
	var soe := trap(d, 0, 0, "Shadow of Eyes")
	next_turn(d)
	var setm := d.debug_give(1, idx("Armored Starfish"))
	d.summon(1, setm, [], -1, true)
	settle(d, "use")
	check(setm.face_up and setm.pos == "atk" and d.side(0).grave.has(soe), "Shadow of Eyes turns a Set monster face-up in Attack Position")
	# Dimensionhole
	d = new_duel()
	var dh_m := mon(d, 0, 0, 1000)
	var dh := d.debug_give(0, idx("Dimensionhole"))
	d.activate_effect(0, dh, 0)
	settle(d)
	check(d.side(0).banished.has(dh_m), "Dimensionhole removes my monster from play")
	next_turn(d)
	check(d.side(0).banished.has(dh_m), "...through the opponent's turn")
	next_turn(d)
	check(d.side(0).monsters.has(dh_m) and dh_m.face_up, "...and it returns at my next Standby Phase")
	# The Unfriendly Amazon
	d = new_duel()
	var ua := place(d, 0, 0, "The Unfriendly Amazon")
	var food := mon(d, 0, 1, 100)
	next_turn(d)
	next_turn(d)
	check(d.side(0).grave.has(food) and d.side(0).monsters.has(ua), "The Unfriendly Amazon offers another monster each Standby Phase")
	next_turn(d)
	next_turn(d)
	check(d.side(0).grave.has(ua), "...and is destroyed when there is none left")
