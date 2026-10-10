extends SceneTree
## Sanity check: the ported AI should beat the old placeholder AI more often than not (same decks, both seatings).

func _init() -> void:
	var db := CardDB.load_default()
	var presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return k.begins_with("cpu_")).slice(0, 10)
	var joey := 0
	var simple := 0
	var unfinished := 0
	for n in names.size():
		for seat in 2:
			var deck := _deck(presets[names[n]])
			var d := Duel.create(db, deck, _deck(presets[names[(n + 3) % names.size()]]), n * 2 + seat + 1, seat)
			var guard := 0
			var joey_seat := seat
			while d.winner == -1 and guard < 6000:
				guard += 1
				var p: int = d.turn_player
				if not (JoeyAI.answer(d, 1 - p)):
					if p == joey_seat:
						JoeyAI.step(d, p)
					else:
						SimpleAI.step(d, p)
				d.drain_events()
			if d.winner == joey_seat:
				joey += 1
			elif d.winner == -1 or d.winner == 2:
				unfinished += 1
			else:
				simple += 1
	print("JoeyAI wins %d, SimpleAI wins %d, unfinished %d" % [joey, simple, unfinished])
	quit()

func _deck(p: Dictionary) -> Deck:
	var d := Deck.new()
	d.main = p["main"].map(func(x): return int(x))
	d.extra = p["extra"].map(func(x): return int(x))
	return d
