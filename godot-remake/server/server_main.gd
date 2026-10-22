extends Node
## Dedicated server entry:
##   godot --path . --headless -- --server --port=9080 --data=user://server_dev [--dev]
##         [--tls-cert=fullchain.pem --tls-key=privkey.pem]   (wss:// directly; or put a TLS proxy in front)
## Options also accept a separate value (`--port 9080`); the scene can be run directly (res://server/server_main.tscn).

var server: GameServer

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var opts := {"--port": str(Protocol.DEFAULT_PORT), "--data": "user://server_dev", "--tls-cert": "", "--tls-key": ""}
	var dev := false
	var i := 0
	while i < args.size():
		var a: String = args[i]
		if a == "--dev":
			dev = true
		elif a.contains("=") and opts.has(a.get_slice("=", 0)):
			opts[a.get_slice("=", 0)] = a.substr(a.find("=") + 1)
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
	var tls: TLSOptions = null
	if opts["--tls-cert"] != "" and opts["--tls-key"] != "":
		var cert := X509Certificate.new()
		var key := CryptoKey.new()
		if cert.load(opts["--tls-cert"]) != OK or key.load(opts["--tls-key"]) != OK:
			server.log_line("ERROR", "could not load the TLS certificate/key")
			get_tree().quit(1)
			return
		tls = TLSOptions.server(key, cert)
	if server.listen(int(opts["--port"]), tls) != OK:
		get_tree().quit(1)
		return
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and server != null:
		server.stop()
		get_tree().quit()
