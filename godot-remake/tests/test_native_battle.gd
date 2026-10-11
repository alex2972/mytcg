extends SceneTree
## Regression cases derived from native battle stat calculation.
var db: CardDB
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func idx(name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	push_error("Missing card: " + name)
	return 0

func duel() -> Duel:
	var deck := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var d := Duel.create(db, deck, deck, 1, 0)
	d.side(0).hand.clear()
	d.side(1).hand.clear()
	d.turn = 3
	d.phase = "battle"
	return d

func monster(d: Duel, player: int, zone: int, attack: int) -> DCard:
	var c := d.debug_place(player, idx("Armored Starfish"), zone, true, "atk")
	c.atk_bonus = attack - d.atk_of(c)
	c.summon_turn = -1
	return c

func settle(d: Duel) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 100:
		guard += 1
		match d.fx.pending["type"]:
			"chain": d.respond("pass")
			"yesno": d.respond(false)
			"choice": d.respond(0)
			"select": d.respond((d.fx.pending["candidates"] as Array).slice(0, d.fx.pending["max"]))

func _init() -> void:
	db = CardDB.load_default()
	test_current_stats_and_rounding()
	test_metal_bonus_only_when_attacking()
	test_damage_uses_native_stats()
	test_direct_damage_uses_mirror_wall()
	test_copycat_original_stats()
	test_mage_power_all_spell_zones()
	print("native battle tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_current_stats_and_rounding() -> void:
	var d := duel()
	var a := monster(d, 0, 0, 1001)
	var t := monster(d, 1, 0, 1501)
	var metal := d.debug_place_spell(0, idx("Metalmorph"), 0, true)
	d.equip_card(metal, a, {"atk": 300, "def": 300})
	a.mods.append({"atk": 501, "until": "end_turn"})
	d.current_attack = {"attacker": a, "target": t, "player": 0}
	check(d.atk_of(a) == 2553, "Metalmorph adds rounded-up half current target ATK to modified ATK")
	d.debug_place_spell(1, idx("Mirror Wall"), 0, true)
	check(d.atk_of(a) == 1277, "Mirror Wall halves completed ATK and Metalmorph bonus separately")
	d.debug_place_spell(1, idx("Mirror Wall"), 1, true)
	check(d.atk_of(a) == 639, "multiple Mirror Walls apply successively with native rounding")
	d.current_attack.clear()
	check(d.atk_of(a) == 1802, "Mirror Wall's reduction applies only to attacking monsters")

func test_metal_bonus_only_when_attacking() -> void:
	var d := duel()
	var a := monster(d, 0, 0, 1000)
	var t := monster(d, 1, 0, 1501)
	var metal := d.debug_place_spell(0, idx("Metalmorph"), 0, true)
	d.equip_card(metal, a, {"atk": 300, "def": 300})
	check(d.atk_of(a) == 1300, "equipped monster has only +300 outside an attack")
	d.current_attack = {"attacker": t, "target": a, "player": 1}
	check(d.atk_of(a) == 1300, "defending Metalmorph monster gains no half-ATK bonus")
	d.current_attack = {"attacker": a, "target": null, "player": 0}
	check(d.atk_of(a) == 1300, "a direct attack has no target-based bonus")

func test_damage_uses_native_stats() -> void:
	var d := duel()
	var a := monster(d, 0, 0, 1701)
	var t := monster(d, 1, 0, 1501)
	var metal := d.debug_place_spell(0, idx("Metalmorph"), 0, true)
	d.equip_card(metal, a, {"atk": 300, "def": 300})
	d.debug_place_spell(1, idx("Mirror Wall"), 0, true)
	check(d.attack(0, a, t) == "", "native stat scenario starts an attack")
	settle(d)
	# ceil(2001/2) + ceil(ceil(1501/2)/2) = 1001 + 376 = 1377.
	check(d.side(0).lp == 7876, "damage uses 1377 versus 1501 after both effects")
	check(d.side(0).grave.has(a) and d.is_on_field(t), "the correctly weaker attacker is destroyed")

func test_direct_damage_uses_mirror_wall() -> void:
	var d := duel()
	var a := monster(d, 0, 0, 1001)
	d.debug_place_spell(1, idx("Mirror Wall"), 0, true)
	check(d.attack(0, a) == "", "Mirror Wall scenario starts a direct attack")
	settle(d)
	check(d.side(1).lp == 7499, "direct attack uses rounded-up half ATK before context clears")

func test_copycat_original_stats() -> void:
	var d := duel()
	var target := monster(d, 1, 0, 1800)
	target.def_bonus = 500
	target.mods.append({"atk": 700, "def": 300, "until": "end_turn"})
	var copy := d.debug_give(0, idx("Copycat"))
	check(d.special_summon(copy, 0) == "", "Copycat can be Special Summoned")
	settle(d)
	check(d.atk_of(copy) == 850 and d.def_of(copy) == 1400, "Copycat copies printed stats despite permanent and temporary target modifiers")

func test_mage_power_all_spell_zones() -> void:
	var d := duel()
	var host := monster(d, 1, 0, 1000)
	var mage := d.debug_place_spell(0, idx("Mage Power"), 0, true)
	d.equip_card(mage, host, {})
	d.debug_place_spell(0, idx("Mirror Force"), 1, false)
	var field := d.debug_place_spell(0, idx("Fusion Gate"), 2, true)
	d.side(0).spells[2] = null
	d.side(0).field_spell = field
	check(d.atk_of(host) == 2500, "Mage Power counts its controller's equip, Set trap and Field Spell when equipping an opposing monster")
	check(d.def_of(host) == 2900, "Mage Power increases DEF by the same full spell-zone count")
	d.side(0).field_spell = null
	check(d.atk_of(host) == 2000, "Mage Power's bonus changes when the Field Spell leaves")
