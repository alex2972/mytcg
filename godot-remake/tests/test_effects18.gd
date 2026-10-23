extends SceneTree
## Cards of data/effects/batch23.json (Legacy of Darkness) and the engine hooks they need, plus CPU duels with those cards.

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

## Answer every pending decision: selections take the next entry of `picks` that fits (else the first candidates),
## yes/no is yes, choices take 0, chain prompts pass or ("use") take the first option.
func settle(d: Duel, chain_choice := "pass", picks: Array = []) -> void:
	var guard := 0
	var queue := picks.duplicate()
	while not d.fx.pending.is_empty() and guard < 80:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"select":
				var want: Array = []
				if not queue.is_empty():
					want = (queue.pop_front() as Array).filter(func(u): return (p["candidates"] as Array).has(u))
				if want.is_empty():
					want = (p["candidates"] as Array).slice(0, p["max"])
				d.respond(want)
			"yesno": d.respond(true)
			"choice": d.respond(0)
			"presentation": d.respond(true)
			"chain":
				if chain_choice == "pass":
					d.respond("pass")
				else:
					var o: Dictionary = p["options"][0]
					d.respond({"uid": o["uid"], "idx": o["idx"]})
			_:
				return

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

func face_up_spell(d: Duel, p: int, zone: int, name: String) -> DCard:
	var c := d.debug_place_spell(p, idx(name), zone, true)
	c.summon_turn = -1
	return c

func in_grave(d: Duel, c: DCard) -> DCard:
	d.side(c.owner).grave.append(c)
	return c

## A monster of the original pool with this Attribute and Level.
func find_monster(attr: int, level: int) -> int:
	for i in range(1, db.cards.size()):
		var c: Dictionary = db.card(i)
		if c.get("type", "") == "monster" and int(c.get("attribute", 0)) == attr and int(c.get("level", 0)) == level and int(c.get("category", 0)) == 0:
			return i
	return 0

func _initialize() -> void:
	db = CardDB.load_default()
	test_battle()
	test_fiends()
	test_warriors()
	test_dragons()
	test_other_monsters()
	test_spells()
	test_traps()
	test_cpu_duels()
	print("effect tests 18 (Legacy of Darkness): ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func test_battle() -> void:
	# Airknight Parshath: piercing, and a draw when it inflicts battle damage
	var d := new_duel()
	var ak := place(d, 0, 0, "Airknight Parshath")
	var wall := mon(d, 1, 0, 0, 1000, true, "def")
	var hand_n: int = d.side(0).hand.size()
	d.to_battle(0)
	d.attack(0, ak, wall)
	settle(d)
	check(d.side(1).lp == 7100, "Airknight Parshath: piercing battle damage (LP %d)" % d.side(1).lp)
	check(d.side(0).hand.size() == hand_n + 1, "...and it draws 1 card")
	# Spear Dragon: piercing, then Defense Position
	d = new_duel()
	var sp := place(d, 0, 0, "Spear Dragon")
	wall = mon(d, 1, 0, 0, 1000, true, "def")
	d.to_battle(0)
	d.attack(0, sp, wall)
	settle(d)
	check(d.side(1).lp == 7100 and sp.pos == "def", "Spear Dragon: piercing damage, then Defense Position (LP %d, %s)" % [d.side(1).lp, sp.pos])
	# Dragon's Rage: Dragons I control pierce
	d = new_duel()
	face_up_spell(d, 0, 0, "Dragon's Rage")
	var ld := place(d, 0, 0, "Luster Dragon #2")
	var other := mon(d, 0, 1, 2400)
	wall = mon(d, 1, 0, 0, 1000, true, "def")
	var wall2 := mon(d, 1, 1, 0, 1000, true, "def")
	d.to_battle(0)
	d.attack(0, ld, wall)
	settle(d)
	check(d.side(1).lp == 6600, "Dragon's Rage: a Dragon inflicts piercing damage (LP %d)" % d.side(1).lp)
	d.attack(0, other, wall2)
	settle(d)
	check(d.side(1).lp == 6600, "...other monsters do not")
	# Susa Soldier: halved battle damage, back to the hand at the End Phase, cannot be Special Summoned
	d = new_duel()
	var susa := d.debug_give(0, idx("Susa Soldier"))
	d.summon(0, susa)
	settle(d)
	d.to_battle(0)
	d.attack(0, susa, null)
	settle(d)
	check(d.side(1).lp == 7000, "Susa Soldier: the battle damage it inflicts is halved (LP %d)" % d.side(1).lp)
	d.to_main2(0)
	d.end_turn(0)
	settle(d)
	check(d.side(0).hand.has(susa), "...it returns to the hand at the End Phase of its Summon turn")
	var susa2 := in_grave(d, d._new_card(idx("Susa Soldier"), 0))
	check(d.special_summon_problem(susa2, 0, true) != "", "...and it cannot be Special Summoned")
	# Heart of Clear Water: not destroyed by battle nor by targeting effects; destroyed at 1300 ATK
	d = new_duel()
	var host := mon(d, 0, 0, 1000)
	var heart := d.debug_give(0, idx("Heart of Clear Water"))
	d.activate_effect(0, heart, 0)
	settle(d)
	check(heart.equipped_to == host, "Heart of Clear Water equips")
	next_turn(d)
	var big := mon(d, 1, 0, 2000)
	d.to_battle(1)
	d.attack(1, big, host)
	settle(d)
	check(d.side(0).monsters.has(host) and d.side(0).lp == 7000, "...the monster is not destroyed by battle, damage still applies (LP %d)" % d.side(0).lp)
	d.to_main2(1)
	var exf := place(d, 1, 1, "Exiled Force")
	d.activate_effect(1, exf, 0)
	settle(d, "pass", [[host.uid]])
	check(d.side(0).monsters.has(host), "...nor by an effect that targets it")
	host.atk_bonus += 300
	d.fx.pump()
	check(d.side(0).grave.has(heart), "...and the Heart is destroyed when the ATK reaches 1300")

func test_fiends() -> void:
	# Lesser Fiend: its battle victims are removed from play, also in a tie
	var d := new_duel()
	var lf := place(d, 0, 0, "Lesser Fiend")
	var v := mon(d, 1, 0, 1000)
	d.to_battle(0)
	d.attack(0, lf, v)
	settle(d)
	check(d.side(1).banished.has(v) and not d.side(1).grave.has(v), "Lesser Fiend: the monster it destroys is removed from play")
	d = new_duel()
	lf = place(d, 0, 0, "Lesser Fiend")
	v = mon(d, 1, 0, 2100)
	d.to_battle(0)
	d.attack(0, lf, v)
	settle(d)
	check(d.side(1).banished.has(v) and d.side(0).grave.has(lf), "...also when both are destroyed")
	# Dark Ruler Ha Des: effects of monsters destroyed by my Fiends are negated; no revival from the Graveyard
	d = new_duel()
	var hd := place(d, 0, 0, "Dark Ruler Ha Des")
	var sangan := place(d, 1, 0, "Sangan")
	var h1: int = d.side(1).hand.size()
	d.to_battle(0)
	d.attack(0, hd, sangan)
	settle(d)
	check(d.side(1).grave.has(sangan) and d.side(1).hand.size() == h1, "Dark Ruler Ha Des: Sangan's effect is negated (hand %d)" % d.side(1).hand.size())
	d = new_duel()
	place(d, 0, 0, "Dark Ruler Ha Des")
	var lf2 := place(d, 0, 1, "Lesser Fiend")
	var sangan2 := place(d, 1, 0, "Sangan")
	h1 = d.side(1).hand.size()
	d.to_battle(0)
	d.attack(0, lf2, sangan2)
	settle(d)
	check(d.side(1).hand.size() == h1, "...also when another Fiend destroys it")
	d = new_duel()
	var plain := mon(d, 0, 0, 2450)
	var sangan3 := place(d, 1, 0, "Sangan")
	h1 = d.side(1).hand.size()
	d.to_battle(0)
	d.attack(0, plain, sangan3)
	settle(d)
	check(d.side(1).hand.size() == h1 + 1, "(control: Sangan searches when Ha Des is absent)")
	var hd2 := in_grave(d, d._new_card(idx("Dark Ruler Ha Des"), 0))
	check(d.special_summon_problem(hd2, 0, true) != "", "Dark Ruler Ha Des cannot be Special Summoned from the Graveyard")
	# Twin-Headed Wolf: with another Fiend, Flip monsters it destroys lose their effects
	d = new_duel()
	var wolf := place(d, 0, 0, "Twin-Headed Wolf")
	place(d, 0, 1, "Lesser Fiend")
	var bug := d.debug_place(1, idx("Man-Eater Bug"), 0, false, "def")
	d.to_battle(0)
	d.attack(0, wolf, bug)
	settle(d)
	check(d.side(0).monsters.has(wolf) and d.side(1).grave.has(bug), "Twin-Headed Wolf: the Flip effect of the monster it destroys is negated")
	d = new_duel()
	wolf = place(d, 0, 0, "Twin-Headed Wolf")
	bug = d.debug_place(1, idx("Man-Eater Bug"), 0, false, "def")
	d.to_battle(0)
	d.attack(0, wolf, bug)
	settle(d)
	check(d.side(0).grave.has(wolf), "...but not without another Fiend (Man-Eater Bug destroys it)")
	# Dark Balter the Terrible
	d = new_duel()
	place(d, 0, 0, "Dark Balter the Terrible")
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Hinotama")), 0)
	settle(d, "use")
	check(d.side(0).lp == 7000, "Dark Balter the Terrible: pays 1000 to negate a Normal Spell (LP %d)" % d.side(0).lp)
	d = new_duel()
	var balter := place(d, 0, 0, "Dark Balter the Terrible")
	var sangan4 := place(d, 1, 0, "Sangan")
	h1 = d.side(1).hand.size()
	d.to_battle(0)
	d.attack(0, balter, sangan4)
	settle(d)
	check(d.side(1).hand.size() == h1, "...negates the effect of an Effect Monster it destroys")
	d = new_duel()
	var bx := d._new_card(idx("Dark Balter the Terrible"), 0)
	d.side(0).extra.append(bx)
	d.debug_give(0, idx("Possessed Dark Soul"))
	d.debug_give(0, idx("Goddess with the Third Eye"))
	check(not d.fx.ops.fusion_candidates(0).has(bx), "...cannot be Fusion Summoned with a Fusion Substitute")
	d.debug_give(0, idx("Frontier Wiseman"))
	check(d.fx.ops.fusion_candidates(0).has(bx), "...but can with its own materials")
	# Possessed Dark Soul
	d = new_duel()
	var pds := place(d, 0, 0, "Possessed Dark Soul")
	var small := place(d, 1, 0, "Skull Knight #2")
	var tall := place(d, 1, 1, "Exiled Force")
	d.activate_effect(0, pds, 0)
	settle(d)
	check(small.controller == 0 and tall.controller == 1 and d.side(0).grave.has(pds), "Possessed Dark Soul takes the Level 3 or lower monsters")
	# Skull Knight #2
	d = new_duel()
	var sk := place(d, 0, 0, "Skull Knight #2")
	var sk_deck := d._new_card(idx("Skull Knight #2"), 0)
	d.side(0).deck.append(sk_deck)
	var lf3 := d.debug_give(0, idx("Lesser Fiend"))
	d.summon(0, lf3, [sk])
	settle(d)
	check(d.side(0).monsters.has(sk_deck), "Skull Knight #2: Tributed for a Fiend, it Special Summons another copy from the Deck")
	d = new_duel()
	sk = place(d, 0, 0, "Skull Knight #2")
	sk_deck = d._new_card(idx("Skull Knight #2"), 0)
	d.side(0).deck.append(sk_deck)
	d.summon(0, d.debug_give(0, idx("Luster Dragon #2")), [sk])
	settle(d)
	check(not d.side(0).monsters.has(sk_deck), "...not when the Tribute Summoned monster is not a Fiend")
	# Ryu-Kishin Clown
	d = new_duel()
	var foe := mon(d, 1, 0, 1000)
	d.summon(0, d.debug_give(0, idx("Ryu-Kishin Clown")))
	settle(d, "pass", [[foe.uid]])
	check(foe.pos == "def", "Ryu-Kishin Clown changes the battle position of a face-up monster")
	# Bark of Dark Ruler
	d = new_duel()
	var lfb := place(d, 0, 0, "Lesser Fiend")
	trap(d, 0, 0, "Bark of Dark Ruler")
	var big2 := mon(d, 1, 0, 2500)
	d.to_battle(0)
	d.attack(0, lfb, big2)
	settle(d, "use")
	check(d.side(0).lp == 7500 and d.side(1).banished.has(big2) and d.side(1).lp == 7900,
		"Bark of Dark Ruler: pays just enough to win the battle (LP %d / %d)" % [d.side(0).lp, d.side(1).lp])
	# Fatal Abacus
	d = new_duel()
	face_up_spell(d, 0, 0, "Fatal Abacus")
	var x1 := mon(d, 1, 0, 1000)
	d.effect_player = 0
	d.destroy_card(x1, "effect")
	d.effect_player = -1
	settle(d)
	var x2 := mon(d, 0, 0, 1000)
	d.destroy_card(x2, "effect")
	settle(d)
	check(d.side(1).lp == 7500 and d.side(0).lp == 7500, "Fatal Abacus: 500 damage to the owner of each monster sent from the field (LP %d / %d)" % [d.side(0).lp, d.side(1).lp])
	# Life Absorbing Machine
	d = new_duel()
	face_up_spell(d, 0, 0, "Life Absorbing Machine")
	d.pay_lp(0, 1000)
	next_turn(d)
	next_turn(d)
	check(d.side(0).lp == 7500, "Life Absorbing Machine: half the LP paid during my last turn (LP %d)" % d.side(0).lp)
	# The Puppet Magic of Dark Ruler
	d = new_duel()
	var g1 := in_grave(d, d._new_card(idx("Lesser Fiend"), 0))
	in_grave(d, d._new_card(idx("Dark Ruler Ha Des"), 0))
	var m3 := place(d, 0, 0, "Skull Knight #2")
	var m2 := place(d, 0, 1, "Ryu-Kishin Clown")
	check(FxCustom.puppet_candidates(d, 0) == [g1], "The Puppet Magic of Dark Ruler: only Fiends whose Level matches (and that may be revived)")
	d.activate_effect(0, d.debug_give(0, idx("The Puppet Magic of Dark Ruler")), 0)
	settle(d)
	check(d.side(0).monsters.has(g1) and d.side(0).banished.has(m3) and d.side(0).banished.has(m2), "...removes Levels 3 + 2 and revives the Level 5 Fiend")
	# Soul Demolition
	d = new_duel()
	var sd := face_up_spell(d, 0, 0, "Soul Demolition")
	place(d, 0, 0, "Lesser Fiend")
	var og := in_grave(d, d._new_card(idx("Sangan"), 1))
	var mg := in_grave(d, d._new_card(idx("Sangan"), 0))
	check(d.activate_effect(0, sd, 1) == "", "Soul Demolition can be used with a Fiend on the field")
	settle(d)
	check(d.side(0).lp == 7500 and d.side(1).banished.has(og) and d.side(0).banished.has(mg), "...both players remove a monster from the other's Graveyard")

func test_warriors() -> void:
	# Freed the Matchless General: Spells that target it are negated; the draw may become a search
	var d := new_duel()
	var freed := place(d, 0, 0, "Freed the Matchless General")
	var axe := d.debug_give(0, idx("Axe of Despair"))
	d.activate_effect(0, axe, 0)
	settle(d)
	check(d.atk_of(freed) == 2300 and d.side(0).grave.has(axe), "Freed: a Spell that targets it is negated and destroyed (ATK %d)" % d.atk_of(freed))
	var warrior := d._new_card(idx("Exiled Force"), 0)
	d.side(0).deck.push_front(warrior)
	var deck_n: int = d.side(0).deck.size()
	next_turn(d)
	next_turn(d)
	check(d.side(0).hand.has(warrior) and d.side(0).deck.size() == deck_n - 1, "...and it adds a Level 4 Warrior from the Deck instead of drawing")
	# Throwstone Unit
	d = new_duel()
	var tu := place(d, 0, 0, "Throwstone Unit")
	var tw := place(d, 0, 1, "Exiled Force")
	var lo := mon(d, 1, 0, 0, 800, true, "def")
	var hi := mon(d, 1, 1, 0, 1500, true, "def")
	d.activate_effect(0, tu, 0)
	settle(d, "pass", [[tw.uid], [lo.uid]])
	check(d.side(1).grave.has(lo) and d.side(1).monsters.has(hi) and d.side(0).grave.has(tw), "Throwstone Unit destroys a monster whose DEF is at most its ATK")
	# Marauding Captain
	d = new_duel()
	var cap := place(d, 1, 0, "Marauding Captain")
	var ef := place(d, 1, 1, "Exiled Force")
	var att := mon(d, 0, 0, 3000)
	d.to_battle(0)
	check(d.attack(0, att, ef) != "", "Marauding Captain: other Warriors cannot be attacked")
	check(d.attack(0, att, cap) == "", "...the Captain itself can")
	settle(d)
	d = new_duel()
	var extra := d.debug_give(0, idx("Exiled Force"))
	d.summon(0, d.debug_give(0, idx("Marauding Captain")))
	settle(d, "use")
	check(d.side(0).monsters.has(extra), "...its Summon lets me Special Summon a Level 4 or lower monster from the hand")
	# Ryu Senshi
	d = new_duel()
	place(d, 0, 0, "Ryu Senshi")
	trap(d, 1, 0, "Trap Hole")
	var ns := d.debug_give(0, idx("Wolf Axwielder"))
	d.summon(0, ns)
	settle(d, "use")
	check(d.side(0).monsters.has(ns) and d.side(0).lp == 7000, "Ryu Senshi pays 1000 to negate a Normal Trap (LP %d)" % d.side(0).lp)
	# Mysterious Guard
	d = new_duel()
	var guard := d.debug_place(0, idx("Mysterious Guard"), 0, false, "def")
	place(d, 0, 1, "Exiled Force")
	var a1 := mon(d, 1, 0, 1000)
	var b1 := mon(d, 1, 1, 1200)
	d.change_position(0, guard)
	settle(d, "pass", [[a1.uid], [b1.uid]])
	check(d.side(1).deck.back() == a1 and d.side(1).hand.has(b1), "Mysterious Guard: one monster to the top of the Deck, another to the hand")
	# Frontier Wiseman
	d = new_duel()
	place(d, 0, 0, "Frontier Wiseman")
	var war := place(d, 0, 1, "Exiled Force")
	next_turn(d)
	var coh := d.debug_give(1, idx("Change of Heart"))
	d.activate_effect(1, coh, 0)
	settle(d, "pass", [[war.uid]])
	check(war.controller == 0 and d.side(1).grave.has(coh), "Frontier Wiseman negates a Spell that targets my Warrior")
	# Exiled Force
	d = new_duel()
	var exf := place(d, 0, 0, "Exiled Force")
	var vic := mon(d, 1, 0, 2500)
	d.activate_effect(0, exf, 0)
	settle(d)
	check(d.side(0).grave.has(exf) and d.side(1).grave.has(vic), "Exiled Force: Tribute it to destroy a monster")
	# The Hunter with 7 Weapons
	d = new_duel()
	var hunter := d.debug_give(0, idx("The Hunter with 7 Weapons"))
	d.summon(0, hunter)
	settle(d)
	check(int(hunter.flags.get("chosen_race", -1)) == 1 and d.atk_of(hunter) == 1000, "The Hunter with 7 Weapons declares a Type (Dragon)")
	var drg := mon(d, 1, 0, 1800, 1000, true, "atk", "Luster Dragon #2")
	d.to_battle(0)
	d.attack(0, hunter, drg)
	settle(d)
	check(d.side(1).grave.has(drg) and d.side(1).lp == 7800, "...and has 2000 ATK in battle against that Type (LP %d)" % d.side(1).lp)
	# Shadow Tamer / Dragon Manipulator
	for pair in [["Shadow Tamer", "Lesser Fiend"], ["Dragon Manipulator", "Luster Dragon #2"]]:
		d = new_duel()
		var tamer := d.debug_place(0, idx(pair[0]), 0, false, "def")
		var prey := place(d, 1, 0, pair[1])
		d.change_position(0, tamer)
		settle(d)
		check(prey.controller == 0, "%s takes control of a %s" % pair)
		next_turn(d)
		check(prey.controller == 1, "...until the End Phase")
	# The A. Forces
	d = new_duel()
	face_up_spell(d, 0, 0, "The A. Forces")
	var w1 := place(d, 0, 0, "Exiled Force")
	place(d, 0, 1, "Throwstone Unit")
	var wise := place(d, 0, 2, "Frontier Wiseman")
	check(d.atk_of(w1) == 1600 and d.atk_of(wise) == 1600, "The A. Forces: Warriors +200 per Warrior/Spellcaster (%d, %d)" % [d.atk_of(w1), d.atk_of(wise)])
	# The Warrior Returning Alive
	d = new_duel()
	var gw := in_grave(d, d._new_card(idx("Exiled Force"), 0))
	d.activate_effect(0, d.debug_give(0, idx("The Warrior Returning Alive")), 0)
	settle(d)
	check(d.side(0).hand.has(gw), "The Warrior Returning Alive adds a Warrior from the Graveyard")
	# Fusion Sword Murasame Blade
	d = new_duel()
	var wh := place(d, 0, 0, "Exiled Force")
	var blade := d.debug_give(0, idx("Fusion Sword Murasame Blade"))
	d.activate_effect(0, blade, 0)
	settle(d)
	check(d.atk_of(wh) == 1800, "Fusion Sword Murasame Blade: +800 ATK")
	d.effect_player = 1
	d.destroy_card(blade, "effect")
	d.effect_player = -1
	check(d.is_on_field(blade), "...and it is not destroyed by card effects while equipped")

func test_dragons() -> void:
	# Tyrant Dragon
	var d := new_duel()
	var ty := place(d, 0, 0, "Tyrant Dragon")
	var t1 := mon(d, 1, 0, 1000)
	var t2 := mon(d, 1, 1, 1000)
	d.to_battle(0)
	d.attack(0, ty, t1)
	settle(d)
	check(d.can_attack(0, ty) == "", "Tyrant Dragon: a second attack while the opponent has a monster")
	d.attack(0, ty, t2)
	settle(d)
	check(d.can_attack(0, ty) != "", "...but not a third")
	d = new_duel()
	ty = place(d, 0, 0, "Tyrant Dragon")
	var ring := trap(d, 1, 0, "Ring of Destruction")
	d.end_turn(0)
	settle(d, "use")
	check(d.side(0).monsters.has(ty) and d.side(1).grave.has(ring) and d.side(0).lp == 8000, "...a Trap that targets it is negated and destroyed")
	d = new_duel()
	var tyg := in_grave(d, d._new_card(idx("Tyrant Dragon"), 0))
	check(d.special_summon(tyg, 0) != "", "...it cannot be revived without a Dragon to Tribute")
	var drag := place(d, 0, 0, "Luster Dragon #2")
	check(d.special_summon(tyg, 0) == "" and d.side(0).grave.has(drag), "...and with one, the Dragon is Tributed")
	# Spirit Ryu
	d = new_duel()
	var sr := place(d, 0, 0, "Spirit Ryu")
	var dh := d.debug_give(0, idx("Luster Dragon #2"))
	var foe2 := mon(d, 1, 0, 1500)
	d.to_battle(0)
	d.attack(0, sr, foe2)
	settle(d, "use")
	check(d.side(0).grave.has(dh) and d.side(1).grave.has(foe2), "Spirit Ryu discards a Dragon for +1000 ATK in battle")
	# Fiend Skull Dragon: Flip Effects are negated
	d = new_duel()
	var fsd := place(d, 0, 0, "Fiend Skull Dragon")
	var bug := d.debug_place(1, idx("Man-Eater Bug"), 0, false, "def")
	next_turn(d)
	d.change_position(1, bug)
	settle(d)
	check(d.side(0).monsters.has(fsd), "Fiend Skull Dragon negates Flip Effects")
	# Cave Dragon
	d = new_duel()
	var cave := d.debug_give(0, idx("Cave Dragon"))
	check(d.summon_problem(0, cave) == "", "Cave Dragon can be summoned on an empty field")
	mon(d, 0, 0, 1000)
	check(d.summon_problem(0, cave) != "" and d.summon(0, cave) != "", "...not while I control a monster")
	d = new_duel()
	var cv := place(d, 0, 0, "Cave Dragon")
	d.to_battle(0)
	check(d.can_attack(0, cv) != "", "...it cannot attack without another Dragon")
	place(d, 0, 1, "Luster Dragon #2")
	check(d.can_attack(0, cv) == "", "...and can with one")
	# Troop Dragon
	d = new_duel()
	var td := place(d, 0, 0, "Troop Dragon")
	var td2 := d._new_card(idx("Troop Dragon"), 0)
	d.side(0).deck.append(td2)
	var killer := mon(d, 1, 0, 2000)
	next_turn(d)
	d.to_battle(1)
	d.attack(1, killer, td)
	settle(d)
	check(d.side(0).monsters.has(td2), "Troop Dragon: destroyed in battle, it calls another Troop Dragon")
	# The Dragon's Bead
	d = new_duel()
	var ldb := place(d, 0, 0, "Luster Dragon #2")
	face_up_spell(d, 0, 1, "The Dragon's Bead")
	var junk := d.debug_give(0, idx("Exiled Force"))
	ring = trap(d, 1, 0, "Ring of Destruction")
	d.end_turn(0)
	settle(d, "use")
	check(d.side(0).monsters.has(ldb) and d.side(0).grave.has(junk) and d.side(1).grave.has(ring), "The Dragon's Bead negates a Trap that targets a Dragon")
	# A Wingbeat of Giant Dragon
	d = new_duel()
	var wd := place(d, 0, 0, "Luster Dragon #2")
	var s1 := trap(d, 0, 0, "Trap Hole")
	var s2 := trap(d, 1, 0, "Trap Hole")
	d.activate_effect(0, d.debug_give(0, idx("A Wingbeat of Giant Dragon")), 0)
	settle(d)
	check(d.side(0).hand.has(wd) and d.side(0).grave.has(s1) and d.side(1).grave.has(s2), "A Wingbeat of Giant Dragon: Dragon to the hand, all Spells and Traps destroyed")
	# Stamping Destruction
	d = new_duel()
	place(d, 0, 0, "Luster Dragon #2")
	var st2 := trap(d, 1, 0, "Trap Hole")
	d.activate_effect(0, d.debug_give(0, idx("Stamping Destruction")), 0)
	settle(d)
	check(d.side(1).grave.has(st2) and d.side(1).lp == 7500, "Stamping Destruction destroys a Spell/Trap and deals 500 (LP %d)" % d.side(1).lp)
	# Burst Breath
	d = new_duel()
	trap(d, 0, 0, "Burst Breath")
	place(d, 0, 0, "Luster Dragon #2")
	var lowdef := mon(d, 1, 0, 1000, 2000)
	var highdef := mon(d, 1, 1, 1000, 2500)
	d.end_turn(0)
	settle(d, "use")
	check(d.side(1).grave.has(lowdef) and d.side(1).monsters.has(highdef), "Burst Breath destroys monsters with DEF up to the Tributed Dragon's ATK")

func test_other_monsters() -> void:
	# Patrician of Darkness
	var d := new_duel()
	place(d, 1, 0, "Patrician of Darkness")
	var pa := mon(d, 1, 1, 500)
	var pb := mon(d, 1, 2, 2500)
	var att := mon(d, 0, 0, 2200)
	d.to_battle(0)
	d.attack(0, att, pa)
	settle(d, "pass", [[pb.uid]])
	check(d.side(1).monsters.has(pa) and d.side(0).grave.has(att), "Patrician of Darkness chooses the attack target")
	# Thunder Nyan Nyan
	d = new_duel()
	var tnn := place(d, 0, 0, "Thunder Nyan Nyan")
	place(d, 0, 1, "Airknight Parshath")
	d.fx.pump()
	check(d.side(0).monsters.has(tnn), "Thunder Nyan Nyan stays with LIGHT monsters")
	d.summon(0, d.debug_give(0, idx("Exiled Force")))
	settle(d)
	check(d.side(0).grave.has(tnn), "...and is destroyed with a non-LIGHT monster")
	# Twin-Headed Behemoth
	d = new_duel()
	var beh := place(d, 0, 0, "Twin-Headed Behemoth")
	var k := mon(d, 1, 0, 2000)
	next_turn(d)
	d.to_battle(1)
	d.attack(1, k, beh)
	settle(d)
	check(d.side(0).grave.has(beh), "Twin-Headed Behemoth is destroyed")
	d.end_turn(1)
	settle(d, "use")
	check(d.side(0).monsters.has(beh) and d.atk_of(beh) == 1000 and d.def_of(beh) == 1000, "...and comes back at the End Phase with 1000/1000")
	d.destroy_card(beh, "effect")
	settle(d)
	d.end_turn(0)
	settle(d, "use")
	check(d.side(0).grave.has(beh), "...only once per Duel")

func test_spells() -> void:
	# A Legendary Ocean
	var d := new_duel()
	d.activate_effect(0, d.debug_give(0, idx("A Legendary Ocean")), 0)
	settle(d)
	var wm := d.debug_place(0, find_monster(3, 4), 0)
	check(d.atk_of(wm) == int(db.card(wm.idx)["atk"]) + 200, "A Legendary Ocean: WATER monsters +200 ATK")
	var five := d.debug_give(0, find_monster(3, 5))
	check(d.level_of(five) == 4 and d.tributes_required(five) == 0, "...their Level is 1 lower, also in the hand (Level %d)" % d.level_of(five))
	check(d.has_face_up_name("Umi"), "...and it is treated as Umi")
	# Creature Swap
	d = new_duel()
	var mine := mon(d, 0, 0, 500)
	var theirs := mon(d, 1, 0, 2500)
	d.activate_effect(0, d.debug_give(0, idx("Creature Swap")), 0)
	settle(d)
	check(mine.controller == 1 and theirs.controller == 0, "Creature Swap switches control")
	check(d.change_position(0, theirs) != "", "...and the monsters cannot change position this turn")
	# Second Coin Toss
	var offered := false
	for s in 30:
		d = new_duel(s)
		var sct := face_up_spell(d, 0, 0, "Second Coin Toss")
		d.fx.push_script([{"op": "coin", "as": "won"}], {"src": sct, "controller": 0, "vars": {}, "event": {}, "effect": {}})
		d.fx.pump()
		if d.fx.pending.get("type", "") == "yesno":
			offered = true
			check(str(d.fx.pending.get("prompt_text", "")).contains("Second Coin Toss"), "Second Coin Toss asks to toss again")
			d.respond(true)
			settle(d)
			check(int(sct.flags.get("sct_turn", -1)) == d.turn, "...once per turn")
			break
	check(offered, "Second Coin Toss is offered after a lost toss")
	# The Secret of the Bandit
	d = new_duel()
	var bm := mon(d, 0, 0, 1000)
	d.activate_effect(0, d.debug_give(0, idx("The Secret of the Bandit")), 0)
	settle(d)
	for i in 3:
		d.debug_give(1, idx("Exiled Force"))
	d.to_battle(0)
	d.attack(0, bm, null)
	settle(d)
	check(d.side(1).hand.size() == 2 and d.side(1).lp == 7000, "The Secret of the Bandit: a random discard per battle damage (hand %d)" % d.side(1).hand.size())
	# Magic Reflector
	d = new_duel()
	var af := face_up_spell(d, 0, 0, "The A. Forces")
	d.activate_effect(0, d.debug_give(0, idx("Magic Reflector")), 0)
	settle(d)
	d.destroy_card(af, "effect")
	check(d.is_on_field(af), "Magic Reflector: the counter is removed instead of destroying the card")
	d.destroy_card(af, "effect")
	settle(d)
	check(d.side(0).grave.has(af), "...only once")
	# Emergency Provisions
	d = new_duel()
	trap(d, 0, 0, "Trap Hole")
	trap(d, 0, 1, "Bottomless Trap Hole")
	d.activate_effect(0, d.debug_give(0, idx("Emergency Provisions")), 0)
	settle(d)
	check(d.side(0).lp == 10000, "Emergency Provisions: 1000 LP per card sent (LP %d)" % d.side(0).lp)

func test_traps() -> void:
	# Ready for Intercepting
	var d := new_duel()
	trap(d, 0, 0, "Ready for Intercepting")
	var rw := place(d, 1, 0, "Exiled Force")
	d.end_turn(0)
	settle(d, "use")
	check(not rw.face_up and rw.pos == "def", "Ready for Intercepting turns a Warrior face-down")
	# A Feint Plan
	d = new_duel()
	trap(d, 1, 0, "A Feint Plan")
	var fu := mon(d, 1, 0, 500)
	var fd := d.debug_place(1, idx("Exiled Force"), 1, false, "def")
	var a2 := mon(d, 0, 0, 3000)
	var a3 := mon(d, 0, 1, 3000)
	d.to_battle(0)
	d.attack(0, a2, fu)
	settle(d, "use")
	check(d.attack(0, a3, fd) != "", "A Feint Plan: face-down monsters cannot be attacked this turn")
	# Blast with Chain
	d = new_duel()
	var bh := mon(d, 0, 0, 1000)
	var bwc := trap(d, 0, 0, "Blast with Chain")
	var victim := mon(d, 1, 0, 1000)
	d.end_turn(0)
	settle(d, "use", [[bh.uid]])
	check(bwc.equipped_to == bh and d.atk_of(bh) == 1500, "Blast with Chain equips for +500 ATK")
	d.effect_player = 1
	d.destroy_card(bwc, "effect")
	d.effect_player = -1
	settle(d, "pass", [[victim.uid]])
	check(d.side(1).grave.has(victim), "...destroyed by an effect while equipped, it destroys a card")
	# Disappear
	d = new_duel()
	trap(d, 0, 0, "Disappear")
	var og := in_grave(d, d._new_card(idx("Sangan"), 1))
	d.end_turn(0)
	settle(d, "use")
	check(d.side(1).banished.has(og), "Disappear removes a card in the opponent's Graveyard from play")
	# Bottomless Trap Hole
	d = new_duel()
	trap(d, 1, 0, "Bottomless Trap Hole")
	var weak := d.debug_give(0, idx("Exiled Force"))
	d.summon(0, weak)
	settle(d, "use")
	check(d.side(0).monsters.has(weak), "Bottomless Trap Hole ignores monsters under 1500 ATK")
	d.end_turn(0)
	settle(d)
	d.end_turn(1)
	settle(d)
	var strong := d.debug_give(0, idx("Wolf Axwielder"))
	d.summon(0, strong)
	settle(d, "use")
	check(d.side(0).banished.has(strong), "...and destroys and removes from play one with 1500 or more")
	# Bad Reaction to Simochi
	d = new_duel()
	face_up_spell(d, 0, 0, "Bad Reaction to Simochi")
	d.heal_player(1, 1000)
	d.heal_player(0, 500)
	check(d.side(1).lp == 7000 and d.side(0).lp == 8500, "Bad Reaction to Simochi turns the opponent's LP gain into damage")
	# Ominous Fortunetelling
	d = new_duel()
	face_up_spell(d, 0, 0, "Ominous Fortunetelling")
	next_turn(d)
	d.side(1).hand.clear()
	d.side(1).hand.append(d._new_card(idx("Exiled Force"), 1))
	d.end_turn(1)
	settle(d, "use")
	check(d.side(1).lp == 7300, "Ominous Fortunetelling: 700 damage for a right call (LP %d)" % d.side(1).lp)
	# Nutrient Z
	d = new_duel()
	trap(d, 0, 0, "Nutrient Z")
	var mine := mon(d, 0, 0, 500)
	var att := mon(d, 1, 0, 3000)
	next_turn(d)
	d.to_battle(1)
	d.attack(1, att, mine)
	settle(d, "use")
	check(d.side(0).lp == 9500, "Nutrient Z: 4000 LP before 2500 battle damage (LP %d)" % d.side(0).lp)

## CPU against CPU with decks full of Legacy of Darkness cards: every duel must end normally.
func test_cpu_duels() -> void:
	var set_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sets/LOD.json"))
	var lod := []
	var fusions := []
	for i in range(1, db.cards.size()):
		if str(db.card(i).get("set", "")).begins_with("LOD-"):
			if int(db.card(i).get("category", 0)) == 2:
				fusions.append(i)
			else:
				lod.append(i)
	check(lod.size() + fusions.size() == 63 and set_data["cards"].size() == 101, "63 Legacy of Darkness cards in the game (%d)" % (lod.size() + fusions.size()))
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return (presets[k]["main"] as Array).size() >= 40)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var bad := []
	for n in 12:
		var seats := []
		for k in 2:
			var p: Dictionary = presets[names[rng.randi_range(0, names.size() - 1)]]
			var deck := Deck.new()
			deck.main = p["main"].map(func(x): return int(x))
			for j in 20:
				deck.main[rng.randi_range(0, deck.main.size() - 1)] = lod[rng.randi_range(0, lod.size() - 1)]
			deck.extra = fusions.duplicate()
			seats.append({"account": "", "name": "CPU%d" % k, "rating": 1500, "bot": true, "peer": 0, "deck": deck})
		var logs := []
		var r := DuelRoom.new()
		r.setup("lod%d" % n, "casual", db, GameServer.DEFAULT_CONFIG.duplicate(), seats[0], seats[1], func(_p, _k, _x): pass,
			func(): return 0.0, func(level, msg): if level != "INFO": logs.append(msg), rng.randi())
		var reason := str(r.result.get("reason", "unfinished")) if r.state == "finished" else "unfinished"
		if reason in ["unfinished", "stuck"] or not logs.is_empty():
			bad.append("%s %s" % [reason, str(logs.slice(0, 2))])
		if r.duel != null:
			r.duel.dispose()
	check(bad.is_empty(), "CPU duels with Legacy of Darkness cards all end normally: %s" % str(bad))
