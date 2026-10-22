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
	test_remaining()
	print("effect tests 15: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_remaining() -> void:
	test_prohibition()
	test_inspection_scroll()
	test_deepsea()
	test_jam_toon()
	test_imitation_makiu()
	test_spirit()

func test_prohibition() -> void:
	var d := new_duel()
	var exempt := trap(d, 0, 0, "Pot of Greed")
	var blocked := d.debug_give(0, idx("Pot of Greed"))
	var prohibition := d.debug_give(0, idx("Prohibition"))
	d.activate_effect(0, prohibition)
	check(d.fx.pending.get("catalog", false), "Prohibition offers all card names")
	check(d.respond(-1) != "", "invalid declaration rejected")
	d.respond((d.fx.pending["labels"] as Array).find("Pot of Greed"))
	settle(d)
	check(d.activate_effect(0, blocked) != "" and d.set_spell_trap(0, blocked) != "", "declared Spell cannot activate or Set")
	d.add_turn_rule("neg_continuous_spell", 0)
	check(not d.prohibited(blocked), "continuous Spell negation suspends Prohibition")
	d.turn_rules.clear()
	check(d.prohibited(blocked), "Prohibition resumes after negation expires")
	check(d.activate_effect(0, exempt) == "", "existing field card is exempt")
	settle(d)
	d.destroy_card(prohibition, "effect")
	check(d.activate_effect(0, blocked) == "", "restriction ends when Prohibition leaves")
	settle(d)
	d = new_duel()
	var existing := place(d, 0, 0, "Axe Raider")
	prohibition = d.debug_give(0, idx("Prohibition"))
	d.activate_effect(0, prohibition)
	d.respond((d.fx.pending["labels"] as Array).find("Axe Raider"))
	settle(d)
	check(not d.prohibited(existing), "existing monster exempt")
	d.return_to_hand(existing)
	check(d.summon(0, existing) != "" and d.special_summon(existing, 0) != "", "exemption expires on leaving field")

func test_inspection_scroll() -> void:
	var d := new_duel()
	var inspection := d.debug_give(0, idx("Inspection"))
	d.activate_effect(0, inspection)
	settle(d)
	var secret := d.debug_give(1, idx("Axe Raider"))
	d.end_turn(0)
	check(d.fx.pending.get("type", "") == "chain", "Inspection optional in opponent Standby")
	d.respond({"uid": inspection.uid, "idx": 1})
	while d.fx.pending.get("type", "") == "chain":
		d.respond("pass")
	check(d.side(0).lp == 7500 and d.fx.pending.get("hidden_pick", false), "Inspection costs 500 and asks which hidden hand card to reveal")
	d.respond([secret.uid])
	var reveal_events: Array = d.drain_events().filter(func(e): return e["type"] == "reveal_cards")
	check(reveal_events.size() == 1 and reveal_events[0]["cards"] == [secret.uid], "Inspection reveals the chosen card in place")
	check(d.side(1).hand.has(secret) and not secret.face_up, "reveal does not change hidden hand state")
	check(d.fx.pending.get("event", "") == "inspection_again", "Inspection can repeat in same Standby")
	d.respond({"uid": inspection.uid, "idx": 1})
	while d.fx.pending.get("type", "") == "chain":
		d.respond("pass")
	check(d.side(0).lp == 7000 and d.fx.pending.get("hidden_pick", false), "repeat pays another 500")
	d.respond([secret.uid])
	settle(d)
	check(d.side(1).hand.has(secret), "Inspection does not remove cards")
	d = new_duel()
	var m := place(d, 0, 0, "Axe Raider")
	var scroll := d.debug_give(0, idx("Scroll of Bewitchment"))
	d.activate_effect(0, scroll)
	check(d.fx.pending.get("type", "") == "choice", "Scroll asks Attribute")
	d.respond(5)
	settle(d)
	check(d.attribute_of(m) == 6 and d.fx.ops.matches(m, {"attribute": "WIND"}, {"controller": 0}), "Scroll changes effective Attribute and filters")
	d.destroy_card(scroll, "effect")
	check(d.attribute_of(m) == 5, "Attribute restored when equip leaves")

func test_deepsea() -> void:
	var d := new_duel()
	var deep := place(d, 0, 0, "Deepsea Warrior")
	var other := place(d, 0, 1, "Axe Raider")
	var umi := d.debug_give(0, idx("Umi"))
	d.activate_effect(0, umi)
	settle(d)
	check(d.atk_of(deep) == 1600, "Deepsea ignores Umi's own ATK penalty")
	var hole := d.debug_give(0, idx("Dark Hole"))
	d.activate_effect(0, hole)
	settle(d)
	check(d.is_on_field(deep) and not d.is_on_field(other), "Deepsea immune to mass Spell destruction")
	var fissure := d.debug_give(0, idx("Fissure"))
	d.activate_effect(0, fissure)
	settle(d)
	check(d.is_on_field(deep), "Deepsea immune to selected Spell destruction")
	var scroll := d.debug_give(0, idx("Scroll of Bewitchment"))
	d.activate_effect(0, scroll)
	d.respond(3)
	settle(d)
	check(d.attribute_of(deep) == 3, "Deepsea ignores Attribute Equip")
	d.destroy_card(umi, "effect")
	check(d.attribute_of(deep) == 4, "attached Equip applies when Umi leaves")
	hole = d.debug_give(0, idx("Dark Hole"))
	d.activate_effect(0, hole)
	settle(d)
	check(not d.is_on_field(deep), "Deepsea loses protection without Umi")

func test_jam_toon() -> void:
	var d := new_duel()
	var jam := place(d, 0, 0, "Revival Jam")
	var original := place(d, 0, 1, "Axe Raider")
	var defender := d.debug_place_spell(0, idx("Jam Defender"), 0, true)
	defender.summon_turn = -1
	next_turn(d)
	var attacker := mon(d, 1, 0, 2000)
	d.phase = "battle"
	d.attack(1, attacker, original)
	check(d.fx.pending.get("event", "") == "target_declared", "Jam offers redirection when own monster attacked")
	d.respond({"uid": defender.uid, "idx": 1})
	settle(d)
	check(d.side(0).grave.has(jam) and d.is_on_field(original), "Jam redirects battle to Revival Jam")
	d = new_duel()
	var toon := d.debug_give(0, idx("Manga Ryu-Ran"))
	check(d.special_summon(toon, 0) != "", "Manga cannot summon without Toon World")
	var world := d.debug_give(0, idx("Toon World"))
	d.activate_effect(0, world)
	settle(d)
	place(d, 0, 0, "Axe Raider")
	place(d, 0, 1, "Armored Starfish")
	check(d.activate_effect(0, toon, 6) == "", "Manga procedure available with Toon World")
	settle(d)
	check(d.is_on_field(toon) and not d.normal_summoned, "Manga procedure Special Summons using two Tributes")
	d.phase = "battle"
	check(d.can_attack(0, toon) != "", "Manga cannot attack summon turn")
	toon.summon_turn = -1
	mon(d, 1, 0, 3000)
	check(d.can_attack_directly(toon), "Manga may attack directly through non Toons")
	var lp: int = d.side(0).lp
	d.attack(0, toon)
	settle(d)
	check(d.side(0).lp == lp - 500 and d.side(1).lp == 5800, "Toon attack pays 500 before direct damage")
	toon.attacked = false
	d.side(0).lp = 500
	check(d.can_attack(0, toon) != "", "Toon must afford attack cost")
	d.side(0).lp = 5000
	var foe_toon := place(d, 1, 1, "Toon Mermaid")
	check(not d.can_attack_directly(toon) and d.attack(0, toon, d.side(1).monsters[0]) != "", "opponent Toon forces Toon target")
	check(d.attack(0, toon, foe_toon) == "", "opponent Toon is legal target")
	settle(d)
	d.return_to_hand(world)
	settle(d)
	check(d.is_on_field(toon), "returning Toon World does not destroy Manga")
	world = d.debug_give(0, idx("Toon World"))
	d.phase = "main2"
	d.activate_effect(0, world)
	settle(d)
	d.destroy_card(world, "effect")
	settle(d)
	check(not d.is_on_field(toon), "destroying Toon World destroys Manga")

func test_imitation_makiu() -> void:
	for position in 2:
		var d := new_duel()
		var tribute := place(d, 0, 0, "Petit Moth")
		var insect := d._new_card(idx("Basic Insect"), 0)
		d.side(0).deck.append(insect)
		var spell := d.debug_give(0, idx("Insect Imitation"))
		check(d.activate_effect(0, spell) == "", "Insect Imitation has legal +1 Level target")
		while d.fx.pending.get("type", "") == "chain":
			d.respond("pass")
		check(d.fx.pending.get("type", "") == "select", "player picks Insect from Deck")
		d.respond([insect.uid])
		check(d.fx.pending.get("type", "") == "choice", "player picks summon position")
		d.respond(position)
		settle(d)
		check(d.side(0).grave.has(tribute) and d.is_on_field(insect), "Imitation Tributes and summons exactly +1 Level Insect")
		check(insect.face_up == (position == 0) and insect.pos == ("atk" if position == 0 else "def"), "both summon positions supported")
	var d := new_duel()
	var skull := place(d, 0, 0, "Summoned Skull")
	var low := mon(d, 1, 0, 500, 2499, false, "def")
	var equal := mon(d, 1, 1, 500, 2500)
	var makiu := d.debug_give(0, idx("Makiu"))
	check(d.activate_effect(0, makiu) == "", "Makiu chooses Summoned Skull")
	settle(d)
	check(not d.is_on_field(low) and d.is_on_field(equal) and d.is_on_field(skull), "Makiu destroys strictly lower DEF, including face-down")
	check(d.to_battle(0) != "", "Makiu prevents Battle Phase")
	d = new_duel()
	place(d, 0, 0, "Axe Raider")
	makiu = d.debug_give(0, idx("Makiu"))
	check(d.activate_effect(0, makiu) != "", "Makiu rejects non Thunder non Skull")

func test_spirit() -> void:
	var d := new_duel()
	var substitute := place(d, 0, 0, "Armored Starfish")
	var grave := d.debug_give(0, idx("Armored Starfish"))
	d.send_to_grave(grave, "effect")
	var spirit := d.debug_give(0, idx("Spirit Elimination"))
	d.activate_effect(0, spirit)
	settle(d)
	var aqua := d.debug_give(0, idx("Aqua Spirit"))
	check(d.activate_effect(0, aqua, 1) == "", "Spirit Elimination replaces summon banish cost")
	check(d.fx.pending.get("type", "") == "select" and (d.fx.pending.get("candidates", []) as Array).has(substitute.uid), "player selects substitute on field")
	d.respond([substitute.uid])
	settle(d)
	check(d.side(0).grave.has(grave) and d.side(0).banished.has(substitute) and d.is_on_field(aqua), "substitute banished, grave monster preserved, summon resolves")
	next_turn(d)
	check(not d.has_turn_rule("spirit_elimination", 0) and d.side(0).banished.has(substitute), "rule expires, substitute stays banished")
	d = new_duel()
	substitute = place(d, 0, 0, "Axe Raider")
	grave = d.debug_give(0, idx("Armored Starfish"))
	d.send_to_grave(grave, "effect")
	spirit = d.debug_give(0, idx("Spirit Elimination"))
	d.activate_effect(0, spirit)
	settle(d)
	var soul := d.debug_give(0, idx("Soul Release"))
	d.activate_effect(0, soul)
	if d.fx.pending.get("type", "") == "select":
		d.respond([grave.uid])
	settle(d)
	check(d.side(0).grave.has(grave) and d.side(0).banished.has(substitute), "Spirit also substitutes effect removals")

	# Cost substitutes must be face-up and retain the original Attribute restriction.
	d = new_duel()
	place(d, 0, 0, "Axe Raider")
	place(d, 0, 1, "Armored Starfish", false, "def")
	grave = d.debug_give(0, idx("Armored Starfish"))
	d.send_to_grave(grave, "effect")
	spirit = d.debug_give(0, idx("Spirit Elimination"))
	d.activate_effect(0, spirit)
	settle(d)
	aqua = d.debug_give(0, idx("Aqua Spirit"))
	check(d.activate_effect(0, aqua, 1) != "", "Aqua Spirit cannot use EARTH or face-down WATER substitutes")
	var water := place(d, 0, 2, "Armored Starfish")
	check(d.activate_effect(0, aqua, 1) == "", "face-up WATER is eligible")
	check(d.fx.pending.get("candidates", []) == [water.uid], "replacement selector preserves Attribute condition")
	d.respond([water.uid])
	settle(d)

	d = new_duel()
	var sheep := d.new_token("Sheep Token", 0)
	d.special_summon(sheep, 0, "def")
	grave = d.debug_give(0, idx("Armored Starfish"))
	d.send_to_grave(grave, "effect")
	spirit = d.debug_give(0, idx("Spirit Elimination"))
	d.activate_effect(0, spirit)
	settle(d)
	soul = d.debug_give(0, idx("Soul Release"))
	d.activate_effect(0, soul)
	d.respond([grave.uid])
	settle(d)
	check(d.side(0).grave.has(grave) and not d.is_on_field(sheep) and not d.side(0).banished.has(sheep), "unrestricted Spirit substitute may be Token, which disappears")
