class_name OnlineHarness
extends RefCounted
## Test helper: runs a GameServer and any number of OnlineClients inside one SceneTree, talking over
## a real localhost WebSocket, with a throwaway data folder.

var tree: SceneTree
var server: GameServer
var clients: Array = []
var port := 0
var data_dir := ""
var url := ""

static func free_port() -> int:
	var probe := TCPServer.new()
	for i in 200:
		var p := randi_range(20000, 45000)
		if probe.listen(p, "127.0.0.1") == OK:
			probe.stop()
			return p
	return 29999

static func wipe(dir: String) -> void:
	var path := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		wipe(dir + "/" + sub)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)

## Starts a fresh server named `tag` (data in user://test_online_<tag>).
func start(scene_tree: SceneTree, tag: String, overrides := {}) -> bool:
	tree = scene_tree
	data_dir = "user://test_online_" + tag
	wipe(data_dir)
	port = free_port()
	url = "ws://127.0.0.1:%d" % port
	server = GameServer.new()
	server.name = "Server_" + tag
	tree.root.add_child(server)
	var cfg := {"pbkdf2_iterations": 200}
	cfg.merge(overrides, true)
	server.setup(data_dir, cfg)
	return server.listen(port) == OK

## A connected client that already passed hello (or null).
func client(tag: String, do_hello := true) -> OnlineClient:
	var c := OnlineClient.new()
	c.name = "Client_%s_%d" % [tag, clients.size()]
	tree.root.add_child(c)
	clients.append(c)
	if do_hello:
		var hello: Dictionary = await c.connect_and_hello(url)
		if not hello.get("ok", false):
			return null
	else:
		c.open(url)
		var deadline := Time.get_ticks_msec() + 5000
		while c.state == "connecting" and Time.get_ticks_msec() < deadline:
			await tree.process_frame
	return c

## Registers (or logs in) `name` with an empty password; returns the login reply.
func login(c: OnlineClient, name: String, password := "") -> Dictionary:
	var r: Dictionary = await c.request("register", {"name": name, "password": password})
	if not r.get("ok", false) and r.get("error", "") == "name_taken":
		r = await c.request("login", {"name": name, "password": password})
	return r

## Waits (frames) until `cond` returns true or `seconds` pass.
func wait_until(cond: Callable, seconds := 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if cond.call():
			return true
		await tree.process_frame
	return bool(cond.call())

func frames(n: int) -> void:
	for i in n:
		await tree.process_frame

func stop() -> void:
	for c in clients:
		if is_instance_valid(c):
			c.close()
			c.queue_free()
	clients.clear()
	if is_instance_valid(server):
		server.stop()
		server.queue_free()
	await tree.process_frame
	await tree.process_frame
	wipe(data_dir)
