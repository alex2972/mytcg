extends SceneTree

var db: CardDB
var fails := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)
func idx(card_name: String) -> int:
	for i in range(1, db.cards.size()):
		if db.card_name(i) == card_name: return i
	return 0
func fresh() -> Duel:
	var deck := Deck.load_file("res://data/default_deck.ydc", db)
	var d := Duel.create(db, deck, deck, 5, 0)
	for p in 2:
		d.side(p).deck.clear()
		d.side(p).hand.clear()
		d.side(p).grave.clear()
	d.phase = "main1"
	d.drain_events()
	d.fx.presentation_enabled = true
	return d
func card(d: Duel, card_name: String, p := 0) -> DCard:
	return d._new_card(idx(card_name), p)
func begin(d: Duel, src: DCard) -> Dictionary:
	var ctx := {"src": src, "controller": src.controller, "vars": {}, "event": {}}
	d.fx.resolving = true # This op normally runs inside the resolving Flip chain.
	d.fx.push_script([{"op": "custom", "fn": "morphing_jar2"}], ctx)
	d.fx.pump()
	return ctx
func finish(d: Duel) -> Array:
	var events := d.drain_events()
	var guard := 0
	while not d.fx.pending.is_empty() and guard < 200:
		guard += 1
		check(d.fx.pending.type == "presentation", "resolution requires no card choices")
		d.respond(true)
		events.append_array(d.drain_events())
	check(guard < 200 and d.fx.tasks.is_empty(), "resolution terminates without stalled cards")
	return events
func _init() -> void:
	db = CardDB.load_default()
	var d := fresh()
	var jar := d.debug_place(0, idx("Morphing Jar #2"), 0)
	var high := d.debug_place(0, idx("Blue-Eyes White Dragon"), 1)
	var stolen := d.debug_place(0, idx("Armored Starfish"), 2)
	d.side(0).monsters[2] = null
	d.side(1).monsters[0] = stolen
	stolen.controller = 1
	var fusion := d.debug_place(0, idx("Flame Swordsman"), 3)
	var token := d.new_token("Sheep Token", 0)
	d.side(0).monsters[4] = token
	d.drain_events()
	var ctx := begin(d, jar)
	check(ctx.vars.jar2.remaining == [3, 0], "all Levels count, by owner; Fusion and token do not")
	check(d.side(0).extra.has(fusion) and not d.side(0).deck.has(fusion), "Fusion returns to Extra Deck")
	check(not d.is_on_field(token) and not d.side(0).deck.has(token), "token vanishes")
	var initial := d.drain_events()
	check(initial.filter(func(e): return e.type == "shuffle").size() == 1, "affected deck shuffles once after all returns")
	check(d.monsters_of(0).is_empty() and d.monsters_of(1).is_empty(), "all field monsters return before excavation")
	# Override the shuffled order at its presentation barrier to exercise exact top-card semantics.
	var spell := card(d, "Raigeki")
	var low1 := card(d, "Axe Raider")
	var low2 := card(d, "Armored Lizard")
	d.side(0).deck = [jar, stolen, low2, low1, high, spell]
	var events := finish(d)
	var excavated: Array = events.filter(func(e): return e.type == "excavate").map(func(e): return e.uid)
	check(excavated == [spell.uid, high.uid, low1.uid, low2.uid], "high-Level excavated monster consumes count; spells do not")
	check(d.side(0).grave == [spell, high], "remaining cards go to Graveyard in excavation order")
	check(d.monsters_of(0).size() == 2 and d.monsters_of(0).has(low1) and d.monsters_of(0).has(low2), "only Level 4 or lower monsters summon")
	check(not low1.face_up and low1.pos == "def" and not low2.face_up and low2.pos == "def", "summons are face-down Defense")
	check(d.side(0).deck == [jar, stolen], "excavation stops exactly at requested monster count")
	check(events.any(func(e): return e.type == "shuffle_set_monsters"), "multiple newly Set monsters are shuffled after excavation")
	check(not events.any(func(e): return e.type in ["draw", "discard"]) and d.fx.queued.all(func(e): return e.event != "discarded"), "excavation does not trigger drawing or hand-discard effects")
	check(not ctx.vars.has("jar2"), "resolution state is cleaned up")
	# Opponent's turn: its cards are picked up first, irrespective of Jar's owner.
	d = fresh()
	d.turn_player = 1
	jar = d.debug_place(0, idx("Morphing Jar #2"), 0)
	var opponent := d.debug_place(1, idx("Blue-Eyes White Dragon"), 0)
	begin(d, jar)
	d.drain_events()
	low1 = card(d, "Axe Raider")
	d.side(0).deck = [jar, low1]
	d.side(1).deck = [opponent]
	events = finish(d)
	var picks: Array = events.filter(func(e): return e.type == "excavate")
	check(picks.size() == 2 and picks[0].player == 1 and picks[1].player == 0, "turn player resolves excavation first")
	check(d.side(1).grave.has(opponent) and d.monsters_of(1).is_empty(), "high-Level return still requires one excavation and no summon")
	# Summon prevention used to leave the same top card in an infinite loop.
	d = fresh()
	jar = d.debug_place(0, idx("Morphing Jar #2"), 0)
	begin(d, jar)
	d.drain_events()
	low1 = card(d, "Axe Raider")
	d.side(0).deck = [jar, low1]
	d.add_turn_rule("no_summon", 0)
	events = finish(d)
	check(d.side(0).grave.has(low1) and d.side(0).deck == [jar], "unsummonable monster goes to Graveyard and still consumes count")
	# Picking up fewer cards than requested is not a failed draw/deck-out.
	d = fresh()
	jar = d.debug_place(0, idx("Morphing Jar #2"), 0)
	begin(d, jar)
	d.drain_events()
	spell = card(d, "Raigeki")
	d.side(0).deck = [spell]
	finish(d)
	check(d.side(0).deck.is_empty() and d.side(0).grave.has(spell) and d.winner == -1, "empty deck ends excavation safely without draw loss")
	# A battle Flip removes both combatants before calculation and leaves no stale attack.
	d = fresh()
	d.fx.presentation_enabled = false
	d.no_first_turn_attack = false
	d.phase = "battle"
	var attacker := d.debug_place(0, idx("Blue-Eyes White Dragon"), 0)
	attacker.summon_turn = -1
	jar = d.debug_place(1, idx("Morphing Jar #2"), 0, false, "def")
	check(d.attack(0, attacker, jar) == "", "battle attack flips Jar normally")
	check(d.current_attack.is_empty() and d.fx.pending.is_empty(), "battle Flip completes without a stale combat decision")
	check(d.side(0).lp == 8000 and d.side(1).lp == 8000, "returned combatants do not inflict stale battle damage")
	check(d.side(0).grave.has(attacker) and d.side(1).monsters.has(jar) and not jar.face_up, "battle Flip resolves both excavations correctly")
	print("Morphing Jar #2: ", "OK" if fails == 0 else str(fails) + " FAILED")
	quit(0 if fails == 0 else 1)
