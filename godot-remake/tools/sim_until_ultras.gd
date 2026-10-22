extends SceneTree
## Buys packs in batches of 100 until N ultra rares were pulled:
##   godot --headless --path . -s tools/sim_until_ultras.gd [-- <product_id> <ultras> <batch>]
const ROOT := "user://sim_until_accounts"

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
	var target: int = int(args[1]) if args.size() > 1 else 3
	var batch: int = int(args[2]) if args.size() > 2 else 100
	wipe(ROOT)
	var audio := root.get_node_or_null("Audio")
	if audio != null: audio.queue_free()
	var session := root.get_node("Session")
	session.use_root(ROOT)
	var backend: LocalShopBackend = session.backend
	var db: CardDB = session.db
	var account: String = session.account_id()
	var packs := 0
	var found := []
	while found.size() < target and packs < 20000:
		var in_batch := 0
		for n in batch:
			var profile: Dictionary = backend.store.profile(account)
			profile.dp = 1000000
			backend.store.save_profile(profile)
			var result: Dictionary = await backend.purchase(account, product_id)
			packs += 1
			for card in result.cards:
				if card.rarity == "ultra_rare":
					in_batch += 1
					found.append("%s (pack %d)" % [card.name, packs])
		print("after %d packs: %d ultra rares so far (%d in the last %d)" % [packs, found.size(), in_batch, batch])
	print("RESULT: %d ultra rares after %d packs (%d DP)" % [found.size(), packs, packs * 150])
	print(found)
	wipe(ROOT)
	quit()
