extends SceneTree

func _init() -> void:
	var db := CardDB.load_default()
	var fails := 0
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	if not DeckRules.problems(d, db).is_empty(): fails += 1; print("FAIL user deck should be valid: ", DeckRules.problems(d, db))
	var e := Deck.new()
	if DeckRules.problems(e, db).is_empty(): fails += 1; print("FAIL empty deck must be invalid")
	var starfish: int = db.search("armored starfish")[0]
	for k in 3: DeckRules.add(e, db, starfish)
	if DeckRules.add(e, db, starfish) == "": fails += 1; print("FAIL 4th copy allowed")
	var fusion: int = db.search("aqua dragon")[0]
	DeckRules.add(e, db, fusion)
	if e.extra.size() != 1 or e.main.size() != 3: fails += 1; print("FAIL fusion routing")
	if DeckRules.add(e, db, fusion, "main") == "": fails += 1; print("FAIL fusion in main")
	var decks = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var bad := 0
	for k in decks:
		var p: Dictionary = decks[k]
		if p["main"].size() < 40 and not k.begins_with("ful_"): bad += 1
	print("presets with <40 main (info): ", bad, " of ", decks.size())
	print("deck rules tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
