class_name FxOps
extends RefCounted
## The verbs of the effect language, selectors/filters, conditions and decision handling. See docs/EFFECTS.md.
## `run(step, ctx)` returns null to continue, a Dictionary (a pending decision) to pause, "pushed" when it queued a
## nested script, or "abort" to cancel the rest of the script.

var fx: Fx
var duel: Duel

const ATTRS := {"LIGHT": 1, "DARK": 2, "WATER": 3, "FIRE": 4, "EARTH": 5, "WIND": 6, "DIVINE": 7}

func _init(f: Fx) -> void:
	fx = f
	duel = f.duel

# --- references -------------------------------------------------------------------

func who(x, ctx: Dictionary) -> int:
	var me: int = ctx["controller"]
	match str(x):
		"self": return me
		"opp": return 1 - me
		"turn": return duel.turn_player
		"event": return int(ctx["event"].get("player", me))
		"equipped_ctrl": return (ctx["src"].equipped_to.controller if ctx["src"].equipped_to != null else me)
	return me

func race_id(x) -> int:
	if x is int or x is float:
		return int(x)
	return CardDB.RACES.find(str(x))

func attr_id(x) -> int:
	if x is int or x is float:
		return int(x)
	return ATTRS.get(str(x).to_upper(), 0)

## Cards in a zone spec like "opp.monsters", "self.grave", "monsters" (both), "field".
func zone_cards(spec: String, ctx: Dictionary) -> Array:
	var parts := spec.split(".")
	var sides := [0, 1]
	var zone := spec
	if parts.size() == 2:
		sides = [who(parts[0], ctx)]
		zone = parts[1]
	var out := []
	for p in sides:
		var s: Duel.PlayerSide = duel.side(p)
		match zone:
			"monsters": out.append_array(duel.monsters_of(p))
			"spells": out.append_array((s.spells as Array).filter(func(c): return c != null))
			"fieldspell": if s.field_spell != null: out.append(s.field_spell)
			"hand": out.append_array(s.hand)
			"deck": out.append_array(s.deck)
			"grave": out.append_array(s.grave)
			"banished": out.append_array(s.banished)
			"extra": out.append_array(s.extra)
			"field":
				out.append_array(duel.monsters_of(p))
				out.append_array((s.spells as Array).filter(func(c): return c != null))
				if s.field_spell != null:
					out.append(s.field_spell)
	return out

func matches(c: DCard, f: Dictionary, ctx: Dictionary) -> bool:
	var d: Dictionary = duel.card_data(c)
	if f.has("face_up") and c.face_up != bool(f["face_up"]):
		return false
	if f.has("pos") and c.pos != f["pos"]:
		return false
	if f.has("type"):
		var tl = f["type"]
		if not ((tl is Array and tl.has(d.get("type", ""))) or (not tl is Array and d.get("type", "") == tl)):
			return false
	if f.has("subtype") and d.get("subtype_name", "") != f["subtype"]:
		return false
	if f.has("category"):
		var cats = f["category"]
		var cat: int = int(d.get("category", 0))
		if not ((cats is Array and cats.has(cat)) or (not cats is Array and int(cats) == cat)):
			return false
		if d.get("type", "") != "monster":
			return false
	if f.has("attribute"):
		var a = f["attribute"]
		var list: Array = a if a is Array else [a]
		var ok := false
		for x in list:
			if int(d.get("attribute", 0)) == attr_id(x):
				ok = true
		if not ok:
			return false
	if f.has("race"):
		var r = f["race"]
		var list2: Array = r if r is Array else [r]
		var ok2 := false
		for x in list2:
			if d.get("type", "") == "monster" and int(d.get("kind", 0)) == race_id(x):
				ok2 = true
		if not ok2:
			return false
	if f.has("not_race"):
		var nr = f["not_race"]
		var nlist: Array = nr if nr is Array else [nr]
		for x in nlist:
			if d.get("type", "") == "monster" and int(d.get("kind", 0)) == race_id(x):
				return false
	var is_mon: bool = d.get("type", "") == "monster"
	if f.has("level_min") and (not is_mon or int(d.get("level", 0)) < int(f["level_min"])):
		return false
	if f.has("level_max") and (not is_mon or int(d.get("level", 0)) > int(f["level_max"])):
		return false
	if f.has("atk_min") and (not is_mon or duel.atk_of(c) < int(f["atk_min"])):
		return false
	if f.has("atk_max") and (not is_mon or duel.atk_of(c) > int(f["atk_max"])):
		return false
	if f.has("def_min") and (not is_mon or duel.def_of(c) < int(f["def_min"])):
		return false
	if f.has("def_max") and (not is_mon or duel.def_of(c) > int(f["def_max"])):
		return false
	if f.has("name_has") and not duel.db.card_name(c.idx).to_lower().contains(str(f["name_has"]).to_lower()):
		return false
	if f.has("number") and not (f["number"] as Array).has(c.number):
		return false
	if f.get("not_src", false) and c == ctx.get("src"):
		return false
	if f.has("has_equip") and (c.equips.size() > 0) != bool(f["has_equip"]):
		return false
	if f.has("controller") and c.controller != who(f["controller"], ctx):
		return false
	if f.has("owner") and c.owner != who(f["owner"], ctx):
		return false
	return true

func select_candidates(step: Dictionary, ctx: Dictionary) -> Array:
	var out := []
	var f: Dictionary = step.get("filter", {})
	var from = step.get("from", "field")
	var specs: Array = from if from is Array else [from]
	for spec in specs:
		var pool: Array = (ctx["vars"].get(str(spec).substr(1), []) as Array) if str(spec).begins_with("$") else zone_cards(str(spec), ctx)
		for c in pool:
			if matches(c, f, ctx) and not out.has(c):
				out.append(c)
	var pick: String = step.get("pick", "")
	if pick != "" and not out.is_empty():
		var best := 0
		var first := true
		for c in out:
			var v: int = duel.atk_of(c) if pick.ends_with("atk") else duel.def_of(c)
			if first or (pick.begins_with("min") and v < best) or (pick.begins_with("max") and v > best):
				best = v
				first = false
		out = out.filter(func(c): return (duel.atk_of(c) if pick.ends_with("atk") else duel.def_of(c)) == best)
	return out

# --- values and conditions -------------------------------------------------------------

func val(x, ctx: Dictionary) -> int:
	if x is int or x is float:
		return int(x)
	if x is Dictionary:
		if x.has("stat"):
			var total := 0
			for c in ctx["vars"].get(x.get("of", ""), []):
				total += duel.atk_of(c) if x["stat"] == "atk" else duel.def_of(c) if x["stat"] == "def" else int(duel.card_data(c).get("level", 0))
			return total
		if x.has("lp"):
			return duel.side(who(x["lp"], ctx)).lp
		if x.has("count"):
			var step := {"from": x["count"], "filter": x.get("filter", {})}
			return select_candidates(step, ctx).size()
		if x.has("var"):
			return int(ctx["vars"].get(x["var"], 0))
		if x.has("event"):
			return int(ctx["event"].get(x["event"], 0))
		if x.has("mul"):
			return int(val(x["mul"], ctx) * float(x.get("by", 1)))
		if x.has("half"):
			@warning_ignore("integer_division")
			return val(x["half"], ctx) / 2
	return 0

func cmp(a: int, op: String, b: int) -> bool:
	match op:
		"<": return a < b
		"<=": return a <= b
		">": return a > b
		">=": return a >= b
		"==": return a == b
		"!=": return a != b
	return false

## Check a list of conditions; returns "" when all hold, else a reason. `activation` also checks that targets exist.
func conditions_ok(conds: Array, ctx: Dictionary, activation := false) -> String:
	for c in conds:
		if not _cond(c, ctx):
			return "Condition not met."
	if activation:
		var e: Dictionary = ctx.get("effect", {})
		for step in (e.get("cost", []) as Array) + (e.get("target", []) as Array):
			if step.get("op", "") == "select" and step.get("required", true):
				if select_candidates(step, ctx).size() < int(step.get("min", step.get("n", 1))):
					return "No valid target."
			if step.get("op", "") == "pay_lp" and duel.side(ctx["controller"]).lp < val(step.get("amount", 0), ctx):
				return "Not enough Life Points."
			if step.get("op", "") == "discard":
				var hand_n: int = duel.side(ctx["controller"]).hand.size() - (1 if duel.side(ctx["controller"]).hand.has(ctx["src"]) else 0)
				if hand_n < int(step.get("n", 1)):
					return "Not enough cards in hand."
	return ""

func _cond(c: Dictionary, ctx: Dictionary) -> bool:
	var me: int = ctx["controller"]
	match c.get("c", ""):
		"has":
			var step := {"from": c.get("zone", "field"), "filter": c.get("filter", {})}
			return select_candidates(step, ctx).size() >= int(c.get("n", 1))
		"none":
			var step2 := {"from": c.get("zone", "field"), "filter": c.get("filter", {})}
			return select_candidates(step2, ctx).is_empty()
		"lp": return cmp(duel.side(who(c.get("who", "self"), ctx)).lp, c.get("op", ">="), val(c.get("v", 0), ctx))
		"hand": return cmp(duel.side(who(c.get("who", "self"), ctx)).hand.size(), c.get("op", ">="), int(c.get("v", 0)))
		"deck": return cmp(duel.side(who(c.get("who", "self"), ctx)).deck.size(), c.get("op", ">="), int(c.get("v", 0)))
		"event_by": return int(ctx["event"].get("player", -1)) == who(c.get("who", "opp"), ctx)
		"event_card":
			var ec := duel.card_by_uid(int(ctx["event"].get("uid", -1)))
			return ec != null and matches(ec, c.get("filter", {}), ctx)
		"event_target":
			var tc := duel.card_by_uid(int(ctx["event"].get("target", -1)))
			return tc != null and matches(tc, c.get("filter", {}), ctx) and (not c.has("mine") or (tc.controller == me) == bool(c["mine"]))
		"event_attacker":
			var ac := duel.card_by_uid(int(ctx["event"].get("attacker", -1)))
			return ac != null and matches(ac, c.get("filter", {}), ctx)
		"direct_attack": return int(ctx["event"].get("target", -1)) == -1
		"phase": return (c.get("is", []) as Array).has(duel.phase)
		"turn": return duel.turn_player == who(c.get("is", "self"), ctx)
		"src_on_field": return fx._zone_of(ctx["src"]) in ["monster", "spell", "fieldspell"]
		"chain_top_kind": return not fx.chain.is_empty() and fx.chain.back()["kind"] == c.get("is", "")
		"chain_top_by": return not fx.chain.is_empty() and fx.chain.back()["player"] == who(c.get("is", "opp"), ctx)
		"flag": return bool(ctx["src"].flags.get(c.get("name", ""), false)) == bool(c.get("is", true))
		"var_nonempty": return not (ctx["vars"].get(c.get("name", ""), []) as Array).is_empty()
		"summoned_this_turn": return ctx["src"].summon_turn == duel.turn
		"was_flipped_by_battle": return bool(ctx["event"].get("by_battle", false))
		"event_src": return int(ctx["event"].get("uid", -1)) == ctx["src"].uid
		"event_from": return str(ctx["event"].get("from", "")) == str(c.get("is", ""))
		"equipped_is": return ctx["src"].equipped_to != null and matches(ctx["src"].equipped_to, c.get("filter", {}), ctx)
		"event_reason": return str(ctx["event"].get("reason", "")) == str(c.get("is", ""))
		"was_on_field": return bool(ctx["event"].get("was_on_field", false))
		"counter": return cmp(int(ctx["src"].flags.get(c.get("name", ""), 0)), c.get("op", ">="), int(c.get("v", 0)))
		"free_zone": return duel.free_zone(duel.side(who(c.get("who", "self"), ctx)).monsters) != -1
		"attacker_atk": return duel.card_by_uid(int(ctx["event"].get("attacker", -1))) != null
	return true

# --- decisions ------------------------------------------------------------------------

## Validate the player's answer to the pending decision and apply it. Returns "" or a reason.
func accept(p: Dictionary, answer) -> String:
	var t: Dictionary = p["_task"]
	match p["type"]:
		"select":
			var uids: Array = answer if answer is Array else [answer]
			var cands: Array = p["candidates"]
			if uids.size() < p["min"] or uids.size() > p["max"]:
				return "Select %d card(s)." % p["max"]
			var cards := []
			for u in uids:
				if not cands.has(u) or cards.has(duel.card_by_uid(u)):
					return "Invalid selection."
				cards.append(duel.card_by_uid(u))
			t["ctx"]["vars"][p["as"]] = cards
			fx.pending = {}
		"yesno":
			t["ctx"]["vars"][p["as"]] = bool(answer)
			fx.pending = {}
		"choice":
			if int(answer) < 0 or int(answer) >= int(p["count"]):
				return "Invalid choice."
			t["ctx"]["vars"][p["as"]] = int(answer)
			fx.pending = {}
		"chain":
			fx.pending = {}
			var cur: int = p["player"]
			if answer == null or (answer is String and answer == "pass") or (answer is Dictionary and answer.get("pass", false)):
				t["passes"] += 1
				t["cur"] = 1 - cur
			else:
				var uid := int(answer["uid"])
				var idx := int(answer["idx"])
				var ok := false
				for o in p["options"]:
					if o["uid"] == uid and o["idx"] == idx:
						ok = true
				if not ok:
					fx.pending = p
					return "That card cannot be chained."
				t["passes"] = 0
				t["cur"] = 1 - cur
				t["fired"]["%d:%d" % [uid, idx]] = true
				fx._start_activation(cur, fx.duel_card(uid), idx, t["event"], t["data"], false)
		_:
			fx.pending = {}
	return ""

# --- the verbs ------------------------------------------------------------------------

func _targets(x, ctx: Dictionary) -> Array:
	if x is String and (x as String).begins_with("$"):
		return (ctx["vars"].get((x as String).substr(1), []) as Array).duplicate()
	if x is String and x == "src":
		return [ctx["src"]]
	if x is String and x == "event_card":
		var c := duel.card_by_uid(int(ctx["event"].get("uid", -1)))
		return [c] if c != null else []
	if x is String and x == "attacker":
		var a := duel.card_by_uid(int(ctx["event"].get("attacker", -1)))
		return [a] if a != null else []
	if x is String and x == "attack_target":
		var target := duel.card_by_uid(int(ctx["event"].get("target", -1)))
		return [target] if target != null else []
	if x is String and x == "equipped":
		var s: DCard = ctx["src"].equipped_to
		return [s] if s != null else []
	if x is Dictionary:
		var step := {"from": x.get("from", "field"), "filter": x.get("filter", {})}
		return select_candidates(step, ctx)
	return []

## `what` of a step, minus anything listed in `except`.
func tg(step: Dictionary, ctx: Dictionary) -> Array:
	var out := _targets(step.get("what", "$t"), ctx)
	if step.has("except"):
		var ex := _targets(step["except"], ctx)
		out = out.filter(func(c): return not ex.has(c))
	return out

func run(step: Dictionary, ctx: Dictionary):
	var me: int = ctx["controller"]
	var op: String = step.get("op", "")
	match op:
		"select":
			var cands := select_candidates(step, ctx)
			var mn: int = int(step.get("min", step.get("n", 1)))
			var mx: int = int(step.get("n", 1))
			if cands.size() < mn:
				ctx["vars"][step["as"]] = []
				if step.get("required", true):
					return "abort"
				return null
			if cands.size() <= mn and step.get("auto", true) and mn == mx:
				ctx["vars"][step["as"]] = cands.slice(0, mx)
				return null
			if step.get("random", false):
				var picks := cands.duplicate()
				for i in range(picks.size() - 1, 0, -1):
					var j := duel.rng.randi_range(0, i)
					var tmp = picks[i]
					picks[i] = picks[j]
					picks[j] = tmp
				ctx["vars"][step["as"]] = picks.slice(0, mx)
				return null
			var chooser: int = who(step.get("chooser", "self"), ctx)
			return {"type": "select", "player": chooser, "candidates": cands.map(func(c): return c.uid), "min": mn, "max": mx,
				"as": step["as"], "prompt": step.get("prompt", 0), "from": step.get("from", "field"), "cost": step.get("cost", false)}
		"yesno":
			return {"type": "yesno", "player": who(step.get("chooser", "self"), ctx), "as": step["as"], "prompt": step.get("prompt", 0), "card": ctx["src"].uid}
		"choice":
			return {"type": "choice", "player": who(step.get("chooser", "self"), ctx), "as": step["as"], "prompt": step.get("prompt", 0), "count": int(step.get("count", 2)), "labels": step.get("labels", [])}
		"if":
			var ok := true
			for c in step.get("cond", []):
				if not _cond_dyn(c, ctx):
					ok = false
			var branch: Array = step.get("then", []) if ok else step.get("else", [])
			if not branch.is_empty():
				fx.tasks.append({"t": "script", "steps": branch, "i": 0, "ctx": ctx})
				return "pushed"
		"coin":
			var heads := duel.rng.randi_range(0, 1) == 1
			ctx["vars"][step.get("as", "coin")] = heads
			duel.log_event("coin", {"player": me, "heads": heads})
			var branch2: Array = step.get("heads", []) if heads else step.get("tails", [])
			if not branch2.is_empty():
				fx.tasks.append({"t": "script", "steps": branch2, "i": 0, "ctx": ctx})
				return "pushed"
		"damage": duel.damage_player(who(step.get("who", "opp"), ctx), val(step.get("amount", 0), ctx), "effect")
		"heal": duel.heal_player(who(step.get("who", "self"), ctx), val(step.get("amount", 0), ctx))
		"pay_lp": duel.pay_lp(me, val(step.get("amount", 0), ctx))
		"set_lp": duel.set_lp(who(step.get("who", "self"), ctx), val(step.get("amount", 0), ctx))
		"draw": duel.draw_cards(who(step.get("who", "self"), ctx), val(step.get("n", 1), ctx))
		"destroy": for c in tg(step, ctx): duel.destroy_card(c, "effect")
		"to_grave": for c in tg(step, ctx): duel.send_to_grave(c, "effect")
		"to_hand": for c in tg(step, ctx): duel.return_to_hand(c)
		"to_deck": for c in tg(step, ctx): duel.return_to_deck(c, step.get("where", "top"))
		"banish": for c in tg(step, ctx): duel.banish_card(c)
		"discard":
			var hand: Array = duel.side(who(step.get("who", "self"), ctx)).hand
			var n := mini(int(step.get("n", 1)), hand.size())
			if step.get("all", false):
				n = hand.size()
			if step.has("as"):
				ctx["vars"][step["as"]] = n
			if n > 0 and not step.get("random", step.get("all", false)):
				var chooser2: int = who(step.get("who", "self"), ctx)
				if hand.size() > n:
					fx.tasks.append({"t": "script", "steps": [{"op": "select", "as": "_disc", "from": "hand", "n": n, "chooser": "self", "prompt": step.get("prompt", 12), "cost": true}, {"op": "to_grave", "what": "$_disc"}], "i": 0, "ctx": {"src": ctx["src"], "controller": chooser2, "vars": {}, "event": ctx["event"]}})
					return "pushed"
			var pool := hand.duplicate()
			for i in n:
				var pick: DCard = pool[duel.rng.randi_range(0, pool.size() - 1)] if step.get("random", false) else pool[0]
				pool.erase(pick)
				duel.send_to_grave(pick, "discard")
		"search":
			# pick matching cards out of the deck and add them to the hand (then shuffle)
			fx.tasks.append({"t": "script", "steps": [
				{"op": "select", "as": "_s", "from": "self.deck", "filter": step.get("filter", {}), "n": 1, "min": 0, "required": false, "auto": false, "prompt": step.get("prompt", 51)},
				{"op": "to_hand", "what": "$_s"}, {"op": "shuffle", "who": "self"}], "i": 0, "ctx": ctx})
			return "pushed"
		"shuffle": duel.shuffle_deck(who(step.get("who", "self"), ctx))
		"special_summon":
			for c in _targets(step.get("what", "$t"), ctx):
				var to: int = who(step.get("to", "self"), ctx)
				var position: String = step.get("pos", "atk")
				if step.has("pos_var"):
					position = "def" if int(ctx["vars"].get(step["pos_var"], 0)) == 1 else "atk"
				var r: String = duel.special_summon(c, to, position, step.get("face_up", true))
				if r == "":
					for k in step.get("then_mod", []):
						pass
		"mod":
			var atk: int = val(step.get("atk", 0), ctx)
			var def: int = val(step.get("def", 0), ctx)
			for c in _targets(step.get("what", "$t"), ctx):
				c.mods.append({"atk": atk, "def": def, "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
		"set_stat":
			for c in _targets(step.get("what", "$t"), ctx):
				if step.has("atk"):
					c.mods.append({"atk": val(step["atk"], ctx) - duel.atk_of(c), "def": 0, "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
				if step.has("def"):
					c.mods.append({"atk": 0, "def": val(step["def"], ctx) - duel.def_of(c), "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
		"equip":
			var tgt := _targets(step.get("to", "$t"), ctx)
			if tgt.size() > 0:
				duel.equip_card(ctx["src"], tgt[0], {"atk": val(step.get("atk", 0), ctx), "def": val(step.get("def", 0), ctx)})
		"take_control":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.take_control(c, who(step.get("to", "self"), ctx), step.get("until", "forever"))
		"set_pos":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.force_position(c, step.get("pos", "def"), step.get("face_up", true))
		"flip_down":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.force_position(c, "def", false)
		"negate":
			# negate the activation of the link below this one (or the one at `link`)
			var i := fx.chain.size() - 1
			if i >= 0:
				(fx.chain[i] as Dictionary)["negated"] = true
				if step.get("destroy", false):
					var tc: DCard = (fx.chain[i] as Dictionary)["card"]
					fx.push_call(func(): duel.destroy_card(tc, "effect"))
		"negate_attack": duel.negate_current_attack()
		"set_flag":
			for c in _targets(step.get("what", "src"), ctx):
				c.flags[step["name"]] = step.get("value", true)
		"skip_phase": duel.skip_phase(step.get("phase", "battle"))
		"win": duel.force_win(me, str(step.get("reason", "effect")))
		"log": duel.log_event(step.get("event", "effect"), step.get("data", {}))
		"let": ctx["vars"][step["as"]] = _targets(step.get("what", "src"), ctx)
		"counter": ctx["src"].flags[step["name"]] = int(ctx["src"].flags.get(step["name"], 0)) + int(step.get("add", 1))
		"rule_turn": duel.add_turn_rule(step["rule"], who(step.get("who", "self"), ctx))
		"skip_next_draw": duel.skip_draw[who(step.get("who", "self"), ctx)] = true
		"nothing": pass
		"custom": return FxCustom.run(step.get("fn", ""), step, ctx, fx)
		_:
			push_warning("unknown effect op: " + op)
	return null

func _cond_dyn(c: Dictionary, ctx: Dictionary) -> bool:
	match c.get("c", ""):
		"var_true": return bool(ctx["vars"].get(c.get("name", ""), false))
		"var_false": return not bool(ctx["vars"].get(c.get("name", ""), false))
		"var_eq": return int(ctx["vars"].get(c.get("name", ""), -1)) == int(c.get("v", 0))
	return _cond(c, ctx)
