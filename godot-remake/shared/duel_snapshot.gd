class_name DuelSnapshot
extends RefCounted
## Builds what one seat may know about a running Duel (server side), as plain data, from that seat's
## point of view: the viewer is always player 0 in the output (seat 1's data is mirrored).
## This is the ONLY place where hidden information is filtered. Rules:
##   - opponent hand, both decks and the opponent's Fusion deck: uids only (decks in a random order);
##   - opponent's face-down field cards: uid, zone and position only;
##   - graveyards and banished cards are public; face-up field cards are public;
##   - the viewer's own cards are fully visible;
##   - `known` carries identities legitimately revealed in this batch (reveal_cards, excavate) and the
##     viewer's own selection candidates; nothing else.
## Events never contain card identities (only uids), so they only need mirroring (`mirror_event`).

const PLAYER_KEYS := ["player", "viewer", "owner", "controller"]

## Snapshot for `viewer` (0/1). `revealed` = {uid: true} for cards this viewer may identify now.
static func build(duel: Duel, viewer: int, revealed := {}, rng: RandomNumberGenerator = null) -> Dictionary:
	var mine := viewer
	var foe := 1 - viewer
	var players := []
	for p: int in [mine, foe]:
		var s: Duel.PlayerSide = duel.side(p)
		var own: bool = p == viewer
		var deck_uids: Array = s.deck.map(func(c): return c.uid)
		_shuffle(deck_uids, rng)
		players.append({
			"lp": s.lp,
			"deck": deck_uids.map(func(u): return _hidden(duel.card_by_uid(u), viewer)),
			"hand": s.hand.map(func(c): return _card(duel, c, viewer) if own else _hidden(c, viewer)),
			"monsters": s.monsters.map(func(c): return null if c == null else (_card(duel, c, viewer) if own or c.face_up else _hidden(c, viewer))),
			"spells": s.spells.map(func(c): return null if c == null else (_card(duel, c, viewer) if own or c.face_up else _hidden(c, viewer))),
			"field_spell": null if s.field_spell == null else (_card(duel, s.field_spell, viewer) if own or s.field_spell.face_up else _hidden(s.field_spell, viewer)),
			"grave": s.grave.map(func(c): return _card(duel, c, viewer)),
			"banished": s.banished.map(func(c): return _card(duel, c, viewer)),
			"extra": s.extra.map(func(c): return _card(duel, c, viewer) if own else _hidden(c, viewer)),
		})
	var out := {
		"turn": duel.turn,
		"turn_player": _seat(duel.turn_player, viewer),
		"phase": duel.phase,
		"winner": duel.winner if duel.winner < 0 or duel.winner == 2 else _seat(duel.winner, viewer),
		"win_reason": duel.win_reason,
		"normal_summoned": duel.normal_summoned,
		"no_first_turn_attack": duel.no_first_turn_attack,
		"current_attack": _attack(duel),
		"soul_exchange": _mirror_dict(duel.soul_exchange, viewer),
		"players": players,
		"chain": duel.fx.chain.map(func(link): return {"card": (link["card"] as DCard).uid if link.get("card") is DCard else -1, "player": _seat(int(link.get("player", 0)), viewer)}),
		"pending": pending_for(duel, viewer),
		"known": {},
		"legal": legal_for(duel, viewer),
	}
	var known := {}
	for uid in revealed:
		var c := duel.card_by_uid(int(uid))
		if c != null:
			known[str(c.uid)] = c.idx
	var pend: Dictionary = duel.fx.pending
	if not pend.is_empty() and int(pend.get("player", -1)) == viewer:
		for uid in pend.get("candidates", []):
			var c := duel.card_by_uid(int(uid))
			if c != null and _may_identify(duel, c, viewer):
				known[str(c.uid)] = c.idx
	out["known"] = known
	return out

## The viewer's decision (with internal data stripped) or a marker that the other seat is deciding.
static func pending_for(duel: Duel, viewer: int) -> Dictionary:
	var pend: Dictionary = duel.fx.pending
	if pend.is_empty():
		return {}
	if int(pend.get("player", -1)) != viewer:
		return {"type": "opponent", "player": 1}
	var out: Dictionary = Protocol.plain(pend)
	return _mirror_dict(out, viewer)

## Precomputed answers to the rule questions the board asks about the viewer's own cards.
static func legal_for(duel: Duel, viewer: int) -> Dictionary:
	var s: Duel.PlayerSide = duel.side(viewer)
	var summon := {}
	var tributes := {}
	for c in s.hand:
		if duel.is_monster(c):
			summon[str(c.uid)] = duel.summon_problem(viewer, c)
			tributes[str(c.uid)] = duel.tributes_required(c)
	var attack := {}
	var direct := {}
	for c in duel.monsters_of(viewer):
		attack[str(c.uid)] = duel.can_attack(viewer, c)
		attack[str(c.uid) + ":idle"] = duel.can_attack(viewer, c, true)
		direct[str(c.uid)] = duel.can_attack_directly(c)
	var effects: Array = []
	if duel.winner == -1:
		effects = Protocol.plain(duel.activatable_effects(viewer))
	return {"summon_problem": summon, "tributes": tributes, "can_attack": attack, "direct": direct,
		"effects": effects, "hand_excess": duel.hand_excess(viewer)}

## Event mirrored for `viewer` (player indices swapped for seat 1). Events carry uids, never identities.
static func mirror_event(e: Dictionary, viewer: int) -> Dictionary:
	var out: Dictionary = Protocol.plain(e)
	return _mirror_dict(out, viewer)

# --- helpers -------------------------------------------------------------------------------------

static func _seat(p: int, viewer: int) -> int:
	return p if viewer == 0 or p < 0 or p > 1 else 1 - p

static func _mirror_dict(d: Dictionary, viewer: int) -> Dictionary:
	var out := d.duplicate(true)
	if viewer == 0:
		return out
	for k in PLAYER_KEYS:
		if out.has(k) and typeof(out[k]) == TYPE_INT:
			out[k] = _seat(int(out[k]), viewer)
		elif out.has(k) and typeof(out[k]) == TYPE_FLOAT:
			out[k] = _seat(int(out[k]), viewer)
	return out

static func _attack(duel: Duel) -> Dictionary:
	var a: Dictionary = duel.current_attack
	if a.is_empty():
		return {}
	var out := {}
	for k in a:
		var v = a[k]
		out[str(k)] = v.uid if v is DCard else Protocol.plain(v)
	return out

## Full card data (visible cards).
static func _card(duel: Duel, c: DCard, viewer: int) -> Dictionary:
	var on_field := duel.is_on_field(c)
	return {
		"uid": c.uid, "idx": c.idx, "owner": _seat(c.owner, viewer), "controller": _seat(c.controller, viewer),
		"face_up": c.face_up, "pos": c.pos, "token": c.token,
		"atk": duel.atk_of(c) if on_field else int(duel.card_data(c).get("atk", 0)),
		"def": duel.def_of(c) if on_field else int(duel.card_data(c).get("def", 0)),
		"level": duel.level_of(c), "summon_turn": c.summon_turn, "attacked": c.attacked, "pos_changed": c.pos_changed,
		"equipped_to": c.equipped_to.uid if c.equipped_to != null else -1,
		"equips": c.equips.map(func(x): return x.uid),
		"flags": Protocol.plain(c.flags),
	}

## A card whose identity this viewer may not see.
static func _hidden(c: DCard, viewer: int) -> Dictionary:
	return {"uid": c.uid, "idx": 0, "hidden": true, "owner": _seat(c.owner, viewer), "controller": _seat(c.controller, viewer),
		"face_up": false, "pos": c.pos, "token": ""}

## May this viewer see the identity of `c` right now (own cards anywhere but the deck, public zones)?
static func _may_identify(duel: Duel, c: DCard, viewer: int) -> bool:
	var s: Duel.PlayerSide = duel.side(c.owner)
	if s.grave.has(c) or s.banished.has(c):
		return true
	if duel.is_on_field(c):
		return c.face_up or c.controller == viewer
	if c.owner == viewer:
		return s.hand.has(c) or s.extra.has(c) or s.deck.has(c)     # searching your own deck shows your cards
	return false

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	if rng == null:
		arr.shuffle()
		return
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
