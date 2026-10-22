extends SceneTree
## Windowed end-to-end check of the online UI with an in-process server:
## lobby -> practice duel (janken decided by the server) -> board on a RemoteDuel -> a summon -> surrender -> result.
## Saves screenshots to the folder after "--".  godot --path . -s tools/online/shot_online.gd -- <folder>
var out := "user://"
var n := 0

func _initialize() -> void:
	call_deferred("run")

func shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	n += 1

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(800, 600)
	var h := OnlineHarness.new()
	h.start(self, "shot", {"dev": true})
	var session := root.get_node("Session")
	session.use_root("user://test_online_shot_local")
	session.online_cfg_path = "user://test_online_shot_local/online.cfg"
	var r: Dictionary = await session.go_online(h.url, "Tester", "", true)
	print("online: ", r.get("ok", false))
	# A legal deck for the account (server side).
	var shop: LocalShopBackend = h.server.services["shop_backend"]
	var db: CardDB = h.server.db
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var d := Deck.new()
	d.main = presets["cpu_003"]["main"].map(func(x): return int(x))
	d.extra = presets["cpu_003"]["extra"].map(func(x): return int(x))
	var c := Collection.load_default(db, shop.store.collection_path("tester"))
	for i in d.main + d.extra:
		c.counts[i] = mini(3, d.copies(i))
	c.save(shop.store.collection_path("tester"))
	d.save_working(db, shop.store.deck_path("tester"))
	var shell = load("res://ui/main.tscn").instantiate()
	root.add_child(shell)
	await wait(0.3)
	await shot("title_online")
	shell.show_online()
	await wait(1.0)
	await shot("lobby")
	shell.current._join("practice")
	await wait(1.5)
	await shot("janken")
	var screen = shell.current
	var tries := 0
	while screen.janken != null and screen.janken.phase == JankenScreen.Phase.SELECT and tries < 10:
		tries += 1
		screen.janken._choose("gu")
		await wait(3.0)
		await shot("janken_result")
	if screen.janken != null and screen.janken.phase == JankenScreen.Phase.ORDER and screen.janken.human_won:
		screen.janken._choose_order(0, true)
	await wait(4.0)
	while screen.board == null and tries < 30:
		tries += 1
		await wait(0.5)
	await wait(6.0)
	await shot("board_start")
	var remote: RemoteDuel = screen.remote
	# Summon a monster if it is our turn.
	var t := 0
	while t < 40 and (remote.turn_player != 0 or not remote.fx.pending.is_empty() or screen.board.anim_busy or remote.phase != "main1"):
		t += 1
		var pend: Dictionary = remote.fx.pending
		if not pend.is_empty() and int(pend.get("player", -1)) == 0 and pend.get("type", "") == "chain":
			remote.respond("pass")
		elif remote.turn_player == 0 and remote.phase in ["main1", "battle", "main2"] and pend.is_empty() and not screen.board.anim_busy and remote.phase != "main1":
			screen.board._do(remote.end_turn(0, []))
		await wait(0.5)
	for card in remote.side(0).hand:
		if remote.is_monster(card) and remote.summon_problem(0, card) == "" and remote.tributes_required(card) == 0:
			screen.board._do(remote.summon(0, card, [], -1, false))
			break
	await wait(4.0)
	await shot("board_summon")
	remote.surrender(0)
	await wait(4.0)
	await shot("board_end")
	screen.board.left.emit()
	await wait(1.5)
	await shot("result")
	await h.stop()
	OnlineHarness.wipe("user://test_online_shot_local")
	quit()
