extends Node
## Dedicated server entry: godot --headless --path . res://server/server_main.tscn -- --port 9080 --data user://server_dev [--dev]

var server: GameServer

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var opts := {"--port": str(Protocol.DEFAULT_PORT), "--data": "user://server_dev"}
	var dev := false
	var i := 0
	while i < args.size():
		var a: String = args[i]
		if a == "--dev":
			dev = true
		elif opts.has(a) and i + 1 < args.size():
			opts[a] = args[i + 1]
			i += 1
		i += 1
	server = GameServer.new()
	server.name = "GameServer"
	add_child(server)
	var overrides := {}
	if dev:
		overrides["dev"] = true
	server.setup(opts["--data"], overrides)
	if server.listen(int(opts["--port"])) != OK:
		get_tree().quit(1)
		return
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and server != null:
		server.stop()
		get_tree().quit()
