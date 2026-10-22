class_name GameServer
extends Node
## The authoritative game server: one node that owns its own SceneMultiplayer (for its subtree), the "Net"
## RPC node, the configuration, logging, connected peers, and the services (auth, shop, rooms, matchmaking,
## ranked). Clients only send requests ("kinds"); every request is validated here.
## Run: godot --headless --path . -- --server --port=27840 --data=user://server_dev

signal peer_joined(peer: int)
signal peer_left(peer: int)

const DEFAULT_CONFIG := {
	"port": 27840,
	"hello_timeout": 10.0,          ## seconds a new connection has to send hello
	"idle_timeout": 20.0,           ## seconds without any message before a peer is dropped
	"rate_per_second": 30.0,
	"rate_burst": 60.0,
	"max_strikes": 20,              ## invalid/abusive requests before a kick
	"ws_buffer_bytes": 4194304,
	"pbkdf2_iterations": 10000,
	"token_hours": 24.0,
	"login_delay_cap": 30.0,
	"decision_timeout": 60.0,       ## seconds to answer a prompt (chain, selection, yes/no)
	"turn_timeout": 240.0,          ## seconds of inactivity on your own turn before it is ended for you
	"timer_grace": 15.0,            ## added to the timers for animations on the client
	"janken_timeout": 15.0,
	"reconnect_grace": 90.0,
	"max_timeouts": 3,              ## consecutive timeouts before a forfeit
	"elo_start": 1500,
	"elo_k": 32,
	"elo_k_new": 40,
	"elo_new_games": 20,
	"elo_floor": 100,
	"queue_window_base": 100,
	"queue_window_per_second": 25,
	"queue_window_cap": 600,
	"casual_bot_after": 30.0,
	"reward_ranked_win": 50,
	"reward_ranked_loss": 10,
	"reward_casual_win": 20,
	"reward_first_win_of_day": 100,
	"leaderboard_cache_seconds": 10.0,
	"backup_keep": 7,
	"bot_deck": "cpu_000",
	"dev": false,
}

var config := DEFAULT_CONFIG.duplicate()
var data_dir := "user://server_dev"
var api := SceneMultiplayer.new()
var net: NetNode
var peer: MultiplayerPeer
var peers := {}                  ## peer id -> {connected_at, last_seen, hello, account, strikes, replies}
var handlers := {}               ## kind -> {fn: Callable, auth: bool}
var limiter: RateLimiter
var clock_offset := 0.0          ## tests move time forward without waiting
var started_at := 0.0
var _tick_accum := 0.0
var _log_file: FileAccess
var _metrics := {"requests": 0, "errors": 0, "kicks": 0}
var _metrics_at := 0.0
var services := {}               ## name -> service object (auth, shop, rooms, matchmaker, ranked)
var db: CardDB

func now() -> float:
	return Time.get_unix_time_from_system() + clock_offset

## Loads <data>/config.json over the defaults (writing it on first run) and prepares folders.
func setup(dir: String, overrides := {}) -> void:
	data_dir = dir.trim_suffix("/")
	for sub in ["", "/logs", "/accounts", "/matches", "/backups"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(data_dir + sub))
	var path := data_dir + "/config.json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			for k in parsed:
				if config.has(k):
					config[k] = parsed[k]
	else:
		AccountStore.write_json(path, config)
	for k in overrides:
		config[k] = overrides[k]
	limiter = RateLimiter.new(float(config["rate_per_second"]), float(config["rate_burst"]))
	_log_file = FileAccess.open(data_dir + "/logs/server.log", FileAccess.READ_WRITE if FileAccess.file_exists(data_dir + "/logs/server.log") else FileAccess.WRITE)
	if _log_file != null:
		_log_file.seek_end()
	started_at = now()
	_metrics_at = now()
	register("hello", _on_hello, false)
	register("ping", func(_p, _a): return Protocol.ok({"time": now()}), false)
	register("server_status", _on_status, false)
	ServerServices.install(self)

func _ready() -> void:
	net = NetNode.new()
	net.name = "Net"
	net.handler = self
	add_child(net)
	get_tree().set_multiplayer(api, get_path())
	api.server_relay = false
	api.allow_object_decoding = false
	api.peer_connected.connect(_on_peer_connected)
	api.peer_disconnected.connect(_on_peer_disconnected)

## Starts listening for WebSocket clients (wss:// when `tls` is given, e.g. TLSOptions.server(key, cert)).
func listen(port: int, tls: TLSOptions = null) -> Error:
	var ws := WebSocketMultiplayerPeer.new()
	ws.inbound_buffer_size = int(config["ws_buffer_bytes"])
	ws.outbound_buffer_size = int(config["ws_buffer_bytes"])
	ws.max_queued_packets = 4096
	ws.handshake_timeout = 10.0
	var err := ws.create_server(port, "*", tls)
	if err != OK:
		log_line("ERROR", "could not listen on port %d: %s" % [port, error_string(err)])
		return err
	peer = ws
	api.multiplayer_peer = ws
	log_line("INFO", "listening on %s://*:%d (protocol %d, data %s)" % ["wss" if tls != null else "ws", port, Protocol.VERSION, Protocol.data_hash().left(12)])
	return OK

func stop() -> void:
	for id in peers.keys():
		push(id, "server_closing", {})
	for s in services.values():
		if s.has_method("shutdown"):
			s.shutdown()
	if peer != null:
		peer.close()
	log_line("INFO", "stopped")

# --- requests --------------------------------------------------------------------------------

## Adds a request kind. `fn(peer: int, args: Dictionary) -> Dictionary`. `auth` = needs a logged-in session.
func register(kind: String, fn: Callable, auth := true) -> void:
	handlers[kind] = {"fn": fn, "auth": auth}

func on_c2s(sender: int, kind, rid, args) -> void:
	if not peers.has(sender):
		return
	var info: Dictionary = peers[sender]
	info["last_seen"] = now()
	_metrics["requests"] += 1
	if not limiter.allow(sender, now()):
		strike(sender, "rate")
		if int(info.get("rate_notices", 0)) < 3:
			info["rate_notices"] = int(info.get("rate_notices", 0)) + 1
			_reply(sender, rid if typeof(rid) == TYPE_INT else 0, Protocol.fail("rate_limited"))
		return
	info["rate_notices"] = 0
	if typeof(kind) != TYPE_STRING or (kind as String).length() > 40 or typeof(rid) != TYPE_INT or typeof(args) != TYPE_DICTIONARY or not Protocol.is_plain(args):
		strike(sender, "malformed")
		_reply(sender, rid if typeof(rid) == TYPE_INT else 0, Protocol.fail("invalid_args"))
		return
	if not handlers.has(kind):
		strike(sender, "unknown kind")
		_reply(sender, rid, Protocol.fail("unknown_request"))
		return
	var h: Dictionary = handlers[kind]
	if kind != "hello" and not info["hello"]:
		_reply(sender, rid, Protocol.fail("outdated_client"))
		return
	if h["auth"] and str(info["account"]) == "":
		_reply(sender, rid, Protocol.fail("not_authenticated"))
		return
	# A repeated request id gets the stored answer (idempotent purchases and intents).
	var replies: Dictionary = info["replies"]
	# A retransmission is the same request id, kind and arguments; only that gets the stored answer.
	var fingerprint := hash([kind, args])
	if rid > 0 and replies.has(rid) and replies[rid]["fp"] == fingerprint:
		_reply(sender, rid, replies[rid]["result"])
		return
	var result = (h["fn"] as Callable).call(sender, args)
	if not result is Dictionary:
		log_line("ERROR", "handler %s returned %s" % [kind, type_string(typeof(result))])
		result = Protocol.fail("server_error")
	if not result.get("ok", false):
		_metrics["errors"] += 1
	if rid > 0:
		replies[rid] = {"fp": fingerprint, "result": result}
		if replies.size() > 50:
			replies.erase(replies.keys().min())
		_reply(sender, rid, result)

func _reply(to: int, rid: int, result: Dictionary) -> void:
	if rid > 0 and peers.has(to):
		net.s2c.rpc_id(to, "reply", rid, result)

## Server push (not an answer): kind is the message name.
func push(to: int, kind: String, payload: Dictionary) -> void:
	if peers.has(to):
		net.s2c.rpc_id(to, kind, 0, payload)

func strike(sender: int, why: String) -> void:
	if not peers.has(sender):
		return
	var info: Dictionary = peers[sender]
	info["strikes"] = int(info["strikes"]) + 1
	if int(info["strikes"]) >= int(config["max_strikes"]):
		kick(sender, "too many invalid requests (%s)" % why)

func kick(to: int, reason: String) -> void:
	if not peers.has(to) or peers[to].get("kicked", false):
		return
	peers[to]["kicked"] = true
	_metrics["kicks"] += 1
	log_line("WARN", "kick peer %d: %s" % [to, reason])
	push(to, "kicked", {"reason": reason})
	# Let the push go out before closing.
	get_tree().create_timer(0.05).timeout.connect(func():
		if peer != null and peers.has(to):
			peer.disconnect_peer(to))

# --- peers -----------------------------------------------------------------------------------

func _on_peer_connected(id: int) -> void:
	peers[id] = {"connected_at": now(), "last_seen": now(), "hello": false, "account": "", "strikes": 0, "replies": {}}
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	if not peers.has(id):
		return
	peer_left.emit(id)
	peers.erase(id)
	limiter.forget(id)

func account_of(peer_id: int) -> String:
	return str(peers.get(peer_id, {}).get("account", ""))

func _on_hello(sender: int, args: Dictionary) -> Dictionary:
	if int(args.get("version", -1)) != Protocol.VERSION or str(args.get("data_hash", "")) != Protocol.data_hash():
		get_tree().create_timer(0.2).timeout.connect(func():
			if peer != null and peers.has(sender):
				peer.disconnect_peer(sender))
		return Protocol.fail("outdated_client", {"server_version": Protocol.VERSION})
	peers[sender]["hello"] = true
	return Protocol.ok({"server_time": now(), "version": Protocol.VERSION})

func _on_status(_sender: int, _args: Dictionary) -> Dictionary:
	var out := {"uptime": now() - started_at, "peers": peers.size(), "version": Protocol.VERSION}
	for s in services.values():
		if s.has_method("status"):
			out.merge(s.status())
	return Protocol.ok(out)

# --- time ------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum >= 0.25:
		_tick_accum = 0.0
		tick()

## Timeouts and service timers. Tests call it directly after moving `clock_offset`.
func tick() -> void:
	var t := now()
	for id in peers.keys():
		var info: Dictionary = peers[id]
		if not info["hello"] and t - float(info["connected_at"]) > float(config["hello_timeout"]):
			kick(id, "no hello")
		elif t - float(info["last_seen"]) > float(config["idle_timeout"]):
			kick(id, "idle")
	for s in services.values():
		if s.has_method("tick"):
			s.tick(t)
	if t - _metrics_at >= 60.0:
		_metrics_at = t
		log_line("INFO", "metrics peers=%d requests=%d errors=%d kicks=%d" % [peers.size(), _metrics["requests"], _metrics["errors"], _metrics["kicks"]])

# --- logging ---------------------------------------------------------------------------------

func log_line(level: String, msg: String) -> void:
	var line := "%s [%s] %s" % [Time.get_datetime_string_from_system(true), level, msg]
	if level != "DEBUG" or bool(config.get("verbose", false)):
		print(line)
	if _log_file != null:
		_log_file.store_line(line)
		_log_file.flush()
		if _log_file.get_length() > 5 * 1024 * 1024:
			_rotate_log()

func audit(event: String, data: Dictionary) -> void:
	var f := FileAccess.open(data_dir + "/logs/audit.log", FileAccess.READ_WRITE if FileAccess.file_exists(data_dir + "/logs/audit.log") else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	var row := {"t": int(now()), "event": event}
	row.merge(data)
	f.store_line(JSON.stringify(row))
	f.close()

func _rotate_log() -> void:
	_log_file.close()
	var base := ProjectSettings.globalize_path(data_dir + "/logs/server.log")
	if FileAccess.file_exists(base + ".1"):
		DirAccess.remove_absolute(base + ".1")
	DirAccess.rename_absolute(base, base + ".1")
	_log_file = FileAccess.open(data_dir + "/logs/server.log", FileAccess.WRITE)
