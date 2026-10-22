class_name OnlineClient
extends Node
## Client side of the online game: owns a SceneMultiplayer for its subtree and the "Net" RPC node,
## connects to the server, sends requests and awaits their replies, and re-emits server pushes.
## `request(kind, args)` always returns a Dictionary ({"ok": false, "error": "timeout"} when no reply).

signal connected
signal connection_failed
signal disconnected
signal pushed(kind: String, payload: Dictionary)

var api := SceneMultiplayer.new()
var net: NetNode
var url := ""
var state := "offline"           ## offline / connecting / connected
var request_timeout := 10.0
var ping_every := 5.0
var _rid := 0
var _replies := {}               ## rid -> result
var _ping_accum := 0.0
var hello_ok := false

func _ready() -> void:
	net = NetNode.new()
	net.name = "Net"
	net.handler = self
	add_child(net)
	get_tree().set_multiplayer(api, get_path())
	api.allow_object_decoding = false
	api.connected_to_server.connect(_on_connected)
	api.connection_failed.connect(_on_failed)
	api.server_disconnected.connect(_on_server_gone)

## Opens the WebSocket. Await `connect_and_hello()` to also do the version handshake.
func open(server_url: String) -> Error:
	close()
	url = server_url
	var ws := WebSocketMultiplayerPeer.new()
	ws.inbound_buffer_size = 4194304
	ws.outbound_buffer_size = 4194304
	ws.max_queued_packets = 4096
	ws.handshake_timeout = 10.0
	var err := ws.create_client(server_url)
	if err != OK:
		state = "offline"
		return err
	state = "connecting"
	api.multiplayer_peer = ws
	return OK

## Connects and performs the hello handshake. Returns the hello reply (or an error dictionary).
func connect_and_hello(server_url: String, wait := 10.0) -> Dictionary:
	if open(server_url) != OK:
		return Protocol.fail("not_connected")
	var deadline := Time.get_ticks_msec() + int(wait * 1000)
	while state == "connecting" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if state != "connected":
		close()
		return Protocol.fail("not_connected")
	var hello: Dictionary = await request("hello", {"version": Protocol.VERSION, "data_hash": Protocol.data_hash()})
	hello_ok = hello.get("ok", false)
	return hello

func close() -> void:
	if api.multiplayer_peer != null and not api.multiplayer_peer is OfflineMultiplayerPeer:
		api.multiplayer_peer.close()
	api.multiplayer_peer = null
	if state != "offline":
		state = "offline"
	hello_ok = false

func is_online() -> bool:
	return state == "connected"

## Sends a request and waits for its reply.
func request(kind: String, args := {}) -> Dictionary:
	if state != "connected":
		return Protocol.fail("not_connected")
	_rid += 1
	var rid := _rid
	net.c2s.rpc_id(1, kind, rid, args)
	var deadline := Time.get_ticks_msec() + int(request_timeout * 1000)
	while not _replies.has(rid):
		if state != "connected":
			return Protocol.fail("not_connected")
		if Time.get_ticks_msec() > deadline:
			return Protocol.fail("timeout")
		await get_tree().process_frame
	var result: Dictionary = _replies[rid]
	_replies.erase(rid)
	return result

## Fire-and-forget message (no reply expected).
func send(kind: String, args := {}) -> void:
	if state == "connected":
		net.c2s.rpc_id(1, kind, 0, args)

func on_s2c(kind, rid, payload) -> void:
	if typeof(kind) != TYPE_STRING or typeof(payload) != TYPE_DICTIONARY:
		return
	if kind == "reply":
		_replies[int(rid)] = payload
	else:
		pushed.emit(kind, payload)

func _process(delta: float) -> void:
	if state != "connected" or not hello_ok:
		return
	_ping_accum += delta
	if _ping_accum >= ping_every:
		_ping_accum = 0.0
		send("ping")

func _on_connected() -> void:
	state = "connected"
	connected.emit()

func _on_failed() -> void:
	state = "offline"
	connection_failed.emit()

func _on_server_gone() -> void:
	state = "offline"
	hello_ok = false
	disconnected.emit()
