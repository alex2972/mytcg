class_name Fx
extends RefCounted
## The effect engine: chains, response windows, triggers and the pausable script interpreter.
##
## Everything runs as a stack of small "tasks" so a script can stop to ask a player something (`pending`)
## and carry on exactly where it left off when `respond()` is called. Callers (UI / AI / tests) only ever see:
##   - fx.pending : {} when idle, otherwise a decision for `pending.player` to answer with respond()
##   - the normal Duel state
## Events from the rules engine are offered as response windows (traps, quick effects, triggers).

var duel: Duel
var edb: EffectDB
var ops: FxOps
var tasks: Array = []
var chain: Array = []            ## open links, last = top
var pending: Dictionary = {}
var resolving := false
var activating := 0              ## activations whose cost/targets are still being paid; events raised meanwhile wait
var queued: Array = []           ## events raised while a chain resolves; windows open after it finishes
var _pumping := false
var rule_cache_turn := -1

func _init(d: Duel, effect_db: EffectDB) -> void:
	duel = d
	edb = effect_db
	ops = FxOps.new(self)

# --- lookups -------------------------------------------------------------------------

func effects_of(c: DCard) -> Array:
	return edb.for_number(c.number)

## Does any card on the field react to `event`? (used to avoid opening empty windows for frequent events)
func has_listener(event: String) -> bool:
	for p in 2:
		for c in cards_controlled(p):
			for e in effects_of(c):
				var w = e.get("when", "")
				if (w is Array and w.has(event)) or (w is String and w == event):
					return true
	return false

func is_busy() -> bool:
	return not pending.is_empty() or not tasks.is_empty()

# --- the task pump ------------------------------------------------------------------

func pump() -> void:
	if _pumping:
		return
	_pumping = true
	while pending.is_empty() and not tasks.is_empty():
		var t: Dictionary = tasks.back()
		match t["t"]:
			"call":
				tasks.pop_back()
				(t["fn"] as Callable).call()
			"script": _run_script(t)
			"window": _run_window(t)
			"resolve": _run_resolve(t)
	_pumping = false

## Answer the current decision. Returns "" or a reason the answer was refused.
func respond(answer) -> String:
	if pending.is_empty():
		return "Nothing to answer."
	var why: String = ops.accept(pending, answer)
	if why != "":
		return why
	pump()
	return ""

func _run_script(t: Dictionary) -> void:
	var steps: Array = t["steps"]
	while t["i"] < steps.size():
		var step: Dictionary = steps[t["i"]]
		t["i"] += 1
		var r = ops.run(step, t["ctx"])
		if r is Dictionary:
			pending = r
			pending["_task"] = t
			return
		if r is String and r == "pushed":
			return
		if r is String and r == "abort":
			tasks.erase(t)
			return
	if tasks.has(t) and tasks.back() == t:
		tasks.pop_back()

func push_script(steps: Array, ctx: Dictionary) -> void:
	tasks.append({"t": "script", "steps": steps, "i": 0, "ctx": ctx})

func push_call(fn: Callable) -> void:
	tasks.append({"t": "call", "fn": fn})

# --- events and response windows --------------------------------------------------

## Called by the rules engine when something happened that other cards may react to.
## `cont` runs after the window (and any chain it produced) has fully resolved.
func window(event: String, data: Dictionary, cont: Callable = Callable()) -> void:
	if (resolving or activating > 0) and not cont.is_valid():
		queued.append({"event": event, "data": data})
		return
	if cont.is_valid():
		push_call(cont)
	tasks.append({"t": "window", "event": event, "data": data, "cur": duel.turn_player, "passes": 0, "fired": {}, "stage": 0})
	pump()

func _run_window(t: Dictionary) -> void:
	var cur: int = t["cur"]
	if t["passes"] >= 2:
		tasks.pop_back()
		if not chain.is_empty():
			resolving = true
			tasks.append({"t": "resolve"})
		return
	# mandatory effects fire on their own the first time this player has priority
	var auto := _auto_effects(cur, t)
	if not auto.is_empty():
		var o: Dictionary = auto[0]
		t["fired"]["%d:%d" % [o["uid"], o["idx"]]] = true
		t["passes"] = 0
		t["cur"] = 1 - cur
		_start_activation(cur, duel_card(o["uid"]), o["idx"], t["event"], t["data"], false)
		return
	var options := options_for(cur, t["event"], t["data"], t)
	if options.is_empty():
		t["passes"] += 1
		t["cur"] = 1 - cur
		return
	pending = {"type": "chain", "player": cur, "options": options, "event": t["event"], "_task": t, "prompt": 8}

func _auto_effects(p: int, t: Dictionary) -> Array:
	var out := []
	for o in options_for(p, t["event"], t["data"], t):
		if o["mandatory"] and not t["fired"].has("%d:%d" % [o["uid"], o["idx"]]):
			out.append(o)
	return out

## Effects `p` could activate right now in response to `event`.
func options_for(p: int, event: String, data: Dictionary, window_task: Dictionary = {}) -> Array:
	var out := []
	for c in cards_controlled(p) + _extra_zone_cards(p):
		var effs := effects_of(c)
		for i in effs.size():
			var e: Dictionary = effs[i]
			if _event_matches(e, event) and activation_problem(p, c, i, event, data) == "":
				if window_task.has("fired") and window_task["fired"].has("%d:%d" % [c.uid, i]):
					continue
				var mandatory: bool = e.get("mandatory", e.get("type", "") in ["flip", "trigger_forced"])
				out.append({"uid": c.uid, "idx": i, "mandatory": mandatory, "type": e.get("type", ""), "name": duel.db.card_name(c.idx)})
	return out

func _event_matches(e: Dictionary, event: String) -> bool:
	var w = e.get("when", "")
	return (w is Array and w.has(event)) or (w is String and w == event)

func cards_controlled(p: int) -> Array:
	var s: Duel.PlayerSide = duel.side(p)
	var out := []
	for c in s.monsters + s.spells:
		if c != null:
			out.append(c)
	if s.field_spell != null:
		out.append(s.field_spell)
	return out

## Cards outside the field that may have usable effects (e.g. "when sent to the graveyard" from the grave, or hand quick effects).
func _extra_zone_cards(p: int) -> Array:
	var s: Duel.PlayerSide = duel.side(p)
	var out := []
	for c in s.grave:
		if not effects_of(c).is_empty():
			out.append(c)
	# cards in hand only answer an event when their effect explicitly says it works from the hand
	for c in s.hand:
		for e in effects_of(c):
			if e.get("zone", "") == "hand":
				out.append(c)
				break
	return out

func duel_card(uid: int) -> DCard:
	return duel.card_by_uid(uid)

# --- activation ---------------------------------------------------------------------

## Why `c`'s effect `idx` cannot be activated by `p` now ("" = it can).
func activation_problem(p: int, c: DCard, idx: int, event: String, data: Dictionary) -> String:
	var effs := effects_of(c)
	if idx >= effs.size():
		return "No such effect."
	var e: Dictionary = effs[idx]
	var s: Duel.PlayerSide = duel.side(p)
	var zone := _zone_of(c)
	var default_zone := "hand_or_field" if e.get("type", "") in ["spell", "equip", "field", "ritual_spell", "quickplay"] else "field"
	var needed_zone: String = e.get("zone", default_zone)
	match needed_zone:
		"field":
			if zone != "monster" and zone != "spell" and zone != "fieldspell":
				return "Not on the field."
		"grave":
			if zone != "grave":
				return "Not in the graveyard."
		"hand":
			if zone != "hand":
				return "Not in the hand."
		"extra":
			if zone != "extra":
				return "Not in the Extra Deck."
		"deck":
			if zone != "deck":
				return "Not in the Deck."
		"hand_or_field":
			if zone != "hand" and zone != "monster" and zone != "spell":
				return "Wrong zone."
	if c.controller != p and zone != "grave" and zone != "hand":
		return "Not yours."
	if zone == "grave" or zone == "hand":
		if c.owner != p:
			return "Not yours."
	var type: String = e.get("type", "")
	# face-up requirements: monsters' effects need the card face-up (flip effects trigger as they flip)
	if zone == "monster" and not c.face_up and type not in ["flip"] and not e.get("face_down_ok", false):
		return "Face-down."
	# Set spell/trap: activatable only from the turn after it was Set (traps) — quick-play likewise
	if (zone == "spell" or zone == "fieldspell") and not c.face_up and type in ["trap", "counter", "quickplay", "continuous_trap"] and c.summon_turn >= duel.turn:
		return "Cannot activate the turn it was Set."
	if (zone == "spell" or zone == "fieldspell") and c.face_up and type in ["spell", "equip", "field", "ritual_spell", "trap", "counter", "quickplay", "continuous_trap"]:
		return "Already face-up."
	if type in ["trap", "counter", "continuous_trap"] and event == "":
		return "Wait for the right timing."
	if type == "flip" and rule_active("no_flip_effects"):
		return "Flip Effects are negated."
	if type in ["trap", "counter", "continuous_trap"] and rule_active("no_trap"):
		return "Trap Cards cannot be activated."
	if type in ["spell", "equip", "field", "ritual_spell", "quickplay", "trap", "counter", "continuous_trap"] and duel.lockdown_until > duel.turn:
		return "Spell and Trap Cards cannot be activated right now."
	if type in ["spell", "equip", "field", "ritual_spell", "quickplay"] and rule_active("no_spell") and not (zone == "spell" and c.face_up):
		return "Spell Cards cannot be activated."
	if (zone == "spell" or zone == "fieldspell") and not c.face_up and type in ["trigger", "trigger_forced"]:
		return "Face-down."
	if type == "quickplay" and zone == "hand" and p != duel.turn_player:
		return "Quick-Play Spells can only be activated from the hand on your own turn."
	# once per turn
	if e.get("once_per_turn", false) and c.used.get(idx, -1) == duel.turn:
		return "Once per turn."
	# chain / speed rules
	var speed: int = e.get("speed", 1)
	if not chain.is_empty():
		var top: Dictionary = chain.back()
		if speed < maxi(2, int(top["speed"])):
			return "Spell speed too low."
	elif event != "" and speed < 2 and type not in ["flip", "trigger", "trigger_forced", "trap_trigger"]:
		return "Spell speed too low."
	# own-turn main-phase effects
	if type in ["spell", "equip", "field", "ritual_spell", "ignition"] or (type == "quickplay" and event == ""):
		if event == "":
			if duel.turn_player != p or not duel.in_main_phase():
				return "Only during your Main Phase."
			if not chain.is_empty():
				return "A chain is open."
	if type in ["spell", "equip", "field", "ritual_spell"] and zone == "hand":
		if s.spells.find(null) == -1 and type != "field":
			return "Your Spell and Trap Card Zone is full."
	return ops.conditions_ok(e.get("cond", []), {"src": c, "controller": p, "event": data, "effect": e, "idx": idx, "vars": {}}, true)

func _zone_of(c: DCard) -> String:
	var s: Duel.PlayerSide = duel.side(c.controller)
	if (s.monsters as Array).has(c):
		return "monster"
	if (s.spells as Array).has(c):
		return "spell"
	if s.field_spell == c:
		return "fieldspell"
	var o: Duel.PlayerSide = duel.side(c.owner)
	if (o.hand as Array).has(c):
		return "hand"
	if (o.extra as Array).has(c):
		return "extra"
	if (o.deck as Array).has(c):
		return "deck"
	if (o.grave as Array).has(c):
		return "grave"
	return "other"

## Voluntary activation from the UI / AI (main-phase spells, ignition effects, Set cards on your own turn).
func activate(p: int, c: DCard, idx: int) -> String:
	if not pending.is_empty() or not tasks.is_empty():
		return "Resolve the pending decision first."
	var why := activation_problem(p, c, idx, "", {})
	if why != "":
		return why
	_start_activation(p, c, idx, "", {}, true)
	return ""

func _start_activation(p: int, c: DCard, idx: int, event: String, data: Dictionary, open_window: bool) -> void:
	var e: Dictionary = effects_of(c)[idx]
	var ctx := {"src": c, "controller": p, "vars": {}, "event": data, "effect": e, "idx": idx}
	var type: String = e.get("type", "")
	# physical placement: spells from hand go to the field; Set cards turn face-up
	if _zone_of(c) == "hand" and type in ["spell", "equip", "field", "ritual_spell", "quickplay", "trap", "counter"]:
		duel.place_spell_from_hand(c, type == "field")
	if not c.face_up and _zone_of(c) in ["spell", "monster"]:
		c.face_up = true
		duel.log_event("flip", {"player": p, "uid": c.uid})
	c.used[idx] = duel.turn
	if c.borrowed_from != -1:
		duel.damage_player(p, 2000, "effect")               # Graverobber's price
	activating += 1
	var add := func():
		activating -= 1
		_add_link(p, c, idx, ctx, open_window)
	push_call(add)
	if not (e.get("target", []) as Array).is_empty():
		push_script(e["target"], ctx)
	if not (e.get("cost", []) as Array).is_empty():
		push_script(e["cost"], ctx)
	pump()

func _add_link(p: int, c: DCard, idx: int, ctx: Dictionary, open_window: bool) -> void:
	var e: Dictionary = ctx["effect"]
	var kind := "monster_effect"
	if e.get("type", "") in ["spell", "equip", "field", "ritual_spell", "quickplay"]:
		kind = "spell"
	elif e.get("type", "") in ["trap", "counter", "continuous_trap"]:
		kind = "trap"
	var link := {"uid": c.uid, "card": c, "player": p, "idx": idx, "ctx": ctx, "speed": e.get("speed", 1), "kind": kind, "negated": false}
	chain.append(link)
	duel.log_event("chain", {"player": p, "uid": c.uid, "idx": idx, "n": chain.size(), "kind": kind})
	if open_window:
		# the other player may respond; priority starts with them
		tasks.append({"t": "window", "event": "activated_" + kind, "data": {"player": p, "uid": c.uid, "kind": kind}, "cur": 1 - p, "passes": 0, "fired": {}, "stage": 0})

# --- chain resolution ---------------------------------------------------------------

func _run_resolve(_t: Dictionary) -> void:
	if chain.is_empty():
		tasks.pop_back()
		resolving = false
		_flush_queue()
		return
	var link: Dictionary = chain.pop_back()
	var c: DCard = link["card"]
	var e: Dictionary = link["ctx"]["effect"]
	var finish := func():
		_dispose_after_resolution(link)
	push_call(finish)
	# a Spell that has to stay on the field (Equip, Field, Continuous) does nothing if it was destroyed in response
	if (e.get("type", "") in ["equip", "field"] or e.get("stay", false)) and e.get("type", "") in ["spell", "equip", "field", "ritual_spell"] 			and _zone_of(c) not in ["spell", "fieldspell"]:
		link["negated"] = true
	if link["negated"]:
		duel.log_event("negated", {"uid": c.uid})
		return
	var steps: Array = e.get("do", [])
	if not steps.is_empty():
		push_script(steps, link["ctx"])

func _dispose_after_resolution(link: Dictionary) -> void:
	var c: DCard = link["card"]
	var e: Dictionary = link["ctx"]["effect"]
	var type: String = e.get("type", "")
	if e.get("stay", false):
		return
	if type in ["spell", "quickplay", "ritual_spell", "trap", "counter"] and _zone_of(c) == "spell":
		duel.send_to_grave(c, "resolved")
	elif type == "equip" and c.equipped_to == null and _zone_of(c) == "spell":
		duel.send_to_grave(c, "equip_failed")

func _flush_queue() -> void:
	if queued.is_empty():
		return
	var q := queued
	queued = []
	for i in range(q.size() - 1, -1, -1):
		tasks.append({"t": "window", "event": q[i]["event"], "data": q[i]["data"], "cur": duel.turn_player, "passes": 0, "fired": {}, "stage": 0})

# --- static modifiers and rules ------------------------------------------------------

## Extra ATK/DEF `c` gets from face-up cards' static effects (equips, field spells, continuous effects) and timed mods.
func stat_bonus(c: DCard, stat: String) -> int:
	var total := 0
	for m in c.mods:
		total += int(m.get(stat, 0))
	if c.equipped_to != null:
		pass
	if not c.equips.is_empty() and not rule_active("no_equip"):
		for eq in c.equips:
			total += int(eq.equip_mod.get(stat, 0))
	for p in 2:
		for src in cards_controlled(p):
			if not src.face_up:
				continue
			for e in effects_of(src):
				if e.get("type", "") != "static" or not e.has("mod"):
					continue
				var m: Dictionary = e["mod"]
				if m.has("per") and stat in (m["per"]["stats"] as Array):
					if _static_applies(src, m, c):
						var pc := {"src": src, "controller": c.controller, "vars": {}, "event": {}}
						var n := ops.select_candidates({"from": m["per"]["zone"], "filter": m["per"].get("filter", {})}, pc).size()
						total += mini(n, int(m["per"].get("max_n", 1000))) * int(m["per"]["by"])
				if m.get("half_atk", false) and stat == "atk" and _static_applies(src, m, c):
					# Mirror Wall: half of the ATK the monster would otherwise have
					@warning_ignore("integer_division")
					total -= (int(duel.card_data(c).get("atk", 0)) + c.atk_bonus) / 2
				if m.has("lp_rule") and stat == "atk" and _static_applies(src, m, c):
					# Megamorph: double the original ATK while behind in Life Points, halve it while ahead
					var mine: int = duel.side(c.controller).lp
					var theirs: int = duel.side(1 - c.controller).lp
					var base: int = int(duel.card_data(c).get("atk", 0))
					if mine < theirs:
						total += base
					elif mine > theirs:
						total -= base / 2
				if not m.has(stat):
					continue
				if not _static_applies(src, m, c):
					continue
				if m.get("same_name", false) and not _has_twin(c):
					continue
				total += int(m[stat])
	return total

func _has_twin(c: DCard) -> bool:
	for p in 2:
		for other in duel.monsters_of(p):
			if other != c and other.face_up and duel.db.card_name(other.idx) == duel.db.card_name(c.idx):
				return true
	return false

func _static_applies(src: DCard, m: Dictionary, c: DCard) -> bool:
	var scope: String = m.get("scope", "all")
	match scope:
		"self": if c != src: return false
		"mine": if c.controller != src.controller: return false
		"theirs": if c.controller == src.controller: return false
		"equipped": if c.equips.has(src) == false: return false
	return ops.matches(c, m.get("filter", {}), {"src": src, "controller": src.controller})

## Does a face-up card controlled by `p` carry the static rule (player-wide rules such as Tornado Wall's "no_damage")?
func player_rule(rule: String, p: int) -> bool:
	for src in cards_controlled(p):
		if not src.face_up:
			continue
		for e in effects_of(src):
			if e.get("type", "") == "static" and e.get("rule", "") == rule:
				return true
	return false

## Is a continuous rule (e.g. "no_attack") in force against `c`?
func rule_active(rule: String, c: DCard = null) -> bool:
	for p in 2:
		for src in cards_controlled(p):
			if not src.face_up:
				continue
			for e in effects_of(src):
				if e.get("type", "") == "static" and e.get("rule", "") == rule:
					if c == null or _static_applies(src, e, c):
						return true
	return false
