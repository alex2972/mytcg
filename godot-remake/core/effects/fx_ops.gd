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
			"lost_spells":
				for u in duel.lost_spells:
					var lc := duel.card_by_uid(u)
					if lc != null and (s.grave as Array).has(lc):
						out.append(lc)
			"dead_battle":
				for u in duel.battle_dead:
					var dc := duel.card_by_uid(u)
					if dc != null and (s.grave as Array).has(dc):
						out.append(dc)
			"field":
				out.append_array(duel.monsters_of(p))
				out.append_array((s.spells as Array).filter(func(c): return c != null))
				if s.field_spell != null:
					out.append(s.field_spell)
	return out

func matches(c: DCard, f: Dictionary, ctx: Dictionary) -> bool:
	var d: Dictionary = duel.card_data(c)
	if f.get("tribute_legal", false) and c.token in ["Sheep Token", "Kuriboh Token"]:
		return false
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
			if duel.attribute_of(c) == attr_id(x):
				ok = true
		if not ok:
			return false
	if f.has("race"):
		var r = f["race"]
		var list2: Array = r if r is Array else [r]
		var ok2 := false
		for x in list2:
			if d.get("type", "") == "monster" and duel.race_of(c) == race_id(x):
				ok2 = true
		if not ok2:
			return false
	if f.has("not_race"):
		var nr = f["not_race"]
		var nlist: Array = nr if nr is Array else [nr]
		for x in nlist:
			if d.get("type", "") == "monster" and duel.race_of(c) == race_id(x):
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
	if f.has("name_is") and duel.db.card_name(c.idx) != str(f["name_is"]):
		return false
	if f.has("special_summoned") and bool(c.flags.get("special_summoned", false)) != bool(f["special_summoned"]):
		return false
	if f.get("attacking", false) and duel.current_attack.get("attacker") != c:
		return false
	if f.has("equipping") and (c.equipped_to != null) != bool(f["equipping"]):
		return false
	if f.has("not_equipped_by"):
		for ev in ctx["vars"].get(str(f["not_equipped_by"]), []):
			if c.equips.has(ev):
				return false
	if f.has("fusion") and (not duel.db.fusion_recipe(duel.db.card_name(c.idx)).is_empty()) != bool(f["fusion"]):
		return false
	if f.has("fusion_mat") and bool(c.flags.get("fusion_mat", false)) != bool(f["fusion_mat"]):
		return false
	if f.has("attr_var") and duel.attribute_of(c) != int(ctx["vars"].get(str(f["attr_var"]), -2)) + 1:
		return false
	if f.get("race_of_src_flag", false) and (not ctx.has("src") or duel.race_of(c) != int(ctx["src"].flags.get("chosen_race", -1))):
		return false
	if f.has("name_in") and not (f["name_in"] as Array).has(duel.db.card_name(c.idx)):
		return false
	if f.has("level_eq") and (not (d.get("type", "") == "monster") or int(d.get("level", 0)) != val(f["level_eq"], ctx)):
		return false
	if f.get("same_name_as_event", false):
		var ec := duel.card_by_uid(int(ctx["event"].get("uid", -1)))
		if ec == null or duel.db.card_name(c.idx) != duel.db.card_name(ec.idx):
			return false
	if f.has("not_in"):
		for v in f["not_in"]:
			if (ctx["vars"].get(str(v), []) as Array).has(c):
				return false
	if f.get("not_target", false) and c.uid == int(ctx["event"].get("target", -1)):
		return false
	if f.get("not_src", false) and c == ctx.get("src"):
		return false
	if f.get("not_attacker", false) and c.uid == int(ctx["event"].get("attacker", -1)):
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
		var replaced: bool = str(spec) == "self.grave" and step.get("cost", false) and duel.has_turn_rule("spirit_elimination", ctx["controller"]) and _selection_is_banish_cost(step, ctx)
		var pool: Array = (ctx["vars"].get(str(spec).substr(1), []) as Array) if str(spec).begins_with("$") else zone_cards(str(spec), ctx)
		if replaced:
			pool = pool.filter(func(c): return not duel.is_monster(c)) + duel.monsters_of(ctx["controller"])
		for c in pool:
			if replaced and duel.is_monster(c) and not c.face_up and (f.has("attribute") or f.has("race")):
				continue
			if matches(c, f, ctx) and not out.has(c):
				out.append(c)
	if not step.get("cost", false) and step.get("pick", "") == "" and not step.get("random", false) and fx.has_untargetable():
		# Lord of D.: such monsters cannot be selected as the target of a card effect
		out = out.filter(func(c): return not (duel.is_on_field(c) and fx.rule_active("untargetable", c)))
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

## Can `p` Ritual Summon `monster_name` (in hand) by offering monsters worth `level` Level Stars from hand and field?
func ritual_possible(p: int, monster_name: String, level: int) -> bool:
	var s: Duel.PlayerSide = duel.side(p)
	var rm: DCard = null
	for c in s.hand:
		if duel.db.card_name(c.idx) == monster_name:
			rm = c
			break
	if rm == null:
		return false
	var total := 0
	for c in s.hand + duel.monsters_of(p):
		if c != rm and duel.is_monster(c):
			total += duel.level_of(c)
	return total >= level

func _already_blocked(list: Array, side_id: int, z: int) -> bool:
	for b in list:
		if int(b["side"]) == side_id and int(b["zone"]) == z:
			return true
	return false

## Fusion Monsters in my Extra Deck that I can summon right now with my hand and monsters [Polymerization, Fusion Gate].
func fusion_candidates(p: int) -> Array:
	var out := []
	var s: Duel.PlayerSide = duel.side(p)
	if duel.free_zone(s.monsters) == -1 and duel.monsters_of(p).is_empty():
		return out
	var pool: Array = []
	for c in s.hand + duel.monsters_of(p):
		if duel.is_monster(c):
			pool.append(c)
	for fm in s.extra:
		var recipe: Array = duel.db.fusion_recipe(duel.db.card_name(fm.idx))
		if recipe.is_empty():
			continue
		var avail := pool.duplicate()
		var ok := true
		var substitute_used := false
		for need in recipe:
			var found: DCard = null
			for c in avail:
				if duel.db.card_name(c.idx) == need:
					found = c
					break
			if found == null and not substitute_used:
				for c in avail:
					if duel.db.card_name(c.idx) in ["Goddess with the Third Eye", "Versago the Destroyer"]:
						found = c
						substitute_used = true
						break
			if found == null:
				ok = false
				break
			avail.erase(found)
		if ok:
			out.append(fm)
	return out

# --- values and conditions -------------------------------------------------------------

func val(x, ctx: Dictionary) -> int:
	if x is int or x is float:
		return int(x)
	if x is Dictionary:
		if x.has("stat"):
			var total := 0
			for c in ctx["vars"].get(x.get("of", ""), []):
				if x.get("original", false):
					total += int(duel.card_data(c).get(x["stat"], 0))
				else:
					total += duel.atk_of(c) if x["stat"] == "atk" else duel.def_of(c) if x["stat"] == "def" else int(duel.card_data(c).get("level", 0))
			return total
		if x.has("lp"):
			return duel.side(who(x["lp"], ctx)).lp
		if x.has("count"):
			var step := {"from": x["count"], "filter": x.get("filter", {})}
			return select_candidates(step, ctx).size()
		if x.has("var"):
			return int(ctx["vars"].get(x["var"], 0))
		if x.has("var_count"):
			return (ctx["vars"].get(x["var_count"], []) as Array).size()
		if x.has("event"):
			return int(ctx["event"].get(x["event"], 0))
		if x.has("mul"):
			return int(val(x["mul"], ctx) * float(x.get("by", 1)))
		if x.has("half"):
			@warning_ignore("integer_division")
			return val(x["half"], ctx) / 2
	return 0

## Does the Spell Card on top of the chain designate exactly 1 monster as its target? [Riryoku Field, Big Shield Gardna]
func chain_top_single_monster_target(ctx: Dictionary) -> bool:
	if fx.chain.is_empty():
		return false
	var link: Dictionary = fx.chain.back()
	var lctx: Dictionary = link["ctx"]
	var chosen := []
	for step in (lctx["effect"].get("target", []) as Array):
		if step.get("op", "") == "select":
			for c in lctx["vars"].get(step.get("as", ""), []):
				if duel.is_monster(c) and not chosen.has(c):
					chosen.append(c)
	return chosen.size() == 1 and link["kind"] == "spell"

func chain_top_target(ctx: Dictionary) -> DCard:
	var link: Dictionary = fx.chain.back()
	for step in (link["ctx"]["effect"].get("target", []) as Array):
		for c in link["ctx"]["vars"].get(step.get("as", ""), []):
			if duel.is_monster(c):
				return c
	return null

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
		"inspection_source": return not ctx["event"].has("inspection") or int(ctx["event"]["inspection"]) == ctx["src"].uid
		"manga_possible": return FxCustom.manga_possible(duel, ctx["src"])
		"imitation_possible": return not FxCustom.imitation_materials(duel, me).is_empty()
		"makiu_possible": return not FxCustom.makiu_monsters(duel, me).is_empty() and not duel.has_turn_rule("battle_entered", me)
		"procedure_possible": return not FxCustom.procedure_materials(duel, ctx["src"], c["kind"]).is_empty()
		"spell_zone": return duel.free_zone(duel.side(me).spells) != -1
		"labyrinth_possible":
			for shadow in duel.side(me).deck:
				if duel.db.card_name(shadow.idx) == "Wall Shadow" and FxCustom.procedure_materials(duel, shadow, "wall_shadow").has(ctx["src"].equipped_to):
					return true
			return false
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
		"event_was_flipped": return bool(ctx["event"].get("was_flipped", false))
		"destroyed_by_opp_effect": return int(ctx["event"].get("by", -1)) == 1 - me
		"chain_top_card": return not fx.chain.is_empty() and matches(fx.chain.back()["card"], c.get("filter", {}), ctx)
		"chain_top_single_monster_target": return chain_top_single_monster_target(ctx)
		"event_src": return (int(ctx["event"].get("uid", -1)) == ctx["src"].uid) == bool(c.get("is", true))
		"event_from": return str(ctx["event"].get("from", "")) == str(c.get("is", ""))
		"equipped_is": return ctx["src"].equipped_to != null and matches(ctx["src"].equipped_to, c.get("filter", {}), ctx)
		"event_reason": return str(ctx["event"].get("reason", "")) == str(c.get("is", ""))
		"was_on_field": return bool(ctx["event"].get("was_on_field", false))
		"counter": return cmp(int(ctx["src"].flags.get(c.get("name", ""), 0)), c.get("op", ">="), int(c.get("v", 0)))
		"free_zone": return duel.side(who(c.get("who", "self"), ctx)).monsters.count(null) >= int(c.get("n", 1))
		"summon_unused": return not duel.summons_this_turn[who(c.get("who", "self"), ctx)]
		"attacker_atk": return duel.card_by_uid(int(ctx["event"].get("attacker", -1))) != null
		"ritual_possible": return ritual_possible(me, str(c.get("monster", "")), int(c.get("level", 1)))
		"fusion_possible": return not fusion_candidates(me).is_empty()
		"event_pos": return str(ctx["event"].get("pos", "")) == str(c.get("is", ""))
		"was_face_up": return bool(ctx["event"].get("was_face_up", false))
		"src_face_down": return not ctx["src"].face_up
		"normal_summon_used": return duel.normal_summoned and duel.turn_player == me
		"src_pos": return ctx["src"].face_up and ctx["src"].pos == str(c.get("is", "atk"))
		"attacker_weaker_than_target":
			var wa := duel.card_by_uid(int(ctx["event"].get("attacker", -1)))
			var wt := duel.card_by_uid(int(ctx["event"].get("target", -1)))
			return wa != null and wt != null and wt.pos == "def" and duel.atk_of(wa) < duel.def_of(wt)
		"free_zones": return duel.side(me).monsters.count(null) >= int(c.get("n", 1))
		"source_is_src": return int(ctx["event"].get("source", -1)) == ctx["src"].uid
		"var_matches":
			var vv: Array = ctx["vars"].get(c.get("name", ""), [])
			return not vv.is_empty() and matches(vv[0], c.get("filter", {}), ctx)
		"target_is_src": return int(ctx["event"].get("target", -1)) == ctx["src"].uid
		"chain_top_targets_src":
			return not fx.chain.is_empty() and chain_top_target(ctx) == ctx["src"]
		"battle_involves_equipped":
			var host: DCard = ctx["src"].equipped_to
			return host != null and (int(ctx["event"].get("attacker", -1)) == host.uid or int(ctx["event"].get("target", -1)) == host.uid)
		"in_battle": return int(ctx["event"].get("attacker", -1)) == ctx["src"].uid or int(ctx["event"].get("target", -1)) == ctx["src"].uid
		"attacker_is_src": return int(ctx["event"].get("attacker", -1)) == ctx["src"].uid
		"killer_is_src": return int(ctx["event"].get("killer", -1)) == ctx["src"].uid
	return true

# --- decisions ------------------------------------------------------------------------

## Validate the player's answer to the pending decision and apply it. Returns "" or a reason.
func accept(p: Dictionary, answer) -> String:
	var t: Dictionary = p["_task"]
	match p["type"]:
		"presentation":
			if answer != true:
				return "Wait for the roll animation."
			fx.pending = {}
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
			if p.get("banish_intent", false):
				var removals := [0, 0]
				for c in cards:
					if duel.is_monster(c) and duel.side(c.owner).grave.has(c) and duel.has_turn_rule("spirit_elimination", c.owner):
						removals[c.owner] += 1
				for owner in 2:
					if removals[owner] > duel.monsters_of(owner).size():
						return "Not enough monsters on the field to remove as substitutes."
			if int(p.get("sum_level_min", 0)) > 0:
				var total := 0
				for c in cards:
					total += duel.level_of(c)
				if total < int(p["sum_level_min"]):
					return "The Tributes' total Level must be at least %d." % int(p["sum_level_min"])
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
	if x is String and x == "killer":
		var k := duel.card_by_uid(int(ctx["event"].get("killer", -1)))
		return [k] if k != null else []
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
	var previous: DCard = duel.effect_source
	var previous_player: int = duel.effect_player
	duel.effect_player = ctx["controller"]
	duel.effect_source = ctx["src"]
	var result = _run(step, ctx)
	duel.effect_source = previous
	duel.effect_player = previous_player
	return result

func _run(step: Dictionary, ctx: Dictionary):
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
			if cands.size() <= mn and step.get("auto", true) and mn == mx and not (duel.has_turn_rule("spirit_elimination", me) and _selection_is_banish_cost(step, ctx)):
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
				"as": step["as"], "prompt": step.get("prompt", 0), "from": step.get("from", "field"), "cost": step.get("cost", false), "discard": step.get("discard", false), "prompt_text": step.get("prompt_text", ""),
				"sum_level_min": int(step.get("sum_level_min", 0)), "banish_intent": _selection_is_banish_effect(step, ctx)}
		"yesno":
			return {"type": "yesno", "player": who(step.get("chooser", "self"), ctx), "as": step["as"], "prompt": step.get("prompt", 0), "card": ctx["src"].uid, "prompt_text": step.get("prompt_text", ""), "show_hands": step.get("show_hands", false)}
		"choice":
			return {"type": "choice", "player": who(step.get("chooser", "self"), ctx), "as": step["as"], "prompt": step.get("prompt", 0), "count": int(step.get("count", 2)), "labels": step.get("labels", []), "prompt_text": step.get("prompt_text", "")}
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
			var correct := heads
			if step.has("call"):
				correct = heads == (int(ctx["vars"].get(str(step["call"]), 0)) == 0)
			ctx["vars"][step.get("as", "coin")] = correct
			duel.log_event("coin", {"player": me, "heads": heads, "correct": correct, "call": ctx["vars"].get(str(step.get("call", "")), -1)})
			var branch2: Array = step.get("heads", []) if correct else step.get("tails", [])
			if not branch2.is_empty():
				fx.tasks.append({"t": "script", "steps": branch2, "i": 0, "ctx": ctx})
			if fx.presentation_enabled:
				return {"type": "presentation", "player": me}
			if not branch2.is_empty():
				return "pushed"
		"damage": duel.damage_player(who(step.get("who", "opp"), ctx), val(step.get("amount", 0), ctx), "effect")
		"heal": duel.heal_player(who(step.get("who", "self"), ctx), val(step.get("amount", 0), ctx))
		"pay_lp": duel.pay_lp(me, val(step.get("amount", 0), ctx))
		"set_lp": duel.set_lp(who(step.get("who", "self"), ctx), val(step.get("amount", 0), ctx))
		"draw": duel.draw_cards(who(step.get("who", "self"), ctx), val(step.get("n", 1), ctx))
		"destroy":
			duel.effect_player = me
			for c in tg(step, ctx):
				duel.destroy_card(c, "effect")
			duel.effect_player = -1
		"to_grave": for c in tg(step, ctx): duel.send_to_grave(c, step.get("reason", "effect"))
		"to_hand": for c in tg(step, ctx): duel.return_to_hand(c)
		"to_deck": for c in tg(step, ctx): duel.return_to_deck(c, step.get("where", "top"))
		"banish":
			var targets: Array = tg(step, ctx)
			var scripts := []
			for c in targets:
				if duel.is_monster(c) and duel.side(c.owner).grave.has(c) and duel.has_turn_rule("spirit_elimination", c.owner):
					# Effect removal selects substitutes here; banish costs were replaced before selection.
					scripts.append({"op": "select", "as": "substitute", "from": "self.monsters", "n": 1, "cost": true, "auto": false, "prompt_text": "Choose a monster to remove from play instead."})
					scripts.append({"op": "banish_substitute"})
					var subctx := {"src": ctx["src"], "controller": c.owner, "vars": {}, "event": ctx["event"]}
					fx.push_script(scripts.duplicate(true), subctx)
					scripts.clear()
				else:
					duel.banish_card(c)
			if not fx.tasks.is_empty() and fx.tasks.back().get("ctx") != ctx:
				return "pushed"
		"banish_substitute":
			for c in ctx["vars"].get("substitute", []):
				duel.banish_card(c)
		"discard":
			var hand: Array = duel.side(who(step.get("who", "self"), ctx)).hand
			var n := mini(int(step.get("n", 1)), hand.size())
			if step.get("all", false):
				n = hand.size()
			if step.has("as"):
				ctx["vars"][step["as"]] = n
			if n > 0 and not step.get("random", step.get("all", false)):
				var chooser2: int = who(step.get("who", "self"), ctx)
				fx.tasks.append({"t": "script", "steps": [{"op": "select", "as": "_disc", "from": "self.hand", "n": n, "chooser": "self", "prompt": step.get("prompt", 235), "cost": true, "discard": true, "auto": false}, {"op": "to_grave", "what": "$_disc", "reason": "discard"}], "i": 0, "ctx": {"src": ctx["src"], "controller": chooser2, "vars": {}, "event": ctx["event"]}})
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
				if step.get("pos_event", false):
					position = str(ctx["event"].get("pos", "atk"))
				var r: String = duel.special_summon(c, to, position, step.get("face_up", true))
				if r == "":
					for k in step.get("then_mod", []):
						pass
		"mod":
			var atk: int = val(step.get("atk", 0), ctx)
			var def: int = val(step.get("def", 0), ctx)
			var mod_until: String = step.get("until", "end_turn")
			if step.has("turn_offset"):
				mod_until = "turn:%d" % (duel.turn + int(step["turn_offset"]))      # until the end of that turn
			for c in _targets(step.get("what", "$t"), ctx):
				if duel.spell_unaffected(c, ctx["src"]):
					continue
				c.mods.append({"atk": atk, "def": def, "until": mod_until, "src": ctx["src"].uid})
		"set_stat":
			for c in _targets(step.get("what", "$t"), ctx):
				if duel.spell_unaffected(c, ctx["src"]):
					continue
				if step.has("atk"):
					c.mods.append({"atk": val(step["atk"], ctx) - duel.atk_of(c), "def": 0, "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
				if step.has("def"):
					c.mods.append({"atk": 0, "def": val(step["def"], ctx) - duel.def_of(c), "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
		"equip":
			var tgt := _targets(step.get("to", "$t"), ctx)
			if tgt.size() > 0:
				var eq_mod := {"atk": val(step.get("atk", 0), ctx), "def": val(step.get("def", 0), ctx)}
				if step.has("race"):
					eq_mod["race"] = race_id(step["race"])
				if step.has("attribute_var"):
					eq_mod["attribute"] = int(ctx["vars"].get(step["attribute_var"], 0)) + 1
				duel.equip_card(ctx["src"], tgt[0], eq_mod)
		"take_control":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.take_control(c, who(step.get("to", "self"), ctx), step.get("until", "forever"))
		"set_pos":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.force_position(c, step.get("pos", "def"), step.get("face_up", true), step.get("quiet", false))
		"flip_down":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.force_position(c, "def", false)
		"negate":
			if ctx.has("forced_by"):
				return null
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
				c.flags[step["name"]] = ctx["src"].uid if step.get("value_src", false) else step.get("value", true)
		"skip_phase": duel.skip_phase(step.get("phase", "battle"))
		"win": duel.force_win(me, str(step.get("reason", "effect")))
		"log": duel.log_event(step.get("event", "effect"), step.get("data", {}))
		"let": ctx["vars"][step["as"]] = _targets(step.get("what", "src"), ctx)
		"counter": ctx["src"].flags[step["name"]] = int(ctx["src"].flags.get(step["name"], 0)) + int(step.get("add", 1))
		"rule_turn": duel.add_turn_rule(step["rule"], who(step.get("who", "self"), ctx))
		"skip_next_draw": duel.skip_draw[who(step.get("who", "self"), ctx)] = true
		"dice":
			var roll := duel.roll_die()
			ctx["vars"][step.get("as", "roll")] = roll
			duel.log_event("dice", {"player": me, "roll": roll})
			if fx.presentation_enabled:
				return {"type": "presentation", "player": me}
		"coins":
			var heads_n := 0
			var outcomes := []
			for i in int(step.get("n", 3)):
				var heads := duel.rng.randi_range(0, 1) == 1
				outcomes.append(heads)
				if heads:
					heads_n += 1
			ctx["vars"][step.get("as", "heads")] = heads_n
			duel.log_event("coins", {"player": me, "heads": heads_n, "n": int(step.get("n", 3)), "outcomes": outcomes})
			if fx.presentation_enabled:
				return {"type": "presentation", "player": me}
		"redirect_attack":
			var ts := _targets(step.get("to", "$t"), ctx)
			if ts.size() > 0:
				duel.redirect_attack(ts[0])
		"flip_pos":
			for c in _targets(step.get("what", "$t"), ctx):
				duel.force_position(c, "def" if c.pos == "atk" else "atk", true)
		"token":
			var kind: String = step.get("kind", "Sheep Token")
			var owner: int = who(step.get("to", "self"), ctx)
			var token_n: int = (duel.side(owner).monsters as Array).count(null) if str(step.get("n", 1)) == "free" else int(step.get("n", 1))
			for i in token_n:
				var tk := duel.new_token(kind, owner)
				duel.special_summon(tk, owner, step.get("pos", "def"), true)
		"bind":
			var a := _targets(step.get("a", "src"), ctx)
			var b := _targets(step.get("b", "$t"), ctx)
			if a.size() > 0 and b.size() > 0:
				a[0].flags["bound"] = b[0].uid
				b[0].flags["bound"] = a[0].uid
		"swap_stats":
			for c in _targets(step.get("what", "$t"), ctx):
				var a2: int = duel.atk_of(c)
				var d2: int = duel.def_of(c)
				c.mods.append({"atk": d2 - a2, "def": a2 - d2, "until": step.get("until", "end_turn"), "src": ctx["src"].uid})
		"link_control":
			var stolen := _targets(step.get("what", "$t"), ctx)
			if stolen.size() > 0:
				ctx["src"].flags["steals"] = stolen[0].uid
		"ritual":
			fx.tasks.append({"t": "script", "steps": [
				{"op": "select", "as": "rm", "from": "self.hand", "filter": {"name_is": step.get("monster", "")}, "n": 1, "prompt": 241},
				{"op": "select", "as": "rt", "from": ["self.hand", "self.monsters"], "filter": {"type": "monster", "not_in": ["rm"]},
					"n": 5, "min": 1, "auto": false, "sum_level_min": int(step.get("level", 1)), "cost": true, "prompt": 154},
				{"op": "ritual_finish"}], "i": 0, "ctx": ctx})
			return "pushed"
		"ritual_finish":
			for c in ctx["vars"].get("rt", []):
				duel.send_to_grave(c, "ritual_tribute")
			for c in ctx["vars"].get("rm", []):
				duel.special_summon(c, me, "atk", true)
		"fusion":
			var cands2 := fusion_candidates(me)
			if cands2.is_empty():
				return "abort"
			ctx["vars"]["_fcands"] = cands2
			fx.tasks.append({"t": "script", "steps": [
				{"op": "select", "as": "fm", "from": "$_fcands", "n": 1, "prompt": 241},
				{"op": "fusion_pick", "mode": step.get("mode", "poly")}], "i": 0, "ctx": ctx})
			return "pushed"
		"fusion_pick":
			var fm: DCard = (ctx["vars"].get("fm", []) as Array)[0]
			var recipe: Array = duel.db.fusion_recipe(duel.db.card_name(fm.idx))
			var slots := []
			var prev := []
			for i in recipe.size():
				slots.append({"op": "select", "as": "m%d" % i, "from": ["self.hand", "self.monsters"],
					"filter": {"type": "monster", "name_in": [recipe[i], "Goddess with the Third Eye", "Versago the Destroyer"], "not_in": prev.duplicate()}, "n": 1, "prompt": 241})
				prev.append("m%d" % i)
			slots.append({"op": "fusion_finish", "mode": step.get("mode", "poly"), "count": recipe.size()})
			fx.tasks.append({"t": "script", "steps": slots, "i": 0, "ctx": ctx})
			return "pushed"
		"fusion_finish":
			var fm2: DCard = (ctx["vars"].get("fm", []) as Array)[0]
			for i in int(step.get("count", 2)):
				for m in ctx["vars"].get("m%d" % i, []):
					if step.get("mode", "poly") == "gate":
						duel.banish_card(m)
					else:
						duel.send_to_grave(m, "fusion_material")
			duel.special_summon(fm2, me, "atk", true)
		"borrow":
			for c in _targets(step.get("what", "$t"), ctx):
				duel._detach(c)
				c.borrowed_from = c.owner
				c.owner = me
				c.controller = me
				duel.side(me).hand.append(c)
				duel.log_event("to_hand", {"player": me, "uid": c.uid})
		"mill":
			var victim: Duel.PlayerSide = duel.side(who(step.get("who", "opp"), ctx))
			for i in int(step.get("n", 1)):
				if victim.deck.is_empty():
					break
				duel.send_to_grave(victim.deck.back(), "milled")
		"double_atk":
			for c in _targets(step.get("what", "$t"), ctx):
				if duel.spell_unaffected(c, ctx["src"]):
					continue
				c.mods.append({"atk": duel.atk_of(c), "def": 0, "until": "end_turn", "src": ctx["src"].uid})
				if step.get("destroy_at_end", false):
					c.flags["destroy_at_end"] = true
		"become_equip":
			var hosts := _targets(step.get("to", "$t"), ctx)
			var eq_list := _targets(step.get("card", "src"), ctx)
			if eq_list.is_empty() or hosts.is_empty() or (eq_list[0] as DCard).token != "":
				return null
			var eq: DCard = eq_list[0]
			var es: Duel.PlayerSide = duel.side((hosts[0] as DCard).controller if step.get("on_host_side", false) else eq.owner)
			var ez: int = duel.free_zone(es.spells)
			if ez != -1:
				duel._detach(eq)
				es.spells[ez] = eq
				eq.controller = (hosts[0] as DCard).controller if step.get("on_host_side", false) else eq.owner
				eq.face_up = true
				duel.equip_card(eq, hosts[0], {"atk": int(step.get("atk", 0)), "def": int(step.get("def", 0))})
		"flag_from_var":
			for c in _targets(step.get("what", "src"), ctx):
				c.flags[step["name"]] = int(ctx["vars"].get(step["var"], 0)) + int(step.get("add", 0))
		"watch":
			var seen := _targets(step.get("what", "$t"), ctx)
			if not seen.is_empty():
				ctx["src"].flags["watch"] = seen[0].uid
		"skip_turn": duel.skip_turn[who(step.get("who", "self"), ctx)] = true
		"lockdown": duel.lockdown_until = duel.turn + int(step.get("turns", 2))
		"draw_until":
			var dp: int = who(step.get("who", "self"), ctx)
			duel.draw_cards(dp, maxi(0, int(step.get("n", 5)) - duel.side(dp).hand.size()))
		"banish_random_hand":
			var hp: int = who(step.get("who", "opp"), ctx)
			var hand_cards: Array = duel.side(hp).hand
			if not hand_cards.is_empty():
				var chosen: DCard = hand_cards[duel.rng.randi_range(0, hand_cards.size() - 1)]
				duel.banish_card(chosen)
				chosen.face_up = false
				var delay := int(step.get("after", 7))
				if step.has("owner_turns"):
					delay = maxi(0, (int(step["owner_turns"]) - 1) * 2 + (0 if duel.turn_player == hp else 1))
				chosen.flags["return_turn"] = duel.turn + delay
		"give_to_deck":
			var gp: int = who(step.get("to", "opp"), ctx)
			for c in _targets(step.get("what", "src"), ctx):
				duel._detach(c)
				c.planted_by = c.owner
				c.face_up = false
				duel.side(gp).deck.append(c)
				duel.shuffle_deck(gp)
		"block_zones":
			var blocked := []
			var bside: int = who(step.get("side", "opp"), ctx)
			for key in ["a", "b"]:
				var wanted: int = int(ctx["vars"].get(step[key], 0))
				for k in 5:
					var zc := (wanted + k) % 5
					if duel.side(bside).monsters[zc] == null and not _already_blocked(blocked, bside, zc):
						blocked.append({"side": bside, "zone": zc})
						break
			ctx["src"].flags["blocked"] = blocked
		"move_equips":
			var hosts2 := _targets(step.get("to", "$t"), ctx)
			if not hosts2.is_empty():
				for p2 in 2:
					for sc in (duel.side(p2).spells as Array):
						if sc != null and sc.face_up and sc.equipped_to != null and sc.equipped_to != hosts2[0]:
							duel.equip_card(sc, hosts2[0], sc.equip_mod)
		"swap_attacker":
			var nt := _targets(step.get("to", "$t"), ctx)
			if not nt.is_empty():
				duel.swap_attacker(nt[0])
		"take_from_hand":
			# Exchange: `what` (a card in the other hand) joins my hand; it goes home when it is discarded or played out
			for c in _targets(step.get("what", "$t"), ctx):
				duel._detach(c)
				c.home_owner = c.owner
				c.owner = who(step.get("to", "self"), ctx)
				c.controller = c.owner
				duel.side(c.owner).hand.append(c)
				duel.log_event("to_hand", {"player": c.owner, "uid": c.uid})
		"remove_top":
			# banish the top `n` cards of a Deck [Lady Assailant of Flames]
			var rdeck: Array = duel.side(who(step.get("who", "self"), ctx)).deck
			var removed := 0
			for i in int(step.get("n", 1)):
				if rdeck.is_empty():
					break
				duel.banish_card(rdeck.back())
				removed += 1
			if step.has("as"):
				ctx["vars"][step["as"]] = removed
		"switch_equip":
			var sw_cards := _targets(step.get("card", "$e"), ctx)
			var sw_hosts := _targets(step.get("to", "$h"), ctx)
			if not sw_cards.is_empty() and not sw_hosts.is_empty():
				duel.equip_card(sw_cards[0], sw_hosts[0], (sw_cards[0] as DCard).equip_mod)
		"extra_summon": duel.normal_summoned = false          # Ultimate Offering: one more Normal Summon or Set
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
		"var_ge": return int(ctx["vars"].get(c.get("name", ""), 0)) >= int(c.get("v", 0))
		"var_le": return int(ctx["vars"].get(c.get("name", ""), 0)) <= int(c.get("v", 0))
	return _cond(c, ctx)

func _selection_is_banish_cost(step: Dictionary, ctx: Dictionary) -> bool:
	for op in ctx.get("effect", {}).get("cost", []):
		if op.get("op", "") == "banish" and op.get("what", "") == "$" + str(step.get("as", "")):
			return true
	return false

func _selection_is_banish_effect(step: Dictionary, ctx: Dictionary) -> bool:
	for op in ctx.get("effect", {}).get("do", []):
		if op.get("op", "") == "banish" and op.get("what", "") == "$" + str(step.get("as", "")):
			return true
	return false
