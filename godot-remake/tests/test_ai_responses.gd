extends SceneTree
## The AI's Mystical Space Typhoon responses (original handlers 5b1f10 and 5b3210).

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

func new_duel() -> Duel:
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	var du := Duel.create(db, d, d, 1, 0)
	du.side(0).hand.clear()
	du.side(1).hand.clear()
	return du

## The AI (player `ai_player`) answers its own prompts; the other side passes.
func settle(d: Duel, ai_player: int) -> void:
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 60:
		guard += 1
		var p: Dictionary = d.fx.pending
		if p["player"] == ai_player and JoeyAI.answer(d, ai_player):
			continue
		match p["type"]:
			"select": d.respond((p["candidates"] as Array).slice(0, p["max"]))
			"yesno": d.respond(true)
			"choice": d.respond(0)
			_: d.respond("pass")

func _init() -> void:
	db = CardDB.load_default()
	# 1. the AI answers a Field Spell the opponent activates by destroying it
	var d := new_duel()
	var mst := d.debug_place_spell(1, idx("Mystical Space Typhoon"), 0, false)
	mst.summon_turn = -1
	var mount := d.debug_give(0, idx("Mountain"))
	d.activate_effect(0, mount, 0)
	settle(d, 1)
	check(d.side(1).grave.has(mst), "the AI chained its Set Mystical Space Typhoon to the Field Spell")
	check(d.side(0).grave.has(mount) and d.side(0).field_spell == null, "...and the Field Spell was destroyed")
	# 2. it does not waste it on a normal Spell
	d = new_duel()
	mst = d.debug_place_spell(1, idx("Mystical Space Typhoon"), 0, false)
	mst.summon_turn = -1
	var pot := d.debug_give(0, idx("Pot of Greed"))
	d.activate_effect(0, pot, 0)
	settle(d, 1)
	check(not d.side(1).grave.has(mst), "the AI keeps its Typhoon against a normal Spell")
	# 3. at the end of the opponent's turn it hits a Set Spell/Trap
	d = new_duel()
	mst = d.debug_place_spell(1, idx("Mystical Space Typhoon"), 0, false)
	mst.summon_turn = -1
	var trap := d.debug_place_spell(0, idx("Mirror Force"), 0, false)
	d.end_turn(0)
	settle(d, 1)
	check(d.side(0).grave.has(trap), "at the end of the turn the AI Typhoons a Set card")
	print("ai response tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
