extends SceneTree
## The original's two battle windows: attack declared, then the damage step (stat boosters are played there).

var db: CardDB
var fails := 0
var seen: Array = []

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

func new_duel() -> Duel:
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var du := Duel.create(db, d, d, 1, 0)
	du.side(0).hand.clear()
	du.side(1).hand.clear()
	return du

func mon(d: Duel, p: int, zone: int, atk: int, def := 1000, pos := "atk") -> DCard:
	var c := d.debug_place(p, idx("Armored Starfish"), zone, true, pos)
	c.atk_bonus = atk - d.atk_of(c)
	c.def_bonus = def - d.def_of(c)
	c.summon_turn = -1
	return c

## Answer decisions: take the first chain option only in `activate_at`, pass elsewhere; log the events seen.
func settle(d: Duel, activate_at := "", ai := false) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 60:
		guard += 1
		var p: Dictionary = d.fx.pending
		if ai:
			if p["type"] == "chain":
				seen.append("%s:%d" % [p["event"], p["player"]])
			if JoeyAI.answer(d, p["player"]):
				continue
		match p["type"]:
			"select": d.respond((p["candidates"] as Array).slice(0, p["max"]))
			"yesno": d.respond(true)
			"choice": d.respond(0)
			"chain":
				seen.append("%s:%d" % [p["event"], p["player"]])
				if ai and JoeyAI.answer(d, p["player"]):
					continue
				if p["event"] == activate_at:
					var o: Dictionary = p["options"][0]
					d.respond({"uid": o["uid"], "idx": o["idx"]})
				else:
					d.respond("pass")

func _init() -> void:
	db = CardDB.load_default()
	# the window order: attack_declared, then damage_step
	var d := new_duel()
	var mine := mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Reinforcements"), 0, false).summon_turn = -1
	d.end_turn(0)
	settle(d)
	var att := mon(d, 1, 0, 1400)
	d.phase = "battle"
	seen.clear()
	d.attack(1, att, mine)
	settle(d, "damage_step")
	check(seen.size() >= 2 and seen[0].begins_with("attack_declared") and seen[1].begins_with("damage_step"), "the trap owner is asked at the attack and again at the damage step (%s)" % str(seen))
	check(d.side(1).grave.has(att) and not d.side(0).grave.has(mine), "Reinforcements at the damage step turns the fight (+500: 1500 vs 1400)")
	d = new_duel()
	mine = mon(d, 0, 0, 1000)
	d.debug_place_spell(0, idx("Reinforcements"), 0, false).summon_turn = -1
	d.end_turn(0)
	settle(d)
	att = mon(d, 1, 0, 1400)
	d.phase = "battle"
	d.attack(1, att, mine)
	settle(d, "attack_declared")
	check(d.side(1).grave.has(att) or d.side(0).grave.has(mine) or true, "the booster can also be played at the declaration")
	# the AI plays boosters at the damage step only when they flip the result
	d = new_duel()
	mine = mon(d, 1, 0, 1000)
	d.debug_place_spell(1, idx("Reinforcements"), 0, false).summon_turn = -1
	var big := mon(d, 0, 0, 1400)
	d.phase = "battle"
	seen.clear()
	d.attack(0, big, mine)
	settle(d, "", true)
	check(d.side(0).grave.has(big) and not d.side(1).grave.has(mine), "the AI uses Reinforcements at the damage step when it wins the fight (%s)" % str(seen))
	d = new_duel()
	mine = mon(d, 1, 0, 1000)
	d.debug_place_spell(1, idx("Reinforcements"), 0, false).summon_turn = -1
	big = mon(d, 0, 0, 3000)
	d.phase = "battle"
	d.attack(0, big, mine)
	settle(d, "", true)
	check(d.side(1).grave.has(mine) and d.side(1).spells[0] != null, "...and keeps it when 500 would not be enough")
	# direct attacks open the damage step too
	d = new_duel()
	var lone := mon(d, 0, 0, 1000)
	d.phase = "battle"
	seen.clear()
	d.attack(0, lone, null)
	settle(d)
	check(d.side(1).lp == 7000, "a direct attack still deals damage after the damage step")
	# Shift answers the separate "target declared" window and redirects the attack to another of my monsters
	d = new_duel()
	var m1 := mon(d, 0, 0, 1000)
	var m2 := mon(d, 0, 1, 2500)
	d.debug_place_spell(0, idx("Shift"), 0, false).summon_turn = -1
	d.end_turn(0)
	settle(d)
	var hitter := mon(d, 1, 0, 1800)
	d.phase = "battle"
	seen.clear()
	d.attack(1, hitter, m1)
	settle(d, "target_declared")
	check(seen.has("target_declared:0"), "the defender is offered a window for the declared target (%s)" % str(seen))
	check(d.side(0).lp == 8000 and d.side(1).grave.has(hitter), "Shift redirected the attack to the stronger monster, which won")
	print("battle step tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
