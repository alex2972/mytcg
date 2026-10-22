extends SceneTree
## Phase 3: shop, collection and deck on the server (through RPC), card numbers on the wire, validation,
## isolation between accounts, persistence across restarts, idempotent requests, the client Session path.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func shop(c: OnlineClient, method: String, args := {}) -> Dictionary:
	return await c.request("shop", {"method": method, "args": args})

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	var db := CardDB.load_default()
	# Collection format 2 (numbers) round trip, and format 1 (indices) still read.
	var tmp := "user://test_online_data_fmt.json"
	var col := Collection.new()
	col.db = db
	col.counts = {Collection.index_of_number(db, 34): 2, Collection.index_of_number(db, 1003): 3}
	col.save(tmp)
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	check(int(parsed.get("format", 0)) == 2 and parsed["cards"].has("34"), "collections are saved keyed by card number")
	check(Collection.load_default(db, tmp).counts == col.counts, "format 2 loads back the same counts")
	AccountStore.write_json(tmp, {str(Collection.index_of_number(db, 34)): 1})
	check(Collection.load_default(db, tmp).owned(Collection.index_of_number(db, 34)) == 1, "old index-keyed collections are still read")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	var h := OnlineHarness.new()
	check(h.start(self, "data"), "server listens")
	var a: OnlineClient = await h.client("a")
	var b: OnlineClient = await h.client("b")
	await h.login(a, "Alice")
	await h.login(b, "Bob")
	var cat: Dictionary = await shop(a, "get_catalog")
	check(cat.get("ok", false) and cat["products"].size() == 5, "catalog over RPC")
	var contents: Dictionary = await shop(a, "get_product_contents", {"product_id": "pack_monsters_1"})
	check(contents.get("ok", false) and contents["sections"][0]["cards"].has(34), "pack contents are card numbers (Dark Magician = 34)")
	var deck0: Dictionary = await shop(a, "get_deck")
	check(deck0.get("ok", false) and deck0["deck"]["main"].size() == 6 and deck0["deck"]["main"].count(1003) == 3, "a new online account's deck is the 6 starter cards (Polymerization = 1003)")
	var col0: Dictionary = await shop(a, "get_collection")
	check(col0.get("ok", false) and col0["cards"].size() == 2, "a new online account owns only the starter cards")
	var buy: Dictionary = await shop(a, "purchase", {"product_id": "pack_monsters_1"})
	check(buy.get("ok", false) and int(buy["balance"]) == 2300 and buy["cards"].size() == 5, "buying a pack over RPC")
	check(buy["cards"].all(func(c): return c.has("number") and not c.has("index")), "pulled cards travel as card numbers")
	var col1: Dictionary = await shop(a, "get_collection")
	var got := 0
	for c in buy["cards"]:
		if col1["cards"].has(str(c["number"])):
			got += 1
	check(got == 5, "the pulled cards are in the server collection")
	var bobs: Dictionary = await shop(b, "get_collection")
	check(bobs["cards"].size() == 2 and int((await shop(b, "get_profile"))["account"]["dp"]) == 2450, "another account sees none of it")
	# Deck saving with validation
	var first_pull := int(buy["cards"][0]["number"])
	var good := {"main": deck0["deck"]["main"] + [first_pull], "extra": [], "side": []}
	var saved: Dictionary = await shop(a, "save_deck", {"deck": good})
	check(saved.get("ok", false), "saving a deck of owned cards")
	check((await shop(a, "get_deck"))["deck"]["main"].size() == 7, "the saved deck comes back")
	var dm := 34
	var unowned: Dictionary = await shop(a, "save_deck", {"deck": {"main": [dm], "extra": [], "side": []}})
	check(unowned.get("error", "") == "deck_invalid" or col1["cards"].has(str(dm)), "a card you do not own cannot be saved in a deck")
	var fusion_main: Dictionary = await shop(a, "save_deck", {"deck": {"main": [Collection.index_of_number(db, 1003) * 0 + int(db.cards[_first_fusion(db)]["number"])], "extra": [], "side": []}})
	check(fusion_main.get("error", "") == "deck_invalid", "a Fusion monster in the main deck is refused")
	var four: Dictionary = await shop(a, "save_deck", {"deck": {"main": [1003, 1003, 1003, 1003], "extra": [], "side": []}})
	check(four.get("error", "") == "deck_invalid", "more copies than owned / allowed are refused")
	var junk: Dictionary = await shop(a, "save_deck", {"deck": {"main": ["x"], "extra": [], "side": []}})
	check(junk.get("error", "") == "invalid_args", "malformed deck data is refused")
	var unknown_card: Dictionary = await shop(a, "save_deck", {"deck": {"main": [65000], "extra": [], "side": []}})
	check(unknown_card.get("error", "") == "deck_invalid", "unknown card numbers are refused")
	var bad_method: Dictionary = await shop(a, "give_me_cards")
	check(bad_method.get("error", "") == "invalid_args", "unknown shop methods are refused")
	# Refusals
	var store: AccountStore = h.server.services["shop_backend"].store
	var alice := h.server.account_of(h.server.services["auth"].peer_of(store.find_by_name("Alice")))
	var p := store.profile(alice)
	p["dp"] = 100
	store.save_profile(p)
	var poor: Dictionary = await shop(a, "purchase", {"product_id": "pack_monsters_1"})
	check(poor.get("error", "") == "not_enough_dp" and int(poor.get("balance", -1)) == 100, "not enough DP is refused online")
	p["dp"] = 5000
	store.save_profile(p)
	# Idempotency: the same request id is answered once.
	a.net.c2s.rpc_id(1, "shop", 9001, {"method": "purchase", "args": {"product_id": "pack_spells_traps_1"}})
	a.net.c2s.rpc_id(1, "shop", 9001, {"method": "purchase", "args": {"product_id": "pack_spells_traps_1"}})
	await h.wait_until(func(): return a._replies.has(9001), 3.0)
	await h.frames(10)
	check(int(store.profile(alice)["dp"]) == 4850, "a repeated request id does not buy twice (dp %d)" % int(store.profile(alice)["dp"]))
	# Persistence across a restart
	var dir := h.data_dir
	h.server.stop()
	h.server.queue_free()
	await process_frame
	var s2 := GameServer.new()
	s2.name = "Server_data_restart"
	root.add_child(s2)
	s2.setup(dir, {"pbkdf2_iterations": 200})
	h.port = OnlineHarness.free_port()
	h.url = "ws://127.0.0.1:%d" % h.port
	s2.listen(h.port)
	h.server = s2
	var a2: OnlineClient = await h.client("a2")
	await h.login(a2, "Alice")
	var col2: Dictionary = await shop(a2, "get_collection")
	check(col2.get("ok", false) and col2["cards"].size() >= 7, "collections survive a restart")
	check((await shop(a2, "get_deck"))["deck"]["main"].size() == 7, "decks survive a restart")
	# Client Session path
	var session := root.get_node("Session")
	session.use_root("user://test_online_data_local")
	session.online_cfg_path = "user://test_online_data_local/online.cfg"
	var go: Dictionary = await session.go_online(h.url, "Carol", "", true)
	check(go.get("ok", false), "Session online")
	var sc: Collection = await session.load_collection()
	check(sc.counts.size() == 2 and sc.owned(Collection.index_of_number(db, 1003)) == 3, "Session.load_collection reads the server collection")
	var sd: Deck = await session.load_deck()
	check(sd.main.size() == 6, "Session.load_deck reads the server deck")
	var bought: Dictionary = await session.backend.purchase("", "pack_monsters_1")
	check(bought.get("ok", false) and bought["cards"].all(func(c): return int(c["index"]) > 0 and str(c["name"]) != ""), "remote purchases come back with local card indices and names")
	sd.main.append(int(bought["cards"][0]["index"]))
	var ss: Dictionary = await session.save_deck(sd)
	check(ss.get("ok", false) and (await session.load_deck()).main.size() == 7, "Session.save_deck stores the deck on the server")
	var rc: Dictionary = await session.backend.get_product_contents("pack_monsters_1")
	check(rc.get("ok", false) and rc["sections"][0]["cards"].has(Collection.index_of_number(db, 34)), "remote pack contents come back as local indices")
	await session.logout()
	await h.stop()
	OnlineHarness.wipe("user://test_online_data_local")
	print("online data tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)

func _first_fusion(db: CardDB) -> int:
	for i in range(1, db.cards.size()):
		if DeckRules.belongs_in_extra(db, i):
			return i
	return 1
