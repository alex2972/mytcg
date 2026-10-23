class_name CardAI
extends RefCounted
## Per-card "should I use this now?" decisions of the original AI (docs/AI_NOTES.md, table at exe 0x5dd0a8).
## data/ai_cards.json maps a card name to its table entries: the timing group it sits in and its handler
## (the last six hex digits of the handler's address). Only cards listed there are ever used by the AI.
##
## Groups: standby (used first thing in the turn), main_s3 (main phase spells/equips/removal), main_s2 (monster effects),
## end (end phase), chain_response / tbl_5dd308 (answers to what the opponent does).
## A handler we have not ported yet is treated as "yes" for responses and "only if harmless" for main-phase use.

const MAIN_GROUPS := ["standby", "main_s3", "main_s2"]
const RESPONSE_GROUPS := ["chain_response", "tbl_5dd308"]
const FIRE_PRINCESS := 0x59a
const MAGIC_THORN := 0x40e

static var _table := {}

static func _entries(name: String) -> Array:
	if _table.is_empty():
		_table = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai_cards.json"))
	return _table.get(name, [])

static func listed(d: Duel, c: DCard) -> bool:
	return not _entries(d.db.card_name(c.idx)).is_empty()

# --- main phase ---------------------------------------------------------------------------------

## Use one spell / equip / effect the original would use now. Returns true if something was activated.
static func use_main(d: Duel, p: int, include_end: bool) -> bool:
	var groups: Array = MAIN_GROUPS + (["end"] if include_end else [])
	var options: Array = d.activatable_effects(p)
	for group in groups:
		for o in options:
			var c: DCard = d.card_by_uid(o["uid"])
			var e: Dictionary = d.fx.effects_of(c)[o["idx"]]
			if e.get("type", "") in ["trap", "counter", "continuous_trap"]:
				continue
			for en in _entries(str(o["name"])):
				if en["group"] != group:
					continue
				var verdict := _handler(str(en["h"]), d, p, c, int(o["idx"]), "", {})
				if verdict == 0 or (verdict == -1 and not SimpleAI._safe(d, p, e)):
					continue
				# An effect that keeps resolving without changing anything (e.g. a Fusion Gate fusion that
				# aborts) must not be retried forever: at most 2 activations of one effect per turn.
				var key := "%d:%d:%d" % [d.turn, c.uid, int(o["idx"])]
				var tried: Dictionary = d.get_meta("ai_tried", {})
				if int(tried.get(key, 0)) >= 2:
					continue
				if d.activate_effect(p, c, int(o["idx"])) == "":
					tried[key] = int(tried.get(key, 0)) + 1
					d.set_meta("ai_tried", tried)
					return true
	return false

# --- responses ----------------------------------------------------------------------------------

## The chain option the original would take for the pending decision, or {} to pass.
static func respond_choice(d: Duel, p: int, pend: Dictionary) -> Dictionary:
	var event: String = pend.get("event", "")
	var data: Dictionary = (pend["_task"] as Dictionary).get("data", {})
	for o in pend["options"]:
		var c: DCard = d.card_by_uid(o["uid"])
		var name := str(o["name"])
		var entries := _entries(name)
		if entries.is_empty():
			continue                        # cards the table does not list are never used by the AI
		for en in entries:
			if not RESPONSE_GROUPS.has(en["group"]):
				continue
			if _handler(str(en["h"]), d, p, c, int(o["idx"]), event, data) != 0:
				return {"uid": o["uid"], "idx": o["idx"]}
	return {}

# --- handlers -------------------------------------------------------------------------------------
# Return 1 = yes, 0 = no, -1 = not ported yet.

static func _handler(h: String, d: Duel, p: int, c: DCard, idx: int, event: String, data: Dictionary) -> int:
	var opp := 1 - p
	var name: String = d.db.card_name(c.idx)
	match h:
		"581040":                                       # no extra condition
			return 1
		"lod_neg_opp":                                  # Dark Balter, Ryu Senshi, The Dragon's Bead: never negate my own card
			return int(not d.fx.chain.is_empty() and int(d.fx.chain.back()["player"]) != p)
		"5b5a20":                                       # equip: my best monster must have more than 1299 ATK
			return int(_best_target_atk(d, p, c, idx, true) > 1299)
		"5b5a60":                                       # curse: the enemy's best monster must have more than 1299 ATK
			return int(_best_target_atk(d, p, c, idx, false) > 1299)
		"5b5ab0":
			return int(_not_duplicate(d, p, c) and _best_target_atk(d, p, c, idx, true) > 1299)
		"5b5010":                                       # field spell: my field spell zone must be empty
			return int(d.side(p).field_spell == null)
		"5b48d0":                                       # healing: hold it while Fire Princess waits in hand or deck
			return int(_fire_princess(d, p) != 0)
		"5b4860":                                       # needs something to hit on the enemy side
			return int(_has_targets(d, p, c, idx, false))
		"5b5b80":                                       # mass removal: not when it would hit my own monsters
			return int(not _has_targets(d, p, c, idx, true))
		"5b2640":
			return int(_attack_response(d, p, c, event, data))
		"5b1f10":                                       # Mystical Space Typhoon at the end of the turn, when they have a Set Spell/Trap
			return int(d.phase == "end" and _spell_trap_count(d, opp, true) > 0)
		"5b3210":                                       # ...or against a field / equip / continuous Spell they just activated
			var link_card: DCard = d.card_by_uid(int(data.get("uid", -1)))
			if link_card == null or link_card.controller == p or str(data.get("kind", "")) != "spell":
				return 0
			return int(int(d.card_data(link_card).get("subtype", 0)) in [2, 3, 4])
		"5b2e60", "5b35a0", "5b3480":
			return _booster(d, p, c, event, data)
		"5b1e00":                                       # Sebek's Blessing
			var amount: int = int(data.get("amount", 0))
			return int(_fire_princess(d, p) >= 2 or d.side(p).lp <= 1000 or amount >= 1500)
		"5b2090":                                       # Just Desserts
			var foe_n: int = d.monsters_of(opp).size()
			return int(d.side(opp).lp <= foe_n * 500 or foe_n > 1)
		"5b4890":
			return int(_not_duplicate(d, p, c))
		"5b4910":                                       # Tremendous Fire
			return int(d.side(opp).lp < d.side(p).lp + 500)
		"5b4970":                                       # Harpie's Feather Duster
			return int(_spell_trap_count(d, opp, false) > 1)
		"5b49a0":                                       # Mystical Space Typhoon
			return int(_spell_trap_count(d, opp, true) > 0)
		"5b4ae0":                                       # Heavy Storm
			return int(_spell_trap_count(d, opp, false) > _spell_trap_count(d, p, false))
		"5b4b50":                                       # Soul Release
			return int(d.side(opp).grave.size() > 4)
		"5b4df0":                                       # The Dark Door
			var foe_atk := d.monsters_of(opp).filter(func(m): return m.pos == "atk").size()
			return int(_not_duplicate(d, p, c) and foe_atk > 0)
		"5b4f10":                                       # Swords of Revealing Light, Nightmare's Steelcage
			return int(_not_duplicate(d, p, c) and JoeyAI._board_balance(d, p) < 0)
		"5b5060":                                       # Dark Hole
			return int(JoeyAI._in_danger(d, p) or JoeyAI._board_balance(d, p) < 0)
		"5b50a0":                                       # Raigeki
			return int(JoeyAI._in_danger(d, p) or JoeyAI._board_balance(d, p) < 0 or d.monsters_of(opp).size() > 2)
		"5b5100":                                       # Final Destiny
			return int(JoeyAI._board_balance(d, p) < 0)
		"5b5120":                                       # Change of Heart: I need a big monster to tribute the stolen one for
			return int(_change_of_heart_ok(d, p))
		"5b5230":                                       # Share the Pain
			return int(d.monsters_of(opp).size() < d.monsters_of(p).size())
		"5b5270":                                       # Mystic Box
			return int(d.monsters_of(p).size() > 1)
		"5b5300":                                       # Monster Reborn
			return int(_reborn_ok(d, p))
		"5b5720":                                       # Block Attack
			return int(_block_attack_ok(d, p))
		"5b58b0":                                       # Card Destruction
			return int(d.side(opp).hand.size() >= 2)
		"5b49d0":                                       # Giant Trunade
			return int(_trunade_ok(d, p))
		# Legacy of Darkness cards (not in the original game, so no original handler)
		"lod_heart":                                    # Heart of Clear Water: on my best monster that is still under 1300 ATK
			return int(_candidates(d, p, c, idx).any(func(t): return t.controller == p and t.face_up and d.atk_of(t) < 1300 and d.atk_of(t) >= 800))
		"lod_swap":                                     # Creature Swap: they hand over their weakest monster, I give mine
			var mine := d.monsters_of(p).map(func(m): return d.atk_of(m))
			var theirs := d.monsters_of(opp).map(func(m): return d.atk_of(m))
			return int(not mine.is_empty() and not theirs.is_empty() and mine.min() + 300 < theirs.min())
		"lod_exiled":                                   # Exiled Force: trade it for a monster that is clearly better
			return int(d.monsters_of(opp).any(func(m): return not m.face_up or d.atk_of(m) >= 1800))
		"lod_possessed":                                # Possessed Dark Soul: worth it when it takes more than itself
			var taken := 0
			for m in d.monsters_of(opp):
				if m.face_up and d.level_of(m) <= 3:
					taken += d.atk_of(m)
			return int(taken > d.atk_of(c) and d.side(p).monsters.count(null) >= 1)
		"lod_spirit_ryu":                               # Spirit Ryu: discard a Dragon only when the boost wins the battle
			var foe: DCard = d.card_by_uid(int(data.get("target", -1)))
			if foe == null or foe.controller == p:
				return 0
			var foe_v: int = d.atk_of(foe) if foe.pos == "atk" else d.def_of(foe)
			return int(d.atk_of(c) <= foe_v and foe_v < d.atk_of(c) + 1000)
		"lod_have_dragon":                              # Dragon's Rage: only with a Dragon of mine on the field
			return int(d.monsters_of(p).any(func(m): return m.face_up and d.race_of(m) == CardDB.RACES.find("Dragon")))
	return -1

# --- pieces ----------------------------------------------------------------------------------------

## 2 = Fire Princess is on my field, 0 = she is still in hand or deck (hold healing), 1 = otherwise [005aef10].
static func _fire_princess(d: Duel, p: int) -> int:
	if _count_on_field(d, p, FIRE_PRINCESS) > 0:
		return 2
	for c in d.side(p).hand + d.side(p).deck:
		if d.db.ai_id(c.idx) == FIRE_PRINCESS:
			return 0
	return 1

static func _count_on_field(d: Duel, p: int, id: int) -> int:
	var n := 0
	var s: Duel.PlayerSide = d.side(p)
	for c in s.monsters + s.spells + [s.field_spell]:
		if c != null and d.db.ai_id(c.idx) == id:
			n += 1
	return n

## Do not activate a second copy of a continuous card I already have [005b4890].
static func _not_duplicate(d: Duel, p: int, c: DCard) -> bool:
	return _count_on_field(d, p, d.db.ai_id(c.idx)) <= (1 if (d.side(p).spells as Array).has(c) else 0)

static func _spell_trap_count(d: Duel, p: int, face_down_only: bool) -> int:
	var n := 0
	for c in d.side(p).spells:
		if c != null and (not face_down_only or not c.face_up):
			n += 1
	return n

## Cards the effect's first target step could pick.
static func _candidates(d: Duel, p: int, c: DCard, idx: int) -> Array:
	var e: Dictionary = d.fx.effects_of(c)[idx]
	var steps: Array = e.get("target", [])
	for step in steps:
		if step.get("op", "") == "select":
			var ctx := {"src": c, "controller": p, "vars": {}, "event": {}, "effect": e, "idx": idx}
			return d.fx.ops.select_candidates(step, ctx)
	return []

## Highest ATK among the monsters an equip could go to on my side (mine = true) or on the enemy's side.
static func _best_target_atk(d: Duel, p: int, c: DCard, idx: int, mine: bool) -> int:
	var best := -1
	for t in _candidates(d, p, c, idx):
		if (t.controller == p) == mine:
			best = maxi(best, d.atk_of(t) + (500 if d.db.ai_id(t.idx) == 0x1ec else 0))
	return best

## Is there anything the effect would affect on my side (mine) or the enemy's side?
static func _has_targets(d: Duel, p: int, c: DCard, idx: int, mine: bool) -> bool:
	var e: Dictionary = d.fx.effects_of(c)[idx]
	for step in (e.get("target", []) as Array) + (e.get("do", []) as Array):
		var what = step.get("what", step)
		if what is Dictionary and what.has("filter") or step.get("op", "") == "select":
			var ctx := {"src": c, "controller": p, "vars": {}, "event": {}, "effect": e, "idx": idx}
			var spec: Dictionary = what if what is Dictionary and what.has("from") else step
			var cands: Array = d.fx.ops.select_candidates(spec, ctx)
			for t in cands:
				if (t.controller == p) == mine:
					return true
			return false
	return not mine

static func _change_of_heart_ok(d: Duel, p: int) -> bool:
	if d.monsters_of(1 - p).is_empty():
		return false
	for c in d.side(p).hand:
		if d.is_monster(c):
			var lv: int = d.level_of(c)
			if lv >= 5 and (lv < 7 or not d.monsters_of(p).is_empty()):
				return true
	return false

## Monster Reborn: take the best monster from either graveyard if it is strong enough [005b5300].
static func _reborn_ok(d: Duel, p: int) -> bool:
	var best: DCard = null
	for side in 2:
		for c in d.side(side).grave:
			if d.is_monster(c) and (best == null or d.atk_of(c) > d.atk_of(best)):
				best = c
	if best == null:
		return false
	var foe_best := 0
	for m in d.monsters_of(1 - p):
		if m.face_up:
			foe_best = maxi(foe_best, maxi(d.atk_of(m), d.def_of(m)))
	var strong: bool = d.atk_of(best) > 1700 and d.atk_of(best) > foe_best
	if not strong and (int(d.card_data(best).get("category", 0)) != 0 or JoeyAI.FLIP_IDS.has(d.db.ai_id(best.idx))):
		return false
	return true

## Block Attack: one of their attack-position monsters out-attacks my best one but is weaker than it in defense [005b5720].
static func _block_attack_ok(d: Duel, p: int) -> bool:
	var mine := 0
	for c in d.monsters_of(p):
		if c.pos == "atk":
			mine = maxi(mine, d.atk_of(c))
	for m in d.monsters_of(1 - p):
		if m.pos == "atk" and mine <= d.atk_of(m) and d.def_of(m) < mine:
			return true
	return false

static func _trunade_ok(d: Duel, p: int) -> bool:
	if _count_on_field(d, p, 0x488) > 0:                        # my Premature Burial wants its monster back later
		return true
	if d.monsters_of(1 - p).is_empty() and not d.monsters_of(p).is_empty() and _spell_trap_count(d, 1 - p, false) > 0:
		return true
	return false

# --- attack responses [005b2640] ---------------------------------------------------------------------

static func _attack_response(d: Duel, p: int, c: DCard, event: String, data: Dictionary) -> bool:
	if event != "attack_declared" and event != "target_declared":
		return false
	var attacker: DCard = d.card_by_uid(int(data.get("attacker", -1)))
	if attacker == null or attacker.controller == p:
		return false
	var target: DCard = d.card_by_uid(int(data.get("target", -1))) if int(data.get("target", -1)) >= 0 else null
	var direct: bool = target == null
	var atk: int = d.atk_of(attacker)
	var tv := 0
	if not direct:
		tv = d.atk_of(target) if target.pos == "atk" else d.def_of(target)
	var lp: int = d.side(p).lp
	var foe_lp: int = d.side(1 - p).lp
	var card_name: String = d.db.card_name(c.idx)
	match card_name:
		"Magic-Arm Shield", "Widespread Ruin":
			return true
		"Enchanted Javelin", "Spellbinding Circle":
			if card_name == "Enchanted Javelin" and _fire_princess(d, p) == 0:
				return false
			if _count_on_field(d, p, 0x15c) != 0:
				return true
			if direct:
				return atk >= lp
			var foe_max := 0
			for m in d.monsters_of(1 - p):
				if m.face_up:
					foe_max = maxi(foe_max, d.atk_of(m))
			return atk == foe_max
		"Waboku", "Mirror Force", "Mirror Wall", "Fairy Box":
			return direct or tv <= atk or JoeyAI._in_danger(d, p)
		"Negate Attack":
			if direct:
				return lp <= atk or atk >= 1500
			return tv <= atk or atk >= 1500
		"Magic Cylinder":
			return foe_lp <= atk or atk > 1499 or (direct and lp <= atk) or (not direct and tv <= atk)
		"Call Of The Haunted", "Scapegoat":
			return direct and d.monsters_of(p).is_empty()
		"Magical Hats":
			if direct:
				return false
			if JoeyAI.FLIP_IDS.has(d.db.ai_id(target.idx)):
				return target.face_up
			return atk >= tv and tv >= 1800
		"Kunai with Chain":
			return not direct and atk >= tv and d.monsters_of(p).any(func(m): return m.face_up)
		"Shift":
			if direct or tv > atk:
				return false
			for m in d.monsters_of(p):
				if m != target and m.pos == "atk" and d.atk_of(m) > atk:
					return true
			return false
		"Dark Spirit of the Silent":
			if direct or atk < tv:
				return false
			for m in d.monsters_of(1 - p):
				if m != attacker and m.face_up and d.atk_of(m) > tv:
					return true
			return false
		"Gravity Bind":
			return d.level_of(attacker) > 3
	return true

## Stat boosters used in battle: worth it when the boost turns a lost fight into a won one [005b2e60].
static func _booster(d: Duel, p: int, c: DCard, event: String, data: Dictionary) -> int:
	if event != "damage_step":
		return 0
	var attacker: DCard = d.card_by_uid(int(data.get("attacker", -1)))
	if attacker == null:
		return 0
	var target: DCard = d.card_by_uid(int(data.get("target", -1))) if int(data.get("target", -1)) >= 0 else null
	if target == null:
		return 0
	var atk_boost := 0
	var def_boost := 0
	match d.db.card_name(c.idx):
		"Reinforcements": atk_boost = 500
		"Castle Walls": def_boost = 500
		"Rush Recklessly": atk_boost = 700
		"The Reliable Guardian": def_boost = 700
		"Snake Fang": def_boost = -500
		"Mask of Weakness": atk_boost = -700
		_: return -1
	if attacker.controller != p and target.controller == p:
		# I defend: boost my monster so it survives
		var mine_v: int = d.atk_of(target) if target.pos == "atk" else d.def_of(target)
		var boost: int = atk_boost if target.pos == "atk" else def_boost
		var foe_atk: int = d.atk_of(attacker)
		return int(boost > 0 and mine_v < foe_atk and foe_atk <= mine_v + boost)
	if attacker.controller == p and target.controller != p:
		# I attack: weaken their monster so I win
		var my_atk: int = d.atk_of(attacker)
		var foe_v: int = d.atk_of(target) if target.pos == "atk" else d.def_of(target)
		var cut: int = -(atk_boost if target.pos == "atk" else def_boost)
		return int(cut > 0 and my_atk <= foe_v and foe_v - cut < my_atk)
	return 0
