extends SceneTree
## Soak test: an in-process server and K bot clients that keep queueing (ranked and casual), play their
## duels through RemoteDuel over WebSocket (janken, prompts, summons, attacks, turn ends) and queue again,
## for N minutes. Reports duels, errors, stuck rooms, rating consistency and memory.
##   godot --headless --path . -s tools/online/soak.gd -- <minutes=3> <clients=6>
var h: OnlineHarness
var stats := {"duels": 0, "ranked": 0, "casual": 0, "intents": 0, "refused": 0, "kicked": 0, "results": 0}
var errors: Array = []
var reasons := {}
var deadline := 0
var running := 0

func _initialize() -> void:
	call_deferred("run")

func give_ranked_deck(account_name: String) -> void:
	var shop: LocalShopBackend = h.server.services["shop_backend"]
	var db := h.server.db
	var id := shop.store.find_by_name(account_name)
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var legal := []
	for k in presets:
		var d := Deck.new()
		d.main = presets[k]["main"].map(func(x): return int(x))
		d.extra = presets[k]["extra"].map(func(x): return int(x))
		if DeckRules.ranked_problem(d, db) == "":
			legal.append(d)
	var deck: Deck = legal[randi() % legal.size()]
	var c := Collection.load_default(db, shop.store.collection_path(id))
	for i in deck.main + deck.extra:
		c.counts[i] = mini(3, deck.copies(i))
	c.save(shop.store.collection_path(id))
	deck.save_working(db, shop.store.deck_path(id))

func client_loop(i: int) -> void:
	running += 1
	var c: OnlineClient = await h.client("soak%d" % i)
	if c == null:
		errors.append("client %d could not connect" % i)
		running -= 1
		return
	c.request_timeout = 30.0
	var name := "Soak%d" % i
	await h.login(c, name)
	give_ranked_deck(name)
	var inbox := []
	c.pushed.connect(func(k, p): inbox.append([k, p]))
	while Time.get_ticks_msec() < deadline:
		var mode := "ranked" if i % 3 != 0 else "casual"
		var j: Dictionary = await c.request("queue_join", {"mode": mode})
		if not j.get("ok", false) and j.get("error", "") != "in_queue":
			errors.append("%s queue_join: %s" % [name, str(j)])
			await create_timer(1.0).timeout
			continue
		# Wait for a match.
		var start := {}
		while start.is_empty() and Time.get_ticks_msec() < deadline:
			for m in inbox:
				if m[0] == "room_start":
					start = m[1]
			if start.is_empty():
				await process_frame
		if start.is_empty():
			await c.request("queue_leave")
			break
		var rest: Array = inbox.filter(func(m): return m[0] != "room_start")
		inbox.clear()          # in place: the push handler keeps appending to this same array
		inbox.append_array(rest)
		await play_duel(c, start, inbox)
	c.close()
	running -= 1

func play_duel(c: OnlineClient, start: Dictionary, inbox: Array) -> void:
	var room_id: String = start["room_id"]
	var remote := RemoteDuel.make(h.server.db, c, room_id)
	var result := {}
	remote.result_received.connect(func(r): result.merge(r))
	var refusals := [0]
	remote.refused.connect(func(r):
		stats["refused"] += 1
		refusals[0] += 1
		var key := str(r).left(60)
		reasons[key] = int(reasons.get(key, 0)) + 1)
	var guard := 0
	var stalled_since := Time.get_ticks_msec()
	while result.is_empty() and guard < 200000:
		guard += 1
		# Route this room's pushes.
		var keep := []
		for m in inbox:
			var p: Dictionary = m[1]
			if str(p.get("room_id", "")) != room_id:
				keep.append(m)
				continue
			match m[0]:
				"room_janken":
					if p.get("phase", "") == "pick":
						c.send("room_intent", {"room_id": room_id, "kind": "janken_pick", "args": {"hand": randi() % 3}})
					elif p.get("phase", "") == "order" and p.get("you_won", false):
						c.send("room_intent", {"room_id": room_id, "kind": "choose_order", "args": {"first": randi() % 2 == 0}})
				"room_batch":
					remote.receive_batch(p)
				"room_result":
					remote.receive_result(p)
		inbox.clear()
		inbox.append_array(keep)
		if remote.has_queued():
			remote.drain_events()
			stalled_since = Time.get_ticks_msec()
			refusals[0] = 0
		if c.state != "connected":
			errors.append("client lost its connection in room %s" % room_id)
			remote.dispose()
			return
		if refusals[0] > 0:
			# A refused answer is not retried as-is: back off a little and answer differently below.
			await create_timer(0.1).timeout
		if remote.in_flight or not remote.has_state() or remote.winner != -1:
			await process_frame
			if Time.get_ticks_msec() - stalled_since > 120000:
				errors.append("room %s: no progress for 120 s" % room_id)
				remote.dispose()
				return
			continue
		var pend: Dictionary = remote.fx.pending
		if not pend.is_empty() and int(pend.get("player", -1)) == 0 and pend.get("type", "") not in ["opponent", "wait"]:
			var answer = "pass"
			match str(pend.get("type", "")):
				"yesno": answer = randi() % 2 == 0
				"choice": answer = 0
				"select":
					var cands: Array = (pend.get("candidates", []) as Array).duplicate()
					if refusals[0] > 0:
						cands.shuffle()
					var count := int(pend.get("min", 1))
					if refusals[0] > 2:
						count = randi_range(int(pend.get("min", 1)), mini(int(pend.get("max", 1)), cands.size()))
					answer = cands.slice(0, count)
				"chain":
					var opts: Array = pend.get("options", [])
					if not opts.is_empty() and randi() % 3 == 0:
						answer = {"uid": int(opts[0]["uid"]), "idx": int(opts[0]["idx"])}
			if refusals[0] > 6 and str(pend.get("type", "")) == "chain":
				answer = "pass"
			remote.respond(answer)
			stats["intents"] += 1
		elif pend.is_empty() and remote.turn_player == 0 and remote.phase in ["main1", "battle", "main2"]:
			var acted := false
			var hand: Array = remote.side(0).hand
			if refusals[0] > 3:
				pass                       # too many refusals: just end the turn below
			elif remote.phase == "main1":
				if not remote.normal_summoned:
					for card in hand:
						if remote.is_monster(card) and remote.summon_problem(0, card) == "" and remote.tributes_required(card) == 0:
							remote.summon(0, card, [], -1, randi() % 4 == 0)
							acted = true
							break
				if not acted and randi() % 3 == 0:
					for e in remote.activatable_effects(0):
						remote.activate_effect(0, remote.card_by_uid(int(e["uid"])), int(e["idx"]))
						acted = true
						break
				if not acted and remote.turn > 1 and remote.monsters_of(0).any(func(m): return remote.can_attack(0, m) == ""):
					remote.to_battle(0)
					acted = true
			elif remote.phase == "battle" and refusals[0] <= 3:
				for m in remote.monsters_of(0):
					if remote.can_attack(0, m) == "":
						var target: DCard = null
						if not remote.monsters_of(1).is_empty() and not remote.can_attack_directly(m):
							target = remote.monsters_of(1)[randi() % remote.monsters_of(1).size()]
						remote.attack(0, m, target)
						acted = true
						break
			if not acted:
				var excess := remote.hand_excess(0)
				remote.end_turn(0, hand.slice(hand.size() - excess).map(func(x): return x.uid) if excess > 0 else [])
			stats["intents"] += 1
		else:
			await process_frame
		if Time.get_ticks_msec() - stalled_since > 120000:
			errors.append("room %s: no progress for 120 s" % room_id)
			remote.dispose()
			return
	remote.dispose()                   # the real client does this when the duel screen closes
	stats["duels"] += 1
	stats[str(start.get("mode", "casual"))] = int(stats.get(str(start.get("mode", "casual")), 0)) + 1
	stats["results"] += 1

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var minutes := float(args[0]) if args.size() > 0 else 3.0
	var count := int(args[1]) if args.size() > 1 else 6
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	h = OnlineHarness.new()
	h.start(self, "soak", {"casual_bot_after": 20.0, "idle_timeout": 120.0})
	var mem0 := OS.get_static_memory_usage()
	var t0 := Time.get_ticks_msec()
	deadline = t0 + int(minutes * 60000)
	for i in count:
		client_loop(i)
	await create_timer(1.0).timeout
	var peak_rooms := 0
	while running > 0:
		peak_rooms = maxi(peak_rooms, h.server.services["rooms"].rooms.size())
		await create_timer(1.0).timeout
		if Time.get_ticks_msec() > deadline + 300000:
			errors.append("clients did not finish within 5 minutes after the deadline")
			break
	await create_timer(6.0).timeout
	var rooms: RoomManager = h.server.services["rooms"]
	var stuck := rooms.rooms.values().filter(func(r): return r.state != "finished").size()
	var store: AccountStore = h.server.services["shop_backend"].store
	var rating_sum := 0
	var ranked_games := 0
	for a in store.accounts():
		var p := store.profile(str(a["id"]))
		rating_sum += int(p.get("rating", 1500)) - 1500
		ranked_games += int(p.get("ranked_games", 0))
	var mem1 := OS.get_static_memory_usage()
	print("soak: %.1f min, %d clients" % [(Time.get_ticks_msec() - t0) / 60000.0, count])
	print("duels finished (client side): %d  %s" % [stats["duels"], str(stats)])
	print("server: rooms finished %d, peak concurrent rooms %d, rooms left unfinished %d" % [rooms.finished_count, peak_rooms, stuck])
	print("ratings: sum of changes %d over %d ranked games (rounding only)" % [rating_sum, ranked_games / 2])
	print("memory: %.1f MB -> %.1f MB" % [mem0 / 1048576.0, mem1 / 1048576.0])
	print("errors: %d %s" % [errors.size(), str(errors.slice(0, 8))])
	print("refusal reasons: ", reasons)
	var ok: bool = errors.is_empty() and stuck == 0 and absi(rating_sum) <= ranked_games and stats["duels"] > 0
	print("SOAK ", "OK" if ok else "FAILED")
	await h.stop()
	quit(0 if ok else 1)
