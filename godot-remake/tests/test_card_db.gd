extends SceneTree
## Run: Godot --headless --path . -s tests/test_card_db.gd

func _init() -> void:
	var db := CardDB.load_default()
	var fails := 0
	var check := func(ok: bool, msg: String):
		if not ok:
			fails += 1
			print("FAIL: ", msg)
	check.call(db.count() == 1114, "card count %d" % db.count())
	var c := db.card(2)
	check.call(db.card_name(2) == "Armored Starfish", "name")
	check.call(c.atk == 850 and c.def == 1400 and c.level == 4, "stats (card image of Amphibian Beast / Armored Starfish: ATK is the SMALLER field for Starfish)")
	check.call(db.card_name(1, "jpn") == "地縛霊", "jpn name")
	check.call(db.search("starfish").has(2), "search")
	var missing := 0
	for i in range(1, db.cards.size()):
		var p := db.art_path(i)
		if p != "" and not FileAccess.file_exists(p):
			missing += 1
	check.call(missing == 0, "%d missing art files" % missing)
	print("card_db tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
