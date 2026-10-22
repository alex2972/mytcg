extends SceneTree
## Phase 1: WebSocket transport, hello/version handshake, ping, status, rate limits, strikes, timeouts.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var h := OnlineHarness.new()
	check(h.start(self, "transport", {"hello_timeout": 1.0, "idle_timeout": 3.0, "rate_per_second": 20.0, "rate_burst": 20.0, "max_strikes": 5}), "server listens")
	var a: OnlineClient = await h.client("a")
	var b: OnlineClient = await h.client("b")
	check(a != null and b != null and a.hello_ok and b.hello_ok, "two clients connect and pass hello")
	check(h.server.peers.size() == 2, "server sees two peers")
	var ping: Dictionary = await a.request("ping")
	check(ping.get("ok", false) and ping.has("time"), "ping answers")
	var status: Dictionary = await b.request("server_status")
	check(status.get("ok", false) and int(status.get("peers", 0)) == 2 and int(status.get("version", 0)) == Protocol.VERSION, "server_status reports peers and version")
	var unknown: Dictionary = await a.request("make_me_rich", {"dp": 999999})
	check(unknown.get("error", "") == "unknown_request", "unknown request kinds are refused")
	var not_auth: Dictionary = await a.request("server_status", {"nested": {"deep": [1, 2, {"x": "y"}]}})
	check(not_auth.get("ok", false), "plain nested arguments are accepted")
	# Outdated client: wrong data hash is refused and dropped.
	var old: OnlineClient = await h.client("old", false)
	var refused: Dictionary = await old.request("hello", {"version": Protocol.VERSION, "data_hash": "deadbeef"})
	check(refused.get("error", "") == "outdated_client", "a client with different card data is refused")
	check(await h.wait_until(func(): return old.state == "offline", 3.0), "the outdated client is disconnected")
	# Requests before hello are refused.
	var early: OnlineClient = await h.client("early", false)
	var before: Dictionary = await early.request("server_status")
	check(before.get("error", "") == "outdated_client", "requests before hello are refused")
	# No hello at all: dropped after hello_timeout.
	await h.frames(2)
	h.server.clock_offset += 2.0
	h.server.tick()
	check(await h.wait_until(func(): return early.state == "offline", 3.0), "a connection that never says hello is dropped")
	h.server.clock_offset -= 2.0
	# Rate limit: a burst over the bucket gets rate_limited.
	var a_id := a.api.get_unique_id()
	for i in 40:
		a.send("ping")
	await h.wait_until(func(): return not h.server.peers.has(a_id) or int(h.server.peers[a_id]["strikes"]) > 0, 3.0)
	check(not h.server.peers.has(a_id) or int(h.server.peers[a_id]["strikes"]) > 0, "flooding trips the rate limiter")
	# Malformed requests earn strikes and finally a kick.
	var bad: OnlineClient = await h.client("bad")
	for i in 6:
		bad.net.c2s.rpc_id(1, 12345, "not an int", ["not", "a", "dict"])
	check(await h.wait_until(func(): return bad.state == "offline", 3.0), "a client sending malformed requests is kicked")
	# Idle peers are dropped (b stopped pinging because its ping interval is long).
	b.ping_every = 999.0
	h.server.clock_offset += 10.0
	h.server.tick()
	check(await h.wait_until(func(): return b.state == "offline", 3.0), "idle peers are dropped")
	await h.stop()
	print("online transport tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
