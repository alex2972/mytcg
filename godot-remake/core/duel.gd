class_name Duel
extends RefCounted
## Headless duel engine: zones, turn/phase flow, summoning, battle, life points, win conditions, and the
## effect engine (core/effects/fx.gd) hooked in through events and response windows.
## All player-facing changes are appended to `events` so a UI can animate them.
## Action methods return "" on success or a short reason string on failure. When an action opens a decision
## (a trap you may chain, a target to pick, ...) `fx.pending` is set: answer it with respond().
##
## Rules source: the original game's own tutorial text (dialog strings 4201-4265) plus standard
## rules where the tutorial is silent. Items marked ASSUMPTION are not yet confirmed against the exe.

const START_LP := 8000
const START_HAND := 5
const HAND_LIMIT := 6        # ASSUMPTION: standard 6-card hand limit at the end phase
const ZONES := 5
const PHASES := ["draw", "standby", "main1", "battle", "main2", "end"]

class PlayerSide:
	extends RefCounted
	var lp := START_LP
	var deck: Array = []         ## DCard, top = last
	var hand: Array = []
	var monsters: Array = [null, null, null, null, null]
	var spells: Array = [null, null, null, null, null]
	var field_spell: DCard = null
	var grave: Array = []
	var banished: Array = []
	var extra: Array = []        ## Fusion deck

static var _default_effects: EffectDB = null

var db: CardDB
var rng := RandomNumberGenerator.new()
var sides: Array = []
var fx: Fx
var turn := 0                    ## 1-based turn counter (both players share it)
var turn_player := 0
var phase := ""
var normal_summoned := false
var summons_this_turn := [false, false] ## Successful Normal, Flip and Special Summons; excludes Sets.
var no_first_turn_attack := false   ## the original forbids entering the Battle Phase on turn 1
var winner := -1                 ## -1 running, 0/1 winner, 2 draw
var win_reason := ""
var events: Array = []
var cards: Dictionary = {}       ## uid -> DCard
var current_attack: Dictionary = {}
var skipped: Dictionary = {}     ## phase name -> turn it is skipped on
var skip_draw := [false, false]  ## player -> skip their next Draw Phase
var skip_turn := [false, false]        ## Gamble: the player's next turn is skipped
var lockdown_until := -1            ## Cold Wave: no Spell/Trap may be activated or Set while turn < this
var crush_until := [-1, -1]         ## Crush Card: monsters drawn up to this turn with ATK >= 1500 are destroyed
var damage_source := -1               ## monster that is inflicting the damage being dealt (battle)
var dimension_holes: Array = []       ## Dimensionhole: {uid, player} monsters removed from play until their controller's next Standby Phase
var battle_dead: Array = []         ## uids of monsters destroyed in battle this turn
var killer_uid := -1                ## attacker that is destroying a monster in battle right now
var attackers_this_turn: Array = []  ## uids of monsters that attacked this turn
var effect_source: DCard = null ## Source of the currently resolving operation, for Spell immunity.
var effect_player := -1               ## the player whose card effect is destroying something right now (-1: battle, rules or unknown)
var lost_spells: Array = []           ## uids of Spell Cards destroyed by an opponent's card effect this turn (Fairy Guardian)
var soul_exchange := {}              ## Soul Exchange: {player, uid} the opponent's monster that player may Tribute this turn
var next_turn_rules: Array = []       ## {rule, player}: become turn rules at the start of that player's next turn (Mesmeric Control)
var turn_rules: Array = []       ## {rule, player} lasting until the end of the turn
var _next_uid := 1

static func create(card_db: CardDB, deck0: Deck, deck1: Deck, seed_value := 0, first := 0, effect_db: EffectDB = null, deferred_start := false) -> Duel:
	var d := Duel.new()
	d.db = card_db
	d.rng.seed = seed_value
	if effect_db == null:
		if _default_effects == null:
			_default_effects = EffectDB.load_default(card_db)
		effect_db = _default_effects
	d.fx = Fx.new(d, effect_db)
	d.sides = [PlayerSide.new(), PlayerSide.new()]
	for p in 2:
		var deck: Deck = [deck0, deck1][p]
		var s: PlayerSide = d.sides[p]
		for i in deck.main:
			s.deck.append(d._new_card(i, p))
		for i in deck.extra:
			s.extra.append(d._new_card(i, p))
		d._shuffle(s.deck)
		if not deferred_start:
			for k in START_HAND:
				if not s.deck.is_empty():
					s.hand.append(s.deck.pop_back())
	d.turn_player = first
	if deferred_start:
		d.phase = "opening"
	else:
		d._begin_turn()
	return d

func _new_card(idx: int, owner: int) -> DCard:
	var c := DCard.new(_next_uid, idx, owner, int(db.card(idx).get("number", 0)))
	cards[c.uid] = c
	_next_uid += 1
	return c

## Frees a finished duel: the engine objects reference each other (Duel <-> Fx <-> FxOps, equip links,
## tasks holding callables), which reference counting alone never releases. Long-running servers call this.
func dispose() -> void:
	for c in cards.values():
		c.equipped_to = null
		c.equips = []
	if fx != null:
		fx.tasks.clear()
		fx.pending = {}
		fx.chain.clear()
		if fx.ops != null:
			fx.ops.fx = null
			fx.ops.duel = null
		fx.ops = null
		fx.duel = null
	fx = null
	events.clear()
	cards.clear()
	sides.clear()
	current_attack = {}

func card_by_uid(uid: int) -> DCard:
	return cards.get(uid)

func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

func _emit(type: String, data := {}) -> void:
	data["type"] = type
	events.append(data)

func log_event(type: String, data := {}) -> void:
	_emit(type, data)

func drain_events() -> Array:
	var e := events
	events = []
	return e

# --- queries -----------------------------------------------------------------

func side(p: int) -> PlayerSide:
	return sides[p]

func opponent(p: int) -> int:
	return 1 - p

## Tokens created by effects (Scapegoat, Insect Queen). They have no CardDB entry; their stats live here.
const TOKENS := {
	"Sheep Token": {"type": "monster", "atk": 0, "def": 0, "level": 1, "kind": 11, "attribute": 5, "category": 0, "number": 0,
		"name": {"eng": "Sheep Token"}, "desc": {"eng": "Beast / EARTH / Level 1. Cannot be used as a Tribute."}},
	"Slime Token": {"type": "monster", "atk": 500, "def": 500, "level": 1, "kind": 14, "attribute": 3, "category": 0, "number": 0,
		"name": {"eng": "Slime Token"}, "desc": {"eng": "Aqua / WATER / Level 1."}},
	"Hat Token": {"type": "monster", "atk": 0, "def": 0, "level": 1, "kind": 18, "attribute": 2, "category": 0, "number": 0,
		"name": {"eng": "Hat"}, "desc": {"eng": "A decoy created by Magical Hats. Destroyed at the end of the Battle Phase."}},
	"Kuriboh Token": {"type": "monster", "atk": 300, "def": 200, "level": 1, "kind": 3, "attribute": 2, "category": 0, "number": 0,
		"name": {"eng": "Kuriboh Token"}, "desc": {"eng": "Fiend / DARK / Level 1. Cannot be used as a Tribute."}},
	"Insect Monster Token": {"type": "monster", "atk": 100, "def": 100, "level": 1, "kind": 10, "attribute": 5, "category": 0, "number": 0,
		"name": {"eng": "Insect Monster Token"}, "desc": {"eng": "Insect / EARTH / Level 1."}},
}

func card_data(c: DCard) -> Dictionary:
	if c.token != "":
		return TOKENS[c.token]
	return db.card(c.idx)

func is_monster(c: DCard) -> bool:
	return card_data(c).get("type", "") == "monster"

func new_token(kind: String, owner: int) -> DCard:
	var c := _new_card(0, owner)
	c.token = kind
	return c

func roll_die() -> int:
	return rng.randi_range(1, 6)

func level_of(c: DCard) -> int:
	return int(card_data(c).get("level", 0))

func atk_of(c: DCard) -> int:
	return maxi(0, int(card_data(c).get("atk", 0)) + c.atk_bonus + fx.stat_bonus(c, "atk"))

func def_of(c: DCard) -> int:
	return maxi(0, int(card_data(c).get("def", 0)) + c.def_bonus + fx.stat_bonus(c, "def"))

func tributes_required(c: DCard) -> int:
	for e in fx.effects_of(c):
		if e.get("rule", "") == "free_summon_behind" and monsters_of(opponent(c.owner)).size() >= monsters_of(c.owner).size() + 2:
			return 0
	if int(card_data(c).get("kind", 0)) == 24:
		return 3                         # ASSUMPTION: the three gods need 3 tributes
	var lv := level_of(c)
	return 0 if lv <= 4 else 1 if lv <= 6 else 2

func monsters_of(p: int) -> Array:
	return (sides[p].monsters as Array).filter(func(c): return c != null)

func free_zone(arr: Array) -> int:
	var owner := -1
	if is_same(arr, sides[0].monsters):
		owner = 0
	elif is_same(arr, sides[1].monsters):
		owner = 1
	for i in arr.size():
		if arr[i] == null and not (owner != -1 and zone_blocked(owner, i)):
			return i
	return -1

## Ground Collapse: zones that cannot be used while the card is face-up.
func zone_blocked(owner: int, zone: int) -> bool:
	for p in 2:
		for src in fx.cards_controlled(p):
			if not src.face_up:
				continue
			for e in fx.effects_of(src):
				if e.get("rule", "") == "ground_collapse":
					for b in src.flags.get("blocked", []):
						if int(b["side"]) == owner and int(b["zone"]) == zone:
							return true
	return false

## The Type a monster counts as (DNA Surgery changes it for every face-up monster).
func race_of(c: DCard) -> int:
	if not is_monster(c):
		return 0
	for eq in c.equips:                          # Dragonic Attack: the equipped monster is treated as another Type
		if eq.equip_mod.has("race") and not fx.rule_active("no_equip") and not fx._negated_this_turn(eq) and not spell_unaffected(c, eq):
			return int(eq.equip_mod["race"])
	for p in 2:
		for src in fx.cards_controlled(p):
			if src.face_up and src.flags.has("dna_race"):
				for e in fx.effects_of(src):
					if e.get("rule", "") == "dna_surgery":
						return int(src.flags["dna_race"])
	return int(card_data(c).get("kind", 0))

func in_main_phase() -> bool:
	return phase == "main1" or phase == "main2"

## A decision (chain response, target, confirmation) is waiting for `fx.pending.player`.
func pending() -> Dictionary:
	return fx.pending

func respond(answer) -> String:
	return fx.respond(answer)

func _guard(p: int, ignore_busy := false) -> String:
	if winner != -1:
		return "The duel is over."
	if fx.is_busy() and not ignore_busy:
		return "Resolve the pending decision first."
	if p != turn_player:
		return "Not your turn."
	return ""

# --- turn flow ---------------------------------------------------------------

func _begin_turn() -> void:
	turn += 1
	battle_dead.clear()
	lost_spells.clear()
	for r in next_turn_rules.duplicate():
		if int(r["player"]) == turn_player:
			next_turn_rules.erase(r)
			turn_rules.append(r)
	for c in (sides[turn_player].banished as Array).duplicate():
		if int(c.flags.get("return_turn", 1000000)) <= turn:
			c.flags.erase("return_turn")
			sides[turn_player].banished.erase(c)
			c.face_up = false
			sides[turn_player].hand.append(c)
			_emit("to_hand", {"player": turn_player, "uid": c.uid})
	# Count actual controller turns, including skipped turns, rather than global turn arithmetic.
	for eq in fx.cards_controlled(0) + fx.cards_controlled(1):
		if eq.equipped_to != null and eq.equipped_to.controller == turn_player and db.card_name(eq.idx) == "Cocoon of Evolution":
			eq.flags["cocoon_turns"] = int(eq.flags.get("cocoon_turns", 0)) + 1
	if skip_turn[turn_player]:
		skip_turn[turn_player] = false
		_emit("turn_skipped", {"player": turn_player})
		_end_of_turn_cleanup()
		turn_player = opponent(turn_player)
		_begin_turn()
		return
	normal_summoned = false
	summons_this_turn = [false, false]
	for h in dimension_holes.duplicate():
		if int(h["player"]) == turn_player:
			dimension_holes.erase(h)
			var back := card_by_uid(int(h["uid"]))
			if back != null and (sides[turn_player].banished as Array).has(back):
				special_summon(back, turn_player, "atk", true)
	for p in 2:
		for c in monsters_of(p):       # both sides: a monster taken with Change of Heart must not keep its old "already attacked"
			c.reset_turn_flags()
	_emit("turn", {"turn": turn, "player": turn_player})
	fx.after_presentation(_begin_draw_phase)

func _begin_draw_phase() -> void:
	if winner != -1:
		return
	phase = "draw"
	_emit("phase", {"phase": phase, "player": turn_player})
	fx.after_presentation(_draw_for_turn)

func _draw_for_turn() -> void:
	var s: PlayerSide = sides[turn_player]
	if s.deck.is_empty():
		_win(opponent(turn_player), "deck_out")
		return
	if skip_draw[turn_player]:
		skip_draw[turn_player] = false
	else:
		draw_cards(turn_player, 1)
	phase = "standby"
	_emit("phase", {"phase": phase, "player": turn_player})
	fx.after_presentation(func(): fx.window("standby_phase", {"player": turn_player}, _enter_main1))

func _enter_main1() -> void:
	if winner != -1:
		return
	phase = "main1"
	_emit("phase", {"phase": phase, "player": turn_player})

func to_battle(p: int) -> String:
	var g := _guard(p)
	if g != "":
		return g
	if phase != "main1":
		return "You can only enter the Battle Phase from Main Phase 1."
	if skipped.get("battle", -1) == turn:
		return "The Battle Phase is skipped this turn."
	if no_first_turn_attack and turn == 1:
		return "You cannot attack on the first turn."
	phase = "battle"
	add_turn_rule("battle_entered", p)
	_emit("phase", {"phase": phase, "player": p})
	return ""

func to_main2(p: int) -> String:
	var g := _guard(p)
	if g != "":
		return g
	if phase != "battle":
		return "Main Phase 2 follows the Battle Phase."
	_apply_battle_end()
	phase = "main2"
	_emit("phase", {"phase": phase, "player": p})
	return ""

## Goblin Attack Force style effects: attackers turn to Defense Position when the Battle Phase ends.
func _apply_battle_end() -> void:
	for p in 2:
		for c in monsters_of(p):
			if c.flags.get("destroy_at_battle_end", false):
				destroy_card(c, "effect")
	for p in 2:
		for c in monsters_of(p):
			if c.flags.get("atk_after_battle", false):
				c.flags.erase("atk_after_battle")
				force_position(c, "atk", true)
	for c in monsters_of(turn_player):
		if c.flags.get("def_after_battle", false):
			c.flags.erase("def_after_battle")
			force_position(c, "def", true)
			c.flags["lock_pos_until"] = turn + 2

func skip_phase(ph: String) -> void:
	skipped[ph] = turn
	if phase == "battle" and ph == "battle":
		_apply_battle_end()
		phase = "main2"
		_emit("phase", {"phase": phase, "player": turn_player})

func hand_excess(p: int) -> int:
	if fx.rule_active("no_hand_limit"):         # Infinite Cards
		return 0
	return maxi(0, (sides[p].hand as Array).size() - HAND_LIMIT)

## Ends the turn. If the hand is over the limit, `discards` must name (by uid) exactly the excess cards.
func end_turn(p: int, discards: Array = []) -> String:
	var g := _guard(p)
	if g != "":
		return g
	var s: PlayerSide = sides[p]
	var excess := hand_excess(p)
	if discards.size() != excess:
		return "Discard %d card(s) from your hand." % excess
	for uid in discards:
		if _find_in(s.hand, uid) == null:
			return "Invalid discard."
	phase = "end"
	_emit("phase", {"phase": phase, "player": p})
	fx.after_presentation(func(): fx.window("end_phase", {"player": p}, func(): _finish_turn(p, discards)))
	return ""

func _finish_turn(p: int, discards: Array) -> void:
	if winner != -1:
		return
	var s: PlayerSide = sides[p]
	for uid in discards:
		var c := _find_in(s.hand, uid)
		if c != null:
			send_to_grave(c, "discard")
	_end_of_turn_cleanup()
	turn_player = opponent(turn_player)
	_begin_turn()

func _end_of_turn_cleanup() -> void:
	soul_exchange = {}
	for p in 2:
		for c in monsters_of(p):
			if int(c.flags.get("doom_turn", -1)) == turn:        # Zone Eater, Swordsman from a Foreign Land, Steel Scorpion
				destroy_card(c, "effect")
	if has_turn_rule("inf_dismissal", 0) or has_turn_rule("inf_dismissal", 1):
		# Infinite Dismissal: Level 3 or lower monsters summoned (not Special Summoned) this turn are destroyed
		for p in 2:
			for c in monsters_of(p):
				if c.summon_turn == turn and level_of(c) <= 3 and not bool(c.flags.get("special_summoned", false)) and c.token == "":
					destroy_card(c, "effect")
	for p in 2:
		for c in monsters_of(p):
			if c.flags.get("destroy_at_end", false) or c.flags.get("destroy_at_battle_end", false):
				destroy_card(c, "effect")
	for p in 2:
		for c in (sides[p].hand as Array).duplicate():
			if c.borrowed_from != -1:
				send_to_grave(c, "returned")
	for c in cards.values():
		c.expire_mods("end_turn")
		c.expire_mods("turn:%d" % turn)
		if c.flags.get("control_until", "") == "end_turn":
			c.flags.erase("control_until")
			take_control(c, c.owner, "forever")
	current_attack = {}
	turn_rules.clear()
	attackers_this_turn.clear()

func _find_in(arr: Array, uid: int) -> DCard:
	for c in arr:
		if c != null and c.uid == uid:
			return c
	return null

# --- card movement -----------------------------------------------------------------

## Remove `c` from whichever zone it is in (any side). Detaches equips; does not place it anywhere.
func _detach(c: DCard) -> void:
	for p in 2:
		var s: PlayerSide = sides[p]
		for arr in [s.deck, s.hand, s.grave, s.banished, s.extra]:
			if (arr as Array).has(c):
				(arr as Array).erase(c)
		for arr2 in [s.monsters, s.spells]:
			var i: int = (arr2 as Array).find(c)
			if i != -1:
				arr2[i] = null
		if s.field_spell == c:
			s.field_spell = null
	if c.equipped_to != null:
		c.equipped_to.equips.erase(c)
		c.equipped_to = null
	c.equip_mod = {}

func _leave_field_cleanup(c: DCard) -> void:
	for src in fx.cards_controlled(0) + fx.cards_controlled(1):
		if src.flags.has("prohibition_exempt"):
			(src.flags["prohibition_exempt"] as Array).erase(c.uid)
	# equips on a monster that leaves play go to the graveyard
	for eq in c.equips.duplicate():
		send_to_grave(eq, "equip_lost")
	c.equips.clear()
	c.atk_bonus = 0
	c.def_bonus = 0
	c.mods.clear()
	var partner: int = int(c.flags.get("bound", -1))
	var stolen: int = int(c.flags.get("steals", -1))
	c.flags.clear()
	if stolen != -1:
		var victim := card_by_uid(stolen)
		if victim != null and is_on_field(victim) and victim.controller != victim.owner:
			take_control(victim, victim.owner, "forever")
	if partner != -1:
		var other := card_by_uid(partner)
		if other != null and is_on_field(other):
			other.flags.erase("bound")
			destroy_card(other, "bound")

func is_on_field(c: DCard) -> bool:
	for p in 2:
		var s: PlayerSide = sides[p]
		if (s.monsters as Array).has(c) or (s.spells as Array).has(c) or s.field_spell == c:
			return true
	return false

func send_to_grave(c: DCard, reason: String) -> void:
	if reason in ["effect", "destroyed:effect"] and spell_unaffected(c, effect_source):
		return
	var was_on_field := is_on_field(c)
	var from_zone := "field" if was_on_field else ""
	for zone_name in ["hand", "deck", "grave", "banished", "extra"]:
		if from_zone == "" and ((sides[c.owner].get(zone_name) as Array).has(c) or (sides[1 - c.owner].get(zone_name) as Array).has(c)):
			from_zone = zone_name
	var from_ctrl := c.controller
	var was_face_up := c.face_up
	var was_flipped: bool = c.flags.get("was_flipped", false)
	var was_pos := c.pos
	if c.home_owner != -1:
		c.owner = c.home_owner
		c.home_owner = -1
	if c.borrowed_from != -1:
		c.owner = c.borrowed_from
		c.borrowed_from = -1
	_detach(c)
	if was_on_field:
		_leave_field_cleanup(c)
	if c.token != "":
		_emit("token_gone", {"player": from_ctrl, "uid": c.uid})
		return
	if fx.rule_active("banish_graveyard"):        # Banisher of the Light: removed from play instead of the Graveyard
		banish_card(c)
		if reason.begins_with("destroyed"):
			_emit("destroy", {"player": c.owner, "uid": c.uid, "reason": reason})
			fx.window("destroyed", {"player": from_ctrl, "uid": c.uid, "reason": reason, "killer": killer_uid, "pos": was_pos, "was_face_up": was_face_up})
		return
	c.controller = c.owner
	c.face_up = true
	c.pos = "atk"
	sides[c.owner].grave.append(c)
	if reason == "fusion_material":
		c.flags["fusion_mat"] = true      # Supply: remembers it was sent to the Graveyard by a Fusion Summon
	_emit("to_grave", {"player": c.owner, "uid": c.uid, "reason": reason})
	if reason == "destroyed:battle":
		battle_dead.append(c.uid)
	if reason.begins_with("destroyed"):
		_emit("destroy", {"player": c.owner, "uid": c.uid, "reason": reason})
		if effect_player != -1 and effect_player != c.owner and card_data(c).get("type", "") == "spell":
			lost_spells.append(c.uid)
		fx.window("destroyed", {"player": from_ctrl, "uid": c.uid, "reason": reason, "killer": killer_uid, "pos": was_pos, "was_face_up": was_face_up, "by": effect_player})
	fx.window("sent_to_grave", {"player": from_ctrl, "uid": c.uid, "reason": reason, "was_on_field": was_on_field, "from": from_zone, "by": effect_player, "killer": killer_uid,
		"was_face_up": was_face_up, "was_flipped": was_flipped, "pos": was_pos})
	if reason == "discard" and fx.has_listener("discarded"):
		fx.window("discarded", {"player": from_ctrl, "uid": c.uid})

func destroy_card(c: DCard, reason: String) -> void:
	if not is_on_field(c):
		return
	if effect_player != -1 and effect_player != c.controller and card_data(c).get("type", "") == "trap" and card_data(c).get("subtype_name", "") != "":
		for fake in sides[c.controller].spells:          # Fake Trap takes the place of the Trap Card that would be destroyed
			if fake != null and fake != c and db.card_name(fake.idx) == "Fake Trap" and not prohibited(fake):
				send_to_grave(fake, "destroyed:" + reason)
				return
	send_to_grave(c, "destroyed:" + reason)

func return_to_hand(c: DCard) -> void:
	if spell_unaffected(c, effect_source):
		return
	var was_on_field := is_on_field(c)
	var from_controller: int = c.controller
	_detach(c)
	if was_on_field:
		_leave_field_cleanup(c)
	if c.token != "":
		return
	c.controller = c.owner
	c.face_up = false
	if not db.fusion_recipe(db.card_name(c.idx)).is_empty():
		sides[c.owner].extra.append(c)
		_emit("to_deck", {"player": c.owner, "uid": c.uid})
		return
	sides[c.owner].hand.append(c)
	_emit("to_hand", {"player": c.owner, "uid": c.uid})
	check_exodia(c.owner)
	if was_on_field and fx.has_listener("returned_to_hand"):
		fx.window("returned_to_hand", {"player": from_controller, "uid": c.uid, "by": effect_player})

func return_to_deck(c: DCard, where := "top") -> void:
	if spell_unaffected(c, effect_source):
		return
	var was_on_field := is_on_field(c)
	var from_controller: int = c.controller
	_detach(c)
	if was_on_field:
		_leave_field_cleanup(c)
	if c.token != "":
		_emit("token_gone", {"player": from_controller, "uid": c.uid})
		return
	c.controller = c.owner
	c.face_up = false
	if is_monster(c) and int(card_data(c).get("category", -1)) == 2:
		sides[c.owner].extra.append(c)
		_emit("to_deck", {"player": c.owner, "uid": c.uid, "extra": true})
		return
	var deck: Array = sides[c.owner].deck
	if where == "bottom":
		deck.push_front(c)
	else:
		deck.append(c)
	if where == "shuffle":
		_shuffle(deck)
	_emit("to_deck", {"player": c.owner, "uid": c.uid})

func banish_card(c: DCard) -> void:
	if spell_unaffected(c, effect_source):
		return
	var was_on_field := is_on_field(c)
	_detach(c)
	if was_on_field:
		_leave_field_cleanup(c)
	if c.token != "":
		_emit("token_gone", {"player": c.controller, "uid": c.uid})
		return
	c.controller = c.owner
	c.face_up = true
	sides[c.owner].banished.append(c)
	_emit("banish", {"player": c.owner, "uid": c.uid})

func shuffle_deck(p: int) -> void:
	_shuffle(sides[p].deck)
	_emit("shuffle", {"player": p})

func draw_cards(p: int, n: int) -> void:
	for i in n:
		var s: PlayerSide = sides[p]
		if s.deck.is_empty():
			_win(opponent(p), "deck_out")
			return
		var c: DCard = s.deck.pop_back()
		s.hand.append(c)
		_emit("draw", {"player": p, "uid": c.uid})
		if c.planted_by != -1 and c.planted_by != p:
			# Parasite Paracide jumps out of the deck onto the drawer's field
			c.planted_by = -1
			damage_player(p, 1000, "effect")
			if free_zone(s.monsters) != -1:
				special_summon(c, p, "def", true)
		elif crush_until[p] >= turn and is_monster(c) and atk_of(c) >= 1500:
			send_to_grave(c, "crush_card")
		check_exodia(p)
		if fx.has_listener("drew"):
			fx.window("drew", {"player": p, "uid": c.uid, "phase": phase})

const EXODIA := ["Exodia the Forbidden One", "Left Leg of the Forbidden One", "Right Leg of the Forbidden One", "Left Arm of the Forbidden One", "Right Arm of the Forbidden One"]

## Holding all five pieces in hand wins the duel.
func check_exodia(p: int) -> void:
	if winner != -1:
		return
	var names := (sides[p].hand as Array).map(func(c): return db.card_name(c.idx))
	for piece in EXODIA:
		if not names.has(piece):
			return
	_win(p, "exodia")

func special_summon(c: DCard, p: int, position := "atk", face_up := true) -> String:
	var why: String = special_summon_problem(c, p, effect_source != null and effect_source != c)
	if why != "":
		return why
	if c.token == "" and (fx.rule_active("no_summon_any") or fx.rule_active("no_special_summon")) and not c.flags.get("allow_summon", false):
		return "A card effect prevents Special Summons."
	var s: PlayerSide = sides[p]
	var z: int = free_zone(s.monsters)
	if z == -1:
		return "Your Monster Card Zone is full."
	var origin := "field"
	for zone_name in ["hand", "deck", "grave", "banished", "extra"]:
		if (sides[c.owner].get(zone_name) as Array).has(c):
			origin = zone_name
	_detach(c)
	c.controller = p
	s.monsters[z] = c
	c.face_up = face_up or fx.rule_active("no_set")
	c.pos = position
	c.summon_turn = turn
	c.flags["special_summoned"] = true
	summons_this_turn[p] = true
	_emit("special_summon", {"player": p, "uid": c.uid, "zone": z, "face_up": c.face_up, "pos": c.pos})
	fx.window("special_summoned", {"player": p, "uid": c.uid, "from": origin})
	return ""

func place_spell_from_hand(c: DCard, is_field: bool) -> void:
	var s: PlayerSide = sides[c.controller]
	s.hand.erase(c)
	c.face_up = true
	c.summon_turn = turn
	if is_field:
		if s.field_spell != null:
			send_to_grave(s.field_spell, "replaced")
		s.field_spell = c
		_emit("field_spell", {"player": c.controller, "uid": c.uid})
	else:
		var z: int = free_zone(s.spells)
		s.spells[z] = c
		_emit("activate_spell", {"player": c.controller, "uid": c.uid, "zone": z})

func equip_card(equip: DCard, monster: DCard, mod: Dictionary) -> void:
	if fx.rule_active("destroy_equips", monster) and monster.face_up:
		send_to_grave(equip, "equip_lost")
		return
	if equip.equipped_to != null:
		equip.equipped_to.equips.erase(equip)
	equip.equipped_to = monster
	monster.equips.append(equip)
	equip.equip_mod = mod
	if db.card_name(equip.idx) == "Cocoon of Evolution":
		equip.flags["cocoon_turns"] = 0
	_emit("equip", {"uid": equip.uid, "target": monster.uid})
	if fx.has_listener("equipped"):
		fx.window("equipped", {"player": equip.controller, "uid": equip.uid, "target": monster.uid})

func take_control(c: DCard, p: int, until := "forever") -> void:
	if spell_unaffected(c, effect_source):
		return
	if c.controller == p:
		return
	var s: PlayerSide = sides[p]
	var z: int = free_zone(s.monsters)
	if z == -1:
		return
	for arr in [sides[c.controller].monsters]:
		var i: int = (arr as Array).find(c)
		if i != -1:
			arr[i] = null
	c.controller = p
	s.monsters[z] = c
	if until == "end_turn":
		c.flags["control_until"] = "end_turn"
	_emit("control", {"player": p, "uid": c.uid})
	if fx.has_listener("control_switched"):
		fx.window("control_switched", {"player": p, "uid": c.uid})

func force_position(c: DCard, position: String, face_up := true, quiet := false) -> void:
	if spell_unaffected(c, effect_source):
		return
	var was_down := not c.face_up
	c.pos = position
	c.face_up = face_up
	if was_down and face_up:
		c.flags["was_flipped"] = true
	if not face_up:
		c.flags.erase("was_flipped")
		# Cocoon cannot remain equipped to a face-down Petit Moth. Losing the
		# Equip also resets its evolution counter before a later equip starts.
		for eq in c.equips.duplicate():
			if db.card_name(eq.idx) == "Cocoon of Evolution":
				send_to_grave(eq, "equip_lost")
	_emit("change_position", {"player": c.controller, "uid": c.uid, "pos": position})
	if was_down and face_up and not quiet:
		fx.window("flipped", {"player": c.controller, "uid": c.uid, "by_battle": false})

## Dark Spirit of the Silent: another of the attacker's monsters takes over the attack (and is turned to Attack Position).
func swap_attacker(new_attacker: DCard) -> void:
	if current_attack.is_empty():
		return
	if new_attacker.pos == "def":
		force_position(new_attacker, "atk", true, true)
	new_attacker.attacked = true
	current_attack["attacker"] = new_attacker
	current_attack["negated"] = false
	_emit("attack_redirected", {"uid": new_attacker.uid})

func redirect_attack(new_target: DCard) -> void:
	if not current_attack.is_empty():
		current_attack["target"] = new_target
		_emit("attack_redirected", {"uid": new_target.uid})

func negate_current_attack() -> void:
	if not current_attack.is_empty():
		current_attack["negated"] = true

func damage_player(p: int, amount: int, reason: String) -> void:
	_damage(p, amount, reason)

func heal_player(p: int, amount: int) -> void:
	if amount <= 0 or winner != -1:
		return
	var s: PlayerSide = sides[p]
	s.lp += amount
	_emit("heal", {"player": p, "amount": amount, "lp": s.lp})
	if fx.has_listener("healed"):
		fx.window("healed", {"player": p, "amount": amount})

## Chain Energy: LP each player must pay to play or Set a card from the hand ("" when affordable).
func hand_cost_problem(p: int) -> String:
	var cost := fx.rule_total("hand_play_cost")
	if cost > 0 and sides[p].lp <= cost:
		return "Not enough Life Points to play a card from your hand."
	return ""

func pay_hand_cost(p: int) -> void:
	var cost := fx.rule_total("hand_play_cost")
	if cost > 0:
		pay_lp(p, cost)

func pay_lp(p: int, amount: int) -> void:
	var s: PlayerSide = sides[p]
	s.lp = maxi(0, s.lp - amount)
	_emit("damage", {"player": p, "amount": amount, "lp": s.lp, "reason": "cost"})
	if s.lp == 0:
		_win(opponent(p), "life_points")

func set_lp(p: int, value: int) -> void:
	var s: PlayerSide = sides[p]
	var diff: int = value - s.lp
	s.lp = maxi(0, value)
	_emit("heal" if diff > 0 else "damage", {"player": p, "amount": absi(diff), "lp": s.lp, "reason": "set"})
	if s.lp == 0:
		_win(opponent(p), "life_points")

func force_win(p: int, reason: String) -> void:
	_win(p, reason)

# --- summoning ---------------------------------------------------------------

## Normal Summon (face-up attack) or Set (face-down defense) of a monster from hand.
## Could `p` Normal Summon / Set `c` right now, if the right Tributes were chosen? "" = yes, otherwise the reason. Changes nothing.
func summon_problem(p: int, c: DCard) -> String:
	var s: PlayerSide = sides[p]
	if winner != -1 or p != turn_player or not in_main_phase():
		return "Not now."
	if not s.hand.has(c) or not is_monster(c):
		return "Select a monster from your hand."
	if normal_summoned:
		return "You can only Normal Summon or Set once per turn."
	if has_turn_rule("no_summon", p) or fx.rule_active("no_summon_any"):
		return "A card effect prevents you from summoning this turn."
	for e in fx.effects_of(c):
		if e.get("rule", "") in ["no_normal_summon", "summon_needs"]:
			var blocked := true
			if e["rule"] == "summon_needs":
				blocked = true
				for pl in 2:
					for card in fx.cards_controlled(pl):
						if card.face_up and db.card_name(card.idx) == str(e.get("name", "")):
							blocked = false
			if blocked:
				return "This monster cannot be Normal Summoned or Set."
	var need := tributes_required(c)
	if need > 0:
		if fx.rule_active("no_tribute"):
			return "A card effect prevents Tribute Summons."
		var usable := 0
		for m in monsters_of(p):
			if m.token != "Sheep Token":
				usable += 1
		if usable < need:
			return "Not enough monsters to Tribute."
	elif free_zone(s.monsters) == -1:
		return "Your Monster Card Zone is full."
	return ""

func summon(p: int, c: DCard, tributes: Array = [], zone := -1, set_face_down := false) -> String:
	var g := _guard(p)
	if g != "":
		return g
	if not in_main_phase():
		return "You can only summon during a Main Phase."
	if prohibited(c):
		return "This card is prohibited."
	var s: PlayerSide = sides[p]
	if not s.hand.has(c) or not is_monster(c):
		return "Select a monster from your hand."
	if normal_summoned:
		return "You can only Normal Summon or Set once per turn."
	if hand_cost_problem(p) != "":
		return hand_cost_problem(p)
	if (not set_face_down and (has_turn_rule("no_summon", p) or breeding_machine_active(p))) or fx.rule_active("no_summon_any"):
		return "A card effect prevents you from summoning this turn."
	for e in fx.effects_of(c):
		if e.get("rule", "") == "no_normal_summon":
			return "This monster cannot be Normal Summoned or Set."
		if e.get("rule", "") == "summon_needs":
			var present := false
			for pl in 2:
				for card in fx.cards_controlled(pl):
					if card.face_up and db.card_name(card.idx) == str(e.get("name", "")):
						present = true
			if not present:
				return "This monster cannot be summoned unless %s is on the field." % e.get("name", "")
	var need := tributes_required(c)
	if need > 0 and fx.rule_active("no_tribute"):
		return "A card effect prevents Tribute Summons."
	if tributes.size() != need:
		return "This monster requires %d Tribute(s)." % need
	if set_face_down and fx.rule_active("no_set"):
		set_face_down = false
	for t in tributes:
		var borrowed: bool = int(soul_exchange.get("player", -1)) == p and int(soul_exchange.get("uid", -1)) == t.uid and (sides[opponent(p)].monsters as Array).has(t)
		if not (s.monsters as Array).has(t) and not borrowed:
			return "Tributes must be your monsters on the field."
		if t.token == "Sheep Token" or t.token == "Kuriboh Token":
			return "%ss cannot be used as Tributes." % t.token
	if zone == -1:
		# Reuse the leftmost offered monster's zone, regardless of click order.
		for tribute in tributes:
			var offered_zone: int = s.monsters.find(tribute)
			if offered_zone >= 0 and not zone_blocked(p, offered_zone):
				zone = offered_zone if zone == -1 else mini(zone, offered_zone)
		if zone == -1:
			zone = free_zone(s.monsters)
	elif s.monsters[zone] != null and not tributes.has(s.monsters[zone]):
		return "That zone is occupied."
	if zone == -1:
		return "Your Monster Card Zone is full."
	for t in tributes:
		var from_side: PlayerSide = sides[t.controller]            # Soul Exchange: the Tribute may stand on the opponent's side
		var z: int = (from_side.monsters as Array).find(t)
		from_side.monsters[z] = null
		_leave_field_cleanup(t)
		t.controller = t.owner
		sides[t.owner].grave.append(t)      # a monster I took control of goes to its owner's Graveyard
		t.face_up = true
		_emit("tribute", {"player": p, "uid": t.uid})
	pay_hand_cost(p)
	s.hand.erase(c)
	s.monsters[zone] = c
	var forced_up := fx.rule_active("no_set")
	c.face_up = not set_face_down
	c.pos = "def" if (set_face_down or forced_up) else "atk"
	c.summon_turn = turn
	normal_summoned = true
	_emit("set_monster" if set_face_down else "summon", {"player": p, "uid": c.uid, "zone": zone})
	if set_face_down and fx.has_listener("monster_set"):
		fx.window("monster_set", {"player": p, "uid": c.uid})
	if not set_face_down:
		summons_this_turn[p] = true
		fx.window("summoned", {"player": p, "uid": c.uid})
	return ""

func set_spell_trap(p: int, c: DCard, zone := -1) -> String:
	var g := _guard(p)
	if g != "":
		return g
	if prohibited(c):
		return "This card is prohibited."
	if lockdown_until > turn:
		return "Spell and Trap Cards cannot be Set right now."
	if not in_main_phase():
		return "You can only Set during a Main Phase."
	var s: PlayerSide = sides[p]
	if not s.hand.has(c) or is_monster(c):
		return "Select a Spell or Trap card from your hand."
	if hand_cost_problem(p) != "":
		return hand_cost_problem(p)
	pay_hand_cost(p)
	var is_field: bool = card_data(c).get("subtype_name", "") == "field" and card_data(c).get("type", "") == "spell"
	if is_field:
		if s.field_spell != null:
			send_to_grave(s.field_spell, "replaced")
		s.hand.erase(c)
		s.field_spell = c
		c.face_up = false
		c.summon_turn = turn
		_emit("set_spell", {"player": p, "uid": c.uid, "zone": -1})
		return ""
	if zone == -1:
		zone = free_zone(s.spells)
	if zone == -1 or s.spells[zone] != null:
		return "Your Spell and Trap Card Zone is full."
	s.hand.erase(c)
	s.spells[zone] = c
	c.face_up = false
	c.summon_turn = turn
	_emit("set_spell", {"player": p, "uid": c.uid, "zone": zone})
	return ""

## Switch a monster between attack and defense; a face-down defense monster is Flip Summoned face-up in attack.
func change_position(p: int, c: DCard) -> String:
	if prohibited(c):
		return "This card is prohibited."
	if has_turn_rule("no_position_change", p):
		return "A card effect prevents changing positions this turn."
	if not c.face_up:
		if has_turn_rule("no_summon", p) or breeding_machine_active(p):
			return "A card effect prevents Flip Summons."
		for e in fx.effects_of(c):
			if e.get("rule", "") == "summon_needs" and not has_face_up_name(str(e["name"])):
				return "This monster requires %s on the field." % e["name"]
	var g := _guard(p)
	if g != "":
		return g
	if not in_main_phase():
		return "You can only change positions during a Main Phase."
	if not (sides[p].monsters as Array).has(c):
		return "Select one of your monsters."
	if c.summon_turn == turn:
		return "A monster cannot change position the turn it was summoned or Set."
	if c.pos_changed or c.attacked:
		return "This monster already used its action this turn."
	if fx.rule_active("no_position_change", c) or int(c.flags.get("lock_pos_until", -1)) >= turn:
		return "A card effect prevents position changes."
	c.pos_changed = true
	if not c.face_up:
		c.face_up = true
		c.flags["was_flipped"] = true
		c.pos = "atk"
		summons_this_turn[p] = true
		_emit("flip_summon", {"player": p, "uid": c.uid})
		var data := {"player": p, "uid": c.uid, "by_battle": false}
		fx.window("flip_summoned", data, func(): fx.window("flipped", data))
	else:
		c.pos = "def" if c.pos == "atk" else "atk"
		_emit("change_position", {"player": p, "uid": c.uid, "pos": c.pos})
		if fx.has_listener("position_changed"):
			fx.window("position_changed", {"player": p, "uid": c.uid, "pos": c.pos})
	return ""

# --- effects (voluntary activation) -----------------------------------------------------

## All effects `p` may activate on their own right now: {uid, idx, name}.
func activatable_effects(p: int) -> Array:
	var out := []
	if winner != -1 or fx.is_busy() or p != turn_player:
		return out
	var s: PlayerSide = sides[p]
	var pool: Array = s.hand + fx.cards_controlled(p)
	for c in s.extra + s.deck:                      # Valkyrion, Red-Eyes Black Metal Dragon: summoned from the Extra Deck / Deck
		for e in fx.effects_of(c):
			if e.get("zone", "") in ["extra", "deck"]:
				pool.append(c)
				break
	for c in pool:
		var effs := fx.effects_of(c)
		for i in effs.size():
			var t: String = effs[i].get("type", "")
			if t in ["spell", "equip", "field", "ritual_spell", "quickplay", "ignition", "trap", "counter"] and fx.activation_problem(p, c, i, "", {}) == "":
				out.append({"uid": c.uid, "idx": i, "name": db.card_name(c.idx)})
	return out

func activate_effect(p: int, c: DCard, idx := 0) -> String:
	var g := _guard(p)
	if g != "":
		return g
	return fx.activate(p, c, idx)

# --- battle ------------------------------------------------------------------

func can_attack(p: int, c: DCard, ignore_busy := false) -> String:
	if prohibited(c):
		return "This card is prohibited."
	if fx.rule_active("toon_attack", c) and sides[p].lp <= 500:
		return "Not enough Life Points to attack."
	if fx.attack_cost(c) > 0 and sides[p].lp <= fx.attack_cost(c):
		return "Not enough Life Points to attack."
	if int(c.flags.get("cannot_attack_until", -1)) >= turn:
		return "This monster cannot attack yet (Electric Lizard)."
	var g := _guard(p, ignore_busy)
	if g != "":
		return g
	if phase != "battle":
		return "You can only attack during the Battle Phase."
	if not (sides[p].monsters as Array).has(c):
		return "Select one of your monsters."
	if not c.face_up or (c.pos != "atk" and not fx.rule_active("attack_in_def", c)):
		return "Only face-up monsters in Attack Position can attack."
	var binder := card_by_uid(int(c.flags.get("cannot_attack_by", -1)))
	if binder != null and is_on_field(binder) and binder.face_up:
		return "A card effect prevents this monster from attacking."
	if c.attacked and not (fx.rule_active("double_attack", c) and attackers_this_turn.count(c.uid) < 2):
		return "This monster has already attacked this turn."
	if c.flags.get("cannot_attack", false) or fx.rule_active("no_attack", c):
		return "A card effect prevents this monster from attacking."
	if c.summon_turn == turn and fx.rule_active("no_attack_new", c):
		return "This monster cannot attack the turn it was summoned."
	if fx.rule_active("one_attacker") and attackers_this_turn.has(c.uid) == false and not attackers_this_turn.is_empty():
		return "Only 1 monster can attack this turn."
	return ""

## May `c` attack the opponent's life points although he/she has monsters? (Jinzo #7; Alligator's Sword Dragon vs EARTH/WATER/FIRE only)
func attack_protected(t: DCard) -> bool:
	for e in fx.effects_of(t):
		if e.get("rule", "") == "protected_by_field":
			for pl in 2:
				var fs: DCard = sides[pl].field_spell
				if fs != null and fs.face_up and db.card_name(fs.idx) == str(e.get("name", "")):
					return true
	return false

func can_attack_directly(c: DCard) -> bool:
	if fx.rule_active("toon_attack", c):
		return toon_targets(opponent(c.controller)).is_empty()
	if fx.rule_active("can_attack_directly", c):
		return true
	for e in fx.effects_of(c):
		if e.get("rule", "") == "direct_vs_attributes" and c.face_up:
			var ok := true
			for m in monsters_of(opponent(c.controller)):
				var allowed := false
				for a in e["attributes"]:
					if int(a) == attribute_of(m):
						allowed = true
				if not allowed:
					ok = false
			return ok
	return false

## `target` = opponent monster, or null for a direct attack (only when the opponent has no monsters).
func attack(p: int, c: DCard, target: DCard = null) -> String:
	var why := can_attack(p, c)
	if why != "":
		return why
	var foe := opponent(p)
	if fx.rule_active("toon_attack", c) and not toon_targets(foe).is_empty() and not toon_targets(foe).has(target):
		return "This Toon must attack an opponent Toon monster."
	if target == null:
		if not monsters_of(foe).is_empty() and not can_attack_directly(c):
			return "You must attack one of your opponent's monsters."
		if fx.rule_active("no_direct_attack", c):
			return "This monster cannot attack your opponent directly."
	elif not (sides[foe].monsters as Array).has(target):
		return "Select one of your opponent's monsters."
	elif attack_protected(target):
		return "This monster cannot be attacked right now."
	if fx.rule_active("attack_needs_tribute", c):
		var others := monsters_of(p).filter(func(m): return m != c)
		if others.is_empty():
			return "This monster cannot attack unless you offer a monster as a Tribute."
		var tctx := {"src": c, "controller": p, "vars": {}, "event": {}}
		fx.push_call(func(): _declare_attack(p, c, target))
		fx.push_script([{"op": "select", "as": "tr", "from": "self.monsters", "filter": {"not_src": true}, "n": 1, "cost": true, "prompt": 154},
			{"op": "to_grave", "what": "$tr", "reason": "tribute"}], tctx)
		fx.pump()
		return ""
	_declare_attack(p, c, target)
	return ""

func _declare_attack(p: int, c: DCard, target: DCard) -> void:
	if not (sides[p].monsters as Array).has(c) or winner != -1:
		return
	if fx.rule_active("toon_attack", c):
		pay_lp(p, 500)
	if fx.attack_cost(c) > 0:                     # Dark Elf, Toll
		pay_lp(p, fx.attack_cost(c))
	c.attacked = true
	attackers_this_turn.append(c.uid)
	current_attack = {"attacker": c, "target": target, "negated": false, "player": p}
	_emit("attack", {"player": p, "attacker": c.uid, "target": target.uid if target else -1})
	fx.window("attack_declared", {"player": p, "attacker": c.uid, "target": target.uid if target else -1}, func(): _resolve_attack())

func _resolve_attack() -> void:
	if current_attack.is_empty() or winner != -1:
		return
	var a: DCard = current_attack["attacker"]
	var t: DCard = current_attack["target"]
	var p: int = current_attack["player"]
	var foe := opponent(p) if t == null else t.controller      # a redirected attack may hit the attacker's own side
	if current_attack["negated"] or not (sides[p].monsters as Array).has(a):
		current_attack = {}
		return
	if t != null and not (sides[foe].monsters as Array).has(t):
		current_attack = {}      # the target left the field: the attack is cancelled
		return
	if t == null:
		_open_damage_step(func(): _direct_damage_step())
		return
	# the original announces the chosen target as a separate window ("The target for attack is X", Shift & co. answer here)
	if fx.has_listener("target_declared"):
		fx.window("target_declared", {"player": p, "attacker": a.uid, "target": t.uid}, func(): _after_target())
		return
	_after_target()

func _after_target() -> void:
	if current_attack.is_empty() or winner != -1:
		return
	var a: DCard = current_attack["attacker"]
	var t: DCard = current_attack["target"]
	var p: int = current_attack["player"]
	if t == null:
		_open_damage_step(func(): _direct_damage_step())
		return
	var foe: int = t.controller
	if current_attack["negated"] or not (sides[p].monsters as Array).has(a) or not (sides[foe].monsters as Array).has(t):
		current_attack = {}
		return
	if not t.face_up:
		t.face_up = true
		t.flags["was_flipped"] = true
		_emit("flip", {"player": foe, "uid": t.uid})
		var data := {"player": foe, "uid": t.uid, "by_battle": true}
		fx.window("flipped", data, func(): _open_damage_step(func(): _battle_damage_step()))
		return
	_open_damage_step(func(): _battle_damage_step())

## The original's second battle window: after the attack is declared (and a face-down defender flipped) but before damage is
## calculated. Stat boosters (Reinforcements, Castle Walls, Mask of Weakness, the dice cards...) are played here.
func _open_damage_step(then: Callable) -> void:
	if current_attack.is_empty():
		return
	var a: DCard = current_attack["attacker"]
	var t: DCard = current_attack["target"]
	var data := {"player": current_attack["player"], "attacker": a.uid, "target": t.uid if t != null else -1}
	_emit("damage_step", data)
	fx.window("damage_step", data, then)

func _direct_damage_step() -> void:
	if current_attack.is_empty() or winner != -1:
		return
	var a: DCard = current_attack["attacker"]
	var p: int = current_attack["player"]
	var foe := opponent(p)
	var ok: bool = not current_attack["negated"] and (sides[p].monsters as Array).has(a)
	var open_field := monsters_of(foe).is_empty() or can_attack_directly(a)
	var attack_value: int = atk_of(a)
	current_attack = {}
	if ok and open_field:
		damage_source = a.uid
		_damage(foe, attack_value, "direct_attack")
		damage_source = -1

func _battle_damage_step() -> void:
	if current_attack.is_empty() or winner != -1:
		return
	var a: DCard = current_attack["attacker"]
	var t: DCard = current_attack["target"]
	var p: int = current_attack["player"]
	var foe: int = t.controller
	if current_attack["negated"] or not (sides[p].monsters as Array).has(a) or not (sides[foe].monsters as Array).has(t):
		current_attack = {}
		return
	var attack_value: int = atk_of(a)
	var target_attack: int = atk_of(t)
	var target_defense: int = def_of(t)
	current_attack = {}
	var shielded := fx.rule_active("no_battle_damage_self", a)      # read before anything leaves the field
	var piercing := fx.rule_active("pierce", a)
	if t.pos == "atk":
		var diff := attack_value - target_attack
		if diff > 0:
			killer_uid = a.uid
			destroy_card(t, "battle")
			killer_uid = -1
			damage_source = a.uid
			_damage(foe, diff, "battle")
			damage_source = -1
		elif diff < 0:
			killer_uid = t.uid
			destroy_card(a, "battle")
			killer_uid = -1
			if not shielded:
				_damage(p, -diff, "battle")
		else:
			killer_uid = t.uid
			destroy_card(a, "battle")
			killer_uid = a.uid
			destroy_card(t, "battle")
			killer_uid = -1
	else:
		var diff2 := attack_value - target_defense
		if diff2 > 0:
			killer_uid = a.uid
			destroy_card(t, "battle")           # no damage to a defender
			killer_uid = -1
			if piercing:
				damage_source = a.uid
				_damage(foe, diff2, "battle")
				damage_source = -1
		elif diff2 < 0:
			if not shielded:
				_damage(p, -diff2, "battle")         # the attacker takes the difference, nothing is destroyed
	_bounce_attacker(a)

func _bounce_attacker(a: DCard) -> void:
	if a.flags.get("return_after_battle", false) and is_on_field(a):
		return_to_hand(a)

# --- state changes -----------------------------------------------------------

func add_turn_rule(rule: String, p: int) -> void:
	turn_rules.append({"rule": rule, "player": p})

func has_turn_rule(rule: String, p: int) -> bool:
	for r in turn_rules:
		if r["rule"] == rule and r["player"] == p:
			return true
	return false

func _damage(p: int, amount: int, reason: String) -> void:
	if amount <= 0 or winner != -1:
		return
	if reason in ["battle", "direct_attack"] and has_turn_rule("no_battle_damage", p):
		return
	if reason in ["battle", "direct_attack"]:
		for i in turn_rules.size():
			if turn_rules[i]["rule"] == "no_battle_damage_once" and int(turn_rules[i]["player"]) == p:
				turn_rules.remove_at(i)             # Kuriboh: the damage from 1 monster is 0
				return
	if fx.player_rule("no_damage", p):
		return
	var s: PlayerSide = sides[p]
	s.lp = maxi(0, s.lp - amount)
	_emit("damage", {"player": p, "amount": amount, "lp": s.lp, "reason": reason})
	if s.lp == 0:
		_win(opponent(p), "life_points")
	else:
		fx.window("damaged", {"player": p, "amount": amount, "reason": reason, "source": damage_source})

func _win(p: int, reason: String) -> void:
	if winner != -1:
		return
	winner = p
	win_reason = reason
	fx.tasks.clear()
	fx.pending = {}
	_emit("win", {"player": p, "reason": reason})

func surrender(p: int) -> void:
	_win(opponent(p), "surrender")

# --- test/AI helpers ---------------------------------------------------------

## Put a card straight onto the field (used by tests and scenario setups).
func debug_place(p: int, card_idx: int, zone: int, face_up := true, position := "atk") -> DCard:
	var c := _new_card(card_idx, p)
	c.face_up = face_up
	c.pos = position
	c.summon_turn = -1
	sides[p].monsters[zone] = c
	return c

## Put a Spell/Trap straight onto the field (tests).
func debug_place_spell(p: int, card_idx: int, zone: int, face_up := false) -> DCard:
	var c := _new_card(card_idx, p)
	c.face_up = face_up
	c.summon_turn = -1
	sides[p].spells[zone] = c
	return c

## Put a fresh copy of a card into a hand (tests).
func debug_give(p: int, card_idx: int) -> DCard:
	var c := _new_card(card_idx, p)
	sides[p].hand.append(c)
	return c

## Cards present before Prohibition resolved are exempt until they leave the field.
func prohibited(c: DCard) -> bool:
	for p in 2:
		for src in fx.cards_controlled(p):
			if src.face_up and not fx._negated_this_turn(src) and src.flags.get("prohibited_name", "") == db.card_name(c.idx) and not (src.flags.get("prohibition_exempt", []) as Array).has(c.uid):
				return true
	return false

func special_summon_problem(c: DCard, p: int, by_effect := false) -> String:
	if has_turn_rule("no_summon", p):
		return "A card effect prevents Special Summons this turn."
	if breeding_machine_active(p) and not (c.token == "Slime Token" and effect_source != null and db.card_name(effect_source.idx) == "Jam Breeding Machine" and effect_source.controller == p):
		return "Jam Breeding Machine prevents other summons."
	if prohibited(c) and not by_effect:
		return "This card is prohibited."
	for e in fx.edb.for_number(c.number):
		if e.get("rule", "") == "summon_needs" and not has_face_up_name(str(e["name"])):
			return "This monster requires %s on the field." % e["name"]
		if e.get("rule", "") == "summon_procedure" and not c.flags.get("procedure_authorized", false):
			# Wall Shadow is a Deck-only procedure; the Moth may be revived after a proper Summon.
			if e.get("kind", "") in ["wall_shadow", "metalzoa"] or not c.properly_summoned or fx._zone_of(c) not in ["grave", "banished"]:
				return "This monster requires its own Special Summon procedure."
	if (fx.rule_active("no_special_summon") or fx.rule_active("no_summon_any")) and not c.flags.get("allow_summon", false):
		return "A card effect prevents Special Summons."
	return ""

## The original restricts only the controller; setting monsters remains legal.
func breeding_machine_active(p: int) -> bool:
	for src in fx.cards_controlled(p):
		if not src.face_up:
			continue
		for e in fx.effects_of(src):
			if e.get("type", "") == "static" and e.get("rule", "") == "breeding_machine":
				return true
	return false

func has_face_up_name(name: String) -> bool:
	for c in fx.cards_controlled(0) + fx.cards_controlled(1):
		if c.face_up and db.card_name(c.idx) == name:
			return true
	return false

func spell_unaffected(c: DCard, source: DCard) -> bool:
	if source == null or not is_monster(c) or not c.face_up or not is_on_field(c) or card_data(source).get("type", "") != "spell":
		return false
	for e in fx.effects_of(c):
		if e.get("rule", "") == "spell_immune_umi" and has_face_up_name("Umi"):
			return true
	return false

func attribute_of(c: DCard) -> int:
	if c.face_up and not fx.rule_active("no_equip"):
		for eq in c.equips:
			if eq.face_up and eq.equip_mod.has("attribute") and not fx._negated_this_turn(eq) and not spell_unaffected(c, eq):
				return int(eq.equip_mod["attribute"])
	return int(card_data(c).get("attribute", 0))

func toon_targets(p: int) -> Array:
	return monsters_of(p).filter(func(c): return c.face_up and db.card_name(c.idx) in ["Manga Ryu-Ran", "Toon Mermaid", "Toon Summoned Skull", "Blue-Eyes Toon Dragon"])


func start_opening_deal() -> void:
	if phase == "opening":
		_deal_opening(opponent(turn_player), 0)

func _deal_opening(player: int, count: int) -> void:
	if count >= START_HAND:
		if player != turn_player:
			_deal_opening(turn_player, 0)
		else:
			_begin_turn()
		return
	var hand: PlayerSide = sides[player]
	if hand.deck.is_empty():
		_win(opponent(player), "deck_out")
		return
	var card: DCard = hand.deck.pop_back()
	hand.hand.append(card)
	_emit("draw", {"player": player, "uid": card.uid, "opening": true})
	fx.after_presentation(func(): _deal_opening(player, count + 1))
