class_name RoomManager
extends RefCounted
## All running duels. Routes "room_intent" requests to the caller's room and seat, handles reconnects
## (by account), the dev-only bot duel, and the end of a duel (ranked results and rewards go through the
## "ranked" service, then each human seat gets its "room_result").

var server: GameServer
var db: CardDB
var rooms := {}                  ## room id -> DuelRoom
var account_room := {}           ## account id -> room id
var finished_count := 0
var _next := 1
var _presets := {}

func _init(game_server: GameServer) -> void:
	server = game_server
	db = server.db
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	_presets = parsed if parsed is Dictionary else {}
	server.register("room_intent", _on_intent, true)
	server.register("room_rejoin", _on_rejoin, true)
	server.register("dev_start_bot_duel", _on_dev_bot_duel, true)
	server.peer_left.connect(_on_peer_left)

func status() -> Dictionary:
	return {"rooms": rooms.size(), "duels_finished": finished_count}

func room_of(account: String) -> DuelRoom:
	var rid: String = account_room.get(account, "")
	return rooms.get(rid) if rid != "" else null

## A preset deck by name ("cpu_000"...), used by bots and dev duels.
func preset_deck(preset: String) -> Deck:
	var p: Dictionary = _presets.get(preset, {})
	var d := Deck.new()
	d.main = p.get("main", []).map(func(x): return int(x))
	d.extra = p.get("extra", []).map(func(x): return int(x))
	d.side = p.get("side", []).map(func(x): return int(x))
	return d

func bot_seat(preset := "") -> Dictionary:
	var name := preset if preset != "" else str(server.config["bot_deck"])
	if not _presets.has(name):
		name = _presets.keys()[0]
	return {"account": "", "name": "CPU", "rating": int(server.config["elo_start"]), "bot": true, "peer": 0, "deck": preset_deck(name)}

## Seat description for a logged-in account with its server-side deck.
func human_seat(account: String) -> Dictionary:
	var auth: ServerAuth = server.services["auth"]
	var summary := auth.summary(account)
	var deck: Dictionary = server.services["shop_backend"].get_deck(account)
	return {"account": account, "name": summary.get("name", account), "rating": int(summary.get("rating", 1500)), "bot": false,
		"peer": auth.peer_of(account), "deck": deck.get("deck", Deck.new())}

## Creates and starts a room. Seats are dictionaries from human_seat()/bot_seat().
func create_room(mode: String, a: Dictionary, b: Dictionary, fixed_seed := -1) -> DuelRoom:
	var room := DuelRoom.new()
	var id := "r%d_%d" % [_next, int(server.now()) % 100000]
	_next += 1
	rooms[id] = room
	for s in [a, b]:
		if not s.get("bot", false):
			account_room[str(s["account"])] = id
	room.ended.connect(_on_room_ended)
	room.setup(id, mode, db, server.config, a, b, func(peer, kind, payload): server.push(peer, kind, payload), server.now, server.log_line, fixed_seed)
	server.log_line("INFO", "room %s (%s): %s vs %s" % [id, mode, a.get("name", "?"), b.get("name", "?")])
	return room

func tick(t: float) -> void:
	for room in rooms.values():
		(room as DuelRoom).tick(t)

func on_account_online(account: String, peer: int) -> void:
	var room := room_of(account)
	if room != null and room.state != "finished":
		room.on_reconnect(room.seat_of_account(account), peer)

func _on_peer_left(peer: int) -> void:
	var account := server.account_of(peer)
	var room := room_of(account)
	if room != null:
		room.on_disconnect(room.seat_of_account(account))

func _on_intent(peer: int, args: Dictionary) -> Dictionary:
	var account := server.account_of(peer)
	var room := room_of(account)
	if room == null or str(args.get("room_id", "")) != room.id:
		return Protocol.fail("not_in_duel")
	var kind = args.get("kind", "")
	var a = args.get("args", {})
	if typeof(kind) != TYPE_STRING or typeof(a) != TYPE_DICTIONARY:
		server.strike(peer, "bad intent")
		return Protocol.fail("invalid_args")
	var r := room.intent(room.seat_of_account(account), kind, a)
	if r.get("error", "") == "invalid_args":
		server.strike(peer, "invalid intent")
	return r

func _on_rejoin(peer: int, _args: Dictionary) -> Dictionary:
	var account := server.account_of(peer)
	var room := room_of(account)
	if room == null:
		return Protocol.fail("not_in_duel")
	room.on_reconnect(room.seat_of_account(account), peer)
	return Protocol.ok({"room_id": room.id})

## Dev only (server started with --dev or config "dev"): duel the CPU with your deck or a preset.
func _on_dev_bot_duel(peer: int, args: Dictionary) -> Dictionary:
	if not bool(server.config.get("dev", false)):
		return Protocol.fail("unknown_request")
	var account := server.account_of(peer)
	if room_of(account) != null:
		return Protocol.fail("already_in_duel")
	var seat := human_seat(account)
	var preset = args.get("deck_preset", "")
	if typeof(preset) == TYPE_STRING and preset != "" and _presets.has(preset):
		seat["deck"] = preset_deck(preset)
	var why := casual_deck_problem(seat["deck"])
	if why != "":
		return Protocol.fail("deck_invalid", {"reason": why})
	var bot_preset = args.get("bot_preset", "")
	var fixed = args.get("seed", -1)
	var room := create_room("dev", seat, bot_seat(str(bot_preset) if typeof(bot_preset) == TYPE_STRING else ""), int(fixed) if typeof(fixed) == TYPE_INT else -1)
	return Protocol.ok({"room_id": room.id})

## Casual/dev decks only need the 40-card minimum (like offline play).
static func casual_deck_problem(deck: Deck) -> String:
	if deck == null or deck.main.size() < DeckRules.MIN_MAIN:
		return "A deck needs at least %d cards." % DeckRules.MIN_MAIN
	return ""

func _on_room_ended(room: DuelRoom) -> void:
	finished_count += 1
	var per_seat := [{}, {}]
	if server.services.has("ranked"):
		per_seat = server.services["ranked"].on_duel_finished(room)
	room.result["per_seat"] = per_seat
	for i in 2:
		room._send(i, "room_result", room.result_for(i))
	server.log_line("INFO", "room %s ended: winner seat %d (%s) after %d turns" % [room.id, int(room.result["winner"]), room.result["reason"], int(room.result["turns"])])
	for i in 2:
		var acc := str(room.seats[i]["account"])
		if acc != "" and account_room.get(acc, "") == room.id:
			account_room.erase(acc)
	# Keep the finished room briefly so late resyncs still get the result.
	server.get_tree().create_timer(5.0).timeout.connect(func(): rooms.erase(room.id))
