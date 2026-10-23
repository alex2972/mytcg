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
