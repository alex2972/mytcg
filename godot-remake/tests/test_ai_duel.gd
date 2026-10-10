extends SceneTree
## Plays complete AI-vs-AI duels with the preset decks: every duel must end, with no stuck turns or illegal moves.

func _init() -> void:
	var db := CardDB.load_default()
	var presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return k.begins_with("cpu_")).slice(0, 12)
	var fails := 0
	var finished := 0
	var turns_total := 0
	for n in names.size() - 1:
		var a := _deck(presets[names[n]])
		var b := _deck(presets[names[n + 1]])
		var d := Duel.create(db, a, b, n + 1, n % 2)
		var guard := 0
		while d.winner == -1 and guard < 5000:
			guard += 1
			var before := "%d|%s|%d" % [d.turn, d.phase, d.turn_player]
			if not JoeyAI.answer(d, 1 - d.turn_player):
				JoeyAI.step(d, d.turn_player)
			d.drain_events()
			if guard > 4000:
				print("STUCK at ", before)
		if d.winner == -1:
			fails += 1
			print("FAIL: duel ", names[n], " vs ", names[n + 1], " did not finish (turn ", d.turn, ")")
		else:
			finished += 1
			turns_total += d.turn
	print("ai duels finished: %d, avg turns %.1f" % [finished, float(turns_total) / maxf(1, finished)])
	print("ai duel tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func _deck(p: Dictionary) -> Deck:
	var d := Deck.new()
	d.main = p["main"].map(func(x): return int(x))
	d.extra = p["extra"].map(func(x): return int(x))
	return d
