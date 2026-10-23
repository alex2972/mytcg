class_name RemoteDuel
extends Duel
## The client's picture of an online duel. It extends Duel so the existing DuelBoard can use it unchanged,
## but it runs no rules: its zones, cards and pending decision are filled from the server's snapshots
## (always from this player's point of view, player 0 = me), rule questions are answered from the
## server's precomputed `legal` data, and actions become intents sent to the server.
## Batches are queued on arrival and applied when the board drains events, so the picture never runs
## ahead of the animations. Card objects are kept per uid across snapshots (the board holds them).

signal updated                     ## a batch was queued (the board should animate it)
signal refused(reason: String)     ## the server refused our last intent
signal result_received(result: Dictionary)

var room_id := ""
var client: OnlineClient
var last_seq := 0
var in_flight := false             ## an intent is waiting for the server's answer
var _queue: Array = []             ## [{seq, events, state}]
var _stats := {}                   ## uid -> [atk, def, level]
var _legal := {}
var _pending_snapshot := {}        ## the server's pending (restored when an intent is refused)
var _ready_state := false

static func make(card_db: CardDB, online_client: OnlineClient, room: String) -> RemoteDuel:
	var d := RemoteDuel.new()
	d.db = card_db
	d.client = online_client
	d.room_id = room
	if Duel._default_effects == null:
		Duel._default_effects = EffectDB.load_default(card_db)
	d.fx = Fx.new(d, Duel._default_effects)
	d.sides = [Duel.PlayerSide.new(), Duel.PlayerSide.new()]
	d.phase = "opening"
	d.rng.randomize()
	return d

## Has at least one snapshot been applied?
func has_state() -> bool:
	return _ready_state

# --- incoming ------------------------------------------------------------------------------------

## A "room_batch" push from the server.
func receive_batch(payload: Dictionary) -> void:
	if str(payload.get("room_id", "")) != room_id:
		return
	var s := int(payload.get("seq", 0))
	if payload.get("resync", false):
		_queue.clear()
		_queue.append(payload)
		last_seq = s
	elif s <= last_seq:
		return
	elif s != last_seq + 1 and last_seq != 0:
		last_seq = s
		_queue.append(payload)
		_send("resync", {})          # we missed something: ask for the full picture
	else:
		last_seq = s
		_queue.append(payload)
	in_flight = false
	if not _ready_state:
		_apply(_queue.back()["state"])
	updated.emit()

func receive_result(payload: Dictionary) -> void:
	if str(payload.get("room_id", "")) == room_id:
		result_received.emit(payload)

## Queued events (oldest first); the newest state becomes current.
func drain_events() -> Array:
	if _queue.is_empty():
		return []
	var out: Array = []
	for b in _queue:
		out.append_array(b.get("events", []))
	var latest: Dictionary = _queue.back()["state"]
	_queue.clear()
	_apply(latest)
	return out

func has_queued() -> bool:
	return not _queue.is_empty()

func _card(uid: int) -> DCard:
	if not cards.has(uid):
		cards[uid] = DCard.new(uid, 0, 0)
	return cards[uid]

func _apply(st: Dictionary) -> void:
	if st.is_empty():
		return
	_ready_state = true
	var known: Dictionary = st.get("known", {})
	var data_by_uid := {}
	for p in 2:
		var ps: Dictionary = st["players"][p]
		var side: Duel.PlayerSide = sides[p]
		side.lp = int(ps.get("lp", 0))
		side.deck = _cards_of(ps.get("deck", []), known, data_by_uid)
		side.hand = _cards_of(ps.get("hand", []), known, data_by_uid)
		side.grave = _cards_of(ps.get("grave", []), known, data_by_uid)
		side.banished = _cards_of(ps.get("banished", []), known, data_by_uid)
		side.extra = _cards_of(ps.get("extra", []), known, data_by_uid)
		side.monsters = (ps.get("monsters", []) as Array).map(func(c): return null if c == null else _from(c, known, data_by_uid))
		side.spells = (ps.get("spells", []) as Array).map(func(c): return null if c == null else _from(c, known, data_by_uid))
		while side.monsters.size() < ZONES:
			side.monsters.append(null)
		while side.spells.size() < ZONES:
			side.spells.append(null)
		side.field_spell = null if ps.get("field_spell") == null else _from(ps["field_spell"], known, data_by_uid)
	for uid in data_by_uid:          # equip links once every card exists
		var d: Dictionary = data_by_uid[uid]
		var c: DCard = cards[uid]
		c.equipped_to = cards.get(int(d.get("equipped_to", -1)))
		c.equips = (d.get("equips", []) as Array).map(func(u): return cards.get(int(u))).filter(func(x): return x != null)
	turn = int(st.get("turn", 0))
	turn_player = int(st.get("turn_player", 0))
	phase = str(st.get("phase", ""))
	winner = int(st.get("winner", -1))
	win_reason = str(st.get("win_reason", ""))
	normal_summoned = bool(st.get("normal_summoned", false))
	no_first_turn_attack = bool(st.get("no_first_turn_attack", true))
	current_attack = {}
	for k in st.get("current_attack", {}):
		var v = st["current_attack"][k]
		current_attack[k] = cards.get(int(v)) if k in ["attacker", "target"] and typeof(v) in [TYPE_INT, TYPE_FLOAT] else v
	soul_exchange = st.get("soul_exchange", {})
	fx.chain = (st.get("chain", []) as Array).map(func(l): return {"card": cards.get(int(l.get("card", -1))), "player": int(l.get("player", 0))}).filter(func(l): return l["card"] != null)
	var pend: Dictionary = st.get("pending", {})
	_pending_snapshot = fx.pending if pend == fx.pending else pend      # keep the same object when unchanged
	fx.pending = _pending_snapshot
	_legal = st.get("legal", {})

func _cards_of(list: Array, known: Dictionary, sink: Dictionary) -> Array:
	return list.map(func(c): return _from(c, known, sink))

func _from(d: Dictionary, known: Dictionary, sink: Dictionary) -> DCard:
	var uid := int(d.get("uid", 0))
	var c := _card(uid)
	if not d.get("hidden", false):
		c.idx = int(d.get("idx", 0))
	elif known.has(str(uid)):
		c.idx = int(known[str(uid)])
	c.owner = int(d.get("owner", 0))
	c.controller = int(d.get("controller", c.owner))
	c.face_up = bool(d.get("face_up", false))
	c.pos = str(d.get("pos", "atk"))
	c.token = str(d.get("token", ""))
	if not d.get("hidden", false):
		c.summon_turn = int(d.get("summon_turn", -1))
		c.attacked = bool(d.get("attacked", false))
		c.pos_changed = bool(d.get("pos_changed", false))
		c.flags = d.get("flags", {}) if d.get("flags", {}) is Dictionary else {}
		_stats[uid] = [int(d.get("atk", 0)), int(d.get("def", 0)), int(d.get("level", 0))]
		sink[uid] = d
	return c

# --- rule questions answered from the snapshot ------------------------------------------------------

func card_data(c: DCard) -> Dictionary:
	if c.token != "":
		return TOKENS.get(c.token, {})
	return db.card(c.idx) if c.idx > 0 else {}

func atk_of(c: DCard) -> int:
	return int(_stats.get(c.uid, [int(card_data(c).get("atk", 0))])[0])

func def_of(c: DCard) -> int:
	var s: Array = _stats.get(c.uid, [])
	return int(s[1]) if s.size() > 1 else int(card_data(c).get("def", 0))

func level_of(c: DCard) -> int:
	var s: Array = _stats.get(c.uid, [])
	return int(s[2]) if s.size() > 2 else int(card_data(c).get("level", 0))

func summon_problem(_p: int, c: DCard) -> String:
	return str(_legal.get("summon_problem", {}).get(str(c.uid), "You can't do that now."))

func tributes_required(c: DCard) -> int:
	return int(_legal.get("tributes", {}).get(str(c.uid), 0))

func can_attack(_p: int, c: DCard, ignore_busy := false) -> String:
	var key := str(c.uid) + (":idle" if ignore_busy else "")
	return str(_legal.get("can_attack", {}).get(key, "This monster cannot attack."))

func can_attack_directly(c: DCard) -> bool:
	return bool(_legal.get("direct", {}).get(str(c.uid), false))

func activatable_effects(_p: int) -> Array:
	var out := []
	for e in _legal.get("effects", []):
		var x: Dictionary = e.duplicate()
		x["uid"] = int(x.get("uid", 0))
		x["idx"] = int(x.get("idx", 0))
		out.append(x)
	return out

func hand_excess(_p: int) -> int:
	return int(_legal.get("hand_excess", 0))

func check_states() -> bool:
	return false                       # the server destroys cards; the client only shows its batches

func start_opening_deal() -> void:
	pass

# --- actions become intents (the result arrives with the next batch) ------------------------------

func summon(_p: int, c: DCard, tributes: Array = [], zone := -1, set_face_down := false) -> String:
	return _act("summon", {"uid": c.uid, "tributes": tributes.map(func(t): return t.uid if t is DCard else int(t)), "zone": zone, "face_down": set_face_down})

func set_spell_trap(_p: int, c: DCard, zone := -1) -> String:
	return _act("set_spell_trap", {"uid": c.uid, "zone": zone})

func change_position(_p: int, c: DCard) -> String:
	return _act("change_position", {"uid": c.uid})

func activate_effect(_p: int, c: DCard, idx := 0) -> String:
	return _act("activate", {"uid": c.uid, "idx": idx})

func attack(_p: int, c: DCard, target: DCard = null) -> String:
	return _act("attack", {"uid": c.uid, "target": target.uid if target != null else -1})

func to_battle(_p: int) -> String:
	return _act("to_battle", {})

func to_main2(_p: int) -> String:
	return _act("to_main2", {})

func end_turn(_p: int, discards: Array = []) -> String:
	return _act("end_turn", {"discards": discards.map(func(u): return u.uid if u is DCard else int(u))})

func surrender(_p: int) -> void:
	_act("surrender", {})

func respond(answer) -> String:
	if fx.pending.is_empty() or int(fx.pending.get("player", -1)) != 0:
		return "Nothing to answer."
	return _act("respond", {"answer": Protocol.plain(answer)})

## Sends an intent and blocks further input until the server answers (the board sees a busy pending).
func _act(kind: String, args: Dictionary) -> String:
	if in_flight:
		return "Wait for the server."
	in_flight = true
	fx.pending = {"type": "wait", "player": 1}
	_send(kind, args)
	return ""

func _send(kind: String, args: Dictionary) -> void:
	if client == null:
		return
	var r: Dictionary = await client.request("room_intent", {"room_id": room_id, "kind": kind, "args": args})
	if not r.get("ok", false):
		in_flight = false
		fx.pending = _pending_snapshot
		refused.emit(str(r.get("reason", r.get("error", "refused"))))
	elif in_flight and kind in ["resync"]:
		in_flight = false
