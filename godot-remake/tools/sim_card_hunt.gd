extends SceneTree
## Packs needed to pull a given card for the first time, over many trials (pure rolls through the backend's pools):
##   godot --headless --path . -s tools/sim_card_hunt.gd -- <product_id> <trials> "Card A" "Card B" ...
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var product_id: String = args[0]
	var trials: int = int(args[1])
	var audio := root.get_node_or_null("Audio")
	if audio != null: audio.queue_free()
	var session := root.get_node("Session")
	session.use_root("user://sim_hunt_accounts")
	var backend: LocalShopBackend = session.backend
	var db: CardDB = session.db
	var contents: Dictionary = backend._product(product_id).contents
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for a in range(2, args.size()):
		var target := -1
		for i in range(1, db.cards.size()):
			if db.card_name(i) == args[a]:
				target = i
				break
		var counts := []
		for t in trials:
			var n := 0
			while n < 100000:
				n += 1
				if PackOpener.roll(contents, backend.pools, rng).any(func(p): return int(p.index) == target):
					break
			counts.append(n)
		counts.sort()
		var sum := 0
		for c in counts: sum += c
		print("%s: average %.1f packs | median %d | 25%% within %d | 75%% within %d | 90%% within %d | worst %d  (%d trials)" % [args[a], float(sum) / trials, counts[trials / 2], counts[trials / 4], counts[trials * 3 / 4], counts[trials * 9 / 10], counts[-1], trials])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sim_hunt_accounts/index.json"))
	quit()
