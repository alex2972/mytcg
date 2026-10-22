extends SceneTree
## Headless pack simulation: godot --headless --path . -s tools/sim_packs.gd [-- <product_id> <packs>]
## Buys <packs> packs (default 100 of pack_monsters_1) through the real backend with a throwaway account,
## then reports tokens, cards outside the pack's pools and removed cards, plus rarity counts.
const ROOT := "user://sim_packs_accounts"

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
	var packs: int = int(args[1]) if args.size() > 1 else 100
	wipe(ROOT)
	var audio := root.get_node_or_null("Audio")
	if audio != null: audio.queue_free()
	var session := root.get_node("Session")
	session.use_root(ROOT)
	var backend: LocalShopBackend = session.backend
	var db: CardDB = session.db
	var account: String = session.account_id()
	var tiers := PackOpener.card_tiers()
	var allowed := {}
	for slot in backend._product(product_id).contents.slots:
		for r in PackOpener.slot_rarities(slot):
			for c in backend.pools.get(r.pool, []): allowed[int(c)] = true
	var tokens := {}
	var outside := {}
	var rarity_count := {}
	var distinct := {}
	var total := 0
	var failed := 0
	for n in packs:
		var profile: Dictionary = backend.store.profile(account)
		profile.dp = 1000000                         # enough DP for any number of packs
		backend.store.save_profile(profile)
		var result: Dictionary = await backend.purchase(account, product_id)
		if not result.ok:
			failed += 1
			continue
		for card in result.cards:
			total += 1
			var i := int(card.index)
			var card_name := db.card_name(i)
			distinct[i] = true
			rarity_count[card.rarity] = int(rarity_count.get(card.rarity, 0)) + 1
			if card_name.ends_with("Token"):
				tokens[card_name] = int(tokens.get(card_name, 0)) + 1
			if not allowed.has(i):
				outside[card_name] = int(outside.get(card_name, 0)) + 1
	print("== %s: %d packs, %d cards (%d failed purchases), %d distinct cards" % [product_id, packs, total, failed, distinct.size()])
	print("rarities: ", rarity_count)
	print("TOKENS: ", "none" if tokens.is_empty() else str(tokens))
	print("cards outside the pack's pools: ", "none" if outside.is_empty() else str(outside))
	var tier_counts := {}
	for i in distinct:
		var t: int = tiers.get(int(db.card(i).number), -1)
		tier_counts[t] = int(tier_counts.get(t, 0)) + 1
	print("distinct cards by tier (-1 = untiered): ", tier_counts)
	wipe(ROOT)
	quit()
