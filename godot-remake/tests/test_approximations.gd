extends SceneTree
## Every card named in data/approximations.json must exist (so the list cannot rot).

func _init() -> void:
	var db := CardDB.load_default()
	var names := {}
	for i in range(1, db.cards.size()):
		names[db.card_name(i)] = true
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/approximations.json"))
	var fails := 0
	for k in data:
		if k.begins_with("_") or k.begins_with("RULE:"):
			continue
		if not names.has(k):
			fails += 1
			print("FAIL: unknown card in approximations.json: ", k)
	print("approximation list tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
