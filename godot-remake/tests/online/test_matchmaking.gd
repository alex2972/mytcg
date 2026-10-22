extends SceneTree
## Phase 6: Elo, queue windows, ranked and casual matchmaking over the network, the ranked deck rules,
## rewards, records, the leaderboard, the CPU fallback, and persistence of ratings.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

## Gives `account` a legal 40-card ranked deck (and owns its cards) on the server.
func give_ranked_deck(h: OnlineHarness, account_name: String) -> void:
	var shop: LocalShopBackend = h.server.services["shop_backend"]
	var db := h.server.db
	var id := shop.store.find_by_name(account_name)
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	for k in presets:
		var d := Deck.new()
		d.main = presets[k]["main"].map(func(x): return int(x))
		d.extra = presets[k]["extra"].map(func(x): return int(x))
		if DeckRules.ranked_problem(d, db) == "" and d.main.size() <= 60:
			var c := Collection.load_default(db, shop.store.collection_path(id))
			for i in d.main + d.extra:
				c.counts[i] = mini(3, d.copies(i))
			c.save(shop.store.collection_path(id))
			d.save_working(db, shop.store.deck_path(id))
			return
	print("   no ranked-legal preset deck found")

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	# Elo
	check(is_equal_approx(RankedService.expected(1500, 1500), 0.5), "equal ratings expect 50%")
	check(RankedService.elo(1500, 1500, 1.0, 32, 100) == 1516 and RankedService.elo(1500, 1500, 0.0, 32, 100) == 1484, "an even game moves 16 points with K=32")
	check(RankedService.elo(1500, 1700, 1.0, 32, 100) == 1524, "beating a stronger player gives more (1524)")
	check(RankedService.elo(1500, 1500, 0.5, 32, 100) == 1500, "a draw between equals changes nothing")
	check(RankedService.elo(105, 105, 0.0, 40, 100) == 100, "ratings never fall below the floor")
	var h := OnlineHarness.new()
	check(h.start(self, "mm", {"casual_bot_after": 30.0, "idle_timeout": 100000.0}), "server listens")
	var mm: Matchmaker = h.server.services["matchmaker"]
	check(mm.window(0.0) == 100.0 and mm.window(10.0) == 350.0 and mm.window(1000.0) == 600.0, "the rating window widens with waiting time and is capped")
	var a: OnlineClient = await h.client("a")
	var b: OnlineClient = await h.client("b")
	await h.login(a, "Ann")
	await h.login(b, "Ben")
	var pushes_a := []
	var pushes_b := []
	a.pushed.connect(func(k, p): pushes_a.append([k, p]))
	b.pushed.connect(func(k, p): pushes_b.append([k, p]))
	# Deck rules at the queue
	var small: Dictionary = await a.request("queue_join", {"mode": "ranked"})
	check(small.get("error", "") == "deck_invalid", "a 6-card deck cannot queue for ranked")
	check((await a.request("queue_join", {"mode": "casual"})).get("error", "") == "deck_invalid", "nor for casual")
	check((await a.request("queue_join", {"mode": "silly"})).get("error", "") == "invalid_args", "unknown modes are refused")
	give_ranked_deck(h, "Ann")
	give_ranked_deck(h, "Ben")
	# Ranked: both join, they are matched, Ann surrenders.
	var ja: Dictionary = await a.request("queue_join", {"mode": "ranked"})
	check(ja.get("ok", false), "Ann joins ranked")
	check((await a.request("queue_join", {"mode": "ranked"})).get("error", "") == "in_queue", "joining twice is refused")
	var jb: Dictionary = await b.request("queue_join", {"mode": "ranked"})
	check(jb.get("ok", false), "Ben joins ranked")
	await h.wait_until(func(): return pushes_a.any(func(p): return p[0] == "room_start") and pushes_b.any(func(p): return p[0] == "room_start"), 3.0)
	var rooms: RoomManager = h.server.services["rooms"]
	var room := rooms.room_of(h.server.account_of(h.server.services["auth"].peer_of("ann")))
	check(room != null and room.mode == "ranked", "Ann and Ben are matched into a ranked room")
	var start_a: Dictionary = pushes_a.filter(func(p): return p[0] == "room_start")[0][1]
	check(start_a["opponent"]["name"] == "Ben" and not start_a["opponent"]["bot"], "Ann sees Ben as her opponent")
	check((await a.request("queue_join", {"mode": "casual"})).get("error", "") == "already_in_duel", "no queueing while in a duel")
	check((await a.request("shop", {"method": "purchase", "args": {"product_id": "pack_monsters_1"}})).get("error", "") == "busy", "no purchases or deck changes during a duel")
	var sur: Dictionary = await a.request("room_intent", {"room_id": room.id, "kind": "surrender", "args": {}})
	check(sur.get("ok", false), "Ann surrenders")
	await h.wait_until(func(): return pushes_a.any(func(p): return p[0] == "room_result") and pushes_b.any(func(p): return p[0] == "room_result"), 3.0)
	var ra: Dictionary = pushes_a.filter(func(p): return p[0] == "room_result")[0][1]
	var rb: Dictionary = pushes_b.filter(func(p): return p[0] == "room_result")[0][1]
	check(not ra["you_won"] and rb["you_won"] and ra["reason"] == "surrender", "results: Ben won by surrender")
	check(int(ra["rating_after"]) == 1480 and int(rb["rating_after"]) == 1520, "K=40 for new players: 1480 / 1520 (%s / %s)" % [ra.get("rating_after"), rb.get("rating_after")])
	check(int(ra["rating_delta"]) + int(rb["rating_delta"]) == 0, "rating changes are symmetric")
	check(int(rb["dp_reward"]) == 150 and int(ra["dp_reward"]) == 10, "ranked rewards: win 50 + first win of the day 100, loss 10")
	var sum_a: Dictionary = await a.request("account_summary")
	check(int(sum_a["account"]["losses"]) == 1 and int(sum_a["account"]["rating"]) == 1480 and int(sum_a["account"]["dp"]) == 2460, "Ann's record, rating and DP are stored")
	var board_rows: Dictionary = await a.request("leaderboard", {"limit": 10, "offset": 0})
	check(board_rows.get("ok", false) and board_rows["rows"].size() == 2 and board_rows["rows"][0]["name"] == "Ben" and int(board_rows["rows"][0]["rank"]) == 1, "the leaderboard lists Ben first")
	check(not board_rows["rows"][0].has("id"), "the leaderboard does not expose account ids")
	var my: Dictionary = await a.request("my_rank")
	check(int(my.get("rank", 0)) == 2, "Ann is rank 2")
	# A second ranked game: Ben wins again; first-win bonus is not repeated.
	pushes_a.clear()
	pushes_b.clear()
	await a.request("queue_join", {"mode": "ranked"})
	await b.request("queue_join", {"mode": "ranked"})
	await h.wait_until(func(): return pushes_a.any(func(p): return p[0] == "room_start"), 3.0)
	var room2 := rooms.room_of("ann")
	await a.request("room_intent", {"room_id": room2.id, "kind": "surrender", "args": {}})
	await h.wait_until(func(): return pushes_b.any(func(p): return p[0] == "room_result"), 3.0)
	var rb2: Dictionary = pushes_b.filter(func(p): return p[0] == "room_result")[0][1]
	check(int(rb2["dp_reward"]) == 50, "the first-win bonus is once per day")
	# Ranked window: a big rating gap is not matched at once, only after waiting.
	var store: AccountStore = h.server.services["shop_backend"].store
	var pb := store.profile("ben")
	pb["rating"] = 1900
	store.save_profile(pb)
	pushes_a.clear()
	await a.request("queue_join", {"mode": "ranked"})
	await b.request("queue_join", {"mode": "ranked"})
	await h.frames(5)
	check(rooms.room_of("ann") == null and mm.in_queue("ann") == "ranked", "a 450-point gap is not matched immediately")
	h.server.clock_offset += 20.0
	mm.tick(h.server.now())
	check(rooms.room_of("ann") != null, "after waiting long enough the window covers the gap")
	await a.request("room_intent", {"room_id": rooms.room_of("ann").id, "kind": "surrender", "args": {}})
	await h.frames(5)
	# Casual: no rating change; leaving the queue works; CPU fallback.
	pushes_a.clear()
	await a.request("queue_join", {"mode": "casual"})
	check(mm.in_queue("ann") == "casual", "Ann is in the casual queue")
	await a.request("queue_leave")
	check(mm.in_queue("ann") == "", "queue_leave removes her")
	await a.request("queue_join", {"mode": "casual"})
	h.server.clock_offset += 31.0
	mm.tick(h.server.now())
	var croom := rooms.room_of("ann")
	check(croom != null and croom.mode == "casual" and croom.seats[1]["bot"], "after 30 s in casual the CPU takes the other seat")
	var rating_before := int(store.profile("ann")["rating"])
	await a.request("room_intent", {"room_id": croom.id, "kind": "surrender", "args": {}})
	await h.frames(5)
	check(int(store.profile("ann")["rating"]) == rating_before, "casual games do not change ratings")
	# Practice: an immediate CPU duel.
	var pr: Dictionary = await a.request("queue_join", {"mode": "practice"})
	check(pr.get("ok", false) and rooms.room_of("ann") != null and rooms.room_of("ann").mode == "practice", "practice starts at once against the CPU")
	await a.request("room_intent", {"room_id": rooms.room_of("ann").id, "kind": "surrender", "args": {}})
	await h.frames(5)
	# The match log and persistence across a restart.
	var month := Time.get_date_string_from_unix_time(int(h.server.now())).left(7)
	var log_text := FileAccess.get_file_as_string(h.data_dir + "/matches/%s.jsonl" % month)
	check(log_text.count("\n") >= 5, "every finished duel is logged")
	var dir := h.data_dir
	h.server.stop()
	h.server.queue_free()
	await process_frame
	var s2 := GameServer.new()
	s2.name = "Server_mm_restart"
	root.add_child(s2)
	s2.setup(dir, {"pbkdf2_iterations": 200})
	h.port = OnlineHarness.free_port()
	h.url = "ws://127.0.0.1:%d" % h.port
	s2.listen(h.port)
	h.server = s2
	var c: OnlineClient = await h.client("c")
	await h.login(c, "Ben")
	var after: Dictionary = await c.request("account_summary")
	check(int(after["account"]["wins"]) >= 3 and int(after["account"]["rating"]) > 1500, "ratings and records survive a restart")
	await h.stop()
	print("online matchmaking tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
