extends SceneTree
## The Summon / Set bubble only appears on monsters that can really be summoned or Set right now.

var fails := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func idx(db: CardDB, name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == name:
			return i
	return 0

func _init() -> void:
	var db := CardDB.load_default()
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var board := DuelBoard.new(db, deck, deck, 3)
	board.ai_delay = 0.0
	root.add_child(board)
	await process_frame
	var d := board.duel
	d.side(0).hand.clear()
	var low := d.debug_give(0, idx(db, "Armored Starfish"))
	var big := d.debug_give(0, idx(db, "Blue-Eyes White Dragon"))
	check(d.tributes_required(low) == 0 and d.tributes_required(big) == 2, "test cards: a 0-tribute and a 2-tribute monster")
	check(board._hover_cursor(low) in ["summon", "set"], "a monster that can be summoned shows the bubble")
	check(board._hover_cursor(big) == "off", "a monster that needs Tributes we do not have shows no bubble")
	board.hand_set_pref = true
	check(board._hover_cursor(big) == "off", "...also in Set mode")
	board.hand_set_pref = false
	check(d.summon_problem(0, big) != "", "summon_problem names the reason")
	# with enough monsters to Tribute the bubble comes back
	d.debug_place(0, idx(db, "Armored Starfish"), 0, true, "atk")
	d.debug_place(0, idx(db, "Armored Starfish"), 1, true, "atk")
	check(board._hover_cursor(big) in ["summon", "set"], "with 2 monsters to Tribute the bubble appears")
	# a full monster zone blocks 0-tribute monsters
	for z in 5:
		if d.side(0).monsters[z] == null:
			d.debug_place(0, idx(db, "Armored Starfish"), z, true, "atk")
	check(board._hover_cursor(low) == "off", "no free monster zone: no bubble")
	# Sheep Tokens cannot be Tributes
	d = board.duel
	for z in 5:
		d.side(0).monsters[z] = null
	for z in 2:
		var tk := d.new_token("Sheep Token", 0)
		d.special_summon(tk, 0, "def", true)
	check(d.summon_problem(0, big) != "", "Sheep Tokens do not count as Tributes")
	# one summon per turn still shows the existing 'already summoned' bubble
	d.normal_summoned = true
	check(board._hover_cursor(low) == "over", "already summoned this turn keeps its own bubble")
	print("summon hover tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
