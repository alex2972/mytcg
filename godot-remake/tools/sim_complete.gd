extends SceneTree
## What happens when a set is completed: buys packs of one product until it hands out nothing, printing pack sizes and DP.
## godot --headless --path . -s tools/sim_complete.gd [-- <product_id>]
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var product_id: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "pack_spells_traps_1"
	var audio := root.get_node_or_null("Audio")
	if audio != null: audio.queue_free()
	var session := root.get_node("Session")
	session.use_root("user://sim_complete_accounts")
	var backend: LocalShopBackend = session.backend
	var account: String = session.account_id()
	var profile: Dictionary = backend.store.profile(account)
	profile.dp = 1000000
	backend.store.save_profile(profile)
	var sizes := []
	var ultras := 0
	for n in 400:
		var before: int = backend.get_profile(account).account.dp
		var r: Dictionary = await backend.purchase(account, product_id)
		if not r.ok:
			print("pack %d refused: %s (DP charged: %d)" % [n + 1, r.error, before - int(backend.get_profile(account).account.dp)])
			break
		sizes.append(r.cards.size())
		for c in r.cards: if c.rarity == "ultra_rare": ultras += 1
		if r.cards.size() < 5:
			print("pack %d: %d cards, DP charged: %d" % [n + 1, r.cards.size(), before - r.balance])
	print("pack sizes (first 5 / last 5): ", sizes.slice(0, 5), " ... ", sizes.slice(maxi(0, sizes.size() - 5)))
	print("ultra rares pulled: ", ultras)
	var d := ProjectSettings.globalize_path("user://sim_complete_accounts")
	OS.move_to_trash(d)
	quit()
