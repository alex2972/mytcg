extends SceneTree
## Runs N bot-vs-bot rooms (random preset decks, random seeds) and reports outcomes, errors and timing.
##   godot --headless --path . -s tools/online/bot_duels.gd -- 200
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var n := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 200
	var db := CardDB.load_default()
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return (presets[k]["main"] as Array).size() >= 40)
	var reasons := {}
	var turns := []
	var errors := []
	var t0 := Time.get_ticks_msec()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var seats := []
		for k in 2:
			var p: Dictionary = presets[names[rng.randi_range(0, names.size() - 1)]]
			var d := Deck.new()
			d.main = p["main"].map(func(x): return int(x))
			d.extra = p["extra"].map(func(x): return int(x))
			seats.append({"account": "", "name": "CPU%d" % k, "rating": 1500, "bot": true, "peer": 0, "deck": d})
		var r := DuelRoom.new()
		r.setup("b%d" % i, "casual", db, GameServer.DEFAULT_CONFIG.duplicate(), seats[0], seats[1], func(_p, _k, _x): pass,
			func(): return 0.0, func(level, msg): if level != "INFO": errors.append(msg), rng.randi())
		var reason := str(r.result.get("reason", "unfinished")) if r.state == "finished" else "unfinished"
		reasons[reason] = int(reasons.get(reason, 0)) + 1
		turns.append(int(r.result.get("turns", 0)))
	turns.sort()
	print("bot duels: %d in %.1f s" % [n, (Time.get_ticks_msec() - t0) / 1000.0])
	print("outcomes: ", reasons)
	print("turns: median %d, max %d" % [turns[turns.size() / 2], turns[-1]])
	print("room warnings/errors: %d %s" % [errors.size(), str(errors.slice(0, 5))])
	quit(0 if not reasons.has("unfinished") and not reasons.has("stuck") else 1)
