extends SceneTree
## Phase 4: nothing a seat may not know ever reaches it. A passive human seat faces the CPU (which plays
## spells, traps, summons, flips, reveals...). Every payload sent to the human is checked against the
## server's real duel state at the moment it is sent. Both seat orientations are covered.
var fails := 0
var db: CardDB
var presets := {}
var clock := 5000.0
var room: DuelRoom
var human_seat := 0
var checked_batches := 0
var checked_cards := 0
var known_seen := 0
var problems := {}

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func problem(msg: String) -> void:
	problems[msg] = int(problems.get(msg, 0)) + 1

func _initialize() -> void:
	call_deferred("run")

func preset(name: String) -> Deck:
	var p: Dictionary = presets[name]
	var d := Deck.new()
	d.main = p["main"].map(func(x): return int(x))
	d.extra = p["extra"].map(func(x): return int(x))
	return d

## Called by the room for every message, while the duel is in the state the message describes.
func on_send(_peer, kind: String, payload: Dictionary) -> void:
	if kind != "room_batch" or room == null or room.duel == null:
		return
	checked_batches += 1
	var d := room.duel
	var v := human_seat
	var st: Dictionary = payload["state"]
	# Cards revealed by this batch's events.
	var revealed := {}
	for e in payload["events"]:
		for k in e:
			if k in ["idx", "number", "card_name"] and str(e.get("type", "")) != "chain":
				problem("event %s carries %s" % [e.get("type", ""), k])
		if e.get("type", "") == "reveal_cards" and (e.get("public", false) or int(e.get("viewer", -1)) == 0):
			for u in e.get("cards", []):
				revealed[int(u)] = true
		if e.get("type", "") == "excavate":
			revealed[int(e.get("uid", -1))] = true
	for pi in 2:
		var real := v if pi == 0 else 1 - v
		var ps: Dictionary = st["players"][pi]
		var s: Duel.PlayerSide = d.side(real)
		if (ps["hand"] as Array).size() != s.hand.size() or (ps["deck"] as Array).size() != s.deck.size():
			problem("zone sizes differ from the server")
		for zone in ["deck", "hand", "monsters", "spells", "grave", "banished", "extra"]:
			for card in ps[zone]:
				if card == null:
					continue
				_check_card(d, v, card)
		if ps["field_spell"] != null:
			_check_card(d, v, ps["field_spell"])
	for uid_s in st["known"]:
		known_seen += 1
		var c := d.card_by_uid(int(uid_s))
		if c == null:
			problem("known card does not exist")
			continue
		var allowed: bool = revealed.has(c.uid) or DuelSnapshot._may_identify(d, c, v)
		if not allowed:
			problem("known reveals a card that was not revealed (%s)" % _where(d, c))
		if int(st["known"][uid_s]) != c.idx:
			problem("known has the wrong identity")
	var pend: Dictionary = st["pending"]
	if not pend.is_empty() and pend.get("type", "") != "opponent":
		if int(d.fx.pending.get("player", -1)) != v:
			problem("a decision of the other seat was sent")
	if not pend.is_empty() and pend.get("type", "") == "opponent" and int(d.fx.pending.get("player", -1)) == v:
		problem("own decision sent as opponent's")

func _check_card(d: Duel, v: int, card: Dictionary) -> void:
	checked_cards += 1
	var c := d.card_by_uid(int(card["uid"]))
	if c == null:
		problem("unknown uid")
		return
	if card.get("hidden", false):
		if int(card["idx"]) != 0:
			problem("hidden card carries an identity")
		return
	if int(card["idx"]) != c.idx:
		problem("visible card has the wrong identity")
	if not DuelSnapshot._may_identify(d, c, v):
		problem("a card the seat may not identify is visible (%s)" % _where(d, c))

func _where(d: Duel, c: DCard) -> String:
	var s: Duel.PlayerSide = d.side(c.owner)
	for z in ["deck", "hand", "grave", "banished", "extra"]:
		if (s.get(z) as Array).has(c):
			return "owner %d %s" % [c.owner, z]
	return "owner %d field face_up=%s controller %d" % [c.owner, c.face_up, c.controller]

func last_batch() -> Dictionary:
	return _last

var _last := {}

func run() -> void:
	db = CardDB.load_default()
	presets = JSON.parse_string(FileAccess.get_file_as_string("res://data/decks.json"))
	var names: Array = presets.keys().filter(func(k): return not str(k).begins_with("ful_") and (presets[k]["main"] as Array).size() >= 40)
	var duels := 0
	for i in 16:
		human_seat = i % 2
		var cpu_deck: String = names[(i * 5 + 1) % names.size()]
		var me := {"account": "hero", "name": "Hero", "rating": 1500, "bot": false, "peer": 7, "deck": preset(names[(i * 3) % names.size()])}
		var cpu := {"account": "", "name": "CPU", "rating": 1500, "bot": true, "peer": 0, "deck": preset(cpu_deck)}
		room = DuelRoom.new()
		var seats := [me, cpu] if human_seat == 0 else [cpu, me]
		room.setup("h%d" % i, "casual", db, GameServer.DEFAULT_CONFIG.duplicate(), seats[0], seats[1],
			func(peer, kind, payload):
				if kind == "room_batch": _last = payload
				on_send(peer, kind, payload),
			func(): return clock, func(_l, _m): pass, 9000 + i)
		var guard := 0
		while room.state != "finished" and guard < 600:
			guard += 1
			if room.state == "janken":
				room.intent(human_seat, "janken_pick", {"hand": guard % 3})
				continue
			if room.state == "order":
				room.intent(human_seat, "choose_order", {"first": guard % 2 == 0})
				continue
			var st: Dictionary = _last.get("state", {})
			var pend: Dictionary = st.get("pending", {})
			if not pend.is_empty() and pend.get("type", "") != "opponent":
				var answer = "pass"
				match str(pend.get("type", "")):
					"yesno": answer = guard % 2 == 0
					"choice": answer = 0
					"select": answer = (pend.get("candidates", []) as Array).slice(0, int(pend.get("min", 1)))
				room.intent(human_seat, "respond", {"answer": answer})
			elif room.actor() == human_seat:
				# Play a little: Set or summon the first card if possible, then end the turn.
				var hand: Array = st["players"][0]["hand"]
				if not hand.is_empty() and guard % 3 == 0:
					var c: Dictionary = hand[0]
					if room.intent(human_seat, "summon", {"uid": int(c["uid"]), "tributes": [], "zone": -1, "face_down": true}).get("ok", false):
						continue
					if room.intent(human_seat, "set_spell_trap", {"uid": int(c["uid"]), "zone": -1}).get("ok", false):
						continue
				var excess := int(st["legal"]["hand_excess"])
				var discards: Array = hand.slice(hand.size() - excess).map(func(x): return int(x["uid"])) if excess > 0 else []
				room.intent(human_seat, "end_turn", {"discards": discards})
			else:
				clock += 100.0
				room.tick(clock)
		if room.state == "finished":
			duels += 1
	check(duels == 16, "all 16 duels finished (%d)" % duels)
	check(checked_batches > 100 and checked_cards > 5000, "enough material was checked (%d batches, %d cards, %d known)" % [checked_batches, checked_cards, known_seen])
	check(problems.is_empty(), "no hidden information leaked: %s" % str(problems))
	print("   hidden-info: %d batches, %d card entries, %d known identities checked" % [checked_batches, checked_cards, known_seen])
	print("online hidden-info tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
