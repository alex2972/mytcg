extends SceneTree
## Review of the Legacy of Darkness cards: corrections found when the effects were checked against the card texts.

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
	test_soul_demolition()
	test_spirit_ryu()
	test_behemoth_and_susa()
	test_bark_any_amount()
	test_own_card_negation()
	test_second_coin_toss_opponent()
	test_puppet_on_resolution()
	print("effect tests 19 (Legacy of Darkness review): ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

## "Both players select 1 Monster Card from their opponent's Graveyard": the selection is mandatory when a monster is available.
func test_soul_demolition() -> void:
	var d := new_duel()
	var sd := face_up_spell(d, 0, 0, "Soul Demolition")
	place(d, 0, 0, "Dark Ruler Ha Des")
	var og := in_grave(d, d._new_card(idx("Armored Starfish"), 1))
	var mg := in_grave(d, d._new_card(idx("Armored Starfish"), 0))
	check(d.activate_effect(0, sd, 1) == "", "Soul Demolition can be activated with a Fiend and monsters in both Graveyards")
	var refused := 0
	for i in 4:
		if d.fx.pending.get("type", "") == "select":
			if d.respond([]) != "":
				refused += 1
			d.respond((d.fx.pending["candidates"] as Array).slice(0, 1))
	settle(d)
	check(refused == 2, "...a player cannot decline to select (refused %d empty answers)" % refused)
	check(d.side(1).banished.has(og) and d.side(0).banished.has(mg) and d.side(0).lp == 7500, "...and both monsters are removed from play")
	# with an empty Graveyard on one side there is nothing to select there and the effect still works for the other
	d = new_duel()
	sd = face_up_spell(d, 0, 0, "Soul Demolition")
	place(d, 0, 0, "Dark Ruler Ha Des")
	og = in_grave(d, d._new_card(idx("Armored Starfish"), 1))
	d.activate_effect(0, sd, 1)
	settle(d)
	check(d.side(1).banished.has(og), "Soul Demolition works when only one Graveyard has a monster")

## "this card gains 1000 ATK/DEF until the end of the Battle Phase"
func test_spirit_ryu() -> void:
	var d := new_duel()
	var sr := place(d, 0, 0, "Spirit Ryu")
	var base: int = d.atk_of(sr)
	d.debug_give(0, idx("Spear Dragon"))
	var foe := mon(d, 1, 0, 100, 100, true, "def")
	d.phase = "battle"
	d.attack(0, sr, foe)
	settle(d, "use")
	check(d.atk_of(sr) == base + 1000 and d.side(0).grave.size() == 1, "Spirit Ryu: discarding a Dragon gives +1000 ATK in battle (%d)" % (d.atk_of(sr) - base))
	d.to_main2(0)
	check(d.atk_of(sr) == base, "...and the bonus ends with the Battle Phase (Main Phase 2 ATK %d)" % d.atk_of(sr))

## "During the End Phase" applies to either player's End Phase; Susa returns the turn it is Flip Summoned.
func test_behemoth_and_susa() -> void:
	var d := new_duel()
	var be := place(d, 0, 0, "Twin-Headed Behemoth")
	next_turn(d)
	d.destroy_card(be, "effect")
	settle(d)
	d.end_turn(1)
	settle(d, "use")
	check(d.side(0).monsters.has(be) and d.atk_of(be) == 1000, "Twin-Headed Behemoth returns at the opponent's End Phase when destroyed on that turn")
	d = new_duel()
	be = place(d, 0, 0, "Twin-Headed Behemoth")
	d.destroy_card(be, "effect")
	settle(d)
	next_turn(d)
	next_turn(d)
	d.end_turn(0)
	settle(d, "use")
	check(not d.side(0).monsters.has(be), "...but not when it was destroyed on an earlier turn")
	d = new_duel()
	var su := d.debug_place(0, idx("Susa Soldier"), 0, false, "def")
	su.summon_turn = -1
	d.change_position(0, su)
	settle(d)
	d.end_turn(0)
	settle(d)
	check(d.side(0).hand.has(su), "Susa Soldier returns to the hand at the End Phase of the turn it is Flip Summoned")

## Answer pending decisions; choices take the next value from `choices` (else 0), chains use the first option.
func drive(d: Duel, choices: Array) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 40:
		guard += 1
		var p: Dictionary = d.fx.pending
		match p["type"]:
			"chain":
				var o: Dictionary = p["options"][0]
				d.respond({"uid": o["uid"], "idx": o["idx"]})
			"choice": d.respond(choices.pop_front() if not choices.is_empty() else 0)
			"select": d.respond((p["candidates"] as Array).slice(0, p["max"]))
			"yesno": d.respond(true)
			"presentation": d.respond(true)
			_: return

## "Pay LP (in multiples of 100 points)": any multiple, not only a preset list.
func test_bark_any_amount() -> void:
	var d := new_duel()
	var lf := place(d, 0, 0, "Lesser Fiend")
	trap(d, 0, 0, "Bark of Dark Ruler")
	var big := mon(d, 1, 0, 2500)
	d.to_battle(0)
	d.attack(0, lf, big)
	drive(d, [1, 2])          # "100 to 900 LP", then "Pay 300 LP"
	check(d.side(0).lp == 8000 - 300 - 100 and d.atk_of(big) == 2200 and d.side(0).grave.has(lf),
		"Bark of Dark Ruler: 300 LP paid exactly, the opponent's monster loses 300 (LP %d, ATK %d)" % [d.side(0).lp, d.atk_of(big)])
	d = new_duel()
	lf = place(d, 0, 0, "Lesser Fiend")
	trap(d, 0, 0, "Bark of Dark Ruler")
	big = mon(d, 1, 0, 2500)
	d.to_battle(0)
	d.attack(0, lf, big)
	drive(d, [3, 4])          # "2000 to 2900 LP", then "Pay 2400 LP"
	check(d.side(0).lp == 8000 - 2400 and d.side(1).banished.has(big), "...also amounts like 2400 (LP %d)" % d.side(0).lp)

## Dark Balter, Ryu Senshi: "When a Normal Spell/Trap Card is activated" includes your own; the CPU only uses them on the opponent's.
func test_own_card_negation() -> void:
	var d := new_duel()
	place(d, 0, 0, "Dark Balter the Terrible")
	d.activate_effect(0, d.debug_give(0, idx("Hinotama")), 0)
	var offered: bool = d.fx.pending.get("type", "") == "chain" and int(d.fx.pending.get("player", -1)) == 0
	check(offered and CardAI.respond_choice(d, 0, d.fx.pending).is_empty(), "Dark Balter is offered against my own Normal Spell, the CPU declines")
	settle(d, "use")
	check(d.side(1).lp == 8000 and d.side(0).lp == 7000, "...and a player who uses it negates it (LP %d / %d)" % [d.side(0).lp, d.side(1).lp])
	d = new_duel()
	place(d, 0, 0, "Dark Balter the Terrible")
	next_turn(d)
	d.activate_effect(1, d.debug_give(1, idx("Hinotama")), 0)
	check(d.fx.pending.get("type", "") == "chain" and not CardAI.respond_choice(d, 0, d.fx.pending).is_empty(), "...the CPU still negates the opponent's Normal Spell")
	d = new_duel()
	place(d, 0, 0, "Ryu Senshi")
	var jar := trap(d, 0, 0, "Jar of Greed")
	var hand_n: int = d.side(0).hand.size()
	d.end_turn(0)
	settle(d, "use")
	check(d.side(0).grave.has(jar) and d.side(0).lp == 7000 and d.side(0).hand.size() == hand_n, "Ryu Senshi can negate my own Normal Trap (LP %d)" % d.side(0).lp)

## "When a coin toss is performed": the opponent's tosses too.
func test_second_coin_toss_opponent() -> void:
	var asked := false
	for sd in 30:
		var d := new_duel(sd)
		var sct := face_up_spell(d, 0, 0, "Second Coin Toss")
		var src := d.debug_place_spell(1, idx("Pot of Greed"), 0, true)
		d.fx.push_script([{"op": "coin", "as": "won"}], {"src": src, "controller": 1, "vars": {}, "event": {}, "effect": {}})
		d.fx.pump()
		if d.fx.pending.get("type", "") == "yesno":
			asked = true
			check(int(d.fx.pending["player"]) == 0 and str(d.fx.pending.get("prompt_text", "")).contains("opponent"), "Second Coin Toss: its owner may make the opponent toss again after a good result for them")
			d.respond(true)
			settle(d)
			check(int(sct.flags.get("sct_turn", -1)) == d.turn and d.fx.pending.is_empty(), "...which uses it for the turn")
			break
	check(asked, "Second Coin Toss is offered against the opponent's toss")

## "Remove from play monsters ... Then Special Summon": the monsters stay until the card resolves.
func test_puppet_on_resolution() -> void:
	var d := new_duel()
	var g1 := in_grave(d, d._new_card(idx("Lesser Fiend"), 0))
	var m3 := place(d, 0, 0, "Skull Knight #2")
	var m2 := place(d, 0, 1, "Ryu-Kishin Clown")
	trap(d, 1, 0, "Jar of Greed")
	d.activate_effect(0, d.debug_give(0, idx("The Puppet Magic of Dark Ruler")), 0)
	var guard := 0
	while d.fx.pending.get("type", "") == "select" and guard < 5:
		guard += 1
		d.respond((d.fx.pending["candidates"] as Array).slice(0, d.fx.pending["max"]))
	var waiting: bool = d.fx.pending.get("type", "") == "chain"
	check(waiting and d.side(0).monsters.has(m3) and d.side(0).monsters.has(m2), "The Puppet Magic of Dark Ruler: the monsters are still on the field while the opponent may respond")
	settle(d)
	check(d.side(0).banished.has(m3) and d.side(0).banished.has(m2) and d.side(0).monsters.has(g1), "...and are removed when it resolves, then the Fiend is revived")
