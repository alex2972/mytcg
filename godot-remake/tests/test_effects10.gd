extends SceneTree
## Card effect scenarios for data/effects/batch14.json (preset-deck cards and Card List cards that need no new interface).

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
func fire(d: Duel) -> void:
	d.end_turn(d.turn_player)
	settle(d, "use")

func in_zone(d: Duel, p: int, zone: String, c: DCard) -> bool:
	return (d.side(p).get(zone) as Array).has(c)

func _init() -> void:
	db = CardDB.load_default()
	test_all()
	print("effect tests 10: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_all() -> void:
	test_simple()
	test_flips()
	test_traps()
	test_preset_deck()

func test_simple() -> void:
	# Blue Medicine
	var d := new_duel()
	var bm := d.debug_give(0, idx("Blue Medicine"))
	d.activate_effect(0, bm, 0)
	settle(d)
	check(d.side(0).lp == 8400, "Blue Medicine: +400 LP (%d)" % d.side(0).lp)
	# Mystic Lamp
	d = new_duel()
	var lamp := place(d, 0, 0, "Mystic Lamp")
	mon(d, 1, 0, 1000, 1000)
	d.phase = "battle"
	check(d.attack(0, lamp, null) == "", "Mystic Lamp attacks directly")
	settle(d)
	check(d.side(1).lp == 8000 - d.atk_of(lamp), "...for its ATK")
	# Muka Muka
	d = new_duel()
	var mk := place(d, 0, 0, "Muka Muka")
	var base: int = d.atk_of(mk)
	for i in 3:
		d.debug_give(0, idx("Pot of Greed"))
	check(d.atk_of(mk) == base + 900 and d.def_of(mk) == int(d.card_data(mk).get("def", 0)) + 900, "Muka Muka: +300 ATK/DEF per card in hand")
	# Harpie's Pet Dragon
	d = new_duel()
	var hp := place(d, 0, 0, "Harpie's Pet Dragon")
	base = d.atk_of(hp)
	place(d, 0, 1, "Harpie Lady")
	place(d, 1, 0, "Harpie Lady")
	place(d, 1, 1, "Harpie Lady", false, "def")
	check(d.atk_of(hp) == base + 600, "Harpie's Pet Dragon: +300 per face-up Harpie Lady on either side (%d)" % (d.atk_of(hp) - base))
	# The Wicked Worm Beast
	d = new_duel()
	var worm := place(d, 0, 0, "The Wicked Worm Beast")
	next_turn(d)
	check(d.side(0).hand.has(worm), "The Wicked Worm Beast returns to the hand at the end of my turn")
	d = new_duel()
	worm = place(d, 1, 0, "The Wicked Worm Beast")
	next_turn(d)
	check(d.side(1).monsters.has(worm) and not d.side(1).hand.has(worm), "...but not at the end of the opponent's turn")
	# Mad Sword Beast
	d = new_duel()
	var msb := place(d, 0, 0, "Mad Sword Beast")
	mon(d, 1, 0, 100, 1000, true, "def")
	d.phase = "battle"
	d.attack(0, msb, d.monsters_of(1)[0])
	settle(d)
	check(d.side(1).lp == 8000 - (d.atk_of(msb) - 1000), "Mad Sword Beast pierces (LP %d)" % d.side(1).lp)
	# Fusion Sage
	d = new_duel()
	var poly := d._new_card(idx("Polymerization"), 0)
	d.side(0).deck.append(poly)
	var fs := d.debug_give(0, idx("Fusion Sage"))
	d.activate_effect(0, fs, 0)
	settle(d)
	check(d.side(0).hand.has(poly), "Fusion Sage adds Polymerization from the Deck")
	# Spirit of the Breeze / Dancing Fairy
	d = new_duel()
	var sb := place(d, 0, 0, "Spirit of the Breeze")
	var df := place(d, 0, 1, "Dancing Fairy", true, "def")
	next_turn(d)
	check(d.side(0).lp == 8000, "no Standby Phase healing on the opponent's turn")
	next_turn(d)
	check(d.side(0).lp == 9000, "Spirit of the Breeze (Attack Position) heals 1000, Dancing Fairy (Attack Position? no) stays quiet (%d)" % d.side(0).lp)
	d.force_position(sb, "def", true)
	d.force_position(df, "atk", true)
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 9000, "...and neither heals in the wrong position (%d)" % d.side(0).lp)
	d.force_position(df, "def", true)
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 10000, "Dancing Fairy (Defense Position) heals 1000 (%d)" % d.side(0).lp)
	# Mysterious Puppeteer
	d = new_duel()
	place(d, 0, 0, "Mysterious Puppeteer")
	var sm := d.debug_give(0, idx("Armored Starfish"))
	d.summon(0, sm)
	settle(d)
	check(d.side(0).lp == 8500, "Mysterious Puppeteer: +500 when I summon (%d)" % d.side(0).lp)
	next_turn(d)
	var sm2 := d.debug_give(1, idx("Armored Starfish"))
	d.summon(1, sm2)
	settle(d)
	check(d.side(0).lp == 9000, "...and when the opponent summons (%d)" % d.side(0).lp)
	# Messenger of Peace
	d = new_duel()
	var mop := d.debug_place_spell(0, idx("Messenger of Peace"), 0, true)
	mop.summon_turn = -1
	var big := mon(d, 0, 0, 1500)
	var small := mon(d, 0, 1, 1400)
	d.phase = "battle"
	check(d.can_attack(0, big) != "" and d.can_attack(0, small) == "", "Messenger of Peace: monsters with 1500+ ATK cannot attack")
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 7900, "...and costs 100 LP each of my Standby Phases (%d)" % d.side(0).lp)
	d.set_lp(0, 100)
	next_turn(d)
	next_turn(d)
	check(not d.side(0).spells.has(mop), "...and is destroyed when I cannot pay")

func test_flips() -> void:
	# Bite Shoes
	var d := new_duel()
	var bs := d.debug_place(0, idx("Bite Shoes"), 0, false, "def")
	var foe := mon(d, 1, 0, 1000, 1000)
	d.change_position(0, bs)
	if not d.fx.pending.is_empty():
		d.respond([foe.uid])
	settle(d)
	check(foe.pos == "def" and foe.face_up, "Bite Shoes: the chosen monster changes position and stays face-up")
	# Amazon Archer / Hysteric Fairy
	d = new_duel()
	var aa := place(d, 0, 0, "Amazon Archer")
	check(d.activate_effect(0, aa, 0) != "", "Amazon Archer needs 2 other monsters to offer")
	mon(d, 0, 1, 1000)
	mon(d, 0, 2, 1000)
	d.activate_effect(0, aa, 0)
	settle(d)
	check(d.side(1).lp == 6800 and d.side(0).grave.size() == 2 and d.side(0).monsters.has(aa), "Amazon Archer: offer 2 monsters for 1200 damage (%d)" % d.side(1).lp)
	d = new_duel()
	var hf := place(d, 0, 0, "Hysteric Fairy")
	mon(d, 0, 1, 1000)
	mon(d, 0, 2, 1000)
	d.activate_effect(0, hf, 0)
	settle(d)
	check(d.side(0).lp == 9000 and d.side(0).grave.size() == 2, "Hysteric Fairy: offer 2 monsters for +1000 LP (%d)" % d.side(0).lp)
	# Fire Sorcerer
	d = new_duel()
	var fsorc := d.debug_place(0, idx("Fire Sorcerer"), 0, false, "def")
	for i in 3:
		d.debug_give(0, idx("Pot of Greed"))
	d.change_position(0, fsorc)
	settle(d)
	check(d.side(0).hand.size() == 1 and d.side(0).banished.size() == 2 and d.side(1).lp == 7200, "Fire Sorcerer: 2 random hand cards removed, 800 damage")
	d = new_duel()
	fsorc = d.debug_place(0, idx("Fire Sorcerer"), 0, false, "def")
	d.debug_give(0, idx("Pot of Greed"))
	d.change_position(0, fsorc)
	settle(d)
	check(d.side(1).lp == 8000 and d.side(0).hand.size() == 1, "...nothing happens with fewer than 2 cards in hand")
	# Lady Assailant of Flames
	d = new_duel()
	var lady := d.debug_place(0, idx("Lady Assailant of Flames"), 0, false, "def")
	var deck_n: int = d.side(0).deck.size()
	d.change_position(0, lady)
	settle(d)
	check(d.side(0).deck.size() == deck_n - 3 and d.side(0).banished.size() == 3 and d.side(1).lp == 7200, "Lady Assailant of Flames: top 3 cards removed, 800 damage")
	# Greenkappa
	d = new_duel()
	var gk := d.debug_place(0, idx("Greenkappa"), 0, false, "def")
	var t1 := trap(d, 1, 0, "Mirror Force")
	var t2 := trap(d, 1, 1, "Trap Hole")
	d.change_position(0, gk)
	settle(d)
	check(d.side(1).grave.has(t1) and d.side(1).grave.has(t2), "Greenkappa destroys 2 face-down Spell/Trap Cards")
	# The Immortal of Thunder
	d = new_duel()
	var it := d.debug_place(0, idx("The Immortal of Thunder"), 0, false, "def")
	d.change_position(0, it)
	settle(d)
	check(d.side(0).lp == 11000, "The Immortal of Thunder: +3000 LP on Flip")
	d.destroy_card(it, "effect")
	settle(d)
	check(d.side(0).lp == 6000, "...and -5000 LP when it leaves the field (%d)" % d.side(0).lp)
	# Supply
	d = new_duel()
	var m1 := d._new_card(idx("Armored Starfish"), 0)
	var m2 := d._new_card(idx("Armored Starfish"), 0)
	var m3 := d._new_card(idx("Armored Starfish"), 0)
	d.side(0).hand.append_array([m1, m2, m3])
	d.send_to_grave(m1, "fusion_material")
	d.send_to_grave(m2, "fusion_material")
	d.send_to_grave(m3, "discard")
	var sup := d.debug_place(0, idx("Supply"), 0, false, "def")
	d.change_position(0, sup)
	settle(d)
	check(d.side(0).hand.has(m1) and d.side(0).hand.has(m2) and d.side(0).grave.has(m3), "Supply returns only Fusion-Material monsters from a Fusion Summon")

func test_traps() -> void:
	# Solomon's Lawbook
	var d := new_duel()
	var sl := trap(d, 0, 0, "Solomon's Lawbook")
	fire(d)
	check(d.skip_draw[0], "Solomon's Lawbook: skips my next draw")
	# Type Zero Magic Crusher
	d = new_duel()
	var tz := trap(d, 0, 0, "Type Zero Magic Crusher")
	d.debug_give(0, idx("Pot of Greed"))
	d.debug_give(0, idx("Dark Hole"))
	d.debug_give(0, idx("Armored Starfish"))
	fire(d)
	check(d.side(1).lp == 7000 and d.side(0).hand.size() == 1, "Type Zero Magic Crusher: 500 per discarded Spell (LP %d)" % d.side(1).lp)
	# Riryoku
	d = new_duel()
	var a := mon(d, 0, 0, 2000)
	var b := mon(d, 0, 1, 1000)
	var rk := d.debug_give(0, idx("Riryoku"))
	d.activate_effect(0, rk, 0)
	settle(d)
	check(d.atk_of(a) == 1000 and d.atk_of(b) == 2000, "Riryoku: half of one monster's ATK moves to another (%d / %d)" % [d.atk_of(a), d.atk_of(b)])
	# Destruction Punch
	d = new_duel()
	var dp := trap(d, 0, 0, "Destruction Punch")
	var wall := mon(d, 0, 0, 100, 2000, true, "def")
	next_turn(d)
	var att := mon(d, 1, 0, 1000, 1000)
	d.phase = "battle"
	d.attack(1, att, wall)
	settle(d, "use")
	check(d.side(1).grave.has(att) and d.side(0).lp == 8000, "Destruction Punch destroys a weaker attacker")
	check(d.side(0).grave.has(dp), "...and goes to the Graveyard")
	# Dimensional Warrior
	d = new_duel()
	var dw := place(d, 0, 0, "Dimensional Warrior")
	var victim := mon(d, 1, 0, 3000, 3000)
	d.phase = "battle"
	d.attack(0, dw, victim)
	settle(d)
	check(d.side(0).banished.has(dw) and d.side(1).banished.has(victim) and d.side(0).lp == 8000, "Dimensional Warrior: both monsters are removed from play when it attacks")
	d = new_duel()
	dw = place(d, 0, 0, "Dimensional Warrior", true, "def")
	next_turn(d)
	var hitter := mon(d, 1, 0, 3000, 3000)
	d.phase = "battle"
	d.attack(1, hitter, dw)
	settle(d)
	check(d.side(0).banished.has(dw) and d.side(1).banished.has(hitter), "...and when it is attacked")
	# Nobleman of Extermination
	d = new_duel()
	var set_trap := trap(d, 1, 0, "Mirror Force")
	var deck_copy_a := d._new_card(idx("Mirror Force"), 0)
	var deck_copy_b := d._new_card(idx("Mirror Force"), 1)
	d.side(0).deck.append(deck_copy_a)
	d.side(1).deck.append(deck_copy_b)
	var ne := d.debug_give(0, idx("Nobleman of Extermination"))
	d.activate_effect(0, ne, 0)
	settle(d)
	check(d.side(1).banished.has(set_trap) and d.side(0).banished.has(deck_copy_a) and d.side(1).banished.has(deck_copy_b), "Nobleman of Extermination removes the Trap and every copy from both Decks")
	# Gryphon Wing
	d = new_duel()
	var gw := trap(d, 0, 0, "Gryphon Wing")
	var mine := trap(d, 0, 1, "Mirror Force")
	next_turn(d)
	var theirs := trap(d, 1, 0, "Trap Hole")
	var duster := d.debug_give(1, idx("Harpie's Feather Duster"))
	d.activate_effect(1, duster, 0)
	settle(d, "use")
	check(d.side(1).grave.has(theirs) and not d.side(0).grave.has(mine) and d.side(0).spells.has(mine), "Gryphon Wing: the Duster destroys the opponent's own Spell/Trap Cards instead")
	check(d.side(0).grave.has(gw), "...and Gryphon Wing goes to the Graveyard")

func test_preset_deck() -> void:
	# Chosen One
	var seen_summon := false
	var seen_grave := false
	for sd in 12:
		var d := new_duel(sd + 1)
		var co := d.debug_give(0, idx("Chosen One"))
		var m := d.debug_give(0, idx("Armored Starfish"))
		var s1 := d.debug_give(0, idx("Pot of Greed"))
		var s2 := d.debug_give(0, idx("Dark Hole"))
		d.activate_effect(0, co, 0)
		settle(d)
		var summoned: bool = d.side(0).monsters.has(m)
		var all_grave: bool = d.side(0).grave.has(s1) and d.side(0).grave.has(s2) and d.side(0).grave.has(co)
		if summoned:
			seen_summon = true
			check(all_grave and not d.side(0).grave.has(m), "Chosen One (hit): the monster is Special Summoned, the other 2 cards go to the Graveyard")
		else:
			seen_grave = true
			check(all_grave and d.side(0).grave.has(m), "Chosen One (miss): all 3 cards go to the Graveyard")
	check(seen_summon and seen_grave, "Chosen One: the opponent's random pick can hit or miss")
	# Return of the Doomed
	var d2 := new_duel()
	var rd := d2.debug_give(0, idx("Return of the Doomed"))
	var disc := d2.debug_give(0, idx("Armored Starfish"))
	var fighter := mon(d2, 0, 0, 500)
	mon(d2, 1, 0, 3000)
	d2.activate_effect(0, rd, 0)
	settle(d2)
	check(d2.side(0).grave.has(disc), "Return of the Doomed: discards a monster as the cost")
	d2.phase = "battle"
	d2.attack(0, fighter, d2.monsters_of(1)[0])
	settle(d2)
	check(d2.side(0).grave.has(fighter), "...my monster dies in battle")
	next_turn(d2)
	check(d2.side(0).hand.has(fighter), "...and returns to my hand at the end of the turn")
	# Gilasaurus
	var d3 := new_duel()
	var dead := d3._new_card(idx("Mystic Lamp"), 1)
	d3.side(1).grave.append(dead)
	var gila := d3.debug_give(0, idx("Gilasaurus"))
	d3.summon(0, gila)
	settle(d3)
	check(d3.side(1).monsters.has(dead) and bool(gila.flags.get("special_summoned", false)), "Gilasaurus: treated as a Special Summon, the opponent revives a monster")
	# Sword Hunter
	var d4 := new_duel()
	var sh := place(d4, 0, 0, "Sword Hunter")
	var prey := mon(d4, 1, 0, 1000)
	var base: int = d4.atk_of(sh)
	d4.phase = "battle"
	d4.attack(0, sh, prey)
	settle(d4)
	check(d4.side(0).spells.has(prey) and prey.equipped_to == sh, "Sword Hunter: the destroyed monster becomes its Equip Card")
	check(d4.atk_of(sh) == base + 200, "...and raises its ATK by 200")
	d4.destroy_card(sh, "effect")
	settle(d4)
	check(d4.side(0).grave.has(sh) and d4.side(1).grave.has(prey), "...and leaves the field with Sword Hunter")
	# Kotodama
	var d5 := new_duel()
	var k1 := place(d5, 0, 0, "Kotodama")
	next_turn(d5)
	var k2 := d5.debug_give(1, idx("Kotodama"))
	d5.summon(1, k2)
	settle(d5)
	check(d5.side(1).grave.has(k2) and d5.side(0).monsters.has(k1), "Kotodama: a later copy is destroyed, the first one stays")
	var d6 := new_duel()
	var k3 := place(d6, 0, 0, "Kotodama")
	var k4 := d6.debug_place(1, idx("Kotodama"), 0, false, "def")
	next_turn(d6)
	d6.change_position(1, k4)
	settle(d6)
	check(d6.side(0).monsters.has(k3) and d6.side(1).grave.has(k4), "...also when a face-down copy is flipped")
	# Big Shield Gardna
	var d7 := new_duel()
	var bsg := place(d7, 0, 0, "Big Shield Gardna", true, "def")
	next_turn(d7)
	var raider := mon(d7, 1, 0, 100, 100)
	d7.phase = "battle"
	d7.attack(1, raider, bsg)
	settle(d7)
	check(bsg.pos == "def", "Big Shield Gardna stays in Defense Position during the attack")
	d7.to_main2(1)
	check(bsg.pos == "atk" and bsg.face_up, "...and shifts to Attack Position after the battle")
	# Respect Play
	var d8 := new_duel()
	var rp := trap(d8, 0, 0, "Respect Play")
	fire(d8)
	check(d8.side(0).spells.has(rp) and rp.face_up, "Respect Play: activates and stays face-up on the field")
