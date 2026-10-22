extends SceneTree
## Packs needed to own every ultra rare x3 and to complete the whole pack (every card x3), over several trials:
##   godot --headless --path . -s tools/sim_set_completion.gd [-- <product_id> <trials>]
const ROOT := "user://sim_completion_accounts"

func _initialize() -> void:
	call_deferred("run")

static func wipe(dir: String) -> void:
	var path := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		wipe(dir + "/" + sub)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var product_id: String = args[0] if args.size() > 0 else "pack_monsters_1"
	var trials: int = int(args[1]) if args.size() > 1 else 20
	var audio := root.get_node_or_null("Audio")
	if audio != null: audio.queue_free()
	var session := root.get_node("Session")
	var ultra_packs := []
	var full_packs := []
	var all_cards := 0
	var ultra_cards := 0
	for t in trials:
		wipe(ROOT)
		session.ensure_ready("user://__reset")      # force the session to rebuild on a fresh root below
		session.use_root(ROOT)
		var backend: LocalShopBackend = session.backend
		var account: String = session.account_id()
		var profile: Dictionary = backend.store.profile(account)
		profile.dp = 100000000
		backend.store.save_profile(profile)
		var pools: Array = []
		var ultra := {}
		var everything := {}
		for slot in backend._product(product_id).contents.slots:
			for r in PackOpener.slot_rarities(slot):
				for c in backend.pools.get(r.pool, []):
					everything[int(c)] = true
					if r.rarity == "ultra_rare": ultra[int(c)] = true
		all_cards = everything.size()
		ultra_cards = ultra.size()
		var owned := {}
		var ultra_done := -1
		var n := 0
		while true:
			n += 1
			var result: Dictionary = await backend.purchase(account, product_id)
			if not result.ok:
				break
			for c in result.cards:
				owned[int(c.index)] = int(owned.get(int(c.index), 0)) + 1
			if ultra_done < 0 and ultra.keys().all(func(i): return int(owned.get(i, 0)) >= Collection.MAX_OWNED):
				ultra_done = n
		ultra_packs.append(ultra_done)
		full_packs.append(n - 1)          # the refused attempt is not a pack
		print("trial %d: all ultra rares x3 after %d packs, whole set after %d packs" % [t + 1, ultra_done, n - 1])
	var sum_u := 0
	var sum_f := 0
	for v in ultra_packs: sum_u += v
	for v in full_packs: sum_f += v
	ultra_packs.sort()
	full_packs.sort()
	print("== %s: %d cards (%d ultra rares), %d trials" % [product_id, all_cards, ultra_cards, trials])
	print("ALL ULTRA RARES x3: average %.0f packs, range %d-%d, median %d  (%.0f DP)" % [float(sum_u) / trials, ultra_packs[0], ultra_packs[-1], ultra_packs[trials / 2], 150.0 * sum_u / trials])
	print("COMPLETE SET x3:    average %.0f packs, range %d-%d, median %d  (%.0f DP)" % [float(sum_f) / trials, full_packs[0], full_packs[-1], full_packs[trials / 2], 150.0 * sum_f / trials])
	wipe(ROOT)
	quit()
