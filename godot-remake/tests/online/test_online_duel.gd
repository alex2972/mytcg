extends SceneTree
## Phase 5: a client duels the CPU through the real server over WebSocket. The client's RemoteDuel picture
## must match the server's duel after every batch (zones, identities it may see, LP, phase, decisions),
## actions sent through RemoteDuel work, and a DuelBoard runs on a RemoteDuel without errors.
var fails := 0
var mismatches := {}

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func compare(remote: RemoteDuel, room: DuelRoom, seat: int) -> void:
	var d := room.duel
	for p in 2:
		var real := seat if p == 0 else 1 - seat
		var mine: Duel.PlayerSide = remote.side(p)
		var srv: Duel.PlayerSide = d.side(real)
		if mine.lp != srv.lp:
			mismatches["lp"] = int(mismatches.get("lp", 0)) + 1
		for zone in ["hand", "grave", "banished", "extra"]:
			var a: Array = (mine.get(zone) as Array).map(func(c): return c.uid)
			var b: Array = (srv.get(zone) as Array).map(func(c): return c.uid)
			if a != b:
				mismatches[zone] = int(mismatches.get(zone, 0)) + 1
		var deck_a: Array = (mine.deck as Array).map(func(c): return c.uid)
		var deck_b: Array = (srv.deck as Array).map(func(c): return c.uid)
		deck_a.sort()
		deck_b.sort()
		if deck_a != deck_b:
			mismatches["deck"] = int(mismatches.get("deck", 0)) + 1
		for z in 5:
			var ma: DCard = mine.monsters[z]
			var mb: DCard = srv.monsters[z]
			if (ma == null) != (mb == null) or (ma != null and (ma.uid != mb.uid or ma.pos != mb.pos or ma.face_up != mb.face_up)):
				mismatches["monsters"] = int(mismatches.get("monsters", 0)) + 1
			elif ma != null and (ma.face_up or p == 0) and (ma.idx != mb.idx or remote.atk_of(ma) != d.atk_of(mb)):
				mismatches["monster identity/atk"] = int(mismatches.get("monster identity/atk", 0)) + 1
			var sa: DCard = mine.spells[z]
			var sb: DCard = srv.spells[z]
			if (sa == null) != (sb == null) or (sa != null and sa.uid != sb.uid):
				mismatches["spells"] = int(mismatches.get("spells", 0)) + 1
		for c in mine.hand:
			if p == 0 and c.idx != d.card_by_uid(c.uid).idx:
				mismatches["own hand identity"] = int(mismatches.get("own hand identity", 0)) + 1
	if remote.phase != d.phase or remote.turn != d.turn:
		mismatches["phase/turn"] = int(mismatches.get("phase/turn", 0)) + 1
	if remote.turn_player != (d.turn_player if seat == 0 else 1 - d.turn_player):
		mismatches["turn player"] = int(mismatches.get("turn player", 0)) + 1
	var mine_pending: bool = not remote.fx.pending.is_empty() and int(remote.fx.pending.get("player", -1)) == 0
	var srv_pending: bool = not d.fx.pending.is_empty() and int(d.fx.pending.get("player", -1)) == seat
	if mine_pending != srv_pending:
		mismatches["pending"] = int(mismatches.get("pending", 0)) + 1

## Plays the client's seat through RemoteDuel (like the board would): Set/summon sometimes, answer prompts, end turns.
func play(h: OnlineHarness, remote: RemoteDuel, room: DuelRoom, seat: int) -> int:
	var actions := 0
	var guard := 0
	while room.state != "finished" and guard < 3000:
		guard += 1
		if remote.has_queued():
			remote.drain_events()
			if not remote.has_queued():
				compare(remote, room, seat)
		if remote.in_flight:
			await process_frame
			continue
		var pend: Dictionary = remote.fx.pending
		if not pend.is_empty() and int(pend.get("player", -1)) == 0 and pend.get("type", "") not in ["opponent", "wait"]:
			var answer = "pass"
			match str(pend.get("type", "")):
				"yesno": answer = guard % 2 == 0
				"choice": answer = 0
				"select": answer = (pend.get("candidates", []) as Array).slice(0, int(pend.get("min", 1)))
			remote.respond(answer)
			actions += 1
		elif pend.is_empty() and remote.turn_player == 0 and remote.winner == -1 and remote.phase in ["main1", "main2", "battle"]:
			var hand: Array = remote.side(0).hand
			var acted := false
			if remote.phase == "main1" and not remote.normal_summoned:
				for c in hand:
					if remote.is_monster(c) and remote.summon_problem(0, c) == "" and remote.tributes_required(c) == 0:
						remote.summon(0, c, [], -1, false)
						acted = true
						break
			if not acted and remote.phase == "main1" and remote.turn > 1:
				for c in remote.monsters_of(0):
					if remote.can_attack(0, c) == "":
						remote.to_battle(0)
						acted = true
						break
			if not acted and remote.phase == "battle":
				for c in remote.monsters_of(0):
					if remote.can_attack(0, c) == "":
						var target: DCard = null
						if not remote.monsters_of(1).is_empty() and not remote.can_attack_directly(c):
							target = remote.monsters_of(1)[0]
						remote.attack(0, c, target)
						acted = true
						break
			if not acted:
				var excess := remote.hand_excess(0)
				remote.end_turn(0, hand.slice(hand.size() - excess).map(func(c): return c.uid) if excess > 0 else [])
			actions += 1
		else:
			await process_frame
	return actions

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	var h := OnlineHarness.new()
	check(h.start(self, "duel", {"dev": true}), "server listens")
	var c: OnlineClient = await h.client("p1")
	await h.login(c, "Player1")
	var rooms: RoomManager = h.server.services["rooms"]
	var db: CardDB = h.server.db
	var pushes := []
	c.pushed.connect(func(kind, payload): pushes.append([kind, payload]))
	# Casual deck rule: the starter deck (6 cards) cannot duel.
	var small: Dictionary = await c.request("dev_start_bot_duel", {})
	check(small.get("error", "") == "deck_invalid", "a 6-card deck cannot start a duel")
	var start: Dictionary = await c.request("dev_start_bot_duel", {"deck_preset": "cpu_003", "bot_preset": "cpu_010", "seed": 31})
	check(start.get("ok", false), "dev duel against the CPU starts")
	var again: Dictionary = await c.request("dev_start_bot_duel", {"deck_preset": "cpu_003"})
	check(again.get("error", "") == "already_in_duel", "one duel at a time")
	var room: DuelRoom = rooms.rooms[start["room_id"]]
	var remote := RemoteDuel.make(db, c, start["room_id"])
	c.pushed.connect(func(kind, payload):
		if kind == "room_batch": remote.receive_batch(payload)
		elif kind == "room_result": remote.receive_result(payload))
	var result := {}
	remote.result_received.connect(func(r): result.merge(r))
	await h.wait_until(func(): return pushes.any(func(p): return p[0] == "room_janken"), 3.0)
	check(pushes.any(func(p): return p[0] == "room_start"), "the client gets room_start")
	var tries := 0
	while room.state == "janken" and tries < 20:
		tries += 1
		await c.request("room_intent", {"room_id": room.id, "kind": "janken_pick", "args": {"hand": tries % 3}})
	if room.state == "order":
		await c.request("room_intent", {"room_id": room.id, "kind": "choose_order", "args": {"first": true}})
	check(await h.wait_until(func(): return remote.has_state(), 5.0), "the client receives the starting picture")
	var foreign: Dictionary = await c.request("room_intent", {"room_id": "nope", "kind": "end_turn", "args": {}})
	check(foreign.get("error", "") == "not_in_duel", "intents for another room are refused")
	var acts := await play(h, remote, room, 0)
	check(room.state == "finished", "the duel through the network finishes (%d actions)" % acts)
	await h.wait_until(func(): return not result.is_empty(), 3.0)
	check(not result.is_empty() and result.has("you_won"), "the client gets the result")
	check(mismatches.is_empty(), "the client's picture always matches the server: %s" % str(mismatches))
	# Reconnect in the middle of a duel: new connection, token login, full snapshot.
	var start2: Dictionary = await c.request("dev_start_bot_duel", {"deck_preset": "cpu_003", "bot_preset": "cpu_011", "seed": 32})
	var room2: DuelRoom = rooms.rooms[start2["room_id"]]
	var t2 := 0
	while room2.state == "janken" and t2 < 20:
		t2 += 1
		await c.request("room_intent", {"room_id": room2.id, "kind": "janken_pick", "args": {"hand": t2 % 3}})
	if room2.state == "order":
		await c.request("room_intent", {"room_id": room2.id, "kind": "choose_order", "args": {"first": false}})
	var login: Dictionary = await c.request("login", {"name": "Player1", "password": ""})
	c.close()
	await h.wait_until(func(): return not room2.seats[0]["connected"], 3.0)
	check(not room2.seats[0]["connected"] and room2.state == "playing", "the room notices the disconnect and waits")
	var c2: OnlineClient = await h.client("p1b")
	var got := []
	c2.pushed.connect(func(kind, payload): got.append(kind))
	var back: Dictionary = await c2.request("login_token", {"token": login["token"]})
	check(back.get("ok", false), "token login on the new connection")
	await h.wait_until(func(): return got.has("room_batch"), 3.0)
	check(got.has("room_start") and got.has("room_batch") and room2.seats[0]["connected"], "the room resends the duel to the new connection")
	var sur: Dictionary = await c2.request("room_intent", {"room_id": room2.id, "kind": "surrender", "args": {}})
	check(sur.get("ok", false) and room2.state == "finished", "surrender over the network")
	# A DuelBoard on a RemoteDuel: renders the server's picture and plays batches without errors.
	var start3: Dictionary = await c2.request("dev_start_bot_duel", {"deck_preset": "cpu_003", "bot_preset": "cpu_012", "seed": 33})
	var room3: DuelRoom = rooms.rooms[start3["room_id"]]
	var remote3 := RemoteDuel.make(db, c2, start3["room_id"])
	c2.pushed.connect(func(kind, payload):
		if kind == "room_batch": remote3.receive_batch(payload))
	var t3 := 0
	while room3.state == "janken" and t3 < 20:
		t3 += 1
		await c2.request("room_intent", {"room_id": room3.id, "kind": "janken_pick", "args": {"hand": t3 % 3}})
	if room3.state == "order":
		await c2.request("room_intent", {"room_id": room3.id, "kind": "choose_order", "args": {"first": true}})
	await h.wait_until(func(): return remote3.has_state(), 3.0)
	var board := DuelBoard.new(db, Deck.new(), Deck.new(), 0, 0, remote3)
	board.ai_delay = 0.0
	root.add_child(board)
	await h.frames(5)
	await h.wait_until(func(): return not board.anim_busy, 5.0)
	check(board.views.size() == remote3.cards.size() and remote3.side(0).hand.size() >= 5, "the board shows every card of the server picture (%d views)" % board.views.size())
	# Let the board end our turns through RemoteDuel and the CPU win or lose; the board must keep up.
	var g := 0
	while room3.state != "finished" and g < 400:
		g += 1
		await h.frames(2)
		if board.anim_busy or remote3.in_flight or remote3.has_queued():
			continue
		var pend: Dictionary = remote3.fx.pending
		if not pend.is_empty() and int(pend.get("player", -1)) == 0 and pend.get("type", "") not in ["opponent", "wait"]:
			remote3.respond("pass" if pend.get("type", "") == "chain" else (false if pend.get("type", "") == "yesno" else (pend.get("candidates", []) as Array).slice(0, int(pend.get("min", 1)))))
			board._after_action()
		elif pend.is_empty() and remote3.turn_player == 0 and remote3.phase in ["main1", "main2", "battle"]:
			var hand: Array = remote3.side(0).hand
			var ex := remote3.hand_excess(0)
			board._do(remote3.end_turn(0, hand.slice(hand.size() - ex).map(func(x): return x.uid) if ex > 0 else []))
	check(room3.state == "finished", "a duel shown on a DuelBoard finishes")
	await h.wait_until(func(): return not board.anim_busy and not remote3.has_queued(), 5.0)
	check(board.duel.winner != -1, "the board knows the duel is over")
	board.queue_free()
	await h.stop()
	print("online duel tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
