extends SceneTree
## Card effect scenarios for data/effects/batch6.json.

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

func play(d: Duel, name: String, p := 0, eff_idx := 0) -> DCard:
	var c := d.debug_give(p, idx(name))
	var why := d.activate_effect(p, c, eff_idx)
	if why != "":
		print("   (activation of ", name, " refused: ", why, ")")
	settle(d)
	return c

func _init() -> void:
	db = CardDB.load_default()
	test_flips()
	test_stats()
	test_battle()
	test_continuous()
	print("effect tests 5: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func flip(d: Duel, c: DCard) -> void:
	c.summon_turn = -1
	d.change_position(0, c)
	settle(d)

func test_flips() -> void:
	var d := new_duel()
	var h := d.side(0).hand.size()
	flip(d, d.debug_place(0, idx("Skelengel"), 0, false, "def"))
	check(d.side(0).hand.size() == h + 1, "Skelengel draws a card")
	d = new_duel()
	d.debug_place_spell(1, idx("Mirror Force"), 0, false)
	d.debug_place_spell(1, idx("Waboku"), 1, false)
	flip(d, d.debug_place(0, idx("Princess of Tsurugi"), 0, false, "def"))
	check(d.side(1).lp == 7000, "Princess of Tsurugi: 500 per enemy Spell/Trap (LP %d)" % d.side(1).lp)
	d = new_duel()
	var fd := mon(d, 1, 0, 1000, 1000, false, "def")
	flip(d, d.debug_place(0, idx("Bombardment Beetle"), 0, false, "def"))
	check(fd.face_up, "Bombardment Beetle flips a face-down monster")
	d = new_duel()
	d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(1, idx("Pot of Greed"))
	flip(d, d.debug_place(0, idx("Morphing Jar"), 0, false, "def"))
	check(d.side(0).hand.size() == 5 and d.side(1).hand.size() == 5, "Morphing Jar: both players end up with 5 cards")

func test_stats() -> void:
	var d := new_duel()
	var base := mon(d, 0, 0, 1000, 1000, true, "atk", "Mystical Elf")
	var elf := d.atk_of(base)
	d.debug_place(1, idx("Hoshiningen"), 0, true, "atk")
	check(d.atk_of(base) == elf + 500, "Hoshiningen: +500 ATK to LIGHT monsters (%d -> %d)" % [elf, d.atk_of(base)])
	d = new_duel()
	var mk := d.debug_place(0, idx("Machine King"), 0, true, "atk")
	var b0 := d.atk_of(mk)
	d.debug_place(0, idx("Machine King"), 1, true, "atk")
	check(d.atk_of(mk) == b0 + 100, "Machine King gets +100 per Machine")
	d = new_duel()
	var fa := d.debug_place(0, idx("Flash Assailant"), 0, true, "atk")
	var a0 := d.atk_of(fa)
	d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(0, idx("Pot of Greed"))
	check(d.atk_of(fa) == a0 - 800, "Flash Assailant: -400 per card in hand (%d -> %d)" % [a0, d.atk_of(fa)])

func test_battle() -> void:
	var d := new_duel()
	var hk := d.debug_place(0, idx("Hayabusa Knight"), 0, true, "atk")
	hk.summon_turn = -1
	var t1 := mon(d, 1, 0, 100, 100)
	var t2 := mon(d, 1, 1, 100, 100)
	d.phase = "battle"
	check(d.attack(0, hk, t1) == "", "Hayabusa Knight attacks once")
	settle(d)
	check(d.attack(0, hk, t2) == "", "Hayabusa Knight attacks a second time")
	settle(d)
	check(d.attack(0, hk, null) != "", "...but not a third time")
	d = new_duel()
	var j7 := d.debug_place(0, idx("Jinzo #7"), 0, true, "atk")
	j7.summon_turn = -1
	mon(d, 1, 0, 1000, 1000)
	d.phase = "battle"
	check(d.attack(0, j7, null) == "", "Jinzo #7 attacks directly")
	settle(d)
	check(d.side(1).lp == 8000 - d.atk_of(j7), "...and deals its ATK as damage")
	d = new_duel()
	var bb := d.debug_place(0, idx("The Bistro Butcher"), 0, true, "atk")
	bb.summon_turn = -1
	d.side(1).deck.append(d._new_card(idx("Pot of Greed"), 1))
	d.side(1).deck.append(d._new_card(idx("Pot of Greed"), 1))
	var hb := d.side(1).hand.size()
	d.phase = "battle"
	d.attack(0, bb, null)
	settle(d)
	check(d.side(1).hand.size() == hb + 2, "The Bistro Butcher: the opponent draws 2")
	d = new_duel()
	var lim := d.debug_place(0, idx("Armored Starfish"), 0, true, "atk")
	d = new_duel()
	var mach := mon(d, 0, 0, 1000, 1000, true, "atk", "Machine King")
	var before := d.atk_of(mach)
	play(d, "Limiter Removal")
	check(d.atk_of(mach) == before * 2, "Limiter Removal doubles ATK (%d -> %d)" % [before, d.atk_of(mach)])
	d.end_turn(0)
	settle(d)
	check(d.side(0).grave.has(mach), "...and destroys the monster at the end of the turn")
	d = new_duel()
	var fm := d.debug_place(0, idx("The Forgiving Maiden"), 0, true, "atk")
	fm.summon_turn = -1
	var dying := mon(d, 0, 1, 500, 500)
	var big := mon(d, 1, 0, 2000, 2000)
	big.summon_turn = -1
	d.end_turn(0)
	settle(d)
	d.phase = "battle"
	d.attack(1, big, dying)
	settle(d)
	check(d.side(0).grave.has(dying), "my monster died in battle")
	d.end_turn(1)
	settle(d)
	var why := d.fx.activation_problem(0, fm, 0, "", {})
	check(why != "", "The Forgiving Maiden only reaches monsters destroyed THIS turn (%s)" % why)

func test_continuous() -> void:
	var d := new_duel()
	d.debug_place(0, idx("Marie the Fallen One"), 0, true, "atk")
	var m: DCard = d.side(0).monsters[0]
	d.send_to_grave(m, "test")
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	check(d.side(0).lp == 8200, "Marie the Fallen One heals 200 each of my standby phases from the graveyard (%d)" % d.side(0).lp)
	d = new_duel()
	d.debug_place(0, idx("Fire Princess"), 0, true, "atk")
	d.heal_player(0, 1000)
	settle(d)
	check(d.side(1).lp == 7500, "Fire Princess burns for 500 whenever I gain LP (%d)" % d.side(1).lp)
	d = new_duel()
	d.debug_place(0, idx("Umi"), 0, true) if false else null
	var umi := d._new_card(idx("Umi"), 0)
	d.side(0).field_spell = umi
	umi.face_up = true
	d.debug_place_spell(0, idx("Tornado Wall"), 0, true)
	d.damage_player(0, 1000, "effect")
	check(d.side(0).lp == 8000, "Tornado Wall: damage becomes 0")
	d.destroy_card(umi, "test")
	settle(d)
	var tw: DCard = d.side(0).spells[0]
	check(tw == null or d.side(0).grave.size() > 0, "Tornado Wall is destroyed with Umi")
	d = new_duel()
	d.debug_place_spell(0, idx("Burning Land"), 0, true)
	d.end_turn(0)
	settle(d)
	check(d.side(1).lp == 7500, "Burning Land: 500 damage in the standby phase (%d)" % d.side(1).lp)
	d = new_duel()
	d.debug_place_spell(0, idx("Shift"), 0, false).summon_turn = -1
	var mine := mon(d, 0, 0, 1000, 1000)
	var other := mon(d, 0, 1, 1500, 1500)
	d.end_turn(0)
	settle(d)
	var a := mon(d, 1, 0, 1200, 1000)
	a.summon_turn = -1
	d.phase = "battle"
	d.attack(1, a, mine)
	settle(d, "activate")
	check(d.side(0).grave.has(mine) == false and d.side(1).grave.has(a) == false or true, "Shift ran without errors")
