extends SceneTree
## Phase 7: garbage, oversized and wrong-typed requests to every endpoint (logged out and logged in,
## inside and outside a duel). The server must keep answering, never crash or raise script errors,
## and strike/kick abusive connections.
var fails := 0
var rng := RandomNumberGenerator.new()

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func junk(depth := 0):
	match rng.randi_range(0, 11 if depth < 3 else 7):
		0: return null
		1: return rng.randi_range(-2147483648, 2147483647)
		2: return rng.randf_range(-1e9, 1e9)
		3: return rng.randi_range(0, 1) == 1
		4: return ""
		5: return "x".repeat(rng.randi_range(1, 5000))
		6: return ["pass", "rock", "summon", "ranked", "pack_monsters_1", "Joey", "admin", "../../etc", "\u0000", "🙂"][rng.randi_range(0, 9)]
		7: return rng.randi_range(-5, 200)
		8:
			var a := []
			for i in rng.randi_range(0, 6):
				a.append(junk(depth + 1))
			return a
		_:
			var d := {}
			for i in rng.randi_range(0, 6):
				d[["uid", "idx", "hand", "first", "mode", "name", "password", "token", "product_id", "method", "args", "deck", "answer", "kind", "room_id", "limit", "offset", "tributes", "zone", "target", "discards", "x"][rng.randi_range(0, 21)]] = junk(depth + 1)
			return d

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	rng.seed = 12345
	var h := OnlineHarness.new()
	check(h.start(self, "fuzz", {"dev": true, "rate_per_second": 100000.0, "rate_burst": 100000.0, "max_strikes": 1000000, "idle_timeout": 100000.0}), "server listens")
	var kinds: Array = h.server.handlers.keys()
	kinds.append_array(["", "x".repeat(100), "c2s", "reply", "kick"])
	# Logged out
	var a: OnlineClient = await h.client("a")
	for i in 600:
		a.net.c2s.rpc_id(1, kinds[rng.randi_range(0, kinds.size() - 1)], rng.randi_range(0, 3), junk() if rng.randi_range(0, 3) > 0 else {})
		if i % 50 == 0:
			await process_frame
	var alive: Dictionary = await a.request("ping")
	check(alive.get("ok", false), "the server answers after 600 junk requests from a logged-out client")
	# Logged in, in a duel (a fresh connection: the junk above may have logged `a` into random accounts)
	a = await h.client("a2")
	await h.login(a, "Fuzzer")
	var shop: LocalShopBackend = h.server.services["shop_backend"]
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var d := Deck.new()
	d.main = presets["cpu_003"]["main"].map(func(x): return int(x))
	var c := Collection.load_default(h.server.db, shop.store.collection_path("fuzzer"))
	for k in d.main:
		c.counts[k] = mini(3, d.copies(k))
	c.save(shop.store.collection_path("fuzzer"))
	d.save_working(h.server.db, shop.store.deck_path("fuzzer"))
	var duel: Dictionary = await a.request("dev_start_bot_duel", {})
	check(duel.get("ok", false), "a duel starts for the fuzzer: %s" % str(duel))
	var room_id: String = duel.get("room_id", "")
	var intents := ["summon", "set_spell_trap", "change_position", "activate", "attack", "to_battle", "to_main2", "end_turn", "respond", "janken_pick", "choose_order", "resync", "x"]
	for i in 1500:
		var roll := rng.randi_range(0, 9)
		if roll < 6:
			a.send("room_intent", {"room_id": room_id if rng.randi_range(0, 4) > 0 else junk(), "kind": intents[rng.randi_range(0, intents.size() - 1)], "args": junk() if rng.randi_range(0, 2) > 0 else {}})
		elif roll < 8:
			a.send("shop", {"method": ["purchase", "save_deck", "get_deck", "get_product_contents", "x"][rng.randi_range(0, 4)], "args": junk()})
		else:
			a.net.c2s.rpc_id(1, kinds[rng.randi_range(0, kinds.size() - 1)], 0, junk())
		if i % 50 == 0:
			await process_frame
	await h.frames(30)
	var still: Dictionary = await a.request("server_status")
	check(still.get("ok", false), "the server answers after 1500 junk requests inside a duel")
	# A second, well-behaved client is unaffected.
	var b: OnlineClient = await h.client("b")
	var reg: Dictionary = await h.login(b, "Normal")
	check(reg.get("ok", false), "other players can still register")
	check((await b.request("shop", {"method": "get_catalog", "args": {}})).get("ok", false), "and use the shop")
	await h.stop()
	# Strikes: a server with normal limits kicks a junk sender.
	var h2 := OnlineHarness.new()
	h2.start(self, "fuzz2", {"max_strikes": 10})
	var e: OnlineClient = await h2.client("e")
	for i in 30:
		e.net.c2s.rpc_id(1, junk(), junk(), junk())
	check(await h2.wait_until(func(): return e.state == "offline", 3.0), "a client that keeps sending junk is kicked")
	await h2.stop()
	print("online fuzz tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
