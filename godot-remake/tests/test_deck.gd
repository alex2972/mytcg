extends SceneTree

func _init() -> void:
	var db := CardDB.load_default()
	var fails := 0
	var d := Deck.load_file("res://tests/fixtures/user_deck.ydc", db)
	if d.main.size() != 40: fails += 1; print("FAIL main size ", d.main.size())
	if d.extra.size() != 1 or db.card_name(d.extra[0]) != "Alligator's Sword Dragon": fails += 1; print("FAIL extra")
	if db.card_name(d.main[3]) != "Axe Raider": fails += 1; print("FAIL first cards ", db.card_name(d.main[3]))
	if d.copies(db.search("Mystical Space Typhoon")[0]) != 2: fails += 1; print("FAIL copies")
	var orig := FileAccess.get_file_as_bytes("res://tests/fixtures/user_deck.ydc")
	if d.to_bytes(db) != orig: fails += 1; print("FAIL round trip")
	print("deck tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
