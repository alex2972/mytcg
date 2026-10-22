extends SceneTree
## Phase 4: authoritative duel rooms without the network. Bot vs bot duels finish, a human seat plays
## through intents, illegal intents are refused, janken/order, surrender, timeouts, disconnects,
## reconnect snapshots, determinism with a fixed seed.
var fails := 0
var db: CardDB
var presets := {}
var clock := 1000.0
var sent := []                 ## [peer, kind, payload]

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func preset(name: String) -> Deck:
	var p: Dictionary = presets[name]
	var d := Deck.new()
	d.main = p["main"].map(func(x): return int(x))
	d.extra = p["extra"].map(func(x): return int(x))
	return d

func seat(name: String, deck: String, bot: bool, peer := 0) -> Dictionary:
	return {"account": "" if bot else name.to_lower(), "name": name, "rating": 1500, "bot": bot, "peer": peer, "deck": preset(deck)}

func make_room(a: Dictionary, b: Dictionary, seed_value := -1) -> DuelRoom:
	var r := DuelRoom.new()
	r.setup("t%d" % randi(), "casual", db, GameServer.DEFAULT_CONFIG.duplicate(), a, b,
		func(peer, kind, payload): sent.append([peer, kind, payload]), func(): return clock, func(_l, m): print("   room log: ", m), seed_value)
	return r

func last(peer: int, kind: String) -> Dictionary:
	for i in range(sent.size() - 1, -1, -1):
		if sent[i][0] == peer and sent[i][1] == kind:
			return sent[i][2]
	return {}

## A passive human: answers its prompts with the safe default and ends its turns.
func play_passive(room: DuelRoom, s: int, peer: int, limit := 400) -> int:
	var actions := 0
	while room.state == "playing" and actions < limit:
		var batch := last(peer, "room_batch")
		if batch.is_empty():
			return actions
		var st: Dictionary = batch["state"]
		var pend: Dictionary = st["pending"]
		var r := {}
		if not pend.is_empty() and pend.get("type", "") != "opponent":
			var answer = "pass"
			match str(pend.get("type", "")):
				"yesno": answer = false
				"choice": answer = 0
				"select": answer = (pend.get("candidates", []) as Array).slice(0, int(pend.get("min", 1)))
				"presentation": answer = true
			r = room.intent(s, "respond", {"answer": answer})
		elif int(st["turn_player"]) == 0 and pend.is_empty():
			var hand: Array = st["players"][0]["hand"]
			var excess := int(st["legal"]["hand_excess"])
			var discards: Array = hand.slice(hand.size() - excess).map(func(c): return int(c["uid"])) if excess > 0 else []
			r = room.intent(s, "end_turn", {"discards": discards})
		else:
			return actions
		actions += 1
		if not r.get("ok", false):
			print("   passive intent refused: ", r)
			return actions
	return actions

func run() -> void:
	db = CardDB.load_default()
	presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return not str(k).begins_with("ful_") and (presets[k]["main"] as Array).size() >= 40)
	# 1. Bot vs bot duels always finish (seat 0 and seat 1 played by the AI).
	var finished := 0
	var reasons := {}
	var t0 := Time.get_ticks_msec()
	for i in 40:
		var r := make_room(seat("A", names[i % names.size()], true), seat("B", names[(i * 7 + 3) % names.size()], true), 1000 + i)
		if r.state == "finished":
			finished += 1
			reasons[r.result["reason"]] = int(reasons.get(r.result["reason"], 0)) + 1
	check(finished == 40, "40 bot vs bot duels finish (%d) %s" % [finished, str(reasons)])
	check(not reasons.has("stuck"), "no bot duel gets stuck")
	print("   40 bot duels in %d ms: %s" % [Time.get_ticks_msec() - t0, str(reasons)])
	# 2. Determinism: same seed and decks -> same outcome.
	var r1 := make_room(seat("A", names[0], true), seat("B", names[1], true), 4242)
	var r2 := make_room(seat("A", names[0], true), seat("B", names[1], true), 4242)
	check(r1.result["winner"] == r2.result["winner"] and r1.result["turns"] == r2.result["turns"] and r1.duel.side(0).lp == r2.duel.side(0).lp and r1.duel.side(1).lp == r2.duel.side(1).lp, "a fixed seed replays the same duel")
	# 3. A human seat (peer 11) against the CPU.
	sent.clear()
	var room := make_room(seat("Hero", names[2], false, 11), seat("CPU", names[3], true), 777)
	var start := last(11, "room_start")
	check(start.get("opponent", {}).get("bot", false) and start["you"]["name"] == "Hero", "room_start tells the human who they face")
	check(last(11, "room_janken").get("phase", "") == "pick" and room.state == "janken", "the duel starts with rock-paper-scissors")
	check(room.intent(0, "end_turn", {}).get("error", "") == "illegal_action", "no duel actions during janken")
	check(room.intent(0, "janken_pick", {"hand": 7}).get("error", "") == "invalid_args", "an impossible hand is refused")
	var pick := room.intent(0, "janken_pick", {"hand": 0})
	var rounds := 0
	while room.state == "janken" and rounds < 20:
		rounds += 1
		room.intent(0, "janken_pick", {"hand": rounds % 3})
	check(pick.get("ok", false) and room.state in ["order", "playing"], "janken resolves (ties replay)")
	if room.state == "order":
		check(room.janken_winner == 0, "order is only asked of the winner")
		check(room.intent(0, "choose_order", {"first": "yes"}).get("error", "") == "invalid_args", "order needs a boolean")
		room.intent(0, "choose_order", {"first": true})
		check(room.first_player == 0, "the winner chose to go first")
	check(room.state == "playing" and room.duel != null, "the duel is running")
	var batch := last(11, "room_batch")
	check(not batch.is_empty() and int(batch["seq"]) >= 1, "the human receives a batch")
	var st: Dictionary = batch["state"]
	check((st["players"][1]["hand"] as Array).all(func(c): return c.get("hidden", false) and int(c["idx"]) == 0), "the opponent's hand is hidden")
	check((st["players"][0]["deck"] as Array).all(func(c): return c.get("hidden", false)) and (st["players"][1]["deck"] as Array).all(func(c): return c.get("hidden", false)), "both decks are hidden")
	check((st["players"][0]["hand"] as Array).all(func(c): return int(c["idx"]) > 0), "your own hand is visible")
	# Illegal intents
	var opp_card: int = int(room.duel.side(1).hand[0].uid)
	check(not room.intent(0, "summon", {"uid": opp_card, "tributes": [], "zone": -1, "face_down": false}).get("ok", true), "you cannot summon the opponent's card")
	check(room.intent(0, "summon", {"uid": "x"}).get("error", "") == "invalid_args", "malformed intents are refused")
	check(room.intent(0, "attack", {"uid": opp_card, "target": -1}).get("ok", true) == false, "you cannot attack with a card you do not control")
	check(room.intent(0, "respond", {"answer": "pass"}).get("error", "") in ["not_your_decision"], "you cannot answer a decision that is not yours")
	check(room.intent(0, "dance", {}).get("error", "") == "invalid_args", "unknown intents are refused")
	check(room.intent(5, "end_turn", {}).get("error", "") == "not_in_duel", "unknown seats are refused")
	# Play it out passively; the CPU wins in the end.
	var guard := 0
	while room.state == "playing" and guard < 50:
		guard += 1
		play_passive(room, 0, 11)
	check(room.state == "finished", "the human vs CPU duel finishes (%s)" % room.state)
	check(int(room.result.get("winner", -1)) in [0, 1, 2], "the room records a winner")
	# 4. Surrender
	sent.clear()
	var room2 := make_room(seat("Hero", names[2], false, 12), seat("CPU", names[3], true), 778)
	room2.intent(0, "janken_pick", {"hand": 1})
	var g2 := 0
	while room2.state == "janken" and g2 < 20:
		g2 += 1
		room2.intent(0, "janken_pick", {"hand": g2 % 3})
	if room2.state == "order":
		room2.intent(0, "choose_order", {"first": false})
	check(room2.intent(0, "surrender", {}).get("ok", false) and room2.state == "finished" and int(room2.result["winner"]) == 1 and room2.result["reason"] == "surrender", "surrender ends the duel")
	# 5. Timeouts: three missed turns forfeit.
	sent.clear()
	var room3 := make_room(seat("Slow", names[2], false, 13), seat("CPU", names[3], true), 779)
	var timeouts := 0
	while room3.state != "finished" and timeouts < 12:
		timeouts += 1
		clock += 1000.0
		room3.tick(clock)
	check(room3.state == "finished" and room3.result["reason"] == "timeout" and int(room3.result["winner"]) == 1, "a player who never acts loses on timeouts (%s)" % str(room3.result))
	# 6. Disconnect, reconnect with a snapshot, and the grace period.
	sent.clear()
	var room4 := make_room(seat("Gone", names[2], false, 14), seat("CPU", names[3], true), 780)
	room4.intent(0, "janken_pick", {"hand": 2})
	var g4 := 0
	while room4.state == "janken" and g4 < 20:
		g4 += 1
		room4.intent(0, "janken_pick", {"hand": g4 % 3})
	if room4.state == "order":
		room4.intent(0, "choose_order", {"first": true})
	room4.on_disconnect(0)
	clock += 30.0
	room4.tick(clock)
	check(room4.state == "playing", "a short disconnect does not lose the duel")
	sent.clear()
	room4.on_reconnect(0, 15)
	var rs := last(15, "room_batch")
	check(not last(15, "room_start").is_empty() and rs.get("resync", false) and not rs["state"].is_empty(), "a reconnect gets room_start and a full snapshot on the new connection")
	room4.on_disconnect(0)
	clock += 200.0
	room4.tick(clock)
	check(room4.state == "finished" and room4.result["reason"] == "disconnect" and int(room4.result["winner"]) == 1, "not coming back within the grace period loses")
	print("online room tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
