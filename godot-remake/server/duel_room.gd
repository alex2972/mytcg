class_name DuelRoom
extends RefCounted
## One authoritative online duel: rock-paper-scissors, first/second choice, then the rules engine (Duel)
## driven by the two seats' intents. The server never waits for animations (presentation barriers off),
## bots (JoeyAI) play their seat inline, and after every change each human seat receives its own filtered
## batch {seq, events, state}. Timers, disconnects, surrender and the end of the duel are handled here.
## Seats are 0/1 on the server; every client sees itself as player 0 (DuelSnapshot mirrors seat 1).

signal ended(room: DuelRoom)

const HANDS := ["rock", "paper", "scissors"]
const MAX_BOT_STEPS := 3000          ## per change; a bot that loops forever is made to surrender
const TURN_LIMIT := 400              ## a duel that reaches it ends in a draw

var id := ""
var mode := "casual"                 ## casual / ranked / dev
var db: CardDB
var config: Dictionary
var seats: Array = []                ## [{account, name, rating, bot, peer, connected, deck, janken, timeouts, away_since}]
var state := "janken"                ## janken / order / playing / finished
var duel: Duel
var seq := 0
var rng := RandomNumberGenerator.new()
var view_rng := RandomNumberGenerator.new()
var janken_winner := -1
var first_player := -1
var deadline := [0.0, 0.0]           ## when the seat's current obligation times out (0 = none)
var result := {}                     ## filled when finished
var intents: Array = []              ## [seat, kind, args] accepted, for replays/determinism checks
var seed_value := 0
var created_at := 0.0
var last_progress := 0.0
var send_fn: Callable                ## func(peer, kind, payload)
var now_fn: Callable                 ## func() -> float
var log_fn: Callable                 ## func(level, msg)
var _revealed := [{}, {}]            ## per seat: uids identified in the current batch

func setup(room_id: String, room_mode: String, card_db: CardDB, cfg: Dictionary, seat_a: Dictionary, seat_b: Dictionary, sender: Callable, clock: Callable, logger: Callable, fixed_seed := -1) -> void:
	id = room_id
	mode = room_mode
	db = card_db
	config = cfg
	send_fn = sender
	now_fn = clock
	log_fn = logger
	if fixed_seed >= 0:
		rng.seed = fixed_seed
	else:
		var b := Crypto.new().generate_random_bytes(8)
		rng.seed = b.decode_s64(0)
	view_rng.seed = rng.randi()
	for s in [seat_a, seat_b]:
		var seat := {"account": str(s.get("account", "")), "name": str(s.get("name", "CPU")), "rating": int(s.get("rating", 1500)),
			"bot": bool(s.get("bot", false)), "peer": int(s.get("peer", 0)), "connected": int(s.get("peer", 0)) != 0,
			"deck": s.get("deck"), "janken": -1, "timeouts": 0, "away_since": 0.0}
		seats.append(seat)
	created_at = _now()
	last_progress = created_at
	for i in 2:
		_send_start(i)
	_janken_round()

func _now() -> float:
	return now_fn.call()

func human(seat: int) -> bool:
	return not seats[seat]["bot"]

func seat_of_account(account: String) -> int:
	for i in 2:
		if seats[i]["account"] == account and not seats[i]["bot"]:
			return i
	return -1

# --- janken / order ------------------------------------------------------------------------------

func _janken_round(tie_picks := []) -> void:
	state = "janken"
	for i in 2:
		seats[i]["janken"] = rng.randi_range(0, 2) if seats[i]["bot"] else -1
		deadline[i] = 0.0 if seats[i]["bot"] else _now() + float(config["janken_timeout"]) + float(config["timer_grace"])
		if human(i):
			var payload := {"room_id": id, "phase": "pick"}
			if not tie_picks.is_empty():
				payload["tie"] = true
				payload["picks"] = [tie_picks[i], tie_picks[1 - i]]
			_send(i, "room_janken", payload)
	_maybe_resolve_janken()

func _maybe_resolve_janken() -> void:
	if int(seats[0]["janken"]) < 0 or int(seats[1]["janken"]) < 0:
		return
	var a := int(seats[0]["janken"])
	var b := int(seats[1]["janken"])
	if a == b:
		_janken_round([a, b])
		return
	janken_winner = 0 if (a - b + 3) % 3 == 1 else 1      # paper(1) beats rock(0), scissors(2) beats paper, rock beats scissors
	state = "order"
	for i in 2:
		deadline[i] = 0.0
		if human(i):
			_send(i, "room_janken", {"room_id": id, "phase": "order", "picks": [int(seats[i]["janken"]), int(seats[1 - i]["janken"])], "you_won": i == janken_winner})
	if seats[janken_winner]["bot"]:
		_start(janken_winner)
	else:
		deadline[janken_winner] = _now() + float(config["janken_timeout"]) + float(config["timer_grace"])

# --- the duel ------------------------------------------------------------------------------------

func _start(first: int) -> void:
	first_player = first
	state = "playing"
	var decks := []
	for i in 2:
		var src: Deck = seats[i]["deck"]
		var d := Deck.new()
		d.main = src.main.duplicate()
		d.extra = src.extra.duplicate()
		d.side = src.side.duplicate()
		# Shuffled before the engine numbers the cards, so a uid never tells which card it is.
		_shuffle(d.main)
		_shuffle(d.extra)
		decks.append(d)
	seed_value = rng.randi()
	duel = Duel.create(db, decks[0], decks[1], seed_value, first, null, true)
	duel.no_first_turn_attack = true
	duel.fx.presentation_enabled = false
	duel.fx.interactive_selections = true
	duel.fx.interactive_players = [0, 1].filter(func(i): return human(i))
	duel.start_opening_deal()
	_advance()

## After any change: let bots act, end the duel if it is over, send every human seat its batch.
func _advance() -> void:
	last_progress = _now()
	_run_bots()
	if duel.turn > TURN_LIMIT and duel.winner == -1:
		duel.winner = 2
		duel.win_reason = "turn_limit"
	_broadcast()
	if duel.winner != -1:
		_finish(duel.winner, duel.win_reason)
	else:
		_update_deadlines()

## Who must act now: the deciding seat, else the turn player (or -1 when the engine is busy/over).
func actor() -> int:
	if duel == null or duel.winner != -1:
		return -1
	var pend: Dictionary = duel.fx.pending
	if not pend.is_empty():
		return int(pend.get("player", -1))
	if duel.fx.is_busy():
		return -1
	return duel.turn_player

func _run_bots() -> void:
	var steps := 0
	while duel.winner == -1 and steps < MAX_BOT_STEPS:
		var a := actor()
		if a < 0 or not seats[a]["bot"]:
			return
		steps += 1
		var pend: Dictionary = duel.fx.pending
		if not pend.is_empty() and pend.get("type", "") == "presentation":
			duel.respond(true)
			continue
		var before := _progress_mark()
		var acted := JoeyAI.step(duel, a)
		if acted and _progress_mark() != before:
			continue
		# The AI found nothing to do (or did nothing): answer/end safely so the duel moves on.
		if not duel.fx.pending.is_empty() and int(duel.fx.pending.get("player", -1)) == a:
			_auto_answer(a)
		elif duel.turn_player == a:
			_auto_end_turn(a)
		if _progress_mark() == before:
			_log("WARN", "room %s: bot seat %d is stuck (phase %s); it surrenders" % [id, a, duel.phase])
			duel.surrender(a)
			return
	if steps >= MAX_BOT_STEPS:
		_log("ERROR", "room %s: bot step limit reached; the bot surrenders" % id)
		var a := actor()
		if a >= 0:
			duel.surrender(a)

func _progress_mark() -> String:
	return "%d|%d|%s|%d|%s" % [duel.events.size(), duel.turn, duel.phase, duel.winner, str(duel.fx.pending.get("type", "")) + str(duel.fx.pending.get("player", ""))]

## Safe default for a decision nobody answered: pass / no / the first allowed choice.
func _auto_answer(seat: int) -> void:
	var pend: Dictionary = duel.fx.pending
	match str(pend.get("type", "")):
		"chain":
			duel.respond("pass")
		"yesno":
			duel.respond(false)
		"presentation":
			duel.respond(true)
		"choice":
			duel.respond(0)
		"select":
			if not SimpleAI.answer(duel, seat) or (not duel.fx.pending.is_empty() and is_same(duel.fx.pending, pend)):
				var cands: Array = pend.get("candidates", [])
				var n := int(pend.get("min", 1))
				duel.respond(cands.slice(0, n))
		_:
			duel.respond(true)

func _auto_end_turn(seat: int) -> void:
	if duel.phase in ["main1", "battle", "main2"]:
		var excess := duel.hand_excess(seat)
		var hand: Array = duel.side(seat).hand
		var discards: Array = hand.slice(hand.size() - excess).map(func(c): return c.uid) if excess > 0 else []
		duel.end_turn(seat, discards)

func _update_deadlines() -> void:
	deadline = [0.0, 0.0]
	var a := actor()
	if a < 0 or seats[a]["bot"]:
		return
	var limit := float(config["decision_timeout"]) if not duel.fx.pending.is_empty() else float(config["turn_timeout"])
	deadline[a] = _now() + limit + float(config["timer_grace"])

# --- intents ------------------------------------------------------------------------------------

## A human seat asks for something. Returns {ok} or {ok: false, error, reason}.
func intent(seat: int, kind: String, args: Dictionary) -> Dictionary:
	if seat < 0 or seat > 1 or seats[seat]["bot"]:
		return Protocol.fail("not_in_duel")
	if state == "finished":
		return Protocol.fail("not_in_duel")
	if kind == "surrender":
		if state != "playing":
			_finish(1 - seat, "surrender")
			return Protocol.ok()
		duel.surrender(seat)
		_record(seat, kind, args)
		_advance()
		return Protocol.ok()
	if kind == "resync":
		resync(seat)
		return Protocol.ok()
	match state:
		"janken":
			if kind != "janken_pick":
				return Protocol.fail("illegal_action", {"reason": "Pick rock, paper or scissors first."})
			var hand = args.get("hand", -1)
			if typeof(hand) != TYPE_INT or hand < 0 or hand > 2 or int(seats[seat]["janken"]) >= 0:
				return Protocol.fail("invalid_args")
			seats[seat]["janken"] = hand
			deadline[seat] = 0.0
			_maybe_resolve_janken()
			return Protocol.ok()
		"order":
			if kind != "choose_order" or seat != janken_winner:
				return Protocol.fail("illegal_action", {"reason": "Waiting for the order choice."})
			if typeof(args.get("first", null)) != TYPE_BOOL:
				return Protocol.fail("invalid_args")
			_start(seat if args["first"] else 1 - seat)
			return Protocol.ok()
	var why := _apply(seat, kind, args)
	if why == "_invalid":
		return Protocol.fail("invalid_args")
	if why == "_not_yours":
		return Protocol.fail("not_your_decision")
	if why != "":
		return Protocol.fail("not_your_turn" if why == "Not your turn." else "illegal_action", {"reason": why})
	seats[seat]["timeouts"] = 0
	_record(seat, kind, args)
	_advance()
	return Protocol.ok()

func _record(seat: int, kind: String, args: Dictionary) -> void:
	intents.append([seat, kind, args.duplicate(true)])

## Validates and performs one duel action. "" = done, otherwise the reason.
func _apply(seat: int, kind: String, args: Dictionary) -> String:
	var s: Duel.PlayerSide = duel.side(seat)
	match kind:
		"summon":
			var c := _card_arg(args, "uid")
			var tributes = args.get("tributes", [])
			var zone = args.get("zone", -1)
			var face_down = args.get("face_down", false)
			if c == null or typeof(tributes) != TYPE_ARRAY or typeof(zone) != TYPE_INT or typeof(face_down) != TYPE_BOOL or (tributes as Array).size() > 3:
				return "_invalid"
			if not s.hand.has(c):
				return "Select a monster from your hand."
			var tcards := []
			for u in tributes:
				var t := duel.card_by_uid(int(u)) if typeof(u) == TYPE_INT else null
				if t == null or not duel.is_on_field(t) or tcards.has(t):
					return "_invalid"
				tcards.append(t)
			return duel.summon(seat, c, tcards, clampi(zone, -1, 4), face_down)
		"set_spell_trap":
			var c := _card_arg(args, "uid")
			var zone = args.get("zone", -1)
			if c == null or typeof(zone) != TYPE_INT:
				return "_invalid"
			if not s.hand.has(c):
				return "Select a card from your hand."
			return duel.set_spell_trap(seat, c, clampi(zone, -1, 4))
		"change_position":
			var c := _card_arg(args, "uid")
			if c == null:
				return "_invalid"
			if not s.monsters.has(c):
				return "Select one of your monsters."
			return duel.change_position(seat, c)
		"activate":
			var c := _card_arg(args, "uid")
			var idx = args.get("idx", 0)
			if c == null or typeof(idx) != TYPE_INT or idx < 0 or idx > 16:
				return "_invalid"
			if c.controller != seat and c.owner != seat:
				return "That is not your card."
			return duel.activate_effect(seat, c, idx)
		"attack":
			var c := _card_arg(args, "uid")
			var target_uid = args.get("target", -1)
			if c == null or typeof(target_uid) != TYPE_INT:
				return "_invalid"
			if not s.monsters.has(c):
				return "Select one of your monsters."
			var target: DCard = null
			if target_uid >= 0:
				target = duel.card_by_uid(target_uid)
				if target == null or not duel.side(1 - seat).monsters.has(target):
					return "Select an opponent's monster."
			return duel.attack(seat, c, target)
		"to_battle":
			return duel.to_battle(seat)
		"to_main2":
			return duel.to_main2(seat)
		"end_turn":
			var discards = args.get("discards", [])
			if typeof(discards) != TYPE_ARRAY or (discards as Array).size() > 20 or not (discards as Array).all(func(x): return typeof(x) == TYPE_INT):
				return "_invalid"
			return duel.end_turn(seat, discards)
		"respond":
			var pend: Dictionary = duel.fx.pending
			if pend.is_empty() or int(pend.get("player", -1)) != seat:
				return "_not_yours"
			var answer = _clean_answer(str(pend.get("type", "")), args.get("answer"))
			if typeof(answer) == TYPE_STRING and answer == "_invalid":
				return "_invalid"
			return duel.respond(answer)
	return "_invalid"

func _card_arg(args: Dictionary, key: String) -> DCard:
	var u = args.get(key, -1)
	if typeof(u) != TYPE_INT:
		return null
	return duel.card_by_uid(u)

## Coerces a client answer into the exact shape the engine expects for this decision type.
static func _clean_answer(type: String, answer):
	match type:
		"chain":
			if answer == null or (typeof(answer) == TYPE_STRING and answer == "pass") or (typeof(answer) == TYPE_DICTIONARY and answer.get("pass", false) == true):
				return "pass"
			if typeof(answer) == TYPE_DICTIONARY and typeof(answer.get("uid")) == TYPE_INT and typeof(answer.get("idx")) == TYPE_INT:
				return {"uid": int(answer["uid"]), "idx": int(answer["idx"])}
			return "_invalid"
		"select":
			if typeof(answer) == TYPE_INT:
				return [answer]
			if typeof(answer) == TYPE_ARRAY and (answer as Array).size() <= 60 and (answer as Array).all(func(x): return typeof(x) == TYPE_INT):
				return answer
			return "_invalid"
		"yesno":
			return bool(answer) if typeof(answer) == TYPE_BOOL else "_invalid"
		"choice":
			return answer if typeof(answer) == TYPE_INT else "_invalid"
		"presentation":
			return true
	if typeof(answer) in [TYPE_BOOL, TYPE_INT, TYPE_NIL]:
		return answer
	return "_invalid"

# --- batches --------------------------------------------------------------------------------------

func _broadcast() -> void:
	var events: Array = duel.drain_events()
	_revealed = [{}, {}]
	for e in events:
		match str(e.get("type", "")):
			"reveal_cards":
				for u in e.get("cards", []):
					if e.get("public", false):
						_revealed[0][int(u)] = true
						_revealed[1][int(u)] = true
					elif int(e.get("viewer", -1)) in [0, 1]:
						_revealed[int(e["viewer"])][int(u)] = true
			"excavate":
				_revealed[0][int(e.get("uid", -1))] = true
				_revealed[1][int(e.get("uid", -1))] = true
	seq += 1
	for i in 2:
		if human(i):
			_send(i, "room_batch", {"room_id": id, "seq": seq, "events": events.map(func(e): return DuelSnapshot.mirror_event(e, i)),
				"state": DuelSnapshot.build(duel, i, _revealed[i], view_rng)})

## Full current state for a seat (reconnects, gaps in seq).
func resync(seat: int) -> void:
	if not human(seat):
		return
	_send_start(seat)
	if state == "janken" and int(seats[seat]["janken"]) < 0:
		_send(seat, "room_janken", {"room_id": id, "phase": "pick"})
	elif state == "order" and seat == janken_winner:
		_send(seat, "room_janken", {"room_id": id, "phase": "order", "picks": [int(seats[seat]["janken"]), int(seats[1 - seat]["janken"])], "you_won": true})
	elif duel != null:
		_send(seat, "room_batch", {"room_id": id, "seq": seq, "events": [], "state": DuelSnapshot.build(duel, seat, {}, view_rng), "resync": true})
	if state == "finished":
		_send(seat, "room_result", result_for(seat))

func _send_start(seat: int) -> void:
	if not human(seat):
		return
	var opp: Dictionary = seats[1 - seat]
	_send(seat, "room_start", {"room_id": id, "mode": mode, "state": state,
		"you": {"name": seats[seat]["name"], "rating": seats[seat]["rating"]},
		"opponent": {"name": opp["name"], "rating": opp["rating"], "bot": opp["bot"]}})

func _send(seat: int, kind: String, payload: Dictionary) -> void:
	var s: Dictionary = seats[seat]
	if s["bot"] or not s["connected"] or int(s["peer"]) == 0:
		return
	send_fn.call(int(s["peer"]), kind, payload)

# --- time, connections, the end ---------------------------------------------------------------------

func tick(t: float) -> void:
	if state == "finished":
		return
	for i in 2:
		if not human(i):
			continue
		if not seats[i]["connected"] and float(seats[i]["away_since"]) > 0.0 and t - float(seats[i]["away_since"]) > float(config["reconnect_grace"]):
			_log("INFO", "room %s: seat %d did not come back" % [id, i])
			_forfeit(i, "disconnect")
			return
		if deadline[i] > 0.0 and t > deadline[i] and seats[i]["connected"]:
			_timeout(i)
			if state == "finished":
				return
	if state == "playing" and duel.winner == -1 and actor() < 0:
		_log("ERROR", "room %s: no one can act (phase %s); ending as a draw" % [id, duel.phase])
		_finish(2, "stuck")

func _timeout(seat: int) -> void:
	deadline[seat] = 0.0
	seats[seat]["timeouts"] = int(seats[seat]["timeouts"]) + 1
	if int(seats[seat]["timeouts"]) >= int(config["max_timeouts"]):
		_forfeit(seat, "timeout")
		return
	match state:
		"janken":
			seats[seat]["janken"] = rng.randi_range(0, 2)
			_maybe_resolve_janken()
		"order":
			_start(seat)
		"playing":
			if not duel.fx.pending.is_empty() and int(duel.fx.pending.get("player", -1)) == seat:
				_auto_answer(seat)
			elif duel.turn_player == seat:
				_auto_end_turn(seat)
			_advance()

func _forfeit(seat: int, reason: String) -> void:
	if state == "playing" and duel != null and duel.winner == -1:
		duel.surrender(seat)
		duel.win_reason = reason
		_broadcast()
	_finish(1 - seat, reason)

func on_disconnect(seat: int) -> void:
	if seat < 0 or not human(seat):
		return
	seats[seat]["connected"] = false
	seats[seat]["away_since"] = _now()

func on_reconnect(seat: int, peer: int) -> void:
	if seat < 0 or not human(seat):
		return
	seats[seat]["peer"] = peer
	seats[seat]["connected"] = true
	seats[seat]["away_since"] = 0.0
	if deadline[seat] > 0.0:
		deadline[seat] = maxf(deadline[seat], _now() + float(config["timer_grace"]))
	resync(seat)

## winner: 0/1 seat, 2 = draw.
func _finish(winner: int, reason: String) -> void:
	if state == "finished":
		return
	state = "finished"
	deadline = [0.0, 0.0]
	result = {"winner": winner, "reason": reason, "turns": duel.turn if duel != null else 0, "mode": mode,
		"accounts": [seats[0]["account"], seats[1]["account"]], "bots": [seats[0]["bot"], seats[1]["bot"]],
		"names": [seats[0]["name"], seats[1]["name"]], "started": created_at, "ended": _now()}
	ended.emit(self)

## The result as seat `seat` sees it (rating/reward details are added by the manager).
func result_for(seat: int) -> Dictionary:
	var w := int(result.get("winner", 2))
	var out := {"room_id": id, "draw": w == 2, "you_won": w == seat, "reason": result.get("reason", ""), "turns": result.get("turns", 0), "mode": mode}
	out.merge(result.get("per_seat", [{}, {}])[seat] if result.has("per_seat") else {}, true)
	return out

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

func _log(level: String, msg: String) -> void:
	if log_fn.is_valid():
		log_fn.call(level, msg)
