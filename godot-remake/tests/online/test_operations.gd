extends SceneTree
## Phase 7: TLS (wss://), damaged save files moved aside, the account index rebuilt from folders,
## daily backups with pruning, and a shutdown that ends running duels as a no-contest.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	# 1. TLS with a self-signed certificate.
	var crypto := Crypto.new()
	var key := crypto.generate_rsa(2048)
	var cert := crypto.generate_self_signed_certificate(key, "CN=localhost,O=Test,C=US")
	OnlineHarness.wipe("user://test_online_tls")
	var s := GameServer.new()
	s.name = "Server_tls"
	root.add_child(s)
	s.setup("user://test_online_tls", {"pbkdf2_iterations": 200})
	var port := OnlineHarness.free_port()
	check(s.listen(port, TLSOptions.server(key, cert)) == OK, "the server listens with TLS")
	var c := OnlineClient.new()
	c.name = "Client_tls"
	c.tls_options = TLSOptions.client_unsafe()
	root.add_child(c)
	var hello: Dictionary = await c.connect_and_hello("wss://127.0.0.1:%d" % port)
	check(hello.get("ok", false), "a client connects over wss:// and passes hello")
	var plain := OnlineClient.new()
	plain.name = "Client_plain"
	root.add_child(plain)
	var refused: Dictionary = await plain.connect_and_hello("ws://127.0.0.1:%d" % port, 3.0)
	check(not refused.get("ok", false), "plain ws:// is refused by a TLS server")
	c.close()
	plain.close()
	c.queue_free()
	plain.queue_free()
	s.stop()
	s.queue_free()
	await process_frame
	OnlineHarness.wipe("user://test_online_tls")
	# 2. Damaged files and the index.
	var h := OnlineHarness.new()
	h.start(self, "ops", {"dev": true})
	var a: OnlineClient = await h.client("a")
	await h.login(a, "Alpha")
	var b: OnlineClient = await h.client("b")
	await h.login(b, "Bravo")
	var dir := h.data_dir
	check(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir + "/backups/" + Time.get_date_string_from_unix_time(int(h.server.now())))), "a backup is made at startup")
	# Running duel for the shutdown check.
	var shop: LocalShopBackend = h.server.services["shop_backend"]
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var d := Deck.new()
	d.main = presets["cpu_003"]["main"].map(func(x): return int(x))
	var col := Collection.load_default(h.server.db, shop.store.collection_path("alpha"))
	for k in d.main:
		col.counts[k] = mini(3, d.copies(k))
	col.save(shop.store.collection_path("alpha"))
	d.save_working(h.server.db, shop.store.deck_path("alpha"))
	var duel: Dictionary = await a.request("dev_start_bot_duel", {})
	var room: DuelRoom = h.server.services["rooms"].rooms[duel["room_id"]]
	var got := []
	a.pushed.connect(func(k, p): got.append(k))
	var rating_before := int(shop.store.profile("alpha")["rating"])
	h.server.stop()
	check(room.state == "finished" and room.result["reason"] == "server_shutdown", "shutdown ends running duels")
	check(int(shop.store.profile("alpha")["rating"]) == rating_before and int(shop.store.profile("alpha")["losses"]) == 0, "a shutdown is a no-contest: no rating change, no loss")
	await h.frames(5)
	h.server.queue_free()
	await process_frame
	# Damage some files while the server is down.
	var f := FileAccess.open(dir + "/accounts/bravo/collection.json", FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	f = FileAccess.open(dir + "/accounts/index.json", FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	var s2 := GameServer.new()
	s2.name = "Server_ops_restart"
	root.add_child(s2)
	s2.setup(dir, {"pbkdf2_iterations": 200})
	h.port = OnlineHarness.free_port()
	h.url = "ws://127.0.0.1:%d" % h.port
	s2.listen(h.port)
	h.server = s2
	var report: Dictionary = s2.services["maintenance"].report
	var moved := DirAccess.get_files_at(ProjectSettings.globalize_path(dir + "/accounts/bravo"))
	check(Array(moved).any(func(n): return n.begins_with("collection.json.corrupt-")), "the damaged collection is kept aside, not overwritten")
	check(Array(DirAccess.get_files_at(ProjectSettings.globalize_path(dir + "/accounts"))).any(func(n): return n.begins_with("index.json.corrupt-")), "the damaged index is kept aside")
	check(s2.services["auth"].store.find_by_name("Alpha") == "alpha" and s2.services["auth"].store.find_by_name("Bravo") == "bravo", "the index is rebuilt from the account folders (%s)" % str(report))
	var c2: OnlineClient = await h.client("c2")
	var back: Dictionary = await c2.request("login", {"name": "Bravo", "password": ""})
	check(back.get("ok", false), "accounts still log in after the repair")
	# 3. Backups are pruned to the newest N.
	var maint: ServerMaintenance = s2.services["maintenance"]
	for day in ["2020-01-01", "2020-01-02", "2020-01-03", "2020-01-04", "2020-01-05", "2020-01-06", "2020-01-07", "2020-01-08"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir + "/backups/" + day))
	maint.prune(7)
	var kept := DirAccess.get_directories_at(ProjectSettings.globalize_path(dir + "/backups"))
	check(kept.size() == 7 and not Array(kept).has("2020-01-01") and not Array(kept).has("2020-01-02"), "only the newest 7 backups are kept (%s)" % str(kept))
	await h.stop()
	print("online operations tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
