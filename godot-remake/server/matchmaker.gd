class_name Matchmaker
extends RefCounted
## Queues for "ranked" and "casual" duels, plus "practice" (an immediate duel against the CPU).
## Ranked pairs players whose ratings are within a window that widens the longer they wait
## (base + per_second * waited, capped); casual pairs any two players at once and falls back to the CPU.
## Decks are checked when joining: casual/practice need 40 cards, ranked the full deck rules.

const MODES := ["ranked", "casual", "practice"]

var server: GameServer
var queues := {"ranked": [], "casual": []}   ## [{account, peer, rating, joined, last_status}]

func _init(game_server: GameServer) -> void:
	server = game_server
	server.register("queue_join", _on_join, true)
	server.register("queue_leave", _on_leave, true)
	server.peer_left.connect(func(peer): _remove_peer(peer))

func status() -> Dictionary:
	return {"queue_ranked": queues["ranked"].size(), "queue_casual": queues["casual"].size()}

func rooms() -> RoomManager:
	return server.services["rooms"]

func in_queue(account: String) -> String:
	for mode in queues:
		for e in queues[mode]:
			if e["account"] == account:
				return mode
	return ""

func _on_join(peer: int, args: Dictionary) -> Dictionary:
	var mode = args.get("mode", "")
	if typeof(mode) != TYPE_STRING or not MODES.has(mode):
		return Protocol.fail("invalid_args")
	var account := server.account_of(peer)
	if rooms().room_of(account) != null:
		return Protocol.fail("already_in_duel")
	if in_queue(account) != "":
		return Protocol.fail("in_queue")
	var seat := rooms().human_seat(account)
	var deck: Deck = seat["deck"]
	var why := ""
	if mode == "ranked":
		why = DeckRules.ranked_problem(deck, server.db)
		if why == "":
			why = server.services["shop_backend"].deck_save_problem(deck, Collection.load_default(server.db, server.services["shop_backend"].store.collection_path(account)))
	else:
		why = RoomManager.casual_deck_problem(deck)
	if why != "":
		return Protocol.fail("deck_invalid", {"reason": why})
	if mode == "practice":
		var room := rooms().create_room("practice", seat, rooms().bot_seat())
		return Protocol.ok({"room_id": room.id})
	queues[mode].append({"account": account, "peer": peer, "rating": int(seat["rating"]), "joined": server.now(), "last_status": 0.0})
	server.log_line("INFO", "%s joined the %s queue" % [account, mode])
	tick(server.now())
	return Protocol.ok({"mode": mode})

func _on_leave(peer: int, _args: Dictionary) -> Dictionary:
	var account := server.account_of(peer)
	for mode in queues:
		queues[mode] = queues[mode].filter(func(e): return e["account"] != account)
	return Protocol.ok()

func _remove_peer(peer: int) -> void:
	for mode in queues:
		queues[mode] = queues[mode].filter(func(e): return e["peer"] != peer)

## Rating window for an entry that has waited `waited` seconds.
func window(waited: float) -> float:
	return minf(float(server.config["queue_window_cap"]), float(server.config["queue_window_base"]) + float(server.config["queue_window_per_second"]) * waited)

func tick(t: float) -> void:
	_match_ranked(t)
	_match_casual(t)
	for mode in queues:
		for e in queues[mode]:
			if t - float(e["last_status"]) >= 2.0:
				e["last_status"] = t
				server.push(int(e["peer"]), "queue_status", {"mode": mode, "waiting": t - float(e["joined"]), "in_queue": queues[mode].size()})

func _match_ranked(t: float) -> void:
	var q: Array = queues["ranked"]
	q.sort_custom(func(a, b): return float(a["joined"]) < float(b["joined"]))
	var i := 0
	while i < q.size():
		var a: Dictionary = q[i]
		var best := -1
		var best_diff := INF
		for j in range(q.size()):
			if j == i:
				continue
			var b: Dictionary = q[j]
			var diff := absf(float(a["rating"]) - float(b["rating"]))
			# Both players must accept the gap at their own waiting time.
			if diff <= window(t - float(a["joined"])) and diff <= window(t - float(b["joined"])) and diff < best_diff:
				best = j
				best_diff = diff
		if best >= 0:
			var b: Dictionary = q[best]
			q.erase(a)
			q.erase(b)
			_start("ranked", a, b)
			i = 0
		else:
			i += 1

func _match_casual(t: float) -> void:
	var q: Array = queues["casual"]
	q.sort_custom(func(a, b): return float(a["joined"]) < float(b["joined"]))
	while q.size() >= 2:          # casual ignores ratings
		var a: Dictionary = q.pop_front()
		var b: Dictionary = q.pop_front()
		_start("casual", a, b)
	for e in q.duplicate():
		if t - float(e["joined"]) >= float(server.config["casual_bot_after"]):
			q.erase(e)
			var room := rooms().create_room("casual", rooms().human_seat(e["account"]), rooms().bot_seat())
			server.log_line("INFO", "casual: %s waited %.0f s, matched with the CPU (room %s)" % [e["account"], t - float(e["joined"]), room.id])

func _start(mode: String, a: Dictionary, b: Dictionary) -> void:
	var sa := rooms().human_seat(a["account"])
	var sb := rooms().human_seat(b["account"])
	if int(sa["peer"]) == 0 or int(sb["peer"]) == 0:
		# Someone left in the meantime: put the other back.
		for e in [a, b]:
			if server.services["auth"].peer_of(e["account"]) != 0:
				queues[mode].append(e)
		return
	rooms().create_room(mode, sa, sb)
