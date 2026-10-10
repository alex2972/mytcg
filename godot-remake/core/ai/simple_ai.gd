class_name SimpleAI
extends RefCounted
## PLACEHOLDER opponent for testing the duel board. The real opponent AI (M6) must reproduce the
## original's behaviour. One call = one action, so a UI can pace and animate the turn.

## Answer the pending decision if it belongs to `p`. Returns true when it answered.
static func answer(d: Duel, p: int) -> bool:
	var pend: Dictionary = d.fx.pending
	if pend.is_empty() or pend["player"] != p:
		return false
	match pend["type"]:
		"select":
			var cands: Array = (pend["candidates"] as Array).map(func(u): return d.card_by_uid(u))
			cands.sort_custom(func(a, b): return _value(d, a) > _value(d, b))
			var cheap: bool = pend.get("cost", false) or str(pend.get("from", "")).contains("hand")
			if cheap:
				cands.reverse()
			else:
				# prefer the opponent's best card for removal, my own best card for boosts (the one in the fight first)
				var eff: Dictionary = ((pend.get("_task", {}) as Dictionary).get("ctx", {}) as Dictionary).get("effect", {})
				var mine := cands.filter(func(c): return c.controller == p)
				var foes := cands.filter(func(c): return c.controller != p)
				if _is_boost(eff) and not mine.is_empty():
					cands = mine
					var fighting: Array = []
					for key in ["attacker", "target"]:
						if d.current_attack.get(key) != null:
							fighting.append(d.current_attack[key])
					cands.sort_custom(func(a, b): return fighting.has(a) and not fighting.has(b))
				elif not foes.is_empty() and not str(pend.get("from", "")).begins_with("self"):
					cands = foes
					if not d.fx.chain.is_empty():
						# answering a Spell they just played: aim at that very card
						var played: DCard = d.fx.chain.back()["card"]
						if played.controller != p and cands.has(played):
							cands = [played]
					elif d.phase == "end":
						# end of turn: hit a Set card first
						cands.sort_custom(func(a, b): return (not a.face_up) and b.face_up)
			var picks: Array = cands.slice(0, pend["max"]).map(func(c): return c.uid)
			if int(pend.get("sum_level_min", 0)) > 0:
				# offer the cheapest cards until the Levels add up
				var ordered: Array = (pend["candidates"] as Array).map(func(u): return d.card_by_uid(u))
				ordered.sort_custom(func(a, b): return _value(d, a) < _value(d, b))
				picks = []
				var total := 0
				for c in ordered:
					if total >= int(pend["sum_level_min"]) or picks.size() >= int(pend["max"]):
						break
					picks.append(c.uid)
					total += d.level_of(c)
			if picks.size() < pend["min"]:
				picks = (pend["candidates"] as Array).slice(0, pend["min"])
			d.respond(picks)
		"yesno":
			d.respond(true)
		"choice":
			d.respond(0)
		"chain":
			var opts: Array = pend["options"]
			var pick: Dictionary = opts[0]
			d.respond({"uid": pick["uid"], "idx": pick["idx"]})
	return true

## Does this effect make a card stronger (equips, positive ATK/DEF changes)?
static func _is_boost(e: Dictionary) -> bool:
	var plus := false
	for st in e.get("do", []):
		if st.get("op", "") in ["mod", "equip", "set_stat"]:
			for key in ["atk", "def"]:
				var v = st.get(key, 0)
				var sign_v: float = float(v) if (v is int or v is float) else float((v as Dictionary).get("by", 1)) if v is Dictionary else 0.0
				if sign_v < 0:
					return false
				if sign_v > 0:
					plus = true
	return plus

static func _value(d: Duel, c: DCard) -> int:
	@warning_ignore("integer_division")
	return d.atk_of(c) + d.def_of(c) / 2 if d.is_monster(c) else 500

## Performs one action for player `p`. Returns true while the turn continues, false once the turn was ended.
static func step(d: Duel, p: int) -> bool:
	if d.winner != -1:
		return false
	if answer(d, p):
		return true
	if d.fx.is_busy() or d.turn_player != p:
		return false
	match d.phase:
		"main1":
			if _develop(d, p):
				return true
			d.to_battle(p)
			return true
		"battle":
			if _attack(d, p):
				return true
			d.to_main2(p)
			return true
		"main2":
			if _develop(d, p):
				return true
			var discards := []
			var hand: Array = d.side(p).hand
			for i in d.hand_excess(p):
				discards.append(hand[hand.size() - 1 - i].uid)
			d.end_turn(p, discards)
			return false
	return false

static func _weakest(d: Duel, p: int, n: int) -> Array:
	var mons: Array = d.monsters_of(p)
	mons.sort_custom(func(a, b): return d.atk_of(a) < d.atk_of(b))
	return mons.slice(0, n)

static func _best_foe_atk(d: Duel, p: int) -> int:
	var best := 0
	for c in d.monsters_of(1 - p):
		best = maxi(best, d.atk_of(c) if c.pos == "atk" else d.def_of(c))
	return best

## Would activating this effect hurt me? (crude: mass destruction / mass bounce of both sides, big LP payments)
static func _safe(d: Duel, p: int, e: Dictionary) -> bool:
	for st in (e.get("do", []) as Array) + (e.get("cost", []) as Array):
		var what = st.get("what", null)
		if st.get("op", "") in ["destroy", "to_hand", "to_grave", "banish", "to_deck"] and what is Dictionary:
			var from: String = str(what.get("from", ""))
			if from in ["monsters", "field", "spells"]:
				return false
		if st.get("op", "") == "pay_lp" and d.side(p).lp < 3000:
			return false
		if st.get("op", "") == "negate" and false:
			return false
	return true

## Use one spell / ignition effect that is harmless to the user. The per-card decisions of the original are not ported yet.
static func use_effects(d: Duel, p: int) -> bool:
	for o in d.activatable_effects(p):
		var c: DCard = d.card_by_uid(o["uid"])
		var e: Dictionary = d.fx.effects_of(c)[o["idx"]]
		if e.get("type", "") in ["trap", "counter", "continuous_trap"]:
			continue
		if _safe(d, p, e) and d.activate_effect(p, c, o["idx"]) == "":
			return true
	return false

static func _develop(d: Duel, p: int) -> bool:
	var s: Duel.PlayerSide = d.side(p)
	if use_effects(d, p):
		return true
	if not d.normal_summoned:
		var best: DCard = null
		for c in s.hand:
			if not d.is_monster(c):
				continue
			var need := d.tributes_required(c)
			if need > d.monsters_of(p).size():
				continue
			if need == 0 and (s.monsters as Array).find(null) == -1:
				continue
			if best == null or d.atk_of(c) > d.atk_of(best):
				best = c
		if best != null:
			var tributes := _weakest(d, p, d.tributes_required(best))
			var face_down: bool = d.atk_of(best) < _best_foe_atk(d, p) and not d.monsters_of(1 - p).is_empty()
			if d.summon(p, best, tributes, -1, face_down) == "":
				return true
	for c in s.hand:
		if not d.is_monster(c) and d.set_spell_trap(p, c) == "":
			return true
	return false

static func _attack(d: Duel, p: int) -> bool:
	var foes: Array = d.monsters_of(1 - p)
	for a in d.monsters_of(p):
		if d.can_attack(p, a) != "":
			continue
		if foes.is_empty():
			return d.attack(p, a, null) == ""
		var pick: DCard = null
		for t in foes:
			var wins: bool
			if t.face_up and t.pos == "atk":
				wins = d.atk_of(a) > d.atk_of(t)
			else:
				wins = d.atk_of(a) > (d.def_of(t) if t.face_up else 1000)
			if wins and (pick == null or d.atk_of(t) > d.atk_of(pick)):
				pick = t
		if pick != null:
			return d.attack(p, a, pick) == ""
	return false
