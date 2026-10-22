extends SceneTree
## Accounts, DP and pack purchases through the local backend (the future server's role), plus the Shop screen.
var fails := 0
const ROOT := "user://test_accounts_shop"

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

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
	root.size = Vector2i(800, 600)
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
		await process_frame
	wipe(ROOT)
	var session := root.get_node("Session")
	session.use_root(ROOT)
	var backend: LocalShopBackend = session.backend
	var db: CardDB = session.db
	var player: String = session.account_id()
	check(session.accounts().size() == 1 and player == "player", "first run creates the Player account")
	var profile: Dictionary = backend.get_profile(player)
	check(profile.ok and profile.account.dp == 2450, "new account starts with the catalog's starting DP")
	check(Collection.active_path() == backend.store.collection_path(player), "collection follows the signed-in account")
	check(Deck.active_working_path() == backend.store.deck_path(player), "working deck follows the signed-in account")
	var start := Collection.load_default(db)
	check(not start.counts.is_empty(), "new account owns the starter collection")
	var catalog: Dictionary = backend.get_catalog()
	check(catalog.ok and catalog.products.size() == 5, "catalog lists the five packs")
	# RITUAL & FUSION: card 1 a Fusion monster, 2-3 its materials, 4 a Ritual monster, 5 its Ritual Spell.
	var fusions_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fusions.json"))
	var ritual_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/effects/batch7.json"))
	var fusion_sets: Array = backend.pools["rf1_fusion_sets"]
	var ritual_sets: Array = backend.pools["rf1_ritual_sets"]
	check(fusion_sets.size() == 17 and ritual_sets.size() == 12, "Ritual & Fusion has 17 Fusion sets and 12 Ritual sets")
	check(fusion_sets.all(func(s): return s.size() == 3 and DeckRules.belongs_in_extra(db, s[0]) and fusions_data.get(db.card_name(s[0]), []) == [db.card_name(s[1]), db.card_name(s[2])]), "each Fusion set is the Fusion monster and the two materials its text names")
	check(ritual_sets.all(func(s): return s.size() == 2 and int(db.card(s[0]).category) == 3 and str(ritual_data[db.card_name(s[1])].fx[0].do[0].monster) == db.card_name(s[0])), "each Ritual set is a Ritual monster and the Ritual Spell that summons it")
	var rf_rng := RandomNumberGenerator.new()
	rf_rng.seed = 5
	var rf_pack: Dictionary = backend._product("pack_ritual_fusion").contents
	var rf_ok := true
	for k in 200:
		var cards: Array = PackOpener.roll(rf_pack, backend.pools, rf_rng).map(func(p): return int(p.index))
		var fusion_hit: Array = fusion_sets.filter(func(s): return s == cards.slice(0, 3))
		var ritual_hit: Array = ritual_sets.filter(func(s): return s == cards.slice(3, 5))
		if cards.size() != 5 or fusion_hit.size() != 1 or ritual_hit.size() != 1:
			rf_ok = false
	check(rf_ok, "every Ritual & Fusion pack is Fusion, its 2 materials, a Ritual monster and its spell, in that order")
	var rf_listing: Dictionary = backend.get_product_contents("pack_ritual_fusion")
	var rf_labels: Array = rf_listing.sections.map(func(x): return x.label)
	check(rf_listing.ok and rf_labels == ["ULTRA RARE", "FUSION SETS", "RITUAL SETS"] and rf_listing.sections[0].cards.size() == 11 and rf_listing.sections[1].cards.size() == 42 and rf_listing.sections[2].cards.size() == 22, "Ritual & Fusion card list: ultra rare sets, then Fusion sets, then Ritual sets (%s)" % str(rf_labels))
	var rare_names: Array = rf_listing.sections[0].cards.map(func(i): return db.card_name(i))
	for n in ["Zera The Mant", "Zera Ritual", "Gaia the Dragon Champion", "Gaia The Fierce Knight", "Curse of Dragon", "Thousand Dragon", "Time Wizard", "Baby Dragon", "Labyrinth Tank", "Giga-Tech Wolf", "Cannon Soldier"]:
		check(rare_names.has(n), "%s shows as ultra rare in Ritual & Fusion" % n)
	# Ultra rare sets are rarer: weight 0.25 against 1 for a normal set.
	var rare_fusion := 0
	var rare_ritual := 0
	var gold_ok := true
	rf_rng.seed = 21
	for k in 4000:
		var pulls: Array = PackOpener.roll(rf_pack, backend.pools, rf_rng)
		if pulls[0].rarity == "ultra_rare": rare_fusion += 1
		if pulls[3].rarity == "ultra_rare": rare_ritual += 1
		for p in pulls:
			if (p.rarity == "ultra_rare") != rare_names.has(db.card_name(int(p.index))):
				gold_ok = false
	check(gold_ok, "every card of an ultra rare set (and only those) is marked ultra rare")
	var fusion_rate := 100.0 * rare_fusion / 4000.0
	var ritual_rate := 100.0 * rare_ritual / 4000.0
	check(fusion_rate > 4.0 and fusion_rate < 6.3, "an ultra rare Fusion set comes in about 5.1%% of packs (%.2f%%)" % fusion_rate)
	check(ritual_rate > 1.5 and ritual_rate < 3.0, "the Zera set comes in about 2.2%% of packs (%.2f%%)" % ritual_rate)
	var rf_capped := {}
	for c in fusion_sets[0]: rf_capped[c] = Collection.MAX_OWNED
	rf_capped[fusion_sets[1][1]] = Collection.MAX_OWNED
	var only_open := true
	for k in 100:
		var pulled: Array = PackOpener.roll(rf_pack, backend.pools, rf_rng, rf_capped).map(func(p): return int(p.index))
		if pulled.has(fusion_sets[0][0]) or pulled.has(fusion_sets[1][1]):
			only_open = false
	check(only_open, "maxed sets are skipped and maxed cards are left out of a set")
	var st_ultra: Array = backend.pools["st1_ultra"]
	var st: Array = backend.pools["st1_common"] + st_ultra
	var st_tiers := PackOpener.card_tiers()
	check(st.size() == 75 and st.all(func(i): return db.card(i).type in ["spell", "trap"] and int(st_tiers.get(int(db.card(i).number), -1)) == 1), "Spells & Traps 1 holds every Tier 1 Spell and Trap")
	var st_names: Array = st_ultra.map(func(i): return db.card_name(i))
	check(st_names.size() == 5 and st_names.has("De-Spell") and st_names.has("The Flute of Summoning Dragon") and st_names.has("Waboku") and st_names.has("Fake Trap") and st_names.has("Stim-Pack"), "Spells & Traps 1 ultra rares are the five chosen cards")
	var st_listing: Dictionary = backend.get_product_contents("pack_spells_traps_1")
	check(st_listing.sections[0].label == "ULTRA RARE" and st_listing.sections[0].cards.size() == 5 and absf(st_listing.sections[0].chance - 500.0 / 75.0) < 0.01, "Spells & Traps 1 card list shows the 5 ultra rares at their real share (5 of 75 cards)")
	# Equal odds: an ultra rare here is as likely as any common card.
	var st_pack: Dictionary = backend._product("pack_spells_traps_1").contents
	var st_rng := RandomNumberGenerator.new()
	st_rng.seed = 11
	var hits := {}
	var st_ultra_pulls := 0
	var st_pulls := 0
	for k in 4000:
		for pull in PackOpener.roll(st_pack, backend.pools, st_rng):
			hits[int(pull.index)] = int(hits.get(int(pull.index), 0)) + 1
			st_pulls += 1
			if pull.rarity == "ultra_rare":
				st_ultra_pulls += 1
	var st_share := 100.0 * st_ultra_pulls / st_pulls
	check(st_share > 6.0 and st_share < 7.4, "Spells & Traps 1 ultra rares come up at the same rate as any card (%.2f%% for 5 of 75 cards)" % st_share)
	var per_card := float(st_pulls) / 75.0
	check(st_ultra.all(func(i): return absf(hits.get(i, 0) - per_card) < per_card * 0.15), "each Spells & Traps 1 ultra rare is as common as an average card")
	check(catalog.products.all(func(p): return not p.has("contents")), "pack contents never leave the backend")
	# Purchase
	backend.rng.seed = 1234
	var bought: Dictionary = await backend.purchase(player, "pack_monsters_1")
	check(bought.ok and bought.balance == 2300, "buying a pack charges its price")
	var indices: Array = bought.cards.map(func(c): return int(c.index))
	check(indices.size() == 5, "a pack gives 5 cards")
	var unique := {}
	for i in indices: unique[i] = true
	check(unique.size() == 5, "a pack's cards are all different")
	var pool := start.pool()
	var m1_pool: Array = backend.pools["m1_common"] + backend.pools["m1_ultra"]
	check(indices.all(func(i): return m1_pool.has(i)), "cards come from the pack's pools")
	check(bought.cards.all(func(c): return c.rare == (c.rarity == "ultra_rare")), "only ultra rares get the golden reveal")
	var after := Collection.load_default(db)
	check(indices.all(func(i): return after.owned(i) == start.owned(i) + 1), "bought cards are saved to the account's collection")
	check(bought.cards.all(func(c): return c.new == (start.owned(int(c.index)) == 0)), "NEW marks cards not owned before")
	check(FileAccess.get_file_as_string(backend.store.purchases_path(player)).contains("pack_monsters_1"), "purchase is logged")
	var reloaded := LocalShopBackend.new(db, ROOT)
	check(reloaded.get_profile(player).account.dp == 2300, "balance persists")
	# Same seed, same cards: the backend owns the randomness.
	var a := LocalShopBackend.new(db, ROOT)
	var b := LocalShopBackend.new(db, ROOT)
	a.rng.seed = 99
	b.rng.seed = 99
	var pack: Dictionary = a._product("pack_monsters_2").contents        # the whole Card List pool
	check(PackOpener.roll(pack, a.pools, a.rng) == PackOpener.roll(pack, b.pools, b.rng), "seeded rolls repeat")
	# MONSTERS 1: level 1-4 Normal/Effect monsters, plus a few ultra rares at 1% per card.
	var commons: Array = backend.pools["m1_common"]
	var ultras: Array = backend.pools["m1_ultra"]
	var tier_of := PackOpener.card_tiers()
	var tier := func(i): return int(tier_of.get(int(db.card(i).number), -1))
	check(commons.size() > 250 and commons.all(func(i): return db.is_monster(i) and int(db.card(i).category) in [0, 1] and tier.call(i) == 1), "MONSTERS 1 commons are the Tier 1 Normal/Effect monsters (%d)" % commons.size())
	check(ultras.all(func(i): return tier.call(i) == 1), "MONSTERS 1 ultra rares are Tier 1 too")
	var banned := ["Krokodilus", "Kaminarikozou", "Kamakiriman", "Key Mace #2", "Kairyu-Shin", "Kageningen"]
	check(commons.all(func(i): return not banned.has(db.card_name(i)) and not db.card_name(i).ends_with(" Token")), "MONSTERS 1 has no tokens and none of the removed cards")
	var ultra_names: Array = ultras.map(func(i): return db.card_name(i))
	check(ultras.size() == 9 and ultra_names.has("Dark Magician") and ultra_names.has("Red-Eyes B. Dragon") and not ultra_names.has("Jinzo"), "MONSTERS 1 ultra rares are the chosen high-ATK monsters")
	check(commons.all(func(i): return not ultra_names.has(db.card_name(i))), "an ultra rare is never also a common")
	var m1: Dictionary = a._product("pack_monsters_1").contents
	var drawn := 0
	var ultra_count := 0
	a.rng.seed = 7
	for k in 3000:
		for pull in PackOpener.roll(m1, a.pools, a.rng):
			drawn += 1
			if pull.rarity == "ultra_rare":
				ultra_count += 1
				check(ultras.has(int(pull.index)), "an ultra rare pull comes from the ultra pool")
	var rate := 100.0 * ultra_count / drawn
	check(rate > 1.6 and rate < 2.4, "ultra rares drop about 2%% per card (%.2f%% of %d)" % [rate, drawn])
	var listing: Dictionary = backend.get_product_contents("pack_monsters_1")
	check(listing.ok and listing.sections.size() == 2 and listing.sections[0].label == "ULTRA RARE" and listing.sections[1].label == "COMMON", "contents list ultra rares first, then commons")
	check(is_equal_approx(listing.sections[0].chance, 2.0) and is_equal_approx(listing.sections[1].chance, 98.0), "contents show the chance per card")
	check(listing.sections[0].cards.size() == ultras.size() and listing.sections[1].cards.size() == commons.size(), "contents list every card the pack can give")
	check(backend.get_product_contents("nope").error == "unknown_product", "unknown product has no contents")
	# Inventory cap: a card with 3 copies is never rolled again; versions count separately.
	var full := {}
	for i in pool.slice(0, 340): full[i] = Collection.MAX_OWNED
	var capped := PackOpener.roll(pack, a.pools, a.rng, full)
	check(capped.size() == 5 and capped.all(func(p): return not full.has(int(p.index))), "packs never roll a card the account already has 3 of")
	var all_ultra := {}
	for i in ultras: all_ultra[i] = Collection.MAX_OWNED
	check(PackOpener.roll(m1, a.pools, a.rng, all_ultra).all(func(p): return p.rarity == "common"), "with every ultra rare maxed, its chance goes to the commons")
	var nearly := {}
	for i in pool.slice(0, pool.size() - 2): nearly[i] = Collection.MAX_OWNED
	check(PackOpener.roll(pack, a.pools, a.rng, nearly).size() == 2, "a nearly complete collection gets a smaller pack")
	var kuri: Array = []
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Kuriboh" and db.is_monster(i): kuri.append(i)
	var inv := Collection.new()
	inv.db = db
	for v in kuri: inv.add(v, 5)
	check(kuri.size() >= 2 and kuri.all(func(v): return inv.owned(v) == 3), "inventory holds 3 of each Kuriboh version, never more per version")
	# Errors
	check(backend.purchase(player, "no_such_pack").error == "unknown_product", "unknown product is refused")
	check(backend.purchase("ghost", "pack_monsters_1").error == "unknown_account", "unknown account is refused")
	var poor: Dictionary = backend.store.profile(player)
	poor.dp = 100
	backend.store.save_profile(poor)
	var before := Collection.load_default(db).counts.duplicate()
	var refused: Dictionary = backend.purchase(player, "pack_monsters_2")
	check(not refused.ok and refused.error == "not_enough_dp" and refused.balance == 100, "not enough DP is refused")
	check(Collection.load_default(db).counts == before and backend.get_profile(player).account.dp == 100, "a refused purchase changes nothing")
	poor.dp = 2300
	backend.store.save_profile(poor)
	# Completed set: nothing left to roll -> refused, no DP charged, no crash.
	var done_collection := Collection.load_default(db)
	for i in st: done_collection.counts[i] = Collection.MAX_OWNED
	done_collection.save()
	var before_dp: int = backend.get_profile(player).account.dp
	var complete: Dictionary = await backend.purchase(player, "pack_spells_traps_1")
	check(not complete.ok and complete.error == "set_complete" and backend.get_profile(player).account.dp == before_dp, "a completed set refuses the purchase and charges nothing")
	check(Collection.load_default(db).counts == done_collection.counts, "a refused purchase leaves the collection alone")
	done_collection.counts[st[0]] = 2
	done_collection.save()
	var last: Dictionary = await backend.purchase(player, "pack_spells_traps_1")
	check(last.ok and last.cards.size() == 1, "with one card left the pack holds just that card")
	after.save()                                   # put Player's collection and DP back for the checks below
	var restore: Dictionary = backend.store.profile(player)
	restore.dp = 2300
	backend.store.save_profile(restore)
	# Second account: own DP, collection and deck.
	var rival: String = session.create_account("Rival")
	check(rival == "rival" and session.account_id() == rival, "creating an account signs into it")
	check(backend.get_profile(rival).account.dp == 2450, "second account has its own DP")
	var rival_cards := Collection.load_default(db)
	var poly := -1
	var little_d := -1
	for i in range(1, db.cards.size()):
		if db.card_name(i) == "Polymerization" and poly < 0: poly = i
		if db.card_name(i) == "Little D" and little_d < 0: little_d = i
	check(rival_cards.counts.size() == 2 and rival_cards.owned(poly) == 3 and rival_cards.owned(little_d) == 3, "a new account owns exactly 3 Polymerization and 3 Little D")
	var rival_deck := Deck.load_working(db)
	check(rival_deck.main.size() == 6 and rival_deck.main.count(poly) == 3 and rival_deck.main.count(little_d) == 3 and rival_deck.extra.is_empty() and rival_deck.side.is_empty(), "a new account's deck is those 6 cards")
	check(rival_cards.counts == start.counts and rival_cards.counts != after.counts, "second account starts from the plain starter, without Player's purchases")
	check(Deck.active_working_path() != backend.store.deck_path(player), "second account has its own deck file")
	backend.purchase(rival, "pack_monsters_3")
	check(backend.get_profile(player).account.dp == 2300, "buying on one account leaves the other alone")
	check(session.create_account("   ") == "", "blank names are refused")
	check(session.create_account("Rival") == "rival_2", "duplicate names get a distinct id")
	session.switch_account(player)
	check(Collection.load_default(db).counts == after.counts, "switching back restores Player's collection")
	# Shop screen
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	shell.current.main_menu.chosen.emit(3)
	await process_frame
	var shop = shell.current
	check(shop.balance.text == "2,300", "Shop shows the account's DP (%s)" % shop.balance.text)
	check(shop.products.size() == 5 and shop.price_buttons.size() == 5, "Shop lists the backend's packs with buy buttons")
	await shop.buy(1)
	check(shop.last_result.get("ok", false) and shop.balance.text == "2,150", "buying from the Shop updates the balance")
	var opening: PackOpening = shop.reveal
	check(opening != null and not opening.done, "buying starts the pack opening animation")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	shop._unhandled_key_input(esc)
	check(shop.reveal == opening and opening.speed > 1.0, "Escape during the animation fast-forwards instead of closing")
	var deadline := Time.get_ticks_msec() + 10000
	while not opening.done and Time.get_ticks_msec() < deadline:
		await process_frame
	check(opening.done and opening.card_nodes.size() == 5, "pack opening deals the five cards")
	var back: Texture2D = load(PackOpening.CARD_BACK)
	check(opening.faces.all(func(f): return f.texture != back), "every card ends face up")
	check(opening.cards.all(func(c): return c.rare == (c.rarity == "ultra_rare")), "the pack opening uses the backend's rarity for the golden reveal")
	check(opening.new_tags.size() == opening.cards.filter(func(c): return c.new).size(), "NEW! appears on each new card")
	check(opening.ok_button != null, "OK appears when the reveal is finished")
	shop._unhandled_key_input(esc)
	check(shop.reveal == null and shell.current == shop, "Escape closes the finished pack opening before leaving the Shop")
	# Card list of the selected pack
	shop.select_product(0)
	await shop.show_contents()
	var view: PackContents = shop.contents_view
	check(view != null and view.sections.size() == 2, "CARD LIST opens the selected pack's contents")
	check(view.slots.size() == ultras.size() + commons.size(), "every card of the pack is shown")
	check(view.preview.texture != null and view.preview_name.text != "", "the first card is previewed large")
	shop._unhandled_key_input(esc)
	check(shop.contents_view == null and shell.current == shop, "Escape closes the card list before leaving the Shop")
	var rich: Dictionary = backend.store.profile(player)
	rich.dp = 140
	backend.store.save_profile(rich)
	await shop.refresh_balance()
	check(shop.price_buttons.all(func(p): return p.disabled), "prices are disabled when the balance is too low")
	shell.queue_free()
	await process_frame
	wipe(ROOT)
	print("accounts/shop tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
