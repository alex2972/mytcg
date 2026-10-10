class_name JoeyAI
extends RefCounted
## The opponent AI, ported from the original's code (see docs/AI_NOTES.md for the function addresses).
## One call to step() performs one action, so the board can pace and animate the opponent's turn.
##
## What is ported (original function in brackets):
##  - attack planner: weakest attacker first, best target by net damage, with the "will I get punished" gate
##    [005b0b90, 005b0d90, 005b0f40, 005b05a0]; face-down enemy monsters are assumed to be 1000 ATK/DEF (1900 for level 5+) [005addc0]
##  - summon for attack: simulate every hand monster and take the one that improves the planned attacks most [005b1360]
##  - general summon choice, flip-effect monsters first when their effect is useful [005b16c0]
##  - attack / defense / set decision from the enemy's strongest monster [005ae0a0, 005ae270, 005adec0]
##  - flipping and repositioning [005b77f0]
## Not ported yet: the per-card spell/trap/effect decisions (the 269-card handler table), the chain/response AI.
## Handlers that are not ported yet fall back to "use it if harmless" (main phase) or "yes" (responses).

## Cards (original ids from data/card_id.bin) with a Flip effect; they are Set face-down, never summoned to attack [00567620].
const FLIP_IDS := [0x262, 0x1d4, 0x27, 0x52, 0x53, 0x65, 0xaa, 0xdf, 0x109, 0x1ab, 0x1cd, 0x1e9, 500, 0x21b, 0x21c, 0x231,
	0x246, 0x249, 0x24e, 0x259, 0x280, 0x2d9, 0x2db, 0x2fa, 0x418, 0x452, 0x45c, 0x48b, 0x4e6, 0x4e7, 0x4e8, 0x51b, 0x532,
	0x539, 0x53a, 0x59b, 0x59c, 0x5e8, 0x5f1, 0x5f4]
## These attack last [005b0b90]; Zombyra the Dark attacks first.
const ATTACK_LAST_IDS := [0x2f9, 0x226, 0x2e8]
const ATTACK_FIRST_ID := 0x5f3
const EXODIA_IDS := [16, 17, 18, 19, 20]
const SWORDS_ID := 0x15b

static func answer(d: Duel, p: int) -> bool:
	var pend: Dictionary = d.fx.pending
	if not pend.is_empty() and pend["player"] == p and pend["type"] == "chain":
		var pick := CardAI.respond_choice(d, p, pend)
		d.respond(pick if not pick.is_empty() else "pass")
		return true
	return SimpleAI.answer(d, p)

# --- the turn ---------------------------------------------------------------------------------

static func step(d: Duel, p: int) -> bool:
	if d.winner != -1:
		return false
	if answer(d, p):
		return true
	if d.fx.is_busy() or d.turn_player != p:
		return false
	match d.phase:
		"main1":
			if CardAI.use_main(d, p, false):
				return true
			if _attack_summon(d, p):
				return true
			if _reposition_for_attack(d, p):
				return true
			if _general_summon(d, p, false):
				return true
			var outlook := _simulate(_board(d, p, true), _board(d, 1 - p, false), d.side(1 - p).lp)
			if not (outlook["used"] as Array).is_empty():
				if d.to_battle(p) == "":
					return true
			return _main2_or_end(d, p)
		"battle":
			var plan := _plan(_real_board(d, p), _board(d, 1 - p, false), d.side(1 - p).lp)
			if not plan.is_empty():
				var a: DCard = plan["card"]
				var t: DCard = null
				if int(plan["tgt"]) >= 0:
					t = d.side(1 - p).monsters[int(plan["tgt"])]
				if d.attack(p, a, t) == "":
					return true
			d.to_main2(p)
			return true
		"main2":
			return _main2_or_end(d, p)
	return false

static func _main2_or_end(d: Duel, p: int) -> bool:
	if CardAI.use_main(d, p, true):
		return true
	if _general_summon(d, p, true):
		return true
	if _reposition_by_threat(d, p):
		return true
	for c in d.side(p).hand:
		if not d.is_monster(c) and d.set_spell_trap(p, c) == "":
			return true
	var discards := []
	var hand: Array = d.side(p).hand
	for i in d.hand_excess(p):
		discards.append(hand[hand.size() - 1 - i].uid)
	d.end_turn(p, discards)
	return false

# --- board views --------------------------------------------------------------------------------
# A view is {c, id, atk, def, lv, def_pos, face_up, can}; `can` = may take part in an attack plan.

static func _view(d: Duel, c: DCard, hide: bool, can: bool) -> Dictionary:
	var lv: int = d.level_of(c)
	if hide and not c.face_up:
		var v: int = 1000 if lv <= 4 else 1900
		return {"c": c, "id": -1, "atk": v, "def": v, "lv": lv, "def_pos": true, "face_up": false, "can": false}
	return {"c": c, "id": d.db.ai_id(c.idx), "atk": d.atk_of(c), "def": d.def_of(c), "lv": lv,
		"def_pos": c.pos == "def", "face_up": c.face_up, "can": can}

## Board of player `p` as the AI sees it. Own side: everything is known and every monster that could still
## attack (after a flip or a position change) counts. Enemy side: face-down monsters are anonymous.
static func _board(d: Duel, p: int, own: bool) -> Array:
	var out := []
	for c in d.side(p).monsters:
		if c == null:
			out.append(null)
		else:
			out.append(_view(d, c, not own, own and _could_attack(d, c)))
	return out

## Own board with the monsters that may attack right now.
static func _real_board(d: Duel, p: int) -> Array:
	var out := []
	for c in d.side(p).monsters:
		if c == null:
			out.append(null)
		else:
			var v := _view(d, c, false, d.can_attack(p, c) == "")
			v["card"] = c
			out.append(v)
	return out

static func _could_attack(d: Duel, c: DCard) -> bool:
	if c.attacked:
		return false
	if c.face_up and c.pos == "atk":
		return true
	if c.summon_turn == d.turn or c.pos_changed:
		return false
	return not (not c.face_up and FLIP_IDS.has(d.db.ai_id(c.idx)))

static func _copy(board: Array) -> Array:
	var out := []
	for v in board:
		out.append(null if v == null else (v as Dictionary).duplicate())
	return out

static func _max_atk(board: Array, exclude: int) -> int:
	var best := -1
	for z in board.size():
		if z != exclude and board[z] != null:
			best = maxi(best, int(board[z]["atk"]))
	return best

# --- attack planner -----------------------------------------------------------------------------

## The next attack: {att, tgt (-1 = direct), score, kill_t, kill_a, card} or {}.
static func _plan(mine: Array, foe: Array, foe_lp: int) -> Dictionary:
	var order := []
	for z in mine.size():
		var m = mine[z]
		if m != null and m["can"]:
			var tier := 2
			if ATTACK_LAST_IDS.has(int(m["id"])):
				tier = 3
			elif int(m["id"]) == ATTACK_FIRST_ID:
				tier = 1
			order.append({"z": z, "key": tier * 65536 + int(m["atk"])})
	order.sort_custom(func(a, b): return a["key"] < b["key"] or (a["key"] == b["key"] and a["z"] < b["z"]))
	for o in order:
		var r := _best_target(mine, foe, foe_lp, int(o["z"]))
		if not r.is_empty():
			if mine[int(o["z"])].has("card"):
				r["card"] = mine[int(o["z"])]["card"]
			return r
	return {}

static func _best_target(mine: Array, foe: Array, foe_lp: int, z: int) -> Dictionary:
	var a: Dictionary = mine[z]
	var any_foe := false
	for f in foe:
		if f != null:
			any_foe = true
	if not any_foe:
		if int(a["atk"]) > 0 and _gate(foe, foe_lp, a, -1):
			return {"att": z, "tgt": -1, "score": int(a["atk"]), "kill_t": false, "kill_a": false}
		return {}
	var best := {}
	for t in foe.size():
		var f = foe[t]
		if f == null:
			continue
		var ev := _eval(a, f)
		if not ev["good"] or not _gate(foe, foe_lp, a, t):
			continue
		ev["att"] = z
		ev["tgt"] = t
		if best.is_empty() or int(ev["score"]) > int(best["score"]):
			best = ev
		elif int(ev["score"]) == int(best["score"]):
			# tie: a face-up target must have more DEF than the current choice, a face-down one is preferred
			if not f["face_up"] or int(f["def"]) > int(foe[int(best["tgt"])]["def"]):
				best = ev
	return best

## Outcome of attacker `a` against `f` [005b0f40].
static func _eval(a: Dictionary, f: Dictionary) -> Dictionary:
	var at: int = a["atk"]
	var t: int = f["def"] if f["def_pos"] else f["atk"]
	var dmg := 0
	var self_dmg := 0
	var kill_t := false
	var kill_a := false
	if at == t:
		if not f["def_pos"] and at >= 1:
			kill_t = true
			kill_a = true
	elif t < at:
		kill_t = true
		if not f["def_pos"]:
			dmg = at - t
	elif not f["def_pos"]:
		kill_a = true
		self_dmg = t - at
	var score := dmg - self_dmg
	return {"score": score, "kill_t": kill_t, "kill_a": kill_a, "good": score >= 1 or (kill_t and not kill_a)}

## Do not attack when another enemy monster would crush the attacker afterwards [005b05a0].
static func _gate(foe: Array, foe_lp: int, a: Dictionary, target: int) -> bool:
	var atk: int = a["atk"]
	if target == -1:
		if foe_lp <= atk:
			return true
		if atk < 300:
			return false
	return _max_atk(foe, target) < atk + 1000

## Repeat the planner on a copy of the boards: total expected damage and enemy monsters destroyed [005b0a50].
static func _simulate(mine: Array, foe: Array, foe_lp: int) -> Dictionary:
	var m := _copy(mine)
	var f := _copy(foe)
	var total := 0
	var kills := 0
	var used := []
	while true:
		var plan := _plan(m, f, foe_lp)
		if plan.is_empty():
			break
		var z: int = plan["att"]
		total += int(plan["score"])
		used.append(z)
		m[z]["can"] = false
		if plan["kill_a"]:
			m[z] = null
		if plan["kill_t"] and int(plan["tgt"]) >= 0:
			f[int(plan["tgt"])] = null
			kills += 1
	return {"total": total, "kills": kills, "used": used}

# --- summoning ------------------------------------------------------------------------------------

## Pick the hand monster whose summon makes the planned attacks best, and summon it face-up [005b1360].
static func _attack_summon(d: Duel, p: int) -> bool:
	if d.normal_summoned or _foe_has_id(d, p, SWORDS_ID):
		return false
	var mine := _board(d, p, true)
	var foe := _board(d, 1 - p, false)
	var lp: int = d.side(1 - p).lp
	var base := _simulate(mine, foe, lp)
	var have_tribute := not d.monsters_of(p).is_empty()
	var modes := []
	if not have_tribute:
		modes = [0, -1] if int(base["total"]) != 0 else [-1]
	else:
		modes = [1, -1]
	for mode in modes:
		var pick := _best_attack_candidate(d, p, mine, foe, lp, base, mode)
		if not pick.is_empty():
			return d.summon(p, pick["card"], pick["tributes"], -1, false) == ""
	return false

static func _best_attack_candidate(d: Duel, p: int, mine: Array, foe: Array, lp: int, base: Dictionary, mode: int) -> Dictionary:
	var best_total: int = base["total"]
	var best_kills: int = base["kills"]
	var best := {}
	for c in d.side(p).hand:
		if not d.is_monster(c):
			continue
		var need: int = d.tributes_required(c)
		if (mode == 0 and need > 0) or (mode == 1 and need == 0):
			continue
		var id: int = d.db.ai_id(c.idx)
		if FLIP_IDS.has(id) or _vetoed(d, p, id, 2) or d.atk_of(c) < 900:
			continue
		var tributes := _pick_tributes(d, p, c, need)
		if tributes.size() < need:
			continue
		var sim := _copy(mine)
		var zone := -1
		for t in tributes:
			var tz: int = (d.side(p).monsters as Array).find(t)
			sim[tz] = null
			if zone == -1:
				zone = tz
		if zone == -1:
			zone = sim.find(null)
		if zone == -1:
			continue
		var v := _view(d, c, false, true)
		sim[zone] = v
		var r := _simulate(sim, foe, lp)
		if not (r["used"] as Array).has(zone):
			continue
		if int(r["total"]) > best_total or (int(r["total"]) == best_total and int(r["kills"]) > best_kills):
			best_total = r["total"]
			best_kills = r["kills"]
			best = {"card": c, "tributes": tributes}
	return best

## Weakest monsters (DEF + 2 ATK) that are weaker than the monster being summoned [005aed60, 005aece0].
static func _pick_tributes(d: Duel, p: int, c: DCard, need: int) -> Array:
	if need == 0:
		return []
	var mons: Array = d.monsters_of(p).filter(func(m): return d.atk_of(m) < d.atk_of(c))
	mons.sort_custom(func(a, b): return d.def_of(a) + 2 * d.atk_of(a) < d.def_of(b) + 2 * d.atk_of(b))
	return mons.slice(0, need) if mons.size() >= need else []

static func _summonable(d: Duel, p: int, c: DCard) -> bool:
	if d.normal_summoned or not d.is_monster(c):
		return false
	var need: int = d.tributes_required(c)
	if need == 0:
		return d.free_zone(d.side(p).monsters) != -1
	return _pick_tributes(d, p, c, need).size() >= need

## The monster to summon when nothing improves the attack: flip-effect monsters when useful, then the
## strongest sensible monster, then anything cheap to defend with [005b16c0].
static func _general_summon(d: Duel, p: int, allow_set: bool) -> bool:
	if d.normal_summoned or _foe_has_id(d, p, SWORDS_ID):
		return false
	var pick: DCard = _choose_general(d, p)
	if pick == null:
		return false
	var id: int = d.db.ai_id(pick.idx)
	var set_it := _should_set(d, p, pick)
	if set_it and not allow_set:
		return false                      # the original waits for Main Phase 2 to Set
	var tributes := _pick_tributes(d, p, pick, d.tributes_required(pick))
	var r := d.summon(p, pick, tributes, -1, set_it)
	if r != "":
		return false
	return id >= 0

static func _choose_general(d: Duel, p: int) -> DCard:
	var s: Duel.PlayerSide = d.side(p)
	var foe_n: int = d.monsters_of(1 - p).size()
	var have_tribute := not d.monsters_of(p).is_empty()
	var free: bool = d.free_zone(s.monsters) != -1
	if not have_tribute and free:
		for entry in _priority_list(d, p, foe_n):
			var c := _hand_with_id(d, p, int(entry))
			if c != null and _summonable(d, p, c):
				return c
	var foe_best := 0
	for c in d.monsters_of(1 - p):
		foe_best = maxi(foe_best, d.atk_of(c))
	var own_best := 0
	for c in d.monsters_of(p):
		own_best = maxi(own_best, d.atk_of(c))
	var pick: DCard = null
	for c in s.hand:
		if not _summonable(d, p, c):
			continue
		var id: int = d.db.ai_id(c.idx)
		if _vetoed(d, p, id, 2):
			continue
		var val: int = maxi(d.atk_of(c), d.def_of(c))
		var lv: int = d.level_of(c)
		if ((own_best < val and foe_best <= val) or (have_tribute and lv > 4)) and (lv > 4 or free):
			pick = c
			own_best = val
	if pick != null:
		return pick
	if free:
		var danger := _in_danger(d, p)
		for c in s.hand:
			if d.is_monster(c) and d.level_of(c) < 5 and _summonable(d, p, c) \
					and not _vetoed(d, p, d.db.ai_id(c.idx), 1 if danger else 2):
				return c
	return null

## Flip-effect monsters worth Setting right now, in the original's order [005b16c0].
static func _priority_list(d: Duel, p: int, foe_n: int) -> Array:
	var out := []
	var s: Duel.PlayerSide = d.side(p)
	if foe_n > 0:
		out.append_array([500, 0x21c])                         # Man-Eater Bug, Hane-Hane
	if _grave_count(d, p, "spell") > 0:
		out.append(0x1ab)                                      # Magician of Faith
	if _grave_count(d, p, "trap") > 0:
		out.append(0x65)                                       # Mask of Darkness
	var opp_hand: int = d.side(1 - p).hand.size()
	if s.hand.size() < 3 or s.hand.size() + 2 < opp_hand:
		out.append_array([0x21b, 0x24e])                       # Skelengel, Morphing Jar
	if _foe_has_id(d, p, SWORDS_ID):
		out.append(0x246)                                      # Weather Report
	if _foe_has_id(d, p, 0x148):
		out.append(0x27)                                       # Dragon Piper vs Dragon Capture Jar
	var foe_st := _foe_spell_trap_count(d, p)
	if foe_st > 1:
		out.append_array([0x109, 0x249])                       # Princess of Tsurugi, Greenkappa
	if foe_st > 0:
		out.append(0xdf)                                       # Trap Master
	if _board_balance(d, p) < 0:
		out.append_array([0x48b, 0x452])                       # Morphing Jar #2, Cyber Jar
	return out

## Cards the AI refuses to summon because their effect would do nothing [005ae3e0, partly].
static func _vetoed(d: Duel, p: int, id: int, level: int) -> bool:
	if EXODIA_IDS.has(id):
		return true
	if level < 2:
		return false
	match id:
		0x1ab: return _grave_count(d, p, "spell") == 0
		0x65: return _grave_count(d, p, "trap") == 0
		0x109, 0x249, 0xdf: return _foe_spell_trap_count(d, p) == 0
		0x4de: return d.monsters_of(1 - p).filter(func(c): return c.face_up).is_empty()
	return false

# --- attack / defense / set decisions --------------------------------------------------------------

## Should this monster Set / defend? [005ae270]
static func _should_set(d: Duel, p: int, c: DCard) -> bool:
	var id: int = d.db.ai_id(c.idx)
	if FLIP_IDS.has(id):
		return true
	return _position_eval(d, p, d.atk_of(c), d.def_of(c)) == 1

## -1 no opinion, 0 attack position, 1 defense position [005ae0a0].
static func _position_eval(d: Duel, p: int, atk: int, def: int) -> int:
	var opp := 1 - p
	var threat := _max_atk(_board(d, opp, false), -1)
	var own_atk := 0
	var own_def := 0
	var own_sum := 0
	for c in d.monsters_of(p):
		own_atk = maxi(own_atk, d.atk_of(c))
		own_def = maxi(own_def, d.def_of(c))
		own_sum += d.atk_of(c)
	if d.monsters_of(opp).is_empty() and d.side(opp).lp <= own_sum:
		return 1 if atk == 0 else 0
	if atk == 0:
		return 1
	if threat - atk >= 1000:
		return 1
	if atk < def:
		if threat <= atk and atk > 1699:
			return 0
		if maxi(own_atk, own_def) <= def and def > 1500:
			return 1
		var foe_face_up := d.monsters_of(opp).filter(func(c): return c.face_up).size()
		if foe_face_up != 0 and threat <= atk:
			return 0
	else:
		if threat <= atk:
			return 0
		if threat - atk < 301 and d.side(p).lp > 300:
			return 0
	return -1 if threat <= atk + 300 else 1

static func _in_danger(d: Duel, p: int) -> bool:
	var own := 0
	for c in d.monsters_of(p):
		own += d.atk_of(c)
	var foe := 0
	for v in _board(d, 1 - p, false):
		if v != null:
			foe += int(v["atk"])
	return d.side(p).lp <= foe - own

## 2 = I am ahead, 0 = even, -2 = behind [005afe90].
static func _board_balance(d: Duel, p: int) -> int:
	var f_atk := 0
	var f_def := 0
	for c in d.monsters_of(1 - p):
		if c.face_up:
			f_atk = maxi(f_atk, d.atk_of(c))
			f_def = maxi(f_def, d.def_of(c))
	var m_atk := 0
	var m_def := 0
	for c in d.monsters_of(p):
		m_atk = maxi(m_atk, d.atk_of(c))
		m_def = maxi(m_def, d.def_of(c))
	if maxi(f_atk, f_def) < m_atk:
		return 2
	return 0 if f_atk <= maxi(m_atk, m_def) else -2

# --- flipping and repositioning ---------------------------------------------------------------------

## Monsters that the plan wants attacking get flipped / switched to attack position [005b76c0, 005b77f0].
static func _reposition_for_attack(d: Duel, p: int) -> bool:
	var mine := _board(d, p, true)
	var sim := _simulate(mine, _board(d, 1 - p, false), d.side(1 - p).lp)
	for z in sim["used"]:
		var c: DCard = d.side(p).monsters[int(z)]
		if c == null or (c.face_up and c.pos == "atk"):
			continue
		if c.summon_turn == d.turn or c.pos_changed or c.attacked:
			continue
		if d.change_position(p, c) == "":
			return true
	return false

## Main Phase 2: each monster takes the position the threat assessment asks for [005b7960, 005adec0].
static func _reposition_by_threat(d: Duel, p: int) -> bool:
	for c in d.monsters_of(p):
		if c.summon_turn == d.turn or c.pos_changed or c.attacked:
			continue
		var id: int = d.db.ai_id(c.idx)
		if not c.face_up and FLIP_IDS.has(id):
			continue
		var want := _position_eval(d, p, d.atk_of(c), d.def_of(c))
		if want == 0 and not (c.face_up and c.pos == "atk"):
			if d.change_position(p, c) == "":
				return true
		elif want == 1 and c.face_up and c.pos == "atk":
			if d.change_position(p, c) == "":
				return true
	return false

# --- small board queries -----------------------------------------------------------------------------

static func _hand_with_id(d: Duel, p: int, id: int) -> DCard:
	for c in d.side(p).hand:
		if d.is_monster(c) and d.db.ai_id(c.idx) == id:
			return c
	return null

static func _foe_has_id(d: Duel, p: int, id: int) -> bool:
	var s: Duel.PlayerSide = d.side(1 - p)
	for c in s.monsters + s.spells + [s.field_spell]:
		if c != null and d.db.ai_id(c.idx) == id:
			return true
	return false

static func _foe_spell_trap_count(d: Duel, p: int) -> int:
	var n := 0
	for c in d.side(1 - p).spells:
		if c != null:
			n += 1
	return n

static func _grave_count(d: Duel, p: int, kind: String) -> int:
	var n := 0
	for c in d.side(p).grave:
		if str(d.card_data(c).get("type", "")) == kind:
			n += 1
	return n
